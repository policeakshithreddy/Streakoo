import '../models/habit.dart';

/// Risk level for streak prediction
enum StreakRiskLevel {
  safe, // No risk - consistent completion
  moderate, // Some risk - occasional misses
  high, // High risk - pattern suggests likely miss
  critical, // Critical - about to break streak
}

/// Prediction result with actionable insights
class StreakPrediction {
  final String habitId;
  final String habitName;
  final String emoji;
  final StreakRiskLevel riskLevel;
  final double breakProbability; // 0.0 to 1.0
  final int currentStreak;
  final String reason;
  final String suggestion;
  final DateTime? predictedBreakDate;
  final List<int> riskyDays; // 1=Mon, 7=Sun

  StreakPrediction({
    required this.habitId,
    required this.habitName,
    required this.emoji,
    required this.riskLevel,
    required this.breakProbability,
    required this.currentStreak,
    required this.reason,
    required this.suggestion,
    this.predictedBreakDate,
    this.riskyDays = const [],
  });

  bool get shouldWarn =>
      riskLevel == StreakRiskLevel.high ||
      riskLevel == StreakRiskLevel.critical;
  bool get shouldAlert => riskLevel == StreakRiskLevel.critical;
}

/// Analyzes habit patterns to predict streak breaks
class StreakPredictorService {
  StreakPredictorService._();
  static final StreakPredictorService instance = StreakPredictorService._();

  /// Analyze all habits and return predictions for at-risk streaks
  List<StreakPrediction> analyzeAllHabits(List<Habit> habits) {
    final predictions = <StreakPrediction>[];

    for (final habit in habits) {
      // Skip habits with no streak to lose
      if (habit.streak == 0) continue;

      final prediction = analyzeHabit(habit);
      if (prediction.shouldWarn) {
        predictions.add(prediction);
      }
    }

    // Sort by risk level (critical first)
    predictions
        .sort((a, b) => b.breakProbability.compareTo(a.breakProbability));

    return predictions;
  }

  /// Analyze a single habit and predict streak break risk
  StreakPrediction analyzeHabit(Habit habit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Parse completion dates
    final completionDates = habit.completionDates
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .toList()
      ..sort();

    if (completionDates.isEmpty) {
      return _createPrediction(
        habit,
        StreakRiskLevel.safe,
        0.0,
        reason: 'New habit',
        suggestion: 'Keep building your streak!',
      );
    }

    // 2. Calculate metrics
    final daysSinceLastCompletion =
        today.difference(completionDates.last).inDays;
    final completionRate =
        _calculateCompletionRate(completionDates, habit.frequencyDays);
    final weekdayPattern = _analyzeWeekdayPattern(completionDates);
    final gapPattern = _analyzeGapPattern(completionDates);

    // 3. Calculate risk score
    double riskScore = 0.0;
    String reason = '';
    String suggestion = '';
    List<int> riskyDays = [];

    // Factor 1: Days since last completion (most important)
    if (!habit.completedToday) {
      if (daysSinceLastCompletion == 0) {
        // Today not completed yet - check time of day
        if (now.hour >= 20) {
          riskScore += 0.4; // Evening and not done
          reason = 'It\'s getting late';
          suggestion = 'Complete now before bed!';
        } else if (now.hour >= 14) {
          riskScore += 0.2; // Afternoon
          reason = 'Afternoon reminder';
        }
      } else if (daysSinceLastCompletion == 1) {
        riskScore += 0.5;
        reason = 'Yesterday was missed';
        suggestion = 'Get back on track today!';
      } else if (daysSinceLastCompletion >= 2) {
        riskScore += 0.8;
        reason = 'Multiple days missed';
        suggestion = 'Your streak needs immediate attention!';
      }
    }

    // Factor 2: Completion rate trend
    if (completionRate < 0.5) {
      riskScore += 0.3;
      if (reason.isEmpty) {
        reason = 'Low completion rate';
        suggestion = 'Consider adjusting your schedule';
      }
    } else if (completionRate < 0.7) {
      riskScore += 0.15;
    }

    // Factor 3: Weekday pattern (identify weak days)
    final todayWeekday = now.weekday;
    final weakDays = weekdayPattern.entries
        .where((e) => e.value < 0.5)
        .map((e) => e.key)
        .toList();

    if (weakDays.contains(todayWeekday)) {
      riskScore += 0.2;
      riskyDays = weakDays;
      if (reason.isEmpty) {
        final dayName = _weekdayName(todayWeekday);
        reason = '$dayName is historically weak';
        suggestion = 'Pay extra attention today!';
      }
    }

    // Factor 4: Gap pattern (longer gaps indicate risk)
    if (gapPattern > 2.0) {
      riskScore += 0.2;
    }

    // Factor 5: High streak value increases importance
    if (habit.streak > 30) {
      riskScore *= 1.2; // Amplify risk for long streaks
    } else if (habit.streak > 7) {
      riskScore *= 1.1;
    }

    // Clamp risk score
    riskScore = riskScore.clamp(0.0, 1.0);

    // Determine risk level
    StreakRiskLevel riskLevel;
    if (riskScore >= 0.7) {
      riskLevel = StreakRiskLevel.critical;
    } else if (riskScore >= 0.5) {
      riskLevel = StreakRiskLevel.high;
    } else if (riskScore >= 0.3) {
      riskLevel = StreakRiskLevel.moderate;
    } else {
      riskLevel = StreakRiskLevel.safe;
    }

    // Default messages
    if (reason.isEmpty) reason = 'Tracking your progress';
    if (suggestion.isEmpty) suggestion = 'Keep up the great work!';

    return _createPrediction(
      habit.copyWith(),
      riskLevel,
      riskScore,
      reason: reason,
      suggestion: suggestion,
      riskyDays: riskyDays,
    );
  }

