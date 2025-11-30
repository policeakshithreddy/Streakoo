import 'package:uuid/uuid.dart';

import '../models/ai_insight.dart';
import '../models/habit.dart';
import '../config/app_config.dart';
import 'groq_ai_service.dart';

class InsightAnalyzerService {
  InsightAnalyzerService._();
  static final InsightAnalyzerService instance = InsightAnalyzerService._();

  final _uuid = const Uuid();

  /// Analyze habits and generate insights
  Future<List<AIInsight>> analyzeHabits(List<Habit> habits) async {
    if (habits.isEmpty) return [];

    final insights = <AIInsight>[];

    // Need at least 7 days of data for meaningful insights
    final hasEnoughData = habits.any((h) => h.completionDates.length >= 7);
    if (!hasEnoughData) return [];

    // Pattern detection
    final patternInsights = await _detectPatterns(habits);
    insights.addAll(patternInsights);

    // Correlation detection
    final correlationInsights = _detectCorrelations(habits);
    insights.addAll(correlationInsights);

    // Risk detection
    final riskInsights = _detectRisks(habits);
    insights.addAll(riskInsights);

    // Achievement detection
    final achievementInsights = _detectAchievements(habits);
    insights.addAll(achievementInsights);

    // Recommendation generation
    final recommendations = await _generateRecommendations(habits);
    insights.addAll(recommendations);

    return insights;
  }

  /// Detect behavioral patterns
  Future<List<AIInsight>> _detectPatterns(List<Habit> habits) async {
    final insights = <AIInsight>[];

    // Find best day of week
    final dayCompletions = <int, int>{};
    for (final habit in habits) {
      for (final dateStr in habit.completionDates) {
        try {
          final date = DateTime.parse(dateStr);
          final weekday = date.weekday;
          dayCompletions[weekday] = (dayCompletions[weekday] ?? 0) + 1;
        } catch (e) {
          continue;
        }
      }
    }

    if (dayCompletions.isNotEmpty) {
      final bestDay =
          dayCompletions.entries.reduce((a, b) => a.value > b.value ? a : b);
      final dayName = _getDayName(bestDay.key);

      insights.add(AIInsight(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
        type: InsightType.pattern,
        title: 'Your Power Day',
        description:
            '$dayName is your strongest day! You complete ${bestDay.value}% more habits on ${dayName}s.',
        actionText: 'Schedule challenging habits on $dayName',
        confidence: 0.85,
      ));
    }

    return insights;
  }

  /// Detect habit correlations
  List<AIInsight> _detectCorrelations(List<Habit> habits) {
    final insights = <AIInsight>[];

    // Look for habits often completed together
    if (habits.length < 2) return insights;

    for (int i = 0; i < habits.length; i++) {
      for (int j = i + 1; j < habits.length; j++) {
        final habit1 = habits[i];
        final habit2 = habits[j];

        final correlation = _calculateCorrelation(
          habit1.completionDates,
          habit2.completionDates,
        );

        if (correlation > 0.7) {
          // Strong positive correlation
          insights.add(AIInsight(
            id: _uuid.v4(),
            createdAt: DateTime.now(),
            type: InsightType.correlation,
            title: 'Habit Synergy Detected',
            description:
                'When you complete "${habit1.name}", you\'re ${(correlation * 100).round()}% more likely to complete "${habit2.name}" the same day.',
            actionText: 'Try pairing these habits together',
            confidence: correlation,
          ));
          break; // Only show one correlation per analysis
        }
      }
    }

    return insights;
  }

  /// Detect habits at risk
  List<AIInsight> _detectRisks(List<Habit> habits) {
    final insights = <AIInsight>[];

    for (final habit in habits) {
      if (habit.streak > 0 && habit.streak >= 7 && !habit.completedToday) {
        // Has a good streak but not completed today
        insights.add(AIInsight(
          id: _uuid.v4(),
          createdAt: DateTime.now(),
          type: InsightType.warning,
          title: 'Streak at Risk!',
          description:
              'Your ${habit.streak}-day streak on "${habit.name}" needs you today! Don\'t break the chain 🔥',
          actionText: 'Complete it now',
          confidence: 0.95,
        ));
        break; // Only show one warning at a time
      }
    }

    return insights;
  }

