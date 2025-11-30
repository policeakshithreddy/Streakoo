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
      print('Error generating health plan: $e');
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

  Future<String> generateDailyTip({
    required String goal,
    required int? steps,
    required double? sleep,
    required double? distance,
  }) async {
    const systemPrompt = '''
    You are a supportive health coach. Give a short, motivating daily health tip (max 2 sentences) based on the user's recent activity.
    If stats are low, be encouraging. If high, be celebratory.
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
      print('Error generating challenge plan: $e');
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
}
