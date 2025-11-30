import '../models/habit.dart';

enum UserMoodState {
  unstoppable, // Completing everything, high performance
  strong, // Good completion rate, building momentum
  steady, // Consistent but not exceptional
  struggling, // Missing some, inconsistent
  overwhelmed, // Missing many, needs support
  recovering, // Coming back from a low period
}

class BehaviorBasedMoodDetector {
  BehaviorBasedMoodDetector._();
  static final BehaviorBasedMoodDetector instance =
      BehaviorBasedMoodDetector._();

  // Analyze user mood based on habit completion behavior
  UserMoodState detectMood(List<Habit> habits) {
    if (habits.isEmpty) return UserMoodState.steady;

    final totalHabits = habits.length;
    final completedToday = habits.where((h) => h.completedToday).length;
    final completionRate = completedToday / totalHabits;

    // Calculate recent performance (last 3 days)
    final recentPerformance = _calculateRecentPerformance(habits);

    // Calculate streak health
    final streakHealth = _calculateStreakHealth(habits);

    // Detect trend
    final trend = _detectTrend(habits);

    // Determine mood state
    return _determineMoodState(
      completionRate: completionRate,
      recentPerformance: recentPerformance,
      streakHealth: streakHealth,
      trend: trend,
    );
  }

  double _calculateRecentPerformance(List<Habit> habits) {
    // Look at last 3 days of data
    final now = DateTime.now();
    final last3Days = List.generate(3, (i) {
      final day = now.subtract(Duration(days: i));
      return _dateToKey(day);
    });

    int totalPossible = habits.length * 3;
    int totalCompleted = 0;

    for (final habit in habits) {
      for (final day in last3Days) {
        if (habit.completionDates.contains(day)) {
          totalCompleted++;
        }
      }
    }

    return totalPossible > 0 ? totalCompleted / totalPossible : 0.0;
  }

  double _calculateStreakHealth(List<Habit> habits) {
    if (habits.isEmpty) return 0.0;

    int healthyStreaks = 0; // Streaks >= 3 days
    int totalStreaks = 0;

    for (final habit in habits) {
      totalStreaks++;
      if (habit.streak >= 3) {
        healthyStreaks++;
      }
    }

    return healthyStreaks / totalStreaks;
  }

  String _detectTrend(List<Habit> habits) {
    // Compare last 3 days vs previous 3 days
    final recent = _calculateRecentPerformance(habits);

    final now = DateTime.now();
    final days4to6 = List.generate(3, (i) {
      final day = now.subtract(Duration(days: i + 3));
      return _dateToKey(day);
    });

    int totalPossible = habits.length * 3;
    int totalCompleted = 0;

    for (final habit in habits) {
      for (final day in days4to6) {
        if (habit.completionDates.contains(day)) {
          totalCompleted++;
        }
      }
    }

    final previous = totalPossible > 0 ? totalCompleted / totalPossible : 0.0;

    if (recent > previous + 0.15) return 'improving';
    if (recent < previous - 0.15) return 'declining';
    return 'stable';
  }

  UserMoodState _determineMoodState({
    required double completionRate,
    required double recentPerformance,
    required double streakHealth,
    required String trend,
  }) {
    // Perfect or near-perfect performance
    if (completionRate >= 0.9 && recentPerformance >= 0.85) {
      return UserMoodState.unstoppable;
    }

    // Strong performance
    if (completionRate >= 0.7 && recentPerformance >= 0.65) {
      return UserMoodState.strong;
    }

    // Recovering from low performance
    if (trend == 'improving' && recentPerformance >= 0.5) {
      return UserMoodState.recovering;
    }

    // Consistent but not exceptional
    if (completionRate >= 0.5 && streakHealth >= 0.4) {
      return UserMoodState.steady;
    }

    // Declining or low performance
    if (recentPerformance < 0.3 || trend == 'declining') {
      return UserMoodState.overwhelmed;
    }

    // Default: struggling
    return UserMoodState.struggling;
  }

