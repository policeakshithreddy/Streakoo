import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/weekly_report.dart';
import '../models/habit.dart';
import '../config/app_config.dart';
import 'groq_ai_service.dart';
import 'health_service.dart';

class WeeklyReportService {
  WeeklyReportService._();
  static final WeeklyReportService instance = WeeklyReportService._();

  final _uuid = const Uuid();

  // Cache for previous week's rate
  double? _previousWeekRate;

  /// Generate a weekly report for a specific week
  Future<WeeklyReport> generateWeeklyReport({
    required DateTime weekStart,
    required List<Habit> habits,
    int? xpEarned,
    int? levelsGained,
  }) async {
    // Ensure weekStart is a Monday
    final monday = _getMonday(weekStart);
    final sunday = monday.add(const Duration(days: 6));

    // Calculate statistics
    int totalCompletions = 0;
    int totalExpected = 0;
    final Map<String, int> dailyCompletions = {};
    final Map<String, int> habitSuccessCount = {};
    int longestStreak = 0;
    int? newPersonalBest;
    final List<StreakAchievement> achievements = [];

    // Initialize daily completions
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dayName = _getDayName(day.weekday);
      dailyCompletions[dayName] = 0;
    }

    // Process each habit
    for (final habit in habits) {
      habitSuccessCount[habit.name] = 0;

      // Track longest streak
      if (habit.streak > longestStreak) {
        longestStreak = habit.streak;
      }

      // Check for streak milestones achieved this week
      _checkStreakMilestones(habit, achievements);

      // Check each day of the week
      for (int i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        final dayName = _getDayName(day.weekday);

        // Check if habit is scheduled for this day
        if (habit.frequencyDays.contains(day.weekday)) {
          totalExpected++;

          // Check if habit was completed on this day
          final dayKey = _formatDateKey(day);
          if (habit.completionDates.contains(dayKey)) {
            totalCompletions++;
            dailyCompletions[dayName] = (dailyCompletions[dayName] ?? 0) + 1;
            habitSuccessCount[habit.name] =
                (habitSuccessCount[habit.name] ?? 0) + 1;
          }
        }
      }
    }

    // Calculate completion rate
    final completionRate =
        totalExpected > 0 ? totalCompletions / totalExpected : 0.0;

    // Check for perfect week
    if (completionRate >= 0.99) {
      achievements.add(StreakAchievement.perfectWeek);
    }

    // Find best and worst days
    String? bestDay;
    String? worstDay;
    int maxCompletions = -1;
    int minCompletions = 999;

    dailyCompletions.forEach((day, count) {
      if (count > maxCompletions) {
        maxCompletions = count;
        bestDay = day;
      }
      if (count < minCompletions) {
        minCompletions = count;
        worstDay = day;
      }
    });

    // Identify top habits (most consistent)
    final sortedHabits = habitSuccessCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topHabits = sortedHabits
        .take(3)
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    // Identify struggling habits (least consistent)
    final strugglingHabits = sortedHabits.reversed
        .take(2)
        .where((e) => e.value < 3) // Less than 3 completions
        .map((e) => e.key)
        .toList();

    // Get health stats for the week
    final healthStats = await _getWeeklyHealthStats(monday, sunday);

    // Generate AI summary with enhanced data
    final aiSummary = await _generateAISummary(
      weekStart: monday,
      weekEnd: sunday,
      completionRate: completionRate,
      totalCompletions: totalCompletions,
      totalExpected: totalExpected,
      bestDay: bestDay,
      topHabits: topHabits,
      strugglingHabits: strugglingHabits,
      healthStats: healthStats,
      previousWeekRate: _previousWeekRate,
    );

    // Store current rate for next week's comparison
    final previousRate = _previousWeekRate;
    _previousWeekRate = completionRate;

