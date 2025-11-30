import '../models/habit.dart';

class InsightService {
  static final InsightService _instance = InsightService._internal();
  factory InsightService() => _instance;
  InsightService._internal();

  // ============ CORRELATION ANALYSIS ============

  /// Analyzes if completing habitA increases likelihood of completing habitB
  Map<String, dynamic> analyzeHabitCorrelation(
    List<Habit> habits,
    String habitAId,
    String habitBId,
  ) {
    final habitA = habits.firstWhere((h) => h.id == habitAId);
    final habitB = habits.firstWhere((h) => h.id == habitBId);

    // Find dates where both were completed
    final commonDates = habitA.completionDates
        .where((date) => habitB.completionDates.contains(date))
        .toList();

    // Calculate correlation percentage
    if (habitA.completionDates.isEmpty) {
      return {
        'correlation': 0.0,
        'strength': 'none',
        'message': 'Not enough data',
      };
    }

    final correlationPercent =
        (commonDates.length / habitA.completionDates.length) * 100;

    String strength;
    if (correlationPercent >= 70) {
      strength = 'strong';
    } else if (correlationPercent >= 40) {
      strength = 'moderate';
    } else {
      strength = 'weak';
    }

    return {
      'correlation': correlationPercent,
      'strength': strength,
      'message':
          'You complete "${habitB.name}" ${correlationPercent.toStringAsFixed(0)}% of the time when you complete "${habitA.name}"',
    };
  }

  /// Finds best time of day for a habit
  Map<String, dynamic> findBestTimeOfDay(Habit habit) {
    // This would analyze completion timestamps to find patterns
    // For now, return a placeholder
    return {
      'bestTime': 'morning',
      'message': 'You typically complete this habit in the morning',
    };
  }

  /// Analyzes streak stability
  Map<String, dynamic> analyzeStreakStability(Habit habit) {
    if (habit.completionDates.length < 7) {
      return {
        'stability': 0.0,
        'message': 'Need at least 7 days of data',
      };
    }

    // Calculate how many days in the last 30 were completed
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentCompletions = habit.completionDates.where((dateStr) {
      final date = DateTime.parse(dateStr);
      return date.isAfter(thirtyDaysAgo);
    }).length;

    final stability = (recentCompletions / 30) * 100;

    String message;
    if (stability >= 80) {
      message = 'Excellent consistency! Keep it up! 🔥';
    } else if (stability >= 50) {
      message = 'Good progress, but there\'s room to improve';
    } else {
      message = 'Try to be more consistent with this habit';
    }

    return {
      'stability': stability,
      'message': message,
    };
  }

  // ============ GENERATE INSIGHTS ============

  Future<List<String>> generateInsights(List<Habit> habits) async {
    final insights = <String>[];

    if (habits.isEmpty) {
      return ['Start tracking habits to see personalized insights!'];
    }

    // 1. Find best performing habit
    final bestHabit = habits.reduce((a, b) => a.streak > b.streak ? a : b);
    if (bestHabit.streak > 0) {
      insights.add(
          '🏆 "${bestHabit.name}" is your strongest habit with a ${bestHabit.streak}-day streak!');
    }

    // 2. Find habits that need attention
    final strugglingHabits =
        habits.where((h) => h.streak == 0 && h.completionDates.isNotEmpty);
    if (strugglingHabits.isNotEmpty) {
      insights.add(
          '⚠️ "${strugglingHabits.first.name}" lost its streak. Try again today!');
    }

    // 3. Analyze correlation between first two habits
    if (habits.length >= 2) {
      final correlation =
          analyzeHabitCorrelation(habits, habits[0].id, habits[1].id);
      if (correlation['correlation'] > 50) {
        insights.add(correlation['message']);
      }
    }

    // 4. Motivational insight based on total progress
    final totalCompletions =
        habits.fold(0, (sum, h) => sum + h.completionDates.length);
    if (totalCompletions > 100) {
      insights.add(
          '💪 You\'ve completed habits $totalCompletions times! You\'re building incredible momentum!');
    }

    return insights;
  }

  /// Suggest optimal habit combinations
  List<Map<String, dynamic>> suggestHabitPairs(List<Habit> habits) {
    final suggestions = <Map<String, dynamic>>[];

    // Example: suggest pairing exercise with meditation
    final exercise = habits.where((h) =>
        h.category == 'Sports' || h.name.toLowerCase().contains('exercise'));
    final meditation =
        habits.where((h) => h.name.toLowerCase().contains('meditat'));

    if (exercise.isNotEmpty && meditation.isNotEmpty) {
      suggestions.add({
        'pair': [exercise.first.name, meditation.first.name],
        'reason':
            'Exercise + Meditation is a powerful combination for well-being',
      });
    }

    return suggestions;
  }
}
