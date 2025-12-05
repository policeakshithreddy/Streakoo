import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/circular_progress_ring.dart';
import '../widgets/streak_flame_widget.dart';

/// Main Duolingo-style progress widget showing daily completion
class DuolingoProgressWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const DuolingoProgressWidget({
    super.key,
    this.onTap,
  });

  String _getMotivationalMessage(int completed, int total) {
    if (completed == 0) {
      return 'Time to start your day! 💪';
    } else if (completed == total) {
      return 'All done! 🎉';
    } else if (completed >= total * 0.8) {
      return 'Almost there! ${total - completed} more to go!';
    } else if (completed >= total / 2) {
      return 'Halfway there! Keep it up! 🔥';
    } else {
      return 'Great start! Keep going! 🌟';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final completed = appState.completedTodayCount;
    final total = appState.totalHabits;
    final longestStreak = appState.habits.isEmpty
        ? 0
        : appState.habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

    final message = _getMotivationalMessage(completed, total);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: completed == total && total > 0
                ? const Color(0xFF58CC02).withValues(alpha: 0.3)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header with streak
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (longestStreak > 0)
                  CompactStreakFlame(
                    streakDays: longestStreak,
                    size: 20,
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress ring
            CircularProgressRing(
              completed: completed,
              total: total > 0 ? total : 1,
              size: 140,
              strokeWidth: 14,
              progressColor: const Color(0xFF58CC02),
              centerChild: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$completed',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: completed == total && total > 0
                          ? const Color(0xFF58CC02)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '/ $total',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Motivational message
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: completed == total && total > 0
                    ? const Color(0xFF58CC02).withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: completed == total && total > 0
                      ? const Color(0xFF58CC02)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // Tap hint
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Tap to view habits',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