  /// Calculate completion rate over last 30 days
  double _calculateCompletionRate(
      List<DateTime> dates, List<int> frequencyDays) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Count expected completions based on frequency
    int expectedDays = 0;
    int actualDays = 0;

    for (var day = thirtyDaysAgo;
        day.isBefore(now);
        day = day.add(const Duration(days: 1))) {
      if (frequencyDays.contains(day.weekday)) {
        expectedDays++;

        // Check if completed on this day
        if (dates.any((d) =>
            d.year == day.year && d.month == day.month && d.day == day.day)) {
          actualDays++;
        }
      }
    }

    if (expectedDays == 0) return 1.0;
    return actualDays / expectedDays;
  }

  /// Analyze which weekdays have best/worst completion
  Map<int, double> _analyzeWeekdayPattern(List<DateTime> dates) {
    final weekdayCount = <int, int>{};
    final weekdayTotal = <int, int>{};

    // Only look at last 8 weeks
    final cutoff = DateTime.now().subtract(const Duration(days: 56));
    final recentDates = dates.where((d) => d.isAfter(cutoff)).toList();

    for (final date in recentDates) {
      weekdayCount[date.weekday] = (weekdayCount[date.weekday] ?? 0) + 1;
    }

    // Count total occurrences of each weekday in period
    for (var i = 1; i <= 7; i++) {
      weekdayTotal[i] = 8; // 8 weeks
    }

    // Calculate rate per weekday
    final result = <int, double>{};
    for (var i = 1; i <= 7; i++) {
      final count = weekdayCount[i] ?? 0;
      final total = weekdayTotal[i] ?? 1;
      result[i] = count / total;
    }

    return result;
  }

  /// Analyze average gap between completions
  double _analyzeGapPattern(List<DateTime> dates) {
    if (dates.length < 2) return 0.0;

    final gaps = <int>[];
    for (var i = 1; i < dates.length; i++) {
      gaps.add(dates[i].difference(dates[i - 1]).inDays);
    }

    if (gaps.isEmpty) return 0.0;
    return gaps.reduce((a, b) => a + b) / gaps.length;
  }

  String _weekdayName(int weekday) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return names[weekday];
  }

  StreakPrediction _createPrediction(
    Habit habit,
    StreakRiskLevel riskLevel,
    double probability, {
    required String reason,
    required String suggestion,
    List<int> riskyDays = const [],
  }) {
    return StreakPrediction(
      habitId: habit.id,
      habitName: habit.name,
      emoji: habit.emoji,
      riskLevel: riskLevel,
      breakProbability: probability,
      currentStreak: habit.streak,
      reason: reason,
      suggestion: suggestion,
      riskyDays: riskyDays,
    );
  }

  /// Get habits that need warning notifications
  List<StreakPrediction> getHabitsNeedingWarning(List<Habit> habits) {
    return analyzeAllHabits(habits).where((p) => p.shouldWarn).toList();
  }

  /// Get the most critical habit at risk
  StreakPrediction? getMostCriticalRisk(List<Habit> habits) {
    final predictions = analyzeAllHabits(habits);
    if (predictions.isEmpty) return null;
    return predictions.first; // Already sorted by risk
  }
}
