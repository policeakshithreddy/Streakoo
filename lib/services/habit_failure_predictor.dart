import '../models/habit.dart';

/// Predicts which habits are at risk of being missed today based on patterns
class HabitFailurePredictor {
  static final HabitFailurePredictor instance = HabitFailurePredictor._();
  HabitFailurePredictor._();

  /// Analyze habits and return predictions for today's risks
  List<HabitRiskPrediction> predictTodaysRisks(List<Habit> habits) {
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
    final hourOfDay = now.hour;

    final predictions = <HabitRiskPrediction>[];

    for (final habit in habits) {
      // Skip if already completed today
      if (habit.completedToday) continue;

      // Skip if not scheduled for today
      if (!habit.frequencyDays.contains(dayOfWeek)) continue;

      final riskScore = _calculateRiskScore(habit, dayOfWeek, hourOfDay);

      if (riskScore > 0.3) {
        // Only include if meaningful risk
        predictions.add(HabitRiskPrediction(
          habit: habit,
          riskScore: riskScore,
          reason: _getRiskReason(habit, dayOfWeek, hourOfDay, riskScore),
          suggestion: _getSuggestion(habit, dayOfWeek, hourOfDay),
          confidence: _getConfidence(habit),
        ));
      }
    }

    // Sort by risk score (highest first)
    predictions.sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return predictions;
  }

  /// Calculate risk score (0.0 to 1.0) for a habit on a specific day
  double _calculateRiskScore(Habit habit, int dayOfWeek, int hourOfDay) {
    double score = 0.0;

    // 1. Day of week pattern analysis
    final dayRisk = _calculateDayOfWeekRisk(habit, dayOfWeek);
    score += dayRisk * 0.4; // 40% weight

    // 2. Time of day analysis (if it's late and not completed)
    if (hourOfDay >= 18) {
      // After 6 PM
      final lateRisk = (hourOfDay - 18) / 6; // 0.0 to 1.0 from 6PM to midnight
      score += lateRisk * 0.3; // 30% weight
    }

    // 3. Recent completion pattern
    final recentMissRisk = _calculateRecentMissRisk(habit);
    score += recentMissRisk * 0.2; // 20% weight

    // 4. Streak pressure (longer streaks = more at risk of breaking)
    if (habit.streak > 7) {
      final streakRisk = (habit.streak / 30).clamp(0.0, 0.3); // Max 0.3
      score += streakRisk * 0.1; // 10% weight
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate misshistorical on this day of week
  double _calculateDayOfWeekRisk(Habit habit, int dayOfWeek) {
    if (habit.completionDates.isEmpty) return 0.3; // Unknown = medium risk

    // Analyze completions by day of week
    int completionsOnDay = 0;
    int scheduledOnDay = 0;

    // Look at last 8 weeks
    final now = DateTime.now();
    for (int week = 0; week < 8; week++) {
      final checkDate = now.subtract(Duration(days: week * 7));
      if (checkDate.weekday == dayOfWeek) {
        scheduledOnDay++;
        final dateKey = _formatDateKey(checkDate);
        if (habit.completionDates.contains(dateKey)) {
          completionsOnDay++;
        }
      }
    }

    if (scheduledOnDay == 0) return 0.3;

    final completionRate = completionsOnDay / scheduledOnDay;
    return 1.0 - completionRate; // Higher miss rate = higher risk
  }

  /// Calculate risk based on recent misses
  double _calculateRecentMissRisk(Habit habit) {
    if (habit.completionDates.isEmpty) return 0.3;

    // Check last 7 days
    final now = DateTime.now();
    int missedDays = 0;
    int scheduledDays = 0;

    for (int i = 1; i <= 7; i++) {
      final checkDate = now.subtract(Duration(days: i));
      if (habit.frequencyDays.contains(checkDate.weekday)) {
        scheduledDays++;
        final dateKey = _formatDateKey(checkDate);
        if (!habit.completionDates.contains(dateKey)) {
          missedDays++;
        }
      }
    }

    if (scheduledDays == 0) return 0.0;
    return missedDays / scheduledDays;
  }

  /// Get human-readable risk reason
  String _getRiskReason(
      Habit habit, int dayOfWeek, int hourOfDay, double riskScore) {
    final dayName = _getDayName(dayOfWeek);

    // Check day pattern
    final dayRisk = _calculateDayOfWeekRisk(habit, dayOfWeek);
    if (dayRisk > 0.5) {
      return 'You often skip this on ${dayName}s';
    }

    // Check time
    if (hourOfDay >= 20) {
      return 'Getting late! Usually done earlier';
    }
    if (hourOfDay >= 18) {
      return 'Evening reminder - don\'t forget!';
    }

    // Check recent misses
    final recentMissRisk = _calculateRecentMissRisk(habit);
    if (recentMissRisk > 0.4) {
      return 'Missed a few recently - stay strong!';
    }

    // General high streak
    if (habit.streak > 14) {
      return '${habit.streak}-day streak at risk!';
    }

    return 'Predicted difficult day';
  }

  /// Get actionable suggestion
  String _getSuggestion(Habit habit, int dayOfWeek, int hourOfDay) {
    // Time-based suggestions
    if (hourOfDay < 12) {
      return 'Try completing it this morning before it slips!';
    }
    if (hourOfDay < 17) {
      return 'Perfect time for a quick break - do it now?';
    }
    if (hourOfDay < 20) {
      return 'Evening is here! Take 5 minutes for this.';
    }
    return 'Last chance before midnight - you got this!';
  }

  /// Suggest optimal time based on past completions
  TimeOfDay? suggestOptimalTime(Habit habit) {
    // For now, return a reasonable default
    // Future: Analyze actual completion times from a more detailed log
    if (habit.reminderTime != null) {
      final parts = habit.reminderTime!.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
    return const TimeOfDay(hour: 9, minute: 0); // Default morning
  }

  /// Calculate confidence in the prediction (based on data availability)
  double _getConfidence(Habit habit) {
    if (habit.completionDates.length < 7) return 0.3; // Low data
    if (habit.completionDates.length < 21) return 0.5; // Some data
    if (habit.completionDates.length < 60) return 0.7; // Good data
    return 0.9; // Lots of data
  }

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'day';
    }
  }
}

/// Represents a habit at risk of being missed
class HabitRiskPrediction {
  final Habit habit;
  final double riskScore; // 0.0 to 1.0
  final String reason;
  final String suggestion;
  final double confidence; // 0.0 to 1.0

  HabitRiskPrediction({
    required this.habit,
    required this.riskScore,
    required this.reason,
    required this.suggestion,
    required this.confidence,
  });

  /// Risk level enum based on score
  RiskLevel get riskLevel {
    if (riskScore >= 0.7) return RiskLevel.high;
    if (riskScore >= 0.5) return RiskLevel.medium;
    return RiskLevel.low;
  }

  /// Display color for risk level
  int get colorValue {
    switch (riskLevel) {
      case RiskLevel.high:
        return 0xFFE53935; // Red
      case RiskLevel.medium:
        return 0xFFFFA94A; // Orange
      case RiskLevel.low:
        return 0xFF4CAF50; // Green
    }
  }
}

enum RiskLevel { low, medium, high }

class TimeOfDay {
  final int hour;
  final int minute;
  const TimeOfDay({required this.hour, required this.minute});
}
