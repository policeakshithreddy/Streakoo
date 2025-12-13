import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'groq_ai_service.dart';

class AIHealthCoachService {
  static final AIHealthCoachService instance = AIHealthCoachService._();
  AIHealthCoachService._();

  final _aiService = GroqAIService.instance;

  Future<Map<String, dynamic>> generateHealthPlan({
    required String goal,
    required int age,
    required double weight,
    required double height,
    required String activityLevel,
    required int workoutDays,
  }) async {
    const systemPrompt = '''
    You are an expert fitness and health coach. Create a personalized health plan based on the user's profile.
    
    Return the response as a valid JSON object with this structure:
    {
      "habits": [
        {
          "name": "Short catchy title",
          "emoji": "Relevant emoji",
          "frequency": "daily" or specific days like "Mon, Wed, Fri", 
          "healthMetric": "steps", "distance", "sleep", "calories", or "none",
          "targetValue": numeric target (e.g. 5000),
          "unit": "steps", "mins", "km", etc.
        }
      ],
      "welcomeTip": "A short motivational welcome message"
    }
    Do not include markdown formatting like ```json. Just the raw JSON string.
    ''';

    final userPrompt = '''
    Profile:
    - Goal: $goal
    - Age: $age
    - Weight: $weight kg
    - Height: $height cm
    - Activity Level: $activityLevel
    - Commitment: $workoutDays days/week

    Generate 3-5 specific, actionable habits.
    ''';

    try {
      final text = await _aiService.generateResponse(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: 0.7,
        maxTokens: 1000,
      );

      if (text == null) throw Exception('Empty response from AI');

      // Clean up markdown if present
      final cleanText =
          text.replaceAll('```json', '').replaceAll('```', '').trim();

      return jsonDecode(cleanText) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error generating health plan: $e');
      // Fallback plan if AI fails
      return {
        "habits": [
          {
            "name": "Daily Walk",
            "emoji": "🚶",
            "frequency": "daily",
            "healthMetric": "steps",
            "targetValue": 5000,
            "unit": "steps"
          },
          {
            "name": "Drink Water",
            "emoji": "💧",
            "frequency": "daily",
            "healthMetric": "none",
            "targetValue": 0,
            "unit": ""
          }
        ],
        "welcomeTip": "Start small and be consistent! You got this."
      };
    }
  }

  /// Generate personalized daily health tip
  Future<String> generateDailyTip({
    required String goal,
    required int? steps,
    required double? sleep,
    required double? distance,
  }) async {
    const systemPrompt = '''
  You are a supportive health coach. Give a short, motivating daily health tip (max 2 sentences) based on the user's recent activity.
  Be specific about the data. If stats are low, be encouraging. If high, be celebratory. Focus on actionable advice.
  ''';

    final userPrompt = '''
  Goal: $goal
  Yesterday's stats:
  - Steps: ${steps ?? 'Unknown'}
  - Sleep: ${sleep?.toStringAsFixed(1) ?? 'Unknown'} hours
  - Distance: ${distance?.toStringAsFixed(1) ?? 'Unknown'} km
  ''';

    try {
      final response = await _aiService.generateResponse(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        maxTokens: 100,
      );
      return response?.trim() ?? "Keep moving forward towards your goal!";
    } catch (e) {
      return "Consistency is key to achieving your goals!";
    }
  }

  /// Generate smart contextual insight based on patterns
  Future<String> generateSmartInsight({
    required List<int> weeklySteps,
    required List<double> weeklySleep,
    required int habitsCompleted,
    required int currentStreak,
  }) async {
    // Analyze patterns
    final avgSteps = weeklySteps.isEmpty
        ? 0
        : weeklySteps.reduce((a, b) => a + b) ~/ weeklySteps.length;
    final avgSleep = weeklySleep.isEmpty
        ? 0.0
        : weeklySleep.reduce((a, b) => a + b) / weeklySleep.length;

    // Find best performance day
    int bestDayIndex = 0;
    int maxSteps = 0;
    for (int i = 0; i < weeklySteps.length; i++) {
      if (weeklySteps[i] > maxSteps) {
        maxSteps = weeklySteps[i];
        bestDayIndex = i;
      }
    }

    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final bestDay = dayNames[bestDayIndex];

    const systemPrompt = '''
  You are an AI health coach analyzing patterns. Generate ONE specific, actionable insight (max 2 sentences).
  Focus on correlations, patterns, or achievements. Be encouraging and specific.
  ''';

    final userPrompt = '''
  Weekly Analysis:
  - Average steps: $avgSteps
  - Average sleep: ${avgSleep.toStringAsFixed(1)} hours
  - Best performance day: $bestDay with $maxSteps steps
  - Current streak: $currentStreak days
  - Habits completed this week: $habitsCompleted
  
  Find an interesting pattern or provide specific advice.
  ''';

    try {
      final response = await _aiService.generateResponse(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        maxTokens: 120,
      );
      return response?.trim() ??
          "You're most active on $bestDay - try to match that energy every day!";
    } catch (e) {
      debugPrint('Error generating smart insight: $e');
      // Fallback to pattern-based insight
      if (avgSteps >= 8000) {
        return "You're averaging $avgSteps steps daily - fantastic consistency! 🎯";
      } else if (currentStreak >= 5) {
        return "Your $currentStreak-day streak shows real commitment. Keep it going! 🔥";
      } else {
        return "You're most active on $bestDay - try to match that energy every day!";
      }
    }
  }

