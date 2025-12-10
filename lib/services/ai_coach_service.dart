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

      // Get time-of-day greeting
      final hour = DateTime.now().hour;
      String timeGreeting;
      if (hour < 12) {
        timeGreeting = 'morning';
      } else if (hour < 17) {
        timeGreeting = 'afternoon';
      } else {
        timeGreeting = 'evening';
      }

      // Natural, friendly system prompt with personality
      final systemPrompt =
          '''You are "Koo" ✨ - a warm, encouraging habit coach who genuinely cares about the user's wellbeing. You have access to their COMPLETE habit and health data.

YOUR PERSONALITY:
- Warm and friendly like a supportive best friend
- Genuinely excited about their wins (big or small!)
- Empathetic when they're struggling
- Uses emojis naturally (not excessively)
- Speaks casually but respectfully

CURRENT TIME: It's $timeGreeting right now.

RESPONSE RULES:
- Keep it SHORT: 2-3 sentences max
- Give ONE specific, actionable tip based on THEIR data
- Reference their actual habits/health stats when relevant
- Celebrate streaks and progress enthusiastically 🎉
- If they're struggling, be gentle and understanding
- Never be preachy or lecture them

EXAMPLE RESPONSES:
"Wow, 15 days on meditation! 🧘 That's seriously impressive. Since you're crushing it, maybe pair it with your morning run for a zen combo? ✨"
"I see you got 8k steps but only 5 hours sleep - you're pushing hard! 💪 Tonight, maybe wind down early? Your body will thank you 😴"
"Day 1 is the hardest, but hey - you're HERE and that's what counts! Start tiny, like 2 minutes. You've got this 🔥"''';

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

    // Warm, friendly fallback responses with personality
    if (lower.contains('how') ||
        lower.contains('start') ||
        lower.contains('begin')) {
      return 'Hey! Here\'s my secret: start embarrassingly small 😊 Like, 2 minutes small. Once it clicks, you can level up. Trust the process! 💪';
    }
    if (lower.contains('motivat') ||
        lower.contains('why') ||
        lower.contains('purpose')) {
      return 'Real talk: motivation shows up AFTER you start, not before ✨ Just do 2 minutes today - that\'s it! Future you will be so grateful 🔥';
    }
    if (lower.contains('hard') ||
        lower.contains('difficult') ||
        lower.contains('struggle') ||
        lower.contains('can\'t')) {
      return 'I hear you - it\'s not easy, and that\'s okay 💙 Every streak starts at day 1. You\'re building something amazing, one day at a time. I believe in you!';
    }
    if (lower.contains('time') ||
        lower.contains('busy') ||
        lower.contains('schedule')) {
      return 'Totally get it - life\'s hectic! 🏃 Try "habit stacking": attach it to something you already do, like "right after coffee" or "before bed". Makes it automatic! ☕';
    }
    if (lower.contains('forget') || lower.contains('remember')) {
      return 'Forgetting happens! 📱 Put a sticky note where you can\'t miss it, or set a fun reminder. Small tricks = big wins! ✨';
    }
    if (lower.contains('streak') ||
        lower.contains('broke') ||
        lower.contains('lost') ||
        lower.contains('fail')) {
      return 'Hey, streaks aren\'t everything 💛 What matters is you\'re back! Every champion has setbacks. Today is a fresh start - let\'s go! 🚀';
    }
    if (lower.contains('thanks') ||
        lower.contains('thank you') ||
        lower.contains('helpful')) {
      return 'You\'re so welcome! 🥰 I\'m always here cheering you on. Keep being awesome! ✨';
    }
    if (lower.contains('good') ||
        lower.contains('great') ||
        lower.contains('awesome') ||
        lower.contains('amazing')) {
      return 'That\'s what I love to hear! 🎉 Keep that energy going - you\'re on fire! 🔥';
    }

    // Default friendly response with personality
    return 'I\'m Koo, your habit buddy! 🤗 What\'s on your mind? Whether you need tips, motivation, or just want to chat about your journey - I\'m here! ✨';
  }

  String getQuickEncouragement(int streak) {
    if (streak == 0) {
      return 'Fresh start! Day 1 is where legends begin 🌟 Let\'s do this! 💪';
    } else if (streak == 1) {
      return 'Day 1 complete! 🎉 You just did the hardest part - starting!';
    } else if (streak < 7) {
      return '$streak days strong! 🔥 You\'re building something amazing!';
    } else if (streak < 14) {
      return 'A whole week+ ($streak days)! 🚀 You\'re officially building a habit!';
    } else if (streak < 30) {
      return '$streak days! 🌟 You\'re in the habit-forming zone now!';
    } else if (streak < 100) {
      return 'WOW! $streak days! 🏆 You\'re a habit champion!';
    } else {
      return '🎊 $streak DAYS?! You\'re literally unstoppable! Legend status! 👑';
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
