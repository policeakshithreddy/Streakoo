// ignore_for_file: deprecated_member_use, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streakoo/providers/habit_provider.dart';
import 'package:streakoo/providers/app_provider.dart';
import 'package:streakoo/utils/constants.dart';
import 'package:table_calendar/table_calendar.dart';

class ProgressDashboardTab extends StatelessWidget {
  const ProgressDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final events = habitProvider.completedHabitsByDay;
    final currentStreak = habitProvider.getOverallCurrentStreak();
    final bestStreak = habitProvider.getOverallBestStreak();

    final appProvider = context.watch<AppProvider>();
    final challengeLength = appProvider.challengeLength;
    final currentStreakDouble = currentStreak.toDouble();
    final progressPct = (challengeLength > 0)
        ? (currentStreakDouble / challengeLength).clamp(0.0, 1.0)
        : 0.0;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(title: const Text('Visualize Streaks')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top Streak Cards ---
            Row(
              children: [
                _buildStatCard(
                  context,
                  'Current Streak',
                  '$currentStreak days',
                  Icons.local_fire_department_rounded,
                  AppColors.accent,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  'Best Streak',
                  '$bestStreak days',
                  Icons.star_rounded,
                  AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Challenge Card with Donut Chart ---
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challengeLength > 0
                                ? '$challengeLength-Day Challenge'
                                : 'No Active Challenge',
                            style:
                                textTheme.titleMedium?.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            challengeLength > 0
                                ? 'Progress'
                                : 'Set a challenge to start',
                            style:
                                textTheme.headlineSmall?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            challengeLength > 0
                                ? 'Complete the challenge by hitting your daily habits each day.'
                                : 'No challenge selected',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(140, 140),
                            painter: DonutPainter(progressPct, AppColors.accent,
                                colorScheme.onSurface.withOpacity(0.12)),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(progressPct * 100).toStringAsFixed(0)}%',
                                style: textTheme.headlineSmall?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$currentStreak/$challengeLength',
                                style: textTheme.bodySmall?.copyWith(
                                    fontSize: 12, color: colorScheme.onSurface),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Secondary Stats ---
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.pie_chart_outline),
                      title: const Text('Overall Completion Rate'),
                      trailing: Text(_computeCompletionRate(habitProvider)),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.flag),
                      title: const Text('Active Challenge Length'),
                      trailing: Text(
                          challengeLength > 0 ? '$challengeLength days' : '—'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Calendar Heatmap ---
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: DateTime.now(),
                  calendarFormat: CalendarFormat.month,
                  eventLoader: (day) {
                    final normalizedDay = DateTime(
                      day.year,
                      day.month,
                      day.day,
                    );
                    return events[normalizedDay] ?? [];
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {
                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle:
                        textTheme.titleLarge ?? const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 22)),
            ],
          ),
        ),
      ),
    );
  }

  String _computeCompletionRate(HabitProvider habitProvider) {
    // Compute using public ValueListenable<Box<Habit>>
    try {
      final values = habitProvider.habitBoxNotifier.value.values.toList();
      if (values.isEmpty) return '0%';
      int totalCompleted = 0;
      DateTime? earliest;
      for (var h in values) {
        if (h.completedDays.isNotEmpty) {
          totalCompleted += h.completedDays.length;
          final first = h.completedDays.first;
          if (earliest == null || first.isBefore(earliest)) earliest = first;
        }
      }
      if (earliest == null) return '0%';
      final daysSpan = DateTime.now().difference(earliest).inDays + 1;
      final totalPossible = daysSpan * values.length;
      if (totalPossible == 0) return '0%';
      final pct = (totalCompleted / totalPossible) * 100;
      return '${pct.toStringAsFixed(0)}%';
    } catch (_) {
      return '0%';
    }
  }
}

class DonutPainter extends CustomPainter {
  final double pct;
  final Color color;
  final Color bgColor;
  DonutPainter(this.pct, this.color, this.bgColor);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    final sweep = 2 * 3.1415926535 * pct;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -3.1415926535 / 2, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) =>
      old.pct != pct || old.color != color;
}