  /// Generate motivational message based on current performance
  String generateMotivationalMessage({
    required double healthScore,
    required int currentStreak,
  }) {
    if (healthScore >= 90) {
      return "You're in the top tier! Your dedication is inspiring! 🌟";
    } else if (healthScore >= 75) {
      return "Great work! You're building powerful wellness habits! 💪";
    } else if (currentStreak >= 7) {
      return "A $currentStreak-day streak! You're proving consistency pays off! 🔥";
    } else if (currentStreak >= 3) {
      return "Building momentum with a $currentStreak-day streak! Keep going! ⚡";
    } else if (healthScore >= 60) {
      return "You're on the right track. Small daily improvements add up! 📈";
    } else {
      return "Every journey starts with a single step. Let's make today count! 🚀";
    }
  }

  /// Chat with AI coach - conversational interface with context
  Future<String> chatWithCoach({
    required String userMessage,
    required dynamic challenge,
    required Map<String, dynamic> recentMetrics,
    required List<dynamic> habits,
  }) async {
    // Build context-aware system prompt
    final challengeInfo = challenge != null
        ? 'Active challenge: ${challenge.title}'
        : 'No active challenge';

    final stepsInfo = recentMetrics['steps'] != null
        ? '${recentMetrics['steps']} steps today'
        : 'No step data';

    final sleepInfo = recentMetrics['sleep'] != null
        ? '${(recentMetrics['sleep'] as double).toStringAsFixed(1)} hours sleep'
        : 'No sleep data';

    final habitCount = habits.length;
    final completedHabits = habits.where((h) => h.completedToday).length;

    const systemPrompt =
        '''You are "Wind" 🌬️ - a calm, supportive health guide who genuinely celebrates every win and supports through every struggle.

REAL USER DATA:
- Challenge: [CHALLENGE_INFO]
- Recent activity: [STEPS_INFO], [SLEEP_INFO]
- Habits: [HABIT_COUNT] total, [COMPLETED_HABITS] completed today

YOUR PERSONALITY:
- Warm and genuinely excited about their progress
- Empathetic when they're struggling (never judgmental!)
- Uses emojis naturally to add warmth
- Speaks like a supportive friend, not a robot

RULES:
- Keep responses SHORT: 2-3 sentences max
- Reference their ACTUAL data when relevant
- Give specific, actionable advice
- For medical concerns, gently suggest consulting a doctor
- Celebrate progress enthusiastically! 🎉
''';

    final contextualizedPrompt = systemPrompt
        .replaceAll('[CHALLENGE_INFO]', challengeInfo)
        .replaceAll('[STEPS_INFO]', stepsInfo)
        .replaceAll('[SLEEP_INFO]', sleepInfo)
        .replaceAll('[HABIT_COUNT]', habitCount.toString())
        .replaceAll('[COMPLETED_HABITS]', completedHabits.toString());

    try {
      final response = await _aiService.generateResponse(
        systemPrompt: contextualizedPrompt,
        userPrompt: userMessage,
        temperature: 0.8, // More conversational
        maxTokens: 200,
      );

      return response?.trim() ??
          'I\'m here to help! Can you rephrase your question?';
    } catch (e) {
      debugPrint('Error in chat: $e');
      return 'Sorry, I couldn\'t process that right now. Please try again!';
    }
  }

