import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class GroqAIService {
  GroqAIService._();
  static final GroqAIService instance = GroqAIService._();

  // Generate AI response using Groq
  Future<String?> generateResponse({
    required String systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    if (!AppConfig.isApiConfigured) {
      print('⚠️ Groq API key not configured. Using fallback responses.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(AppConfig.groqApiUrl),
        headers: {
          'Authorization': 'Bearer ${AppConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConfig.groqModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': temperature ?? AppConfig.aiTemperature,
          'max_tokens': maxTokens ?? AppConfig.maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling Groq API: $e');
      return null;
    }
  }

  // Generate habit suggestions based on user's goals and mood
  Future<List<String>> generateHabitSuggestions({
    required String userGoals,
    String? currentMood,
    List<String>? existingHabits,
    int count = 5,
  }) async {
    const systemPrompt =
        '''You are an expert habit formation coach. Generate personalized habit suggestions that are:
- Specific and actionable
- Aligned with the user's goals
- Appropriate for their current mood
- Not duplicating existing habits
- Realistic and achievable

Format: Return ONLY a numbered list without any additional text.''';

    final userPrompt = '''User Goals: $userGoals
Current Mood: ${currentMood ?? 'Not specified'}
Existing Habits: ${existingHabits?.join(', ') ?? 'None'}

Suggest $count new habit ideas.''';

    final response = await generateResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    if (response == null) {
      // Fallback suggestions
      return [
        'Drink 8 glasses of water daily',
        'Exercise for 30 minutes',
        'Read 10 pages before bed',
        'Meditate for 5 minutes',
        'Write a gratitude journal',
      ];
    }

    // Parse the numbered list
    return response
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .take(count)
        .toList();
  }

  // Generate personalized coaching message
  Future<String> generateCoachingMessage({
    required String userName,
    required int currentStreak,
    required int completedToday,
    required int totalHabits,
    String? mood,
  }) async {
    const systemPrompt =
        '''You are a supportive and motivating habit coach. Create personalized, encouraging messages that:
- Address the user by name
- Reference their current progress
- Adapt tone based on their mood
- Keep it concise (2-3 sentences max)
- Use emojis appropriately
- Be genuine and avoid clichés''';

    final userPrompt = '''User: $userName
Current Streak: $currentStreak days
Completed Today: $completedToday / $totalHabits habits
Mood: ${mood ?? 'Unknown'}

Generate an encouraging message.''';

    final response = await generateResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.8, // More creative
    );

    return response ??
        'Great progress, $userName! You\'ve got $currentStreak days of momentum. Keep it up! 💪';
  }

  // Analyze mood patterns and provide insights
  Future<String> analyzeMoodPatterns({
    required Map<String, int> moodCounts,
    required int daysTracked,
  }) async {
    const systemPrompt =
        '''You are a mental wellness analyst. Analyze mood patterns and provide:
- Brief insights (2-3 sentences)
- Actionable recommendations
- Encouraging tone
Use emojis sparingly.''';

    final userPrompt = '''Mood distribution over past $daysTracked days:
${moodCounts.entries.map((e) => '${e.key}: ${e.value} days').join('\n')}

Provide brief insights and recommendations.''';

    final response = await generateResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    return response ??
        'Your mood patterns show variety over the past $daysTracked days. Keep tracking to understand your emotional wellness better! 🌟';
  }

  // Generate motivational quote based on context
  Future<String> generateMotivationalQuote({
    required String context,
  }) async {
    const systemPrompt =
        '''Generate a short, powerful motivational quote (max 15 words) that:
- Is relevant to the context
- Inspires action
- Feels authentic
Return ONLY the quote, no attribution.''';

    final response = await generateResponse(
      systemPrompt: systemPrompt,
      userPrompt: context,
      maxTokens: 50,
    );

    return response ??
        'Small steps every day lead to big changes. Keep going! 💫';
  }

  // Generate habit story for milestones
  Future<String> generateHabitStory({
    required String habitName,
    required int daysCompleted,
    required String userName,
  }) async {
    const systemPrompt =
        '''You are a storyteller who celebrates user achievements. Create a brief, inspiring story (3-4 sentences) about:
- The user's journey
- The significance of their milestone
- Encouragement for the future
Use emotive language and emojis.''';

    final userPrompt =
        '''$userName has maintained their "$habitName" habit for $daysCompleted consecutive days. 

Write a celebratory story.''';

    final response = await generateResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.9, // Very creative
    );

    return response ??
        'You\'ve become unstoppable! $daysCompleted days of discipline is no small thing. Each day you chose to show up, you became stronger. Keep the flame alive! 🔥';
  }
}