  /// Detect achievements
  List<AIInsight> _detectAchievements(List<Habit> habits) {
    final insights = <AIInsight>[];

    for (final habit in habits) {
      // Check for milestone streaks
      if ([7, 14, 30, 50, 100].contains(habit.streak)) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          createdAt: DateTime.now(),
          type: InsightType.achievement,
          title: '${habit.streak}-Day Streak!',
          description:
              'Congratulations! You\'ve maintained "${habit.name}" for ${habit.streak} days straight! 🎉',
          confidence: 1.0,
        ));
        break; // Show one achievement at a time
      }

      // Check for perfect week
      if (habit.completionDates.length >= 7) {
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        final recentCompletions = habit.completionDates.where((dateStr) {
          try {
            final date = DateTime.parse(dateStr);
            return date.isAfter(sevenDaysAgo) && date.isBefore(now);
          } catch (e) {
            return false;
          }
        }).length;

        if (recentCompletions >= 7) {
          insights.add(AIInsight(
            id: _uuid.v4(),
            createdAt: DateTime.now(),
            type: InsightType.achievement,
            title: 'Perfect Week!',
            description:
                'You completed "${habit.name}" every day this week! Consistency is your superpower! 💪',
            confidence: 1.0,
          ));
          break;
        }
      }
    }

    return insights;
  }

  /// Generate personalized recommendations
  Future<List<AIInsight>> _generateRecommendations(List<Habit> habits) async {
    final insights = <AIInsight>[];

    // Find category balance
    final categoryCount = <String, int>{};
    for (final habit in habits) {
      categoryCount[habit.category] = (categoryCount[habit.category] ?? 0) + 1;
    }

    // Recommend underrepresented categories
    if (!categoryCount.containsKey('Health') ||
        (categoryCount['Health'] ?? 0) < 1) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
        type: InsightType.recommendation,
        title: 'Balance Your Habits',
        description:
            'Consider adding a health-focused habit like exercise or meditation for a more balanced routine.',
        actionText: 'Add a health habit',
        confidence: 0.75,
      ));
    }

    // Recommend based on AI if configured
    if (AppConfig.isApiConfigured &&
        AppConfig.useAIForCoaching &&
        habits.isNotEmpty) {
      try {
        final aiRecommendation = await _getAIRecommendation(habits);
        if (aiRecommendation != null) {
          insights.add(aiRecommendation);
        }
      } catch (e) {
        print('Error getting AI recommendation: $e');
      }
    }

    return insights;
  }

  /// Get AI-powered recommendation
  Future<AIInsight?> _getAIRecommendation(List<Habit> habits) async {
    final habitSummary = habits
        .map((h) => '${h.name} (${h.category}, ${h.streak}-day streak)')
        .join(', ');

    final prompt = '''
Analyze these habits and provide ONE specific, actionable recommendation:

User's habits: $habitSummary

Provide a recommendation to improve their habit routine. Response format:
Title: [Short catchy title]
Description: [1-2 sentences with specific actionable advice]
''';

    try {
      final response = await GroqAIService.instance.generateResponse(
        systemPrompt:
            'You are a habit optimization expert. Provide specific, actionable recommendations.',
        userPrompt: prompt,
        maxTokens: 80,
        temperature: 0.7,
      );

      if (response != null && response.contains('Title:')) {
        final lines = response.split('\n');
        final titleLine =
            lines.firstWhere((l) => l.startsWith('Title:'), orElse: () => '');
        final descLine = lines.firstWhere((l) => l.startsWith('Description:'),
            orElse: () => '');

        final title = titleLine.replaceFirst('Title:', '').trim();
        final description = descLine.replaceFirst('Description:', '').trim();

        if (title.isNotEmpty && description.isNotEmpty) {
          return AIInsight(
            id: _uuid.v4(),
            createdAt: DateTime.now(),
            type: InsightType.recommendation,
            title: title,
            description: description,
            confidence: 0.8,
          );
        }
      }
    } catch (e) {
      print('Error in AI recommendation: $e');
    }

    return null;
  }

  /// Calculate correlation coefficient between two habit completion dates
  double _calculateCorrelation(List<String> dates1, List<String> dates2) {
    if (dates1.isEmpty || dates2.isEmpty) return 0.0;

    // Find dates that appear in both lists (same-day completions)
    final set1 = dates1.toSet();
    final set2 = dates2.toSet();
    final intersection = set1.intersection(set2);

    // Calculate correlation as percentage of overlap
    final maxPossible =
        dates1.length < dates2.length ? dates1.length : dates2.length;
    return intersection.length / maxPossible;
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }
}
