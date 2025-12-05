import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';

class DailyBriefCard extends StatelessWidget {
  const DailyBriefCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final now = DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get greeting based on time
    final greeting = _getGreeting(now.hour);
    final emoji = _getGreetingEmoji(now.hour);

    // Get today's habits
    final todayHabits = appState.habits.where((habit) {
      return habit.frequencyDays.contains(now.weekday);
    }).toList();

    // Get completion stats
    final completedToday = todayHabits.where((h) => h.completedToday).length;
    final totalToday = todayHabits.length;

    // Motivational quote
    final quote = _getMotivationalQuote(completedToday, totalToday);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
              : [const Color(0xFFFFFBF5), const Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d').format(now),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Today's Focus Section
          Text(
            "Today's Focus",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: totalToday > 0 ? completedToday / totalToday : 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA94A), Color(0xFFFFCB74)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Habit list
          if (todayHabits.isEmpty)
            Text(
              'No habits scheduled for today 🎉',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            )
          else
            ...todayHabits.take(3).map((habit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        habit.completedToday
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: habit.completedToday
                            ? const Color(0xFF27AE60)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.3)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black87,
                            decoration: habit.completedToday
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (habit.completedToday)
                        Text(
                          '${habit.emoji} ',
                          style: const TextStyle(fontSize: 16),
                        ),
                    ],
                  ),
                )),

          if (todayHabits.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${todayHabits.length - 3} more',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Motivational quote
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFFFA94A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFFFA94A).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '💬',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    quote,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else if (hour < 21) {
      return 'Good Evening!';
    } else {
      return 'Working Late?';
    }
  }

  String _getGreetingEmoji(int hour) {
    if (hour < 12) {
      return '☀️';
    } else if (hour < 17) {
      return '🌤️';
    } else if (hour < 21) {
      return '🌆';
    } else {
      return '🌙';
    }
  }

  String _getMotivationalQuote(int completed, int total) {
    if (total == 0) {
      return 'Enjoy your free day! Tomorrow is a fresh start. 🌟';
    }

    if (completed == total) {
      return 'All done for today! You\'re unstoppable! 🎉';
    } else if (completed > total / 2) {
      return 'You\'re on fire! Keep the momentum going! 🔥';
    } else if (completed > 0) {
      return 'Great start! Small steps lead to big changes. 💪';
    } else {
      return 'Ready to start strong? Your future self will thank you! ✨';
    }
  }
}
