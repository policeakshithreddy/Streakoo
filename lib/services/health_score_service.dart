/// Service for calculating and analyzing health scores
class HealthScoreService {
  HealthScoreService._();
  static final instance = HealthScoreService._();

  /// Calculate overall health score (0-100) based on multiple factors
  double calculateHealthScore({
    required double sleepHours,
    required int steps,
    required int habitsCompleted,
    required int totalHabits,
    required int currentStreak,
    double? distance,
    double? calories,
  }) {
    // Sleep Score (30 points max)
    // Optimal sleep: 7-9 hours
    final sleepScore = _calculateSleepScore(sleepHours) * 30;

    // Activity Score (25 points max)
    // Based on daily step goal of 10,000
    final activityScore = _calculateActivityScore(steps) * 25;

    // Habit Completion Score (25 points max)
    final habitScore =
        totalHabits > 0 ? (habitsCompleted / totalHabits) * 25 : 0.0;

    // Consistency Score (20 points max)
    // Rewards streaks (up to 7 days gets full points)
    final consistencyScore = (currentStreak / 7).clamp(0.0, 1.0) * 20;

    final totalScore =
        sleepScore + activityScore + habitScore + consistencyScore;

    return totalScore.clamp(0.0, 100.0);
  }

  /// Calculate sleep quality score (0-1)
  double _calculateSleepScore(double hours) {
    if (hours >= 7 && hours <= 9) {
      return 1.0; // Optimal sleep
    } else if (hours >= 6 && hours < 7) {
      return 0.8; // Good but could be better
    } else if (hours >= 5 && hours < 6) {
      return 0.6; // Below optimal
    } else if (hours >= 9 && hours <= 10) {
      return 0.8; // Slight oversleep but okay
    } else if (hours >= 4 && hours < 5) {
      return 0.4; // Poor sleep
    } else if (hours > 10) {
      return 0.6; // Too much sleep
    } else {
      return 0.2; // Very poor
    }
  }

  /// Calculate activity score (0-1) based on steps
  double _calculateActivityScore(int steps) {
    const targetSteps = 10000;
    if (steps >= targetSteps) {
      return 1.0;
    } else if (steps >= 7500) {
      return 0.8;
    } else if (steps >= 5000) {
      return 0.6;
    } else if (steps >= 2500) {
      return 0.4;
    } else {
      return (steps / targetSteps).clamp(0.0, 1.0);
    }
  }

  /// Get health score category and message
  HealthScoreCategory getScoreCategory(double score) {
    if (score >= 90) {
      return HealthScoreCategory(
        level: 'Excellent',
        message: 'Outstanding! You\'re crushing your health goals! 🌟',
        emoji: '🌟',
        color: '4CAF50', // Green
      );
    } else if (score >= 75) {
      return HealthScoreCategory(
        level: 'Great',
        message: 'Great work! Keep up the momentum! 💪',
        emoji: '💪',
        color: '66BB6A', // Light Green
      );
    } else if (score >= 60) {
      return HealthScoreCategory(
        level: 'Good',
        message:
            'You\'re doing well! Small improvements will boost your score.',
        emoji: '👍',
        color: 'FFA726', // Orange
      );
    } else if (score >= 40) {
      return HealthScoreCategory(
        level: 'Fair',
        message: 'You\'re on track, but there\'s room for improvement.',
        emoji: '📊',
        color: 'FF9800', // Dark Orange
      );
    } else {
      return HealthScoreCategory(
        level: 'Needs Attention',
        message: 'Let\'s work on building better habits together!',
        emoji: '💡',
        color: 'EF5350', // Red
      );
    }
  }

  /// Analyze trends and provide insights
  HealthTrend analyzeTrend({
    required List<double> weeklyScores,
  }) {
    if (weeklyScores.length < 2) {
      return HealthTrend(
        direction: TrendDirection.stable,
        message: 'Keep tracking to see your trends!',
        changePercentage: 0.0,
      );
    }

    // Compare recent 3 days vs previous 4 days
    final recentDays = weeklyScores.sublist(
      weeklyScores.length - 3,
      weeklyScores.length,
    );
    final previousDays = weeklyScores.sublist(0, weeklyScores.length - 3);

    final recentAvg = recentDays.reduce((a, b) => a + b) / recentDays.length;
    final previousAvg =
        previousDays.reduce((a, b) => a + b) / previousDays.length;

    final change = ((recentAvg - previousAvg) / previousAvg * 100);

    if (change >= 5) {
      return HealthTrend(
        direction: TrendDirection.improving,
        message: 'Your health score is improving! 📈',
        changePercentage: change,
      );
    } else if (change <= -5) {
      return HealthTrend(
        direction: TrendDirection.declining,
        message: 'Your score has dipped. Let\'s get back on track! 📉',
        changePercentage: change,
      );
    } else {
      return HealthTrend(
        direction: TrendDirection.stable,
        message: 'You\'re maintaining a stable routine. 📊',
        changePercentage: change,
      );
    }
  }

  /// Generate personalized recommendations based on score components
  List<String> getRecommendations({
    required double sleepHours,
    required int steps,
    required int habitsCompleted,
    required int totalHabits,
    required int currentStreak,
  }) {
    final recommendations = <String>[];

    // Sleep recommendations
    if (sleepHours < 6) {
      recommendations.add(
        '😴 Try to get at least 7 hours of sleep tonight. Your body needs rest to recover!',
      );
    } else if (sleepHours > 10) {
      recommendations.add(
        '⏰ You might be oversleeping. Try setting a consistent wake time.',
      );
    }

    // Activity recommendations
    if (steps < 5000) {
      recommendations.add(
        '🚶 Take a 20-minute walk today to boost your step count and energy!',
      );
    } else if (steps < 10000) {
      recommendations.add(
          '👟 You\'re close to your goal! A quick walk will get you there.');
    }

    // Habit recommendations
    if (totalHabits > 0) {
      final completionRate = habitsCompleted / totalHabits;
      if (completionRate < 0.5) {
        recommendations.add(
          '✅ Focus on completing just one more habit today. Small wins matter!',
        );
      }
    }

    // Streak recommendations
    if (currentStreak == 0) {
      recommendations.add(
        '🔥 Start a streak today! Consistency is the key to lasting change.',
      );
    } else if (currentStreak >= 7) {
      recommendations.add(
        '🌟 Amazing $currentStreak-day streak! You\'re building powerful habits.',
      );
    }

    // If already doing great
    if (recommendations.isEmpty) {
      recommendations.add(
        '🎯 You\'re doing fantastic! Keep up this amazing momentum!',
      );
    }

    return recommendations.take(3).toList(); // Return top 3
  }
}

/// Health score category with metadata
class HealthScoreCategory {
  final String level;
  final String message;
  final String emoji;
  final String color; // Hex color without #

  HealthScoreCategory({
    required this.level,
    required this.message,
    required this.emoji,
    required this.color,
  });
}

/// Health trend analysis
class HealthTrend {
  final TrendDirection direction;
  final String message;
  final double changePercentage;

  HealthTrend({
    required this.direction,
    required this.message,
    required this.changePercentage,
  });
}

enum TrendDirection {
  improving,
  declining,
  stable,
}
