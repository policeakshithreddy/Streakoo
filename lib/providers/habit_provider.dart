import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:streakoo/models/habit.dart';
import 'package:streakoo/utils/constants.dart';

class HabitProvider extends ChangeNotifier {
  final Box<Habit> _habitBox = Hive.box<Habit>(kHabitBoxName);
  Timer? _midnightTimer;

  // Use ValueListenableBuilder in the UI for reactive updates
  ValueListenable<Box<Habit>> get habitBoxNotifier => _habitBox.listenable();

  HabitProvider() {
    // Schedule a midnight refresh so the UI updates when the day rolls
    // over while the app is running.
    _scheduleNextReset();
  }

  void _scheduleNextReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final untilMidnight = tomorrow.difference(now);
    _midnightTimer = Timer(untilMidnight, () {
      // At the moment of midnight, compute whether a streak reset occurred
      // (i.e., yesterday had a streak but today is not fully completed).
      try {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final priorStreak = getOverallCurrentStreakForDate(yesterday);
        final today = DateTime.now();
        final allDoneToday = areAllHabitsCompleted(today);
        if (priorStreak > 0 && !allDoneToday) {
          // Record the reset event for stats
          recordStreakReset(priorStreak);
        }
      } catch (_) {
        // ignore any issues during midnight processing
      }

      // Notify listeners so widgets that derive "is completed today" can
      // rebuild and show the new day's state.
      notifyListeners();
      // Schedule the next reset
      _scheduleNextReset();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  // --- CRUD Operations ---

  Future<void> addHabit(Habit habit) async {
    await _habitBox.add(habit);
    // No need to call notifyListeners() if UI uses ValueListenableBuilder
  }

  Future<void> deleteHabit(dynamic key) async {
    await _habitBox.delete(key);
  }

  Future<void> toggleHabitCompletion(dynamic key, DateTime date) async {
    final habit = _habitBox.get(key);
    if (habit == null) return;

    final today = DateTime(date.year, date.month, date.day);

    if (habit.completedDays.contains(today)) {
      habit.completedDays.remove(today);
    } else {
      habit.completedDays.add(today);
    }
    await habit.save();
    // Notify listeners in case some widgets rely on provider notifications
    notifyListeners();
  }

  bool isCompletedToday(dynamic key) {
    final habit = _habitBox.get(key);
    if (habit == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return habit.completedDays.contains(today);
  }

  Future<void> markCompletedToday(dynamic key) async {
    final habit = _habitBox.get(key);
    if (habit == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!habit.completedDays.contains(today)) {
      habit.completedDays.add(today);
      await habit.save();
      notifyListeners();
    }
  }

  Future<void> unmarkCompletedToday(dynamic key) async {
    final habit = _habitBox.get(key);
    if (habit == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (habit.completedDays.contains(today)) {
      habit.completedDays.remove(today);
      await habit.save();
      notifyListeners();
    }
  }

  // --- Statistics ---

  bool areAllHabitsCompleted(DateTime date) {
    if (_habitBox.isEmpty) return false;
    final today = DateTime(date.year, date.month, date.day);

    for (var habit in _habitBox.values) {
      if (!habit.completedDays.contains(today)) {
        return false; // Found a habit not completed today
      }
    }
    return true; // All habits are completed
  }

  Map<DateTime, List<Habit>> get completedHabitsByDay {
    final Map<DateTime, List<Habit>> events = {};
    for (var habit in _habitBox.values) {
      for (var day in habit.completedDays) {
        final normalizedDay = DateTime(day.year, day.month, day.day);
        if (events[normalizedDay] == null) {
          events[normalizedDay] = [];
        }
        events[normalizedDay]!.add(habit);
      }
    }
    return events;
  }

  int getOverallCurrentStreak() {
    int currentStreak = 0;
    DateTime date = DateTime.now();
    DateTime today = DateTime(date.year, date.month, date.day);

    while (areAllHabitsCompleted(today)) {
      currentStreak++;
      today = today.subtract(const Duration(days: 1));
    }
    return currentStreak;
  }

  int getOverallBestStreak() {
    int bestStreak = 0;
    int currentStreak = 0;

    if (_habitBox.isEmpty) return 0;

    // Find the earliest date to start checking from
    DateTime earliestDate = DateTime.now();
    for (var habit in _habitBox.values) {
      if (habit.completedDays.isNotEmpty &&
          habit.completedDays.first.isBefore(earliestDate)) {
        earliestDate = habit.completedDays.first;
      }
    }

    DateTime checkDate =
        DateTime(earliestDate.year, earliestDate.month, earliestDate.day);
    final today = DateTime.now();

    while (checkDate.isBefore(today) || checkDate.isAtSameMomentAs(today)) {
      if (areAllHabitsCompleted(checkDate)) {
        currentStreak++;
      } else {
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
        currentStreak = 0; // Reset streak
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    // Final check in case the best streak is the current one
    return (currentStreak > bestStreak) ? currentStreak : bestStreak;
  }

  /// Compute the overall current streak as-of the provided [date]. This
  /// mirrors [getOverallCurrentStreak] but allows checking previous days
  /// (used during midnight processing to determine if a reset occurred).
  int getOverallCurrentStreakForDate(DateTime date) {
    int currentStreak = 0;
    DateTime today = DateTime(date.year, date.month, date.day);

    while (areAllHabitsCompleted(today)) {
      currentStreak++;
      today = today.subtract(const Duration(days: 1));
    }
    return currentStreak;
  }

  /// Record a streak-reset event in a lightweight Hive box so the app can
  /// show this in statistics. We use a dynamic box with simple maps to avoid
  /// adding additional TypeAdapters or migration steps.
  Future<void> recordStreakReset(int previousStreak) async {
    try {
      final box = await Hive.openBox('streak_events');
      final entry = {
        'timestamp': DateTime.now().toIso8601String(),
        'previousStreak': previousStreak,
      };
      await box.add(entry);
    } catch (_) {
      // ignore errors here — non-critical telemetry-like information
    }
  }

  // --- Onboarding Helpers ---
  void addDefaultHabits() {
    final defaultHabits = [
      Habit(name: 'Go to the gym', iconName: 'gym', completedDays: []),
      Habit(name: 'Read 15 mins', iconName: 'book', completedDays: []),
      Habit(
          name: 'Drink 8 glasses of water',
          iconName: 'water',
          completedDays: []),
      Habit(name: 'Meditate', iconName: 'meditate', completedDays: []),
    ];
    for (var habit in defaultHabits) {
      addHabit(habit);
    }
  }
}
