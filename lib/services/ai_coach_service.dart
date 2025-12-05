import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/habit.dart';
import '../config/app_config.dart';
import 'groq_ai_service.dart';

class AiCoachService {
  AiCoachService._();
  static final AiCoachService instance = AiCoachService._();

  Future<String> getReply({
    required Habit habit,
    required String userMessage,
    required int streak,
    List<Habit>? allHabits, // All user's habits for context
    int? userLevel, // User's level
    int? totalXP, // User's total XP
    // Health data parameters
    int? todaySteps,
    double? todayDistance,
    double? todaySleep,
    int? todayHeartRate,
  }) async {
    if (!AppConfig.isApiConfigured || !AppConfig.useAIForCoaching) {
      return _getFallbackResponse(userMessage);
    }

    try {
      // Build comprehensive user context
      String userContext = '';

      if (allHabits != null && allHabits.isNotEmpty) {
        // Calculate overall stats
        final totalHabits = allHabits.length;
        final completedToday = allHabits.where((h) => h.completedToday).length;
        final avgStreak =
            allHabits.map((h) => h.streak).reduce((a, b) => a + b) /
                totalHabits;

        // Find best and struggling habits
        final sortedByStreak = List<Habit>.from(allHabits)
          ..sort((a, b) => b.streak.compareTo(a.streak));
        final bestHabits = sortedByStreak
            .take(2)
            .map((h) => '${h.name} (${h.streak} days)')
            .join(', ');
        final strugglingHabits = sortedByStreak.reversed
            .take(2)
            .where((h) => h.streak < 3)
            .map((h) => h.name)
            .join(', ');

        final pendingHabits = allHabits
            .where((h) => !h.completedToday)
            .map((h) => h.name)
            .join(', ');

        userContext = '''
USER'S COMPLETE PROFILE:
- Level: ${userLevel ?? 'Unknown'} (${totalXP ?? 0} XP)
- Total habits: $totalHabits
- Completed today: $completedToday/$totalHabits
- Pending today: ${pendingHabits.isNotEmpty ? pendingHabits : 'None! All done 🎉'}
- Average streak: ${avgStreak.toStringAsFixed(1)} days
- Best performing: $bestHabits
${strugglingHabits.isNotEmpty ? '- Needs work: $strugglingHabits' : ''}

All habits: ${allHabits.map((h) => '${h.name} ${h.emoji} (${h.streak}🔥, ${h.category})').join(', ')}
''';
      }

      // Build health context
      String healthContext = '';
      if (todaySteps != null ||
          todayDistance != null ||
          todaySleep != null ||
          todayHeartRate != null) {
        final healthLines = <String>[];
        if (todaySteps != null) {
          healthLines.add(
              '- Steps: ${todaySteps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}');
        }
        if (todayDistance != null) {
          healthLines.add('- Distance: ${todayDistance.toStringAsFixed(2)} km');
        }
        if (todaySleep != null) {
          healthLines.add('- Sleep: ${todaySleep.toStringAsFixed(1)} hours');
        }
        if (todayHeartRate != null) {
          healthLines.add('- Avg Heart Rate: $todayHeartRate bpm');
        }

        if (healthLines.isNotEmpty) {
          healthContext = '''

HEALTH DATA TODAY:
${healthLines.join('\n')}
''';
        }
      }

      // Natural, friendly system prompt with full context
      const systemPrompt =
          '''You're a supportive friend helping someone build better habits. You have their COMPLETE habit data and health metrics.

Keep it real:
- Be warm, encouraging, but honest
- Give ONE clear, actionable tip based on their ACTUAL data
- Keep responses to 2-3 sentences MAX
- Use casual language and emojis
- Reference their health data and habits when relevant
- Sound like you're texting a friend who knows their journey

Example good responses:
"Your running streak is at 12 days - nice! Since you're crushing it there, maybe use that same energy for meditation? 🧘"
"You've done 8,500 steps today but only 5 hours of sleep. Maybe skip the intense workout and prioritize rest tonight? 😴"''';

      final userPrompt = '''$userContext$healthContext

CURRENT CONVERSATION:
They're asking about: "${habit.name}" ${habit.emoji}
Current streak: $streak days
Category: ${habit.category}

User: $userMessage

Give them a quick, friendly response using their data. Be specific. Keep it SHORT and natural.''';

      final response = await GroqAIService.instance.generateResponse(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        maxTokens: 120,
        temperature: 0.8,
      );

      return response ?? _getFallbackResponse(userMessage);
    } catch (e) {
      debugPrint('Error in AiCoachService: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  String _getFallbackResponse(String userMessage) {
    final lower = userMessage.toLowerCase();

    // Natural fallback responses
    if (lower.contains('how') || lower.contains('start')) {
      return 'Start tiny! Like, embarrassingly small. 2 minutes is perfect. Once it\'s a habit, you can go bigger. Trust me on this one 💪';
    }
    if (lower.contains('motivat') || lower.contains('why')) {
      return 'Real talk: the motivation comes AFTER you start, not before. Just do 2 minutes today. That\'s it. You got this! 🔥';
    }
    if (lower.contains('hard') ||
        lower.contains('difficult') ||
        lower.contains('struggle')) {
      return 'Yeah, it\'s tough at first. But here\'s the thing - every streak starts at day 1. You\'re building something solid here. Keep going! 💙';
    }
    if (lower.contains('time') || lower.contains('busy')) {
      return 'I hear you! Try stacking it with something you already do. Like "after coffee" or "before bed". Makes it automatic 🎯';
    }
    if (lower.contains('forget')) {
      return 'Set a simple reminder or put it where you\'ll see it. Phone lock screen, bathroom mirror, whatever works! 📱';
    }

    // Default friendly response
    return 'I\'m here to help! What\'s holding you back? Or what\'s working for you? Let\'s figure this out together 🤝';
  }

  String getQuickEncouragement(int streak) {
    if (streak == 0) {
      return 'Day 1 is the hardest. You got this! 💪';
    } else if (streak < 7) {
      return 'Nice! $streak days down. Keep the momentum! 🔥';
    } else if (streak < 30) {
      return 'Wow, $streak days! You\'re crushing it! 🚀';
    } else {
      return '$streak days?! That\'s seriously impressive! 🏆';
    }
  }

  /// Parse user message to detect task completion intent for sports habits
  Future<Map<String, dynamic>?> parseTaskCompletion(
    String userMessage,
    List<Habit> sportsHabits,
  ) async {
    if (sportsHabits.isEmpty) return null;

    // Check if API is configured
    if (!AppConfig.isApiConfigured || !AppConfig.useAIForCoaching) {
      return _simpleTaskCompletionDetection(userMessage, sportsHabits);
    }

    final habitNames =
        sportsHabits.map((h) => '${h.name} (${h.emoji})').join(', ');

    final prompt = '''
Analyze if the user is reporting completion of a sports/exercise habit.

User's sports habits: $habitNames

User message: "$userMessage"

Respond with ONLY a JSON object in this format:
{
  "isCompletion": true/false,
  "habitName": "exact habit name" or null,
  "confidence": 0.0-1.0
}

If user says they completed/finished/did a habit, set isCompletion to true and identify which habit.
If not sure or not about completing a habit, return isCompletion: false.
''';

    try {
      final response = await http.post(
        Uri.parse(AppConfig.groqApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        },
        body: jsonEncode({
          'model': AppConfig.groqModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a task completion analyzer. Respond ONLY with valid JSON.'
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3, // Lower temperature for more consistent output
          'max_tokens': 100,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('AI task completion parsing failed: ${response.statusCode}');
        return _simpleTaskCompletionDetection(userMessage, sportsHabits);
      }

      final data = jsonDecode(response.body);
      final content =
          data['choices']?[0]?['message']?['content'] as String? ?? '';

      // Try to parse the JSON response
      try {
        final result = jsonDecode(content.trim());
        if (result['isCompletion'] == true) {
          // Find matching habit
          final habitName = result['habitName'] as String?;
          if (habitName != null) {
            final matchedHabit = sportsHabits.firstWhere(
              (h) => h.name.toLowerCase() == habitName.toLowerCase(),
              orElse: () => sportsHabits.first,
            );

            return {
              'habit': matchedHabit,
              'confidence': result['confidence'] ?? 0.8,
            };
          }
        }
      } catch (e) {
        debugPrint('Error parsing AI response JSON: $e');
      }

      return null;
    } catch (e) {
      debugPrint('Error in parseTaskCompletion: $e');
      return _simpleTaskCompletionDetection(userMessage, sportsHabits);
    }
  }

  /// Simple keyword-based detection as fallback
  Map<String, dynamic>? _simpleTaskCompletionDetection(
    String userMessage,
    List<Habit> sportsHabits,
  ) {
    final message = userMessage.toLowerCase();

    final completionKeywords = [
      'completed',
      'finished',
      'done',
      'did',
      'just',
      'went for',
      'ran',
      'workout',
      'exercise',
      'trained',
    ];

    final hasCompletionKeyword = completionKeywords.any(message.contains);

    if (!hasCompletionKeyword) return null;

    // Try to match habit names
    for (final habit in sportsHabits) {
      final habitWords = habit.name.toLowerCase().split(' ');
      if (habitWords.any((word) => message.contains(word))) {
        return {
          'habit': habit,
          'confidence': 0.7,
        };
      }
    }

    // If keywords found but no specific habit match, return first sports habit
    if (hasCompletionKeyword && sportsHabits.isNotEmpty) {
      return {
        'habit': sportsHabits.first,
        'confidence': 0.5,
      };
    }

    return null;
  }
}
