import 'dart:async';
import '../services/health_service.dart';
import '../state/app_state.dart';
import '../models/habit.dart';

/// Service to automatically check and complete health-tracked habits
class HealthCheckerService {
  HealthCheckerService._();
  static final HealthCheckerService instance = HealthCheckerService._();

  Timer? _periodicTimer;
  final HealthService _healthService = HealthService.instance;

  /// Start periodic health data checking (every 15 minutes)
  void startPeriodicCheck(AppState appState) {
    // Stop any existing timer
    stopPeriodicCheck();

    // Check immediately
    checkAndCompleteHabits(appState);

    // Then check every 15 minutes
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => checkAndCompleteHabits(appState),
    );
  }

  /// Stop periodic checking
  void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Check all health-tracked habits and auto-complete if goal is met
  Future<void> checkAndCompleteHabits(AppState appState) async {
    print('🏥 Checking health-tracked habits...');

    for (final habit in appState.habits) {
      // Skip if not health tracked or already completed today
      if (!habit.isHealthTracked || habit.completedToday) {
        continue;
      }

      // Skip if no health metric or goal defined
      if (habit.healthMetric == null || habit.healthGoalValue == null) {
        continue;
      }

      try {
        // Check if goal is met
        final isGoalMet = await _healthService.isGoalMet(
          habit.healthMetric!,
          habit.healthGoalValue!,
        );

        if (isGoalMet) {
          print(
            '✅ Health goal met for "${habit.name}": ${habit.healthGoalValue} ${_getMetricUnit(habit.healthMetric!)}',
          );

          // Auto-complete the habit
          appState.completeHabit(habit);

          // Note: The celebration will be triggered in completeHabit
        }
      } catch (e) {
        print('Error checking health goal for "${habit.name}": $e');
      }
    }
  }

  /// Get current progress for a health-tracked habit
  Future<Map<String, dynamic>> getHabitProgress(Habit habit) async {
    if (!habit.isHealthTracked ||
        habit.healthMetric == null ||
        habit.healthGoalValue == null) {
      return {
        'current': 0.0,
        'target': 0.0,
        'percentage': 0.0,
        'unit': '',
      };
    }

    final currentValue =
        await _healthService.getCurrentValue(habit.healthMetric!);
    final percentage =
        (currentValue / habit.healthGoalValue! * 100).clamp(0.0, 100.0);

    return {
      'current': currentValue,
      'target': habit.healthGoalValue!,
      'percentage': percentage,
      'unit': _getMetricUnit(habit.healthMetric!),
    };
  }

  String _getMetricUnit(HealthMetricType metric) {
    switch (metric) {
      case HealthMetricType.steps:
        return 'steps';
      case HealthMetricType.sleep:
        return 'hours';
      case HealthMetricType.distance:
        return 'km';
      case HealthMetricType.calories:
        return 'cal';
      case HealthMetricType.heartRate:
        return 'bpm';
    }
  }

  /// Get display name for metric type
  static String getMetricDisplayName(HealthMetricType metric) {
    switch (metric) {
      case HealthMetricType.steps:
        return 'Steps';
      case HealthMetricType.sleep:
        return 'Sleep';
      case HealthMetricType.distance:
        return 'Distance';
      case HealthMetricType.calories:
        return 'Calories';
      case HealthMetricType.heartRate:
        return 'Heart Rate';
    }
  }
}