  String _dateToKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get mood display info
  MoodDisplayInfo getMoodDisplay(UserMoodState mood) {
    switch (mood) {
      case UserMoodState.unstoppable:
        return MoodDisplayInfo(
          emoji: '🔥',
          title: 'Unstoppable',
          message:
              'You\'re absolutely crushing it! This momentum is incredible.',
          color: 0xFFFF6B35, // Bright orange-red
          energyLevel: 100,
        );

      case UserMoodState.strong:
        return MoodDisplayInfo(
          emoji: '💪',
          title: 'Strong',
          message: 'You\'re in great shape! Keep this energy going.',
          color: 0xFF4ECDC4, // Teal
          energyLevel: 80,
        );

      case UserMoodState.recovering:
        return MoodDisplayInfo(
          emoji: '🌱',
          title: 'Growing',
          message: 'Nice comeback! You\'re building momentum again.',
          color: 0xFF95E1D3, // Light green
          energyLevel: 65,
        );

      case UserMoodState.steady:
        return MoodDisplayInfo(
          emoji: '⚡',
          title: 'Steady',
          message: 'You\'re maintaining consistency. That\'s what matters!',
          color: 0xFFF38181, // Coral
          energyLevel: 50,
        );

      case UserMoodState.struggling:
        return MoodDisplayInfo(
          emoji: '⚠️',
          title: 'Struggling',
          message: 'It\'s okay to have tough days. Let\'s start small.',
          color: 0xFFFFD93D, // Yellow
          energyLevel: 35,
        );

      case UserMoodState.overwhelmed:
        return MoodDisplayInfo(
          emoji: '😓',
          title: 'Needs Support',
          message: 'Feeling overwhelmed? Try focusing on just 1-2 habits.',
          color: 0xFFB4B4B4, // Gray
          energyLevel: 20,
        );
    }
  }

  // Get AI coaching tone based on mood
  String getCoachingTone(UserMoodState mood) {
    switch (mood) {
      case UserMoodState.unstoppable:
      case UserMoodState.strong:
        return 'enthusiastic and celebratory';

      case UserMoodState.recovering:
      case UserMoodState.steady:
        return 'encouraging and supportive';

      case UserMoodState.struggling:
      case UserMoodState.overwhelmed:
        return 'gentle, compassionate, and understanding';
    }
  }

  // Get recommendations based on mood
  List<String> getRecommendations(UserMoodState mood, List<Habit> habits) {
    final recommendations = <String>[];

    switch (mood) {
      case UserMoodState.unstoppable:
        recommendations.add('Consider adding a new challenge habit');
        recommendations
            .add('Your current momentum is perfect for harder goals');
        break;

      case UserMoodState.strong:
        recommendations.add('Keep your current routine - it\'s working!');
        recommendations.add('Maybe increase difficulty on 1-2 habits');
        break;

      case UserMoodState.recovering:
        recommendations.add('Great job getting back on track!');
        recommendations.add('Lock in this momentum with smaller goals');
        break;

      case UserMoodState.steady:
        recommendations
            .add('You\'re consistent - now try pushing a bit harder');
        recommendations.add('Pick one habit to focus extra attention on');
        break;

      case UserMoodState.struggling:
        recommendations.add('Focus on your easiest 2-3 habits first');
        recommendations.add('Consider pausing less important habits');
        recommendations.add('Set smaller, more achievable daily goals');
        break;

      case UserMoodState.overwhelmed:
        recommendations.add('Pause all but your 1-2 most important habits');
        recommendations.add('Reduce the difficulty of remaining habits');
        recommendations.add('It\'s okay to reset and start fresh');
        break;
    }

    return recommendations;
  }
}

class MoodDisplayInfo {
  final String emoji;
  final String title;
  final String message;
  final int color; // Color value as int (0xFFRRGGBB)
  final int energyLevel; // 0-100

  MoodDisplayInfo({
    required this.emoji,
    required this.title,
    required this.message,
    required this.color,
    required this.energyLevel,
  });
}
