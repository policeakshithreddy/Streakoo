import '../models/habit.dart';

class CompletionPattern {
  final String habitId;
  final List<DateTime> completionTimes;
  final Map<int, int> hourFrequency; // hour -> count
  final int totalCompletions;

  CompletionPattern({
    required this.habitId,
    required this.completionTimes,
    required this.hourFrequency,
    required this.totalCompletions,
  });

  // Get most common completion hour
  int? get preferredHour {
    if (hourFrequency.isEmpty) return null;

    int maxCount = 0;
    int? bestHour;

    hourFrequency.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        bestHour = hour;
      }
    });

    return bestHour;
  }

  // Get completion rate (0.0 to 1.0)
  double get completionRate {
    if (totalCompletions == 0) return 0.0;
    // Calculate based on expected completions vs actual
    final daysSinceStart = completionTimes.isEmpty
        ? 1
        : DateTime.now().difference(completionTimes.first).inDays + 1;
    return (totalCompletions / daysSinceStart).clamp(0.0, 1.0);
  }
}

class SmartReminderEngine {
  SmartReminderEngine._();
  static final SmartReminderEngine instance = SmartReminderEngine._();

  // Analyze completion patterns for a habit
  CompletionPattern analyzePattern(Habit habit) {
    final completionTimes = <DateTime>[];
    final hourFrequency = <int, int>{};

    for (final dateStr in habit.completionDates) {
      try {
        final date = DateTime.parse(dateStr);
        completionTimes.add(date);

        // Track hour (use current hour as approximation for past data)
        // In production, you'd store actual completion timestamps
        final hour = date.hour;
        hourFrequency[hour] = (hourFrequency[hour] ?? 0) + 1;
      } catch (_) {
        // Skip invalid dates
      }
    }

    return CompletionPattern(
      habitId: habit.id,
      completionTimes: completionTimes,
      hourFrequency: hourFrequency,
      totalCompletions: completionTimes.length,
    );
  }

  // Get optimal reminder time for a habit
  int getOptimalReminderHour(Habit habit) {
    final pattern = analyzePattern(habit);

    // If we have a preferred hour, use it
    if (pattern.preferredHour != null) {
      return pattern.preferredHour!;
    }

    // Default based on category
    return _getDefaultHourForCategory(habit.category);
  }

  // Get default reminder hour based on category
  int _getDefaultHourForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'morning':
      case 'health':
        return 7; // 7 AM
      case 'study':
      case 'work':
        return 9; // 9 AM
      case 'evening':
        return 18; // 6 PM
      case 'sleep':
      case 'night':
        return 21; // 9 PM
      default:
        return 12; // Noon
    }
  }

  // Predict if streak is at risk
  bool isStreakAtRisk(Habit habit) {
    if (habit.completedToday) return false;
    if (habit.streak == 0) return false;

    final now = DateTime.now();
    final currentHour = now.hour;

    // If it's past 8 PM and not completed, high risk
    if (currentHour >= 20) return true;

    final pattern = analyzePattern(habit);

    // If user usually completes before this hour, medium risk
    if (pattern.preferredHour != null && currentHour > pattern.preferredHour!) {
      return true;
    }

    return false;
  }

  // Get reminder message based on risk level
  String getReminderMessage(Habit habit) {
    if (isStreakAtRisk(habit)) {
      return '⚠️ Your ${habit.streak}-day streak is at risk! Complete "${habit.name}" before midnight.';
    }

    final pattern = analyzePattern(habit);

    if (pattern.preferredHour != null) {
      return '${habit.emoji} Time for "${habit.name}"! You usually do this around ${_formatHour(pattern.preferredHour!)}';
    }

    return '${habit.emoji} Don\'t forget "${habit.name}" today!';
  }

  // Format hour for display
  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  // Analyze all habits and provide optimization suggestions
  Map<String, dynamic> getOptimizationSuggestions(List<Habit> habits) {
    final suggestions = <String, dynamic>{};
    final atRisk = <Habit>[];
    final wellPerforming = <Habit>[];

    for (final habit in habits) {
      final pattern = analyzePattern(habit);

      if (isStreakAtRisk(habit)) {
        atRisk.add(habit);
      }

      if (pattern.completionRate > 0.8) {
        wellPerforming.add(habit);
      }
    }

    suggestions['habitsAtRisk'] = atRisk.map((h) => h.name).toList();
    suggestions['wellPerforming'] = wellPerforming.map((h) => h.name).toList();
    suggestions['totalAnalyzed'] = habits.length;

    return suggestions;
  }

  // Determine best time slot for a new reminder
  int suggestTimeSlot(List<Habit> existingHabits, String category) {
    // Get hours already occupied by reminders
    final occupiedHours = <int>{};
    for (final habit in existingHabits) {
      final hour = getOptimalReminderHour(habit);
      occupiedHours.add(hour);
    }

    // Get default hour for this category
    final defaultHour = _getDefaultHourForCategory(category);

    // If default hour is free, use it
    if (!occupiedHours.contains(defaultHour)) {
      return defaultHour;
    }

    // Otherwise, find nearest free hour
    for (int offset = 1; offset <= 12; offset++) {
      final earlier = (defaultHour - offset) % 24;
      final later = (defaultHour + offset) % 24;

      if (!occupiedHours.contains(later)) return later;
      if (!occupiedHours.contains(earlier)) return earlier;
    }

    // Fallback to default
    return defaultHour;
  }
}
