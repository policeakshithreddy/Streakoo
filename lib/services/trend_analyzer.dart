/// Trend Analyzer for detecting patterns and correlations
class TrendAnalyzer {
  /// Analyze weekly performance trend
  static TrendAnalysis analyzeWeeklyTrend({
    required List<DailyStats> last7Days,
    required List<DailyStats> previous7Days,
  }) {
    final thisWeekAvg = _calculateAverageCompletion(last7Days);
    final lastWeekAvg = _calculateAverageCompletion(previous7Days);

    final percentageChange = lastWeekAvg > 0
        ? ((thisWeekAvg - lastWeekAvg) / lastWeekAvg) * 100
        : 0.0;

    final trend = percentageChange > 5
        ? TrendDirection.improving
        : percentageChange < -5
            ? TrendDirection.declining
            : TrendDirection.stable;

    return TrendAnalysis(
      direction: trend,
      percentageChange: percentageChange,
      thisWeekAverage: thisWeekAvg,
      lastWeekAverage: lastWeekAvg,
      message: _getTrendMessage(trend, percentageChange.abs()),
    );
  }

  /// Find correlation between habits
  static HabitCorrelation? findCorrelation({
    required List<HabitCompletion> habit1Completions,
    required List<HabitCompletion> habit2Completions,
    required String habit1Name,
    required String habit2Name,
  }) {
    if (habit1Completions.length < 7 || habit2Completions.length < 7) {
      return null; // Need at least a week of data
    }

    // Simple correlation: days both completed / total days
    int bothCompletedCount = 0;
    int totalDays = 0;

    for (int i = 0; i < habit1Completions.length; i++) {
      if (i < habit2Completions.length) {
        if (habit1Completions[i].completed && habit2Completions[i].completed) {
          bothCompletedCount++;
        }
        totalDays++;
      }
    }

    final correlationStrength =
        totalDays > 0 ? (bothCompletedCount / totalDays) * 100 : 0.0;

    if (correlationStrength >= 70) {
      return HabitCorrelation(
        habit1: habit1Name,
        habit2: habit2Name,
        strength: correlationStrength,
        insight:
            '$habit1Name and $habit2Name work great together! Keep pairing them.',
      );
    }

    return null;
  }

  /// Predict best time to work out based on completion history
  static String? predictBestTime(List<DateTime> completionTimes) {
    if (completionTimes.length < 7) return null;

    // Group by hour
    final hourCounts = <int, int>{};
    for (final time in completionTimes) {
      hourCounts[time.hour] = (hourCounts[time.hour] ?? 0) + 1;
    }

    // Find most common hour
    int? bestHour;
    int maxCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        bestHour = hour;
      }
    });

    if (bestHour == null) return null;

    // Convert to readable time range
    if (bestHour! >= 5 && bestHour! < 12) {
      return 'Morning (${bestHour}:00 - ${bestHour! + 1}:00)';
    } else if (bestHour! >= 12 && bestHour! < 17) {
      return 'Afternoon (${bestHour}:00 - ${bestHour! + 1}:00)';
    } else if (bestHour! >= 17 && bestHour! < 21) {
      return 'Evening (${bestHour}:00 - ${bestHour! + 1}:00)';
    } else {
      return 'Night (${bestHour}:00 - ${bestHour! + 1}:00)';
    }
  }

  /// Calculate average completion rate
  static double _calculateAverageCompletion(List<DailyStats> days) {
    if (days.isEmpty) return 0;

    final total = days.fold<double>(
      0,
      (sum, day) => sum + day.completionRate,
    );

    return total / days.length;
  }

  /// Get trend message
  static String _getTrendMessage(TrendDirection direction, double change) {
    switch (direction) {
      case TrendDirection.improving:
        return '↑ ${change.toStringAsFixed(0)}% better than last week!';
      case TrendDirection.declining:
        return '↓ ${change.toStringAsFixed(0)}% lower than last week';
      case TrendDirection.stable:
        return '→ Steady performance maintained';
    }
  }

  /// Predict milestone achievement
  static String? predictMilestone({
    required int currentStreak,
    required double averageDailyCompletion,
    required int targetStreak,
  }) {
    if (currentStreak >= targetStreak) {
      return 'Milestone achieved! 🎉';
    }

    if (averageDailyCompletion < 0.7) {
      return null; // Too inconsistent to predict
    }

    final daysNeeded = targetStreak - currentStreak;
    final projectedDays = (daysNeeded / averageDailyCompletion).ceil();

    if (projectedDays <= 7) {
      return '🎯 Target streak in ~$projectedDays days at current pace!';
    }

    return null;
  }
}

enum TrendDirection { improving, declining, stable }

class TrendAnalysis {
  final TrendDirection direction;
  final double percentageChange;
  final double thisWeekAverage;
  final double lastWeekAverage;
  final String message;

  TrendAnalysis({
    required this.direction,
    required this.percentageChange,
    required this.thisWeekAverage,
    required this.lastWeekAverage,
    required this.message,
  });
}

class HabitCorrelation {
  final String habit1;
  final String habit2;
  final double strength; // 0-100
  final String insight;

  HabitCorrelation({
    required this.habit1,
    required this.habit2,
    required this.strength,
    required this.insight,
  });
}

class DailyStats {
  final DateTime date;
  final int completed;
  final int total;
  final double completionRate;

  DailyStats({
    required this.date,
    required this.completed,
    required this.total,
  }) : completionRate = total > 0 ? (completed / total) * 100 : 0;
}

class HabitCompletion {
  final DateTime date;
  final bool completed;

  HabitCompletion({required this.date, required this.completed});
}
