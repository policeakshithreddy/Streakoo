import '../models/habit.dart';

/// Result of a sync operation with conflict detection
class SyncConflictResult {
  final bool hasStreakConflicts;
  final List<Habit> cloudHabits;
  final List<Habit> localHabits;
  final List<HabitStreakDiff> differences;

  const SyncConflictResult({
    required this.hasStreakConflicts,
    required this.cloudHabits,
    required this.localHabits,
    required this.differences,
  });

  /// Factory for no conflicts
  factory SyncConflictResult.noConflicts() {
    return const SyncConflictResult(
      hasStreakConflicts: false,
      cloudHabits: [],
      localHabits: [],
      differences: [],
    );
  }
}

/// Represents a single habit's streak difference between cloud and local
class HabitStreakDiff {
  final String habitId;
  final String habitName;
  final String emoji;
  final int cloudStreak;
  final int localStreak;

  const HabitStreakDiff({
    required this.habitId,
    required this.habitName,
    required this.emoji,
    required this.cloudStreak,
    required this.localStreak,
  });

  /// Check if there's an actual difference
  bool get hasDifference => cloudStreak != localStreak;

  /// Calculate which streak is higher
  bool get cloudIsHigher => cloudStreak > localStreak;
}