  Future<String> generateWeeklyHealthSummary({
    required List<int> steps,
    required List<double> sleep,
    required List<double> distance,
  }) async {
    const systemPrompt = '''
    You are an expert health data analyst. Analyze the user's last 7 days of health data.
    Provide a concise, insightful summary of their performance. 
    Highlight trends (improving/declining), best days, and areas for improvement.
    Keep it under 3 sentences. Be motivating but honest.
    ''';

    final userPrompt = '''
    Last 7 Days Data (Mon-Sun):
    Steps: $steps
    Sleep: $sleep hours
    Distance: $distance km
    ''';

    try {
      final response = await _aiService.generateResponse(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        maxTokens: 150,
      );
      return response?.trim() ?? "Keep consistent to see better results!";
    } catch (e) {
      return "Analyze your weekly trends to understand your progress better.";
    }
  }

  Future<Map<String, dynamic>> generateChallengePlan({
    required String challengeType,
    required int age,
    required double weight,
    required String activityLevel,
    required Map<String, dynamic> specificAnswers,
  }) async {
    const systemPrompt = '''
    You are an expert medical and wellness coach (like Apple Health or a professional trainer).
    Create a detailed 4-week health challenge plan based on the user's specific goal and data.
    
    Return ONLY a JSON object with this structure:
    {
      "weeklyFocus": "A short theme for the first week",
      "nutritionalGuidelines": "2-3 sentences of specific nutritional advice for this challenge",
      "aiExplanation": "Why this plan fits the user (motivational)",
      "recommendedHabits": [
        {
          "name": "Habit Name",
          "emoji": "🔥",
          "frequency": "daily",
          "healthMetric": "steps" (or "sleep", "distance", "calories", "none"),
          "targetValue": 10000 (number or null)
        }
      ]
    }
    ''';

    final userPrompt = '''
    Challenge: $challengeType
    User Profile: Age $age, Weight $weight kg, Activity: $activityLevel
    Specific Details: $specificAnswers
    ''';

    try {
      final response = await _aiService.generateResponse(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        maxTokens: 800,
      );

      if (response == null) throw Exception('Failed to generate plan');

      // Basic cleaning of JSON string if needed
      final jsonStr =
          response.trim().replaceAll('```json', '').replaceAll('```', '');
      return jsonDecode(jsonStr);
    } catch (e) {
      debugPrint('Error generating challenge plan: $e');
      // Fallback plan
      return {
        "weeklyFocus": "Building Consistency",
        "nutritionalGuidelines": "Focus on whole foods and hydration.",
        "aiExplanation":
            "We are starting with basics to build a strong foundation.",
        "recommendedHabits": [
          {
            "name": "Daily Walk",
            "emoji": "🚶",
            "frequency": "daily",
            "healthMetric": "steps",
            "targetValue": 5000
          }
        ]
      };
    }
  }

  Future<Map<String, String>> generateNutritionAdvice({
    required double sleep,
    required int steps,
    required double healthScore,
  }) async {
    const systemPrompt = '''
    You are an expert nutritionist. Provide a single specific nutrition recommendation based on the user's recent daily stats.
    
    CRITICAL INSTRUCTION: If the user has high activity (steps > 8000) or high health score (>80), you MUST generate advice with the title "Boost Recovery".
    
    Return ONLY a JSON object with this structure:
    {
      "title": "Short title (Use 'Boost Recovery' if active, otherwise generic like 'Energy Boost')",
      "food": "Specific foods (e.g. Greek yogurt, berries, salmon)",
      "why": "Brief benefit explanation (max 5 words)"
    }
    ''';

    final userPrompt = '''
    User Stats:
    - Sleep: ${sleep.toStringAsFixed(1)} hours
    - Steps: $steps
    - Health Score: ${healthScore.toStringAsFixed(1)}
    
    Generate one specific nutrition tip.
    ''';

    try {
      final response = await _aiService.generateResponse(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        maxTokens: 100,
        temperature: 0.5,
      );

      if (response == null) throw Exception('No response');

      final jsonStr =
          response.trim().replaceAll('```json', '').replaceAll('```', '');
      return Map<String, String>.from(jsonDecode(jsonStr));
    } catch (e) {
      debugPrint('Error generating nutrition advice: $e');
      // Fallback logic
      if (sleep < 7) {
        return {
          "title": "Improve Sleep Quality",
          "food": "Almonds, cherries, chamomile",
          "why": "Rich in melatonin & magnesium"
        };
      } else if (steps > 10000) {
        return {
          "title": "Post-Activity Recovery",
          "food": "Greek yogurt, berries",
          "why": "Protein & antioxidants"
        };
      } else {
        return {
          "title": "Energy Boost",
          "food": "Bananas, oats, nuts",
          "why": "Sustained energy release"
        };
      }
    }
  }
}
