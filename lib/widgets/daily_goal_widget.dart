import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/habit.dart';

/// Daily goal widget showing habit checklist (Duolingo-inspired)
class DailyGoalWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const DailyGoalWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final habits = appState.habits;
    final completed = appState.completedTodayCount;
    final total = habits.length;
    final xpEarned = habits
        .where((h) => h.completedToday)
        .fold<int>(0, (sum, h) => sum + h.actualXP);
    final xpRemaining = habits
        .where((h) => !h.completedToday)
        .fold<int>(0, (sum, h) => sum + h.actualXP);

    if (habits.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Goal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (completed == total)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF58CC02),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Complete!',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Habit checkboxes row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                habits.length > 5 ? 5 : habits.length,
                (index) {
                  final habit = habits[index];
                  return _HabitCheckbox(
                    habit: habit,
                    size: habits.length > 4 ? 40 : 50,
                  );
                },
              ),
            ),

            if (habits.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${habits.length - 5} more',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Progress summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed/$total Complete',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    if (xpRemaining > 0) ...[
                      Text(
                        '$xpRemaining XP left',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFFA726),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        '🎉 ',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '+$xpEarned XP earned',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF58CC02),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual habit checkbox
class _HabitCheckbox extends StatelessWidget {
  final Habit habit;
  final double size;

  const _HabitCheckbox({
    required this.habit,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: habit.completedToday
            ? const Color(0xFF58CC02)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: habit.completedToday
              ? const Color(0xFF58CC02)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: habit.completedToday
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 28,
              )
            : Text(
                habit.emoji,
                style: TextStyle(fontSize: size * 0.5),
              ),
      ),
    );
  }
}
