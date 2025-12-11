import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.streakoo.app';
  static const String androidWidgetName = 'StreakooWidgetProvider';
  static const String androidWidgetSmall = 'StreakooWidgetSmall';
  static const String androidWidgetLarge = 'StreakooWidgetLarge';
  static const String androidWidgetFocus = 'StreakooWidgetFocus';

  /// Initialize the widget service - call this on app startup
  static Future<void> initialize() async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
      // Set the app group ID for iOS
      await HomeWidget.setAppGroupId(appGroupId);
      debugPrint('HomeWidgetService initialized');
    } catch (e) {
      debugPrint('Error initializing HomeWidgetService: $e');
    }
  }

  /// Generate a motivational message based on progress
  static String getMotivationalMessage({
    required int completedHabits,
    required int totalHabits,
    required int currentStreak,
  }) {
    if (totalHabits == 0) {
      return "Ready to start! 🚀";
    }

    final progress = completedHabits / totalHabits;

    if (completedHabits == totalHabits) {
      if (currentStreak >= 7) {
        return "On fire! $currentStreak days! 🔥";
      }
      return "All done today! ✨";
    }

    if (progress >= 0.5) {
      return "Almost there! 💪";
    }

    if (currentStreak > 0) {
      return "$currentStreak day streak! 🎯";
    }

    return "Let's do this! 🌟";
  }

  /// Update widget with habit and health data
  static Future<void> updateWidgetData({
    required int completedHabits,
    required int totalHabits,
    required int currentStreak,
    required int steps,
    double sleepHours = 0.0,
    int sleepScore = 0,
  }) async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

      // Generate motivational message
      final message = getMotivationalMessage(
        completedHabits: completedHabits,
        totalHabits: totalHabits,
        currentStreak: currentStreak,
      );

      // Save all data to shared storage
      await HomeWidget.saveWidgetData<int>('completed_habits', completedHabits);
      await HomeWidget.saveWidgetData<int>('total_habits', totalHabits);
      await HomeWidget.saveWidgetData<int>('current_streak', currentStreak);
      await HomeWidget.saveWidgetData<int>('steps', steps);
      await HomeWidget.saveWidgetData<double>('sleep_hours', sleepHours);
      await HomeWidget.saveWidgetData<int>('sleep_score', sleepScore);
      await HomeWidget.saveWidgetData<String>('motivation', message);

      // Trigger update for all widget types
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: 'StreakooWidget',
      );
      await HomeWidget.updateWidget(
        name: androidWidgetSmall,
        iOSName: 'StreakooWidgetSmall',
      );
      await HomeWidget.updateWidget(
        name: androidWidgetLarge,
        iOSName: 'StreakooWidgetLarge',
      );
      await HomeWidget.updateWidget(
        name: androidWidgetFocus,
        iOSName: 'StreakooWidgetFocus',
      );

      debugPrint(
          'All widgets updated: $completedHabits/$totalHabits habits, streak: $currentStreak, sleep: $sleepHours');
    } catch (e) {
      debugPrint('Error updating home widgets: $e');
    }
  }
}
