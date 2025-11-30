import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/health_checker_service.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    required this.habit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.completedToday;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          // Subtle amber border for focus tasks
          border: habit.isFocusTask
              ? Border.all(color: Colors.amber.withOpacity(0.4), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 10),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              habit.emoji,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                          ),
                        ),
                      ),
                      // Star badge for focus tasks
                      if (habit.isFocusTask)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 12),
                              SizedBox(width: 2),
                              Text(
                                'Focus',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (habit.isHealthTracked && !isCompleted)
                    FutureBuilder<Map<String, dynamic>>(
                      future:
                          HealthCheckerService.instance.getHabitProgress(habit),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text(
                            'Syncing...',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          );
                        }

                        final data = snapshot.data!;
                        final current = data['current'] as num;
                        final target = data['target'] as num;
                        final unit = data['unit'] as String;
                        final percentage = (data['percentage'] as double) / 100;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${current.toInt()} / ${target.toInt()} $unit',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                color: theme.colorScheme.primary,
                                minHeight: 4,
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    Text(
                      isCompleted ? 'Completed today 🎉' : 'Not done yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text(
                  '${habit.streak}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF1A1A1A)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
