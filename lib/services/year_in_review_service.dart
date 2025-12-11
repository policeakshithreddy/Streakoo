import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/year_in_review.dart';

/// Service to generate Year in Review statistics
class YearInReviewService {
  static final YearInReviewService _instance = YearInReviewService._internal();
  factory YearInReviewService() => _instance;
  YearInReviewService._internal();

  static YearInReviewService get instance => _instance;

  /// Generate Year in Review for a specific year
  YearInReview generateReview(List<Habit> habits, int year) {
    debugPrint('📊 Generating Year in Review for $year...');

    // Filter habits and completion dates for the specific year
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31, 23, 59, 59);

    int totalCompletions = 0;
    int longestStreak = 0;
    int totalXP = 0;
    Map<String, int> habitBreakdown = {};
    Map<String, int> monthlyCompletions = {}; // Month name -> completions
    Set<String> activeDays = {};

    // Track perfect days
    Map<String, int> dailyCompletionCount = {};
    int totalHabitsPerDay = habits.length;

    for (final habit in habits) {
      int habitCompletions = 0;

      // Count completions in this year
      for (final dateStr in habit.completionDates) {
        try {
          final date = DateTime.parse(dateStr);
          if (date.isAfter(yearStart.subtract(const Duration(days: 1))) &&
              date.isBefore(yearEnd.add(const Duration(days: 1)))) {
            habitCompletions++;
            totalCompletions++;
            totalXP += habit.xpValue;

            // Track active days
            final dayKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            activeDays.add(dayKey);

            // Track daily completion count
            dailyCompletionCount[dayKey] =
                (dailyCompletionCount[dayKey] ?? 0) + 1;

            // Track monthly completions
            final monthName = _getMonthName(date.month);
            monthlyCompletions[monthName] =
                (monthlyCompletions[monthName] ?? 0) + 1;
          }
        } catch (e) {
          debugPrint('Error parsing date: $dateStr');
        }
      }

      habitBreakdown[habit.name] = habitCompletions;

      // Track longest streak in the year
      final yearStreak = _calculateYearStreak(habit.completionDates, year);
      if (yearStreak > longestStreak) {
        longestStreak = yearStreak;
      }
    }

    // Find most consistent habit
    String mostConsistentHabit = 'None';
    String mostConsistentEmoji = '🌟';
    int maxCompletions = 0;

    habitBreakdown.forEach((name, count) {
      if (count > maxCompletions) {
        maxCompletions = count;
        mostConsistentHabit = name;
        // Find the emoji for this habit
        final habit = habits.firstWhere((h) => h.name == name,
            orElse: () => habits.first);
        mostConsistentEmoji = habit.emoji;
      }
    });

    // Find best month
    String bestMonth = 'January';
    int maxMonthCompletions = 0;
    monthlyCompletions.forEach((month, count) {
      if (count > maxMonthCompletions) {
        maxMonthCompletions = count;
        bestMonth = month;
      }
    });

    // Calculate perfect days
    int perfectDays = 0;
    dailyCompletionCount.forEach((day, count) {
      if (count >= totalHabitsPerDay) {
        perfectDays++;
      }
    });

    // Calculate average completion rate
    final daysInYear = yearEnd.difference(yearStart).inDays + 1;
    final possibleCompletions = habits.length * daysInYear;
    final avgCompletionRate =
        possibleCompletions > 0 ? totalCompletions / possibleCompletions : 0.0;

    debugPrint(
        '✅ Year in Review generated: $totalCompletions completions, $longestStreak longest streak');

    return YearInReview(
      year: year,
      totalCompletions: totalCompletions,
      longestStreak: longestStreak,
      mostConsistentHabit: mostConsistentHabit,
      mostConsistentEmoji: mostConsistentEmoji,
      totalXP: totalXP,
      bestMonth: bestMonth,
      avgCompletionRate: avgCompletionRate,
      habitBreakdown: habitBreakdown,
      totalDaysActive: activeDays.length,
      perfectDays: perfectDays,
    );
  }

  /// Calculate the longest streak within a specific year
  int _calculateYearStreak(List<String> completionDates, int year) {
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31);

    // Parse and filter dates for the year
    final dates = completionDates
        .map((dateStr) {
          try {
            return DateTime.parse(dateStr);
          } catch (e) {
            return null;
          }
        })
        .where((date) =>
            date != null &&
            date.isAfter(yearStart.subtract(const Duration(days: 1))) &&
            date.isBefore(yearEnd.add(const Duration(days: 1))))
        .map((date) => date!)
        .toList()
      ..sort();

    if (dates.isEmpty) return 0;

    int currentStreak = 1;
    int maxStreak = 1;

    for (int i = 1; i < dates.length; i++) {
      final daysDiff = dates[i].difference(dates[i - 1]).inDays;

      if (daysDiff == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  /// Get month name from number
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  /// Check if it's time to show Year in Review (early January)
  bool shouldShowYearInReview() {
    final now = DateTime.now();
    // Show in first 2 weeks of January for previous year
    return now.month == 1 && now.day <= 14;
  }

  /// Get the year to review
  int getReviewYear() {
    final now = DateTime.now();
    // If in January, review previous year
    if (now.month == 1) {
      return now.year - 1;
    }
    return now.year;
  }
}
