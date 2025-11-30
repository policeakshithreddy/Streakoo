import 'package:uuid/uuid.dart';

import '../models/weekly_report.dart';
import '../models/habit.dart';
import '../config/app_config.dart';
import 'groq_ai_service.dart';

class WeeklyReportService {
  WeeklyReportService._();
  static final WeeklyReportService instance = WeeklyReportService._();

  final _uuid = const Uuid();

  /// Generate a weekly report for a specific week
  Future<WeeklyReport> generateWeeklyReport({
    required DateTime weekStart,
    required List<Habit> habits,
  }) async {
    // Ensure weekStart is a Monday
    final monday = _getMonday(weekStart);
    final sunday = monday.add(const Duration(days: 6));

    // Calculate statistics
    int totalCompletions = 0;
    int totalExpected = 0;
    final Map<String, int> dailyCompletions = {};
    final Map<String, int> habitSuccessCount = {};

    // Initialize daily completions
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dayName = _getDayName(day.weekday);
      dailyCompletions[dayName] = 0;
    }

    // Process each habit
    for (final habit in habits) {
      habitSuccessCount[habit.name] = 0;

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

    // Generate AI summary
    final aiSummary = await _generateAISummary(
      weekStart: monday,
      weekEnd: sunday,
      completionRate: completionRate,
      totalCompletions: totalCompletions,
      totalExpected: totalExpected,
      bestDay: bestDay,
      topHabits: topHabits,
      strugglingHabits: strugglingHabits,
    );

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
    );
  }

  /// Get current week's report
  Future<WeeklyReport> getCurrentWeekReport(List<Habit> habits) async {
    return await generateWeeklyReport(
      weekStart: DateTime.now(),
      habits: habits,
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
  }) async {
    if (!AppConfig.isApiConfigured || !AppConfig.useAIForCoaching) {
      return _getFallbackSummary(completionRate);
    }

    try {
      final prompt = '''
Generate a brief, motivational weekly summary for a habit tracking app.

Week: ${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}
Completion Rate: ${(completionRate * 100).round()}%
Completions: $totalCompletions out of $totalExpected
Best Day: ${bestDay ?? 'N/A'}
Top Habits: ${topHabits.join(', ')}
${strugglingHabits.isNotEmpty ? 'Needs Attention: ${strugglingHabits.join(', ')}' : ''}

Write a 2-3 sentence encouraging summary. Be specific, use the data, add emojis, and provide actionable insight.
''';

      final summary = await GroqAIService.instance.generateResponse(
        systemPrompt:
            'You are a motivational habit coach. Write brief, data-driven, encouraging summaries with emojis.',
        userPrompt: prompt,
        maxTokens: 100,
        temperature: 0.7,
      );

      return summary?.trim();
    } catch (e) {
      print('Error generating AI summary: $e');
      return _getFallbackSummary(completionRate);
    }
  }

  String _getFallbackSummary(double completionRate) {
    if (completionRate >= 0.9) {
      return '🌟 Outstanding week! You crushed your goals with ${(completionRate * 100).round()}% completion. Keep this momentum going!';
    } else if (completionRate >= 0.7) {
      return '💪 Solid week! ${(completionRate * 100).round()}% completion shows real commitment. A few small tweaks and you\'ll be unstoppable!';
    } else if (completionRate >= 0.5) {
      return '📈 Good progress with ${(completionRate * 100).round()}% completion. Focus on consistency and you\'ll see amazing results!';
    } else {
      return '🌱 Every journey has ups and downs. This week was a learning experience. Ready to bounce back stronger?';
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
