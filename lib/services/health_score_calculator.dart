import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Health Score Calculator - Apple Health-inspired 0-100 score
class HealthScoreCalculator {
  /// Calculate overall health score (0-100)
  static int calculateScore({
    required int completedHabitsToday,
    required int totalHabitsToday,
    required int currentStreak,
    required int totalDaysActive,
    required double sleepQuality, // 1-5
    required double stressLevel, // 1-5
    required int weeklyCompletionRate, // percentage
    required int lastWeekCompletionRate, // percentage
  }) {
    // 1. Completion Rate (40 points)
    double completionScore = 0;
    if (totalHabitsToday > 0) {
      final todayRate = (completedHabitsToday / totalHabitsToday) * 100;
      completionScore = (todayRate / 100) * 40;
    }

    // 2. Streak Consistency (30 points)
    double streakScore = 0;
    if (totalDaysActive > 0) {
      final consistency = (currentStreak / totalDaysActive).clamp(0.0, 1.0);
      streakScore = consistency * 30;

      // Bonus for impressive streaks
      if (currentStreak >= 7) streakScore += 3;
      if (currentStreak >= 30) streakScore += 5;
      if (currentStreak >= 100) streakScore += 7;
    }

    // 3. Sleep & Stress (20 points)
    final sleepScore = ((sleepQuality - 1) / 4) * 10; // 0-10 points
    final stressScore = ((5 - stressLevel) / 4) * 10; // 0-10 points (inverted)
    final wellnessScore = sleepScore + stressScore;

    // 4. Week-over-Week Improvement (10 points)
    double improvementScore = 0;
    if (lastWeekCompletionRate > 0) {
      final improvement = weeklyCompletionRate - lastWeekCompletionRate;
      if (improvement > 0) {
        improvementScore =
            (improvement / 20).clamp(0.0, 1.0) * 10; // Max +20% = 10 pts
      } else if (improvement < -10) {
        improvementScore = -5; // Penalty for significant drops
      }
    }

    final totalScore =
        (completionScore + streakScore + wellnessScore + improvementScore)
            .clamp(0.0, 100.0)
            .round();

    return totalScore;
  }

  /// Get score category and message
  static HealthScoreStatus getScoreStatus(int score) {
    if (score >= 90) {
      return HealthScoreStatus(
        category: 'Excellent',
        emoji: '🏆',
        color: const Color(0xFF00C853),
        message: 'Outstanding performance! You\'re crushing it!',
        actionTip: 'Keep this momentum going - you\'re an inspiration!',
      );
    } else if (score >= 75) {
      return HealthScoreStatus(
        category: 'Great',
        emoji: '⭐',
        color: const Color(0xFF2196F3),
        message: 'Great work! You\'re doing really well.',
        actionTip: 'Push a bit harder to reach Excellent!',
      );
    } else if (score >= 60) {
      return HealthScoreStatus(
        category: 'Good',
        emoji: '👍',
        color: const Color(0xFFFF9800),
        message: 'Good progress! Stay consistent.',
        actionTip: 'Focus on completing one more habit today.',
      );
    } else if (score >= 40) {
      return HealthScoreStatus(
        category: 'Fair',
        emoji: '💪',
        color: const Color(0xFFFF5722),
        message: 'You can do better! Let\'s improve together.',
        actionTip: 'Start small - complete at least 50% of your habits.',
      );
    } else {
      return HealthScoreStatus(
        category: 'Needs Work',
        emoji: '🎯',
        color: const Color(0xFFF44336),
        message: 'Let\'s get back on track!',
        actionTip: 'Begin with just one habit today - you got this!',
      );
    }
  }

  /// Calculate trend percentage (this week vs last week)
  static double calculateTrend({
    required int thisWeekScore,
    required int lastWeekScore,
  }) {
    if (lastWeekScore == 0) return 0;
    return ((thisWeekScore - lastWeekScore) / lastWeekScore) * 100;
  }

  /// Predict days until target score
  static int? predictDaysToTarget({
    required int currentScore,
    required int targetScore,
    required double averageWeeklyGrowth, // percentage
  }) {
    if (currentScore >= targetScore) return 0;
    if (averageWeeklyGrowth <= 0) return null; // Can't predict negative growth

    final pointsNeeded = targetScore - currentScore;
    final weeksNeeded =
        pointsNeeded / (averageWeeklyGrowth / 100 * currentScore);

    return (weeksNeeded * 7).ceil();
  }
}

class HealthScoreStatus {
  final String category;
  final String emoji;
  final Color color;
  final String message;
  final String actionTip;

  HealthScoreStatus({
    required this.category,
    required this.emoji,
    required this.color,
    required this.message,
    required this.actionTip,
  });
}

/// Trend data for charts
class HealthScoreTrend {
  final DateTime date;
  final int score;

  HealthScoreTrend({required this.date, required this.score});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'score': score,
      };

  factory HealthScoreTrend.fromJson(Map<String, dynamic> json) {
    return HealthScoreTrend(
      date: DateTime.parse(json['date']),
      score: json['score'],
    );
  }
}
