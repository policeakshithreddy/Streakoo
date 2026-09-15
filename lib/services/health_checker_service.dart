import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/health_service.dart';
import '../state/app_state.dart';
import '../models/habit.dart';
import '../services/smart_notification_service.dart';

/// Service to automatically check and complete health-tracked habits
class HealthCheckerService {
  HealthCheckerService._();
  static final HealthCheckerService instance = HealthCheckerService._();

  final HealthService _healthService = HealthService.instance;

  /// Check for health data updates immediately
  /// Call this when app starts or resumes
  Future<void> checkHealthHabits(AppState appState) async {
    await checkAndCompleteHabits(appState);
  }

  /// Check all health-tracked habits and auto-complete if goal is met
  Future<void> checkAndCompleteHabits(AppState appState) async {
    try {
      debugPrint('🏥 Checking health-tracked habits...');

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
          final currentValue =
              await _healthService.getCurrentValue(habit.healthMetric!);
          final targetValue = habit.healthGoalValue!;
          final isGoalMet = currentValue >= targetValue;

          debugPrint(
            '❤️ Health Check: "${habit.name}" | Met: ${_getMetricUnit(habit.healthMetric!)} | '
            'Current: ${currentValue.toStringAsFixed(1)} / Target: ${targetValue.toStringAsFixed(1)} | '
            'Goal Met: $isGoalMet',
          );

          if (isGoalMet) {
            debugPrint(
              '✅ Health goal met for "${habit.name}": $targetValue ${_getMetricUnit(habit.healthMetric!)}',
            );

            // Trigger notification BEFORE completing (so we have the habit data)
            await SmartNotificationService.instance
                .sendHealthGoalMetNotification(habit);

            // Auto-complete the habit
            await appState.completeHabit(habit, isAiTriggered: true);

            // Note: The celebration will be triggered in completeHabit
          }
        } catch (e) {
          debugPrint('Error checking health goal for "${habit.name}": $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Health checker failed: $e');
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
    }
  }
}