    return WeeklyReport(
      id: _uuid.v4(),
      weekStart: monday,
      weekEnd: sunday,
      totalCompletions: totalCompletions,
      totalExpected: totalExpected,
      completionRate: completionRate,
      bestDay: bestDay,
      worstDay: worstDay,
      topHabits: topHabits,
      strugglingHabits: strugglingHabits,
      aiSummary: aiSummary,
      dailyCompletions: dailyCompletions,
      healthStats: healthStats,
      previousWeekRate: previousRate,
      xpEarned: xpEarned ?? 0,
      levelsGained: levelsGained ?? 0,
      achievements: achievements,
      longestStreakThisWeek: longestStreak,
      newPersonalBest: newPersonalBest,
    );
  }

  /// Check for streak milestones
  void _checkStreakMilestones(
      Habit habit, List<StreakAchievement> achievements) {
    final streak = habit.streak;

    if (streak >= 100 &&
        !achievements.contains(StreakAchievement.milestone100)) {
      achievements.add(StreakAchievement.milestone100);
    } else if (streak >= 30 &&
        !achievements.contains(StreakAchievement.milestone30)) {
      achievements.add(StreakAchievement.milestone30);
    } else if (streak >= 14 &&
        !achievements.contains(StreakAchievement.milestone14)) {
      achievements.add(StreakAchievement.milestone14);
    } else if (streak >= 7 &&
        !achievements.contains(StreakAchievement.milestone7)) {
      achievements.add(StreakAchievement.milestone7);
    }
  }

  /// Get health stats for the week
  Future<WeeklyHealthStats?> _getWeeklyHealthStats(
      DateTime monday, DateTime sunday) async {
    try {
      final healthService = HealthService.instance;

      // Aggregate health data for the week
      int totalSteps = 0;
      double totalSleep = 0;
      int totalHeartRate = 0;
      int stepDays = 0;
      int sleepDays = 0;
      int heartDays = 0;

      // Get data for each day of the week
      for (int i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        if (day.isAfter(DateTime.now())) continue;

        final steps = await healthService.getStepCount(day);
        final sleep = await healthService.getSleepHours(day);
        // Heart rate only for today
        final heart = day.day == DateTime.now().day
            ? await healthService.getTodayHeartRate()
            : null;

        if (steps > 0) {
          totalSteps += steps;
          stepDays++;
        }
        if (sleep > 0) {
          totalSleep += sleep;
          sleepDays++;
        }
        if (heart != null && heart > 0) {
          totalHeartRate += heart;
          heartDays++;
        }
      }

      return WeeklyHealthStats(
        averageSteps: stepDays > 0 ? (totalSteps / stepDays).round() : null,
        averageSleep: sleepDays > 0 ? totalSleep / sleepDays : null,
        averageHeartRate:
            heartDays > 0 ? (totalHeartRate / heartDays).round() : null,
      );
    } catch (e) {
      debugPrint('Error getting weekly health stats: $e');
      return null;
    }
  }

  /// Get current week's report
  Future<WeeklyReport> getCurrentWeekReport(
    List<Habit> habits, {
    int? xpEarned,
    int? levelsGained,
  }) async {
    return await generateWeeklyReport(
      weekStart: DateTime.now(),
      habits: habits,
      xpEarned: xpEarned,
      levelsGained: levelsGained,
    );
  }

  /// Generate AI summary for the week
  Future<String?> _generateAISummary({
    required DateTime weekStart,
    required DateTime weekEnd,
    required double completionRate,
    required int totalCompletions,
    required int totalExpected,
    String? bestDay,
    required List<String> topHabits,
    required List<String> strugglingHabits,
    WeeklyHealthStats? healthStats,
    double? previousWeekRate,
  }) async {
    if (!AppConfig.isApiConfigured || !AppConfig.useAIForCoaching) {
      return _getFallbackSummary(completionRate, previousWeekRate);
    }

    try {
      // Build health context
      String healthContext = '';
      if (healthStats != null) {
        if (healthStats.averageSteps != null) {
          healthContext += 'Average Steps: ${healthStats.averageSteps}\n';
        }
        if (healthStats.averageSleep != null) {
          healthContext +=
              'Average Sleep: ${healthStats.averageSleep!.toStringAsFixed(1)} hours\n';
        }
      }

      // Build comparison context
      String comparisonContext = '';
      if (previousWeekRate != null) {
        final change = ((completionRate - previousWeekRate) * 100).round();
        if (change > 0) {
          comparisonContext = 'Improved $change% from last week! ';
        } else if (change < 0) {
          comparisonContext = 'Down ${change.abs()}% from last week. ';
        }
      }

      final prompt = '''
Generate a brief, motivational weekly summary for a habit tracking app.

Week: ${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}
Completion Rate: ${(completionRate * 100).round()}%
$comparisonContext
Completions: $totalCompletions out of $totalExpected
Best Day: ${bestDay ?? 'N/A'}
Top Habits: ${topHabits.join(', ')}
${strugglingHabits.isNotEmpty ? 'Needs Attention: ${strugglingHabits.join(', ')}' : ''}
$healthContext

Write a 2-3 sentence encouraging summary. Be specific, use the data, add emojis, and provide actionable insight. Mention health data if available.
''';

      final summary = await GroqAIService.instance.generateResponse(
        systemPrompt:
            'You are Koo, a warm and motivational habit coach. Write brief, data-driven, encouraging summaries with emojis.',
        userPrompt: prompt,
        maxTokens: 120,
        temperature: 0.7,
      );

      return summary?.trim();
    } catch (e) {
      debugPrint('Error generating AI summary: $e');
      return _getFallbackSummary(completionRate, previousWeekRate);
    }
  }

  String _getFallbackSummary(double completionRate, double? previousRate) {
    String comparison = '';
    if (previousRate != null) {
      final change = ((completionRate - previousRate) * 100).round();
      if (change > 0) {
        comparison = ' You improved $change% from last week! ';
      } else if (change < 0) {
        comparison = ' ';
      }
    }

    if (completionRate >= 0.9) {
      return '🌟 Outstanding week! You crushed your goals with ${(completionRate * 100).round()}% completion.$comparison Keep this momentum going!';
    } else if (completionRate >= 0.7) {
      return '💪 Solid week! ${(completionRate * 100).round()}% completion shows real commitment.$comparison A few small tweaks and you\'ll be unstoppable!';
    } else if (completionRate >= 0.5) {
      return '📈 Good progress with ${(completionRate * 100).round()}% completion.$comparison Focus on consistency and you\'ll see amazing results!';
    } else {
      return '🌱 Every journey has ups and downs.$comparison This week was a learning experience. Ready to bounce back stronger?';
    }
  }

  DateTime _getMonday(DateTime date) {
    // Get the Monday of the week containing this date
    final daysFromMonday = (date.weekday - DateTime.monday) % 7;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));
  }

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

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
