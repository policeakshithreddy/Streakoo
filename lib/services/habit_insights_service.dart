import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/habit_insight.dart';

/// Service to analyze habit patterns and generate insights
class HabitInsightsService {
  static final HabitInsightsService _instance =
      HabitInsightsService._internal();
  factory HabitInsightsService() => _instance;
  HabitInsightsService._internal();

  static HabitInsightsService get instance => _instance;

  /// Generate insights for all habits
  List<HabitInsight> generateInsights(List<Habit> habits) {
    debugPrint('🧠 Generating habit insights...');

    final insights = <HabitInsight>[];

    for (final habit in habits) {
      // Only analyze habits with sufficient data
      if (habit.completionDates.length < 7) continue;

      insights.addAll(_analyzeHabit(habit));
    }

    debugPrint('✅ Generated ${insights.length} insights');
    return insights;
  }

  /// Analyze a single habit for patterns
  List<HabitInsight> _analyzeHabit(Habit habit) {
    final insights = <HabitInsight>[];

    // 1. Weekday vs Weekend Pattern
    final weekdayInsight = _analyzeWeekdayPattern(habit);
    if (weekdayInsight != null) insights.add(weekdayInsight);

    // 2. Streak Warning
    final streakWarning = _detectStreakRisk(habit);
    if (streakWarning != null) insights.add(streakWarning);

    // 3. Performance Trend
    final trendInsight = _analyzeTrend(habit);
    if (trendInsight != null) insights.add(trendInsight);

    // 4. Motivation Boost
    final motivationInsight = _generateMotivation(habit);
    if (motivationInsight != null) insights.add(motivationInsight);

    return insights;
  }

