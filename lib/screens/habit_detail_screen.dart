import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/habit.dart';
import '../state/app_state.dart';
import '../utils/slide_route.dart';
import '../services/health_checker_service.dart';
import 'journal_screen.dart';
import 'coach_screen.dart';
import 'focus_mode_screen.dart';

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
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),

            // Health Goal Progress (for health-tracked habits like sports)
            if (currentHabit.isHealthTracked &&
                currentHabit.healthMetric != null &&
                currentHabit.healthGoalValue != null)
              _HealthGoalProgressCard(
                habit: currentHabit,
                isDark: isDark,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.2, end: 0),
            if (currentHabit.isHealthTracked) const SizedBox(height: 16),

            // Total Completions Section with Calendar
            _CompletionsCard(
              totalCompletions: totalCompletions,
              firstDate: firstCompletionDate,
              daysSinceStart: daysSinceStart,
              completionDates: currentHabit.completionDates,
              isDark: isDark,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
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
                // Focus Mode button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FocusModeScreen(
                            habit: currentHabit,
                            durationMinutes: 25,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer_rounded, color: Colors.white),
                    tooltip: 'Focus Mode',
                  ),
                ),
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
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
                    label: const Text('Wind 🌬️'),
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

// Health Goal Progress Card with animated progress bar
class _HealthGoalProgressCard extends StatefulWidget {
  final Habit habit;
  final bool isDark;

  const _HealthGoalProgressCard({
    required this.habit,
    required this.isDark,
  });

  @override
  State<_HealthGoalProgressCard> createState() =>
      _HealthGoalProgressCardState();
}

class _HealthGoalProgressCardState extends State<_HealthGoalProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnimation;
  Map<String, dynamic>? _progressData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _loadProgress();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final data =
        await HealthCheckerService.instance.getHabitProgress(widget.habit);
    if (mounted) {
      setState(() {
        _progressData = data;
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  String _getMetricIcon() {
    switch (widget.habit.healthMetric?.name) {
      case 'steps':
        return '👟';
      case 'distance':
        return '🏃';
      case 'sleep':
        return '😴';
      case 'calories':
        return '🔥';
      case 'heartRate':
        return '❤️';
      default:
        return '🎯';
    }
  }

  String _getMetricName() {
    switch (widget.habit.healthMetric?.name) {
      case 'steps':
        return 'Steps';
      case 'distance':
        return 'Distance';
      case 'sleep':
        return 'Sleep';
      case 'calories':
        return 'Calories';
      case 'heartRate':
        return 'Heart Rate';
      default:
        return 'Progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final current = (_progressData?['current'] as num?)?.toDouble() ?? 0.0;
    final target = (_progressData?['target'] as num?)?.toDouble() ?? 1.0;
    final percentage =
        (_progressData?['percentage'] as num?)?.toDouble() ?? 0.0;
    final unit = _progressData?['unit'] as String? ?? '';
    final isComplete = percentage >= 100;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.isDark ? Colors.grey[900]! : Colors.grey[100]!,
            widget.isDark
                ? const Color(0xFF58CC02).withValues(alpha: 0.1)
                : const Color(0xFF58CC02).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete
              ? const Color(0xFF58CC02)
              : (widget.isDark ? Colors.grey[800]! : Colors.grey[300]!),
          width: isComplete ? 2 : 1,
        ),
        boxShadow: isComplete
            ? [
                BoxShadow(
                  color: const Color(0xFF58CC02).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                _getMetricIcon(),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                '${_getMetricName()} Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              if (isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF58CC02),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Complete!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Section
          Row(
            children: [
              // Circular Progress
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background circle
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          backgroundColor: Colors.transparent,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        // Progress circle
                        CircularProgressIndicator(
                          value: (percentage / 100 * _progressAnimation.value)
                              .clamp(0.0, 1.0),
                          strokeWidth: 12,
                          backgroundColor: Colors.transparent,
                          color: isComplete
                              ? const Color(0xFF58CC02)
                              : theme.colorScheme.primary,
                          strokeCap: StrokeCap.round,
                        ),
                        // Percentage text
                        Center(
                          child: Text(
                            '${(percentage * _progressAnimation.value).toInt()}%',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isComplete
                                  ? const Color(0xFF58CC02)
                                  : (widget.isDark
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),

              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current value
                    Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${current.toStringAsFixed(current == current.toInt() ? 0 : 1)} $unit',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Target value
                    Text(
                      'Target',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${target.toStringAsFixed(target == target.toInt() ? 0 : 1)} $unit',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF58CC02),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: (percentage / 100 * _progressAnimation.value)
                      .clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: isComplete
                      ? const Color(0xFF58CC02)
                      : theme.colorScheme.primary,
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Remaining text
          Text(
            isComplete
                ? '🎉 Goal achieved! Great job!'
                : '${(target - current).toStringAsFixed(current == current.toInt() ? 0 : 1)} $unit to go',
            style: TextStyle(
              fontSize: 13,
              color: isComplete
                  ? const Color(0xFF58CC02)
                  : (widget.isDark ? Colors.grey[400] : Colors.grey[600]),
              fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
