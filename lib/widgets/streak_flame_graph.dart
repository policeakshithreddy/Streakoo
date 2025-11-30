import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/habit.dart';

class StreakFlameGraph extends StatelessWidget {
  final List<Habit> habits;

  const StreakFlameGraph({
    super.key,
    required this.habits,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Center(
        child: Text('No habits to display'),
      );
    }

    // Sort habits by streak (descending)
    final sortedHabits = List<Habit>.from(habits)
      ..sort((a, b) => b.streak.compareTo(a.streak));

    final maxStreak = sortedHabits.first.streak;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔥 Streak Flames',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...sortedHabits.take(5).map((habit) => _FlameBar(
                  habit: habit,
                  maxStreak: maxStreak > 0 ? maxStreak : 1,
                )),
          ],
        ),
      ),
    );
  }
}

class _FlameBar extends StatelessWidget {
  final Habit habit;
  final int maxStreak;

  const _FlameBar({
    required this.habit,
    required this.maxStreak,
  });

  Color _getFlameColor(int streak) {
    if (streak >= 30) return const Color(0xFFFF4500); // Intense red-orange
    if (streak >= 14) return const Color(0xFFFF6347); // Tomato
    if (streak >= 7) return const Color(0xFFFF8C00); // Dark orange
    if (streak > 0) return const Color(0xFFFFA500); // Orange
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final progress = habit.streak / maxStreak;
    final flameColor = _getFlameColor(habit.streak);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Habit name and streak count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${habit.emoji} ${habit.name}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${habit.streak} days',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: flameColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Flame bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Background
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                // Flame fill with gradient
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          flameColor.withValues(alpha: 0.7),
                          flameColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: flameColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (habit.streak > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '🔥',
                              style: TextStyle(
                                fontSize: habit.streak >= 7 ? 18 : 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                      .animate()
                      .scaleX(
                        begin: 0,
                        end: 1,
                        duration: 800.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .then()
                      .shimmer(
                        duration: 2000.ms,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