  /// Analyze weekday vs weekend completion pattern
  HabitInsight? _analyzeWeekdayPattern(Habit habit) {
    int weekdayCompletions = 0;
    int weekendCompletions = 0;
    int totalWeekdays = 0;
    int totalWeekends = 0;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    for (final dateStr in habit.completionDates) {
      try {
        final date = DateTime.parse(dateStr);
        if (date.isBefore(thirtyDaysAgo)) continue;

        final isWeekend = date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;

        if (isWeekend) {
          weekendCompletions++;
        } else {
          weekdayCompletions++;
        }
      } catch (e) {
        continue;
      }
    }

    // Count total possible days
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        totalWeekends++;
      } else {
        totalWeekdays++;
      }
    }

    if (totalWeekdays == 0 || totalWeekends == 0) return null;

    final weekdayRate = weekdayCompletions / totalWeekdays;
    final weekendRate = weekendCompletions / totalWeekends;

    // Only generate insight if there's a significant difference (>30%)
    if ((weekdayRate - weekendRate).abs() < 0.3) return null;

    final percentDiff =
        ((weekdayRate - weekendRate) / weekendRate * 100).round().abs();

    String message;
    if (weekdayRate > weekendRate) {
      message =
          'You complete "${habit.name}" ${percentDiff}% more on weekdays! Consider weekend reminders.';
    } else {
      message =
          'You complete "${habit.name}" ${percentDiff}% more on weekends! Weekdays need more focus.';
    }

    return HabitInsight(
      habitId: habit.id,
      habitName: habit.name,
      habitEmoji: habit.emoji,
      type: InsightType.weekdayPattern,
      message: message,
      confidence: 0.8,
      metadata: {
        'weekdayRate': weekdayRate,
        'weekendRate': weekendRate,
        'percentDiff': percentDiff,
      },
      generatedAt: DateTime.now(),
    );
  }

  /// Detect if habit is at risk of streak loss
  HabitInsight? _detectStreakRisk(Habit habit) {
    if (habit.streak < 3) return null; // Only warn for established streaks

    // Check if user completed today
    if (habit.completedToday) return null;

    // Analyze which days user typically skips
    Map<int, int> daySkips = {}; // weekday -> skip count
    Map<int, int> dayCompletions = {}; // weekday -> completion count

    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (habit.completionDates.contains(dateStr)) {
        dayCompletions[date.weekday] = (dayCompletions[date.weekday] ?? 0) + 1;
      } else {
        daySkips[date.weekday] = (daySkips[date.weekday] ?? 0) + 1;
      }
    }

    // Find the most skipped day
    int mostSkippedDay = 0;
    int maxSkips = 0;
    daySkips.forEach((day, skips) {
      if (skips > maxSkips) {
        maxSkips = skips;
        mostSkippedDay = day;
      }
    });

    // If today is a frequently skipped day, warn the user
    if (now.weekday == mostSkippedDay && maxSkips >= 3) {
      final dayName = _getDayName(mostSkippedDay);
      return HabitInsight(
        habitId: habit.id,
        habitName: habit.name,
        habitEmoji: habit.emoji,
        type: InsightType.streakWarning,
        message:
            'You usually skip "${habit.name}" on ${dayName}s. Don\'t break your ${habit.streak}-day streak!',
        confidence: 0.9,
        metadata: {
          'mostSkippedDay': dayName,
          'currentStreak': habit.streak,
        },
        generatedAt: DateTime.now(),
      );
    }

    return null;
  }

  /// Analyze performance trend (improving or declining)
  HabitInsight? _analyzeTrend(Habit habit) {
    if (habit.completionDates.length < 14) return null;

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    int lastWeekCompletions = 0;
    int previousWeekCompletions = 0;

    for (final dateStr in habit.completionDates) {
      try {
        final date = DateTime.parse(dateStr);

        if (date.isAfter(sevenDaysAgo)) {
          lastWeekCompletions++;
        } else if (date.isAfter(fourteenDaysAgo) &&
            date.isBefore(sevenDaysAgo)) {
          previousWeekCompletions++;
        }
      } catch (e) {
        continue;
      }
    }

    if (previousWeekCompletions == 0) return null;

    final percentChange = ((lastWeekCompletions - previousWeekCompletions) /
            previousWeekCompletions *
            100)
        .round();

    if (percentChange.abs() < 20)
      return null; // Only report significant changes

    if (percentChange > 0) {
      return HabitInsight(
        habitId: habit.id,
        habitName: habit.name,
        habitEmoji: habit.emoji,
        type: InsightType.improvement,
        message:
            'You improved "${habit.name}" by $percentChange% this week! Keep it up! 🚀',
        confidence: 0.85,
        metadata: {
          'lastWeek': lastWeekCompletions,
          'previousWeek': previousWeekCompletions,
          'percentChange': percentChange,
        },
        generatedAt: DateTime.now(),
      );
    } else {
      return HabitInsight(
        habitId: habit.id,
        habitName: habit.name,
        habitEmoji: habit.emoji,
        type: InsightType.decline,
        message:
            'Your "${habit.name}" completion dropped ${percentChange.abs()}% this week. What can help?',
        confidence: 0.85,
        metadata: {
          'lastWeek': lastWeekCompletions,
          'previousWeek': previousWeekCompletions,
          'percentChange': percentChange,
        },
        generatedAt: DateTime.now(),
      );
    }
  }

  /// Generate motivational insight for streaks
  HabitInsight? _generateMotivation(Habit habit) {
    if (habit.streak < 7) return null;

    String message;
    if (habit.streak >= 100) {
      message =
          '🏆 ${habit.streak}-day streak on "${habit.name}"! You\'re unstoppable!';
    } else if (habit.streak >= 30) {
      message =
          '🌟 ${habit.streak} days of "${habit.name}"! That\'s a month of consistency!';
    } else if (habit.streak >= 14) {
      message =
          '⭐ ${habit.streak}-day streak! Your "${habit.name}" habit is becoming automatic!';
    } else if (habit.streak == 7) {
      message = '🔥 7-day streak on "${habit.name}"! One week down!';
    } else {
      return null;
    }

    return HabitInsight(
      habitId: habit.id,
      habitName: habit.name,
      habitEmoji: habit.emoji,
      type: InsightType.motivation,
      message: message,
      confidence: 1.0,
      metadata: {
        'streak': habit.streak,
      },
      generatedAt: DateTime.now(),
    );
  }

  /// Get day name from weekday number
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

  /// Get top 3 most actionable insights
  List<HabitInsight> getTopInsights(List<HabitInsight> insights) {
    // Sort by confidence and return top 3
    final sorted = List<HabitInsight>.from(insights)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    return sorted.take(3).toList();
  }
}
