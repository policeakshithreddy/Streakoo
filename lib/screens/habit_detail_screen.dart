import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/habit.dart';
import '../state/app_state.dart';
import '../utils/slide_route.dart';
import 'journal_screen.dart';
import 'coach_screen.dart';

class HabitDetailScreen extends StatelessWidget {
  final Habit habit;

  const HabitDetailScreen({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentHabit = appState.habits
        .firstWhere((h) => h.id == habit.id, orElse: () => habit);

    // Calculate statistics
    final bestStreak = _calculateBestStreak(currentHabit.completionDates);
    final totalCompletions = currentHabit.completionDates.length;

    // Get the first completion date (earliest date) - need to sort to find it
    DateTime firstCompletionDate;
    if (currentHabit.completionDates.isNotEmpty) {
      final sortedDates = currentHabit.completionDates
          .map((d) => DateTime.parse(d))
          .toList()
        ..sort((a, b) => a.compareTo(b));
      firstCompletionDate = sortedDates.first;
    } else {
      firstCompletionDate = DateTime.now();
    }

    final daysSinceStart =
        DateTime.now().difference(firstCompletionDate).inDays + 1;
    final completionRate = daysSinceStart > 0 && totalCompletions > 0
        ? ((totalCompletions / daysSinceStart) * 100).round()
        : 0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(currentHabit.name),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streaks Section
            _StreaksCard(
              currentStreak: currentHabit.streak,
              bestStreak: bestStreak,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Total Completions Section with Calendar
            _CompletionsCard(
              totalCompletions: totalCompletions,
              firstDate: firstCompletionDate,
              daysSinceStart: daysSinceStart,
              completionDates: currentHabit.completionDates,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Completion Rate
            _InfoCard(
              title: 'Completion Rate',
              value: '$completionRate%',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Frequency
            _InfoCard(
              title: 'Frequency',
              value: _getFrequencyText(currentHabit.frequencyDays),
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Reminder
            if (currentHabit.reminderEnabled &&
                currentHabit.reminderTime != null)
              _InfoCard(
                title: 'Reminder',
                value: _formatReminderTime(currentHabit.reminderTime!),
                isDark: isDark,
              ),
            if (currentHabit.reminderEnabled &&
                currentHabit.reminderTime != null)
              const SizedBox(height: 16),

            // Habit Created On
            _InfoCard(
              title: 'Habit created on',
              value: DateFormat('MMMM d, yyyy').format(firstCompletionDate),
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        slideFromRight(JournalScreen(habit: currentHabit)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Journal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        slideFromRight(CoachScreen(habit: currentHabit)),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('AI Coach'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateBestStreak(List<String> completionDates) {
    if (completionDates.isEmpty) return 0;

    // Sort dates
    final sortedDates = completionDates.map((d) => DateTime.parse(d)).toList()
      ..sort((a, b) => a.compareTo(b));

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prev = DateTime(sortedDates[i - 1].year, sortedDates[i - 1].month,
          sortedDates[i - 1].day);
      final curr = DateTime(
          sortedDates[i].year, sortedDates[i].month, sortedDates[i].day);

      if (curr.difference(prev).inDays == 1) {
        currentStreak++;
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      } else if (curr.difference(prev).inDays > 1) {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  String _getFrequencyText(List<int> frequencyDays) {
    if (frequencyDays.length == 7) {
      return 'Daily';
    } else if (frequencyDays.length == 5 &&
        !frequencyDays.contains(6) &&
        !frequencyDays.contains(7)) {
      return 'Weekdays';
    } else if (frequencyDays.length == 2 &&
        frequencyDays.contains(6) &&
        frequencyDays.contains(7)) {
      return 'Weekends';
    } else {
      return '${frequencyDays.length} days/week';
    }
  }

  String _formatReminderTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

// Streaks Card Widget
class _StreaksCard extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final bool isDark;

  const _StreaksCard({
    required this.currentStreak,
    required this.bestStreak,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StreakItem(
              label: 'Current Streak',
              value: currentStreak,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          Expanded(
            child: _StreakItem(
              label: 'Best Streak',
              value: bestStreak,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakItem extends StatelessWidget {
  final String label;
  final int value;
  final bool isDark;

  const _StreakItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              const Text('🔥', style: TextStyle(fontSize: 32)),
            ],
          ),
        ],
      ),
    );
  }
}

// Completions Card with Calendar
class _CompletionsCard extends StatelessWidget {
  final int totalCompletions;
  final DateTime firstDate;
  final int daysSinceStart;
  final List<String> completionDates;
  final bool isDark;

  const _CompletionsCard({
    required this.totalCompletions,
    required this.firstDate,
    required this.daysSinceStart,
    required this.completionDates,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Completions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Since ${DateFormat('MMMM d, yyyy').format(firstDate)} ($daysSinceStart days)',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            totalCompletions.toString(),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _CompletionCalendar(
            completionDates: completionDates,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// GitHub-style completion calendar
class _CompletionCalendar extends StatelessWidget {
  final List<String> completionDates;
  final bool isDark;

  const _CompletionCalendar({
    required this.completionDates,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 4, 1); // Last ~4 months

    // Convert completion dates to Set for O(1) lookup
    final completedDays = completionDates.map((d) {
      final date = DateTime.parse(d);
      return DateTime(date.year, date.month, date.day).toString();
    }).toSet();

    // Build calendar grid
    final weeks = <List<DateTime>>[];
    var currentWeek = <DateTime>[];

    // Start from the first day we want to show
    var date = startDate;

    // Find the Monday before start date
    while (date.weekday != DateTime.monday) {
      date = date.subtract(const Duration(days: 1));
    }

    while (date.isBefore(now) || date.isAtSameMomentAs(now)) {
      currentWeek.add(date);
      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
      date = date.add(const Duration(days: 1));
    }

    if (currentWeek.isNotEmpty) {
      // Fill remaining days
      while (currentWeek.length < 7) {
        currentWeek.add(date);
        date = date.add(const Duration(days: 1));
      }
      weeks.add(currentWeek);
    }

    // Month labels
    final months = <String>[];
    var lastMonth = -1;
    for (var week in weeks) {
      final month = week[0].month;
      if (month != lastMonth) {
        months.add(DateFormat('MMM').format(week[0]));
        lastMonth = month;
      } else {
        months.add('');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels
        Row(
          children: [
            const SizedBox(width: 24), // Space for day labels
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: months
                    .map((m) => Text(
                          m,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((day) => Container(
                        height: 14,
                        width: 16,
                        alignment: Alignment.centerRight,
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(width: 8),
            // Calendar grid
            Expanded(
              child: SizedBox(
                height: 7 * 14.0, // 7 rows * height
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: weeks.length,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    childAspectRatio: 1,
                  ),
                  itemCount: weeks.length * 7,
                  itemBuilder: (context, index) {
                    final weekIndex = index ~/ 7;
                    final dayIndex = index % 7;
                    final day = weeks[weekIndex][dayIndex];
                    final dayKey =
                        DateTime(day.year, day.month, day.day).toString();
                    final isCompleted = completedDays.contains(dayKey);
                    final isFuture = day.isAfter(now);

                    return Container(
                      decoration: BoxDecoration(
                        color: isFuture
                            ? (isDark ? Colors.grey[850] : Colors.grey[200])
                            : isCompleted
                                ? const Color(0xFFFFA94A)
                                : (isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[300]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Info Card Widget
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
