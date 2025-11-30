import 'package:flutter/material.dart';

/// Time period of the day for theme/color variations
enum TimePeriod {
  morning, // 5 AM - 12 PM
  afternoon, // 12 PM - 6 PM
  evening, // 6 PM - 10 PM
  night, // 10 PM - 5 AM
}

/// Utility class for time-related functions
class TimeUtils {
  /// Get current time period based on hour
  static TimePeriod getCurrentPeriod() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return TimePeriod.morning;
    } else if (hour >= 12 && hour < 18) {
      return TimePeriod.afternoon;
    } else if (hour >= 18 && hour < 22) {
      return TimePeriod.evening;
    } else {
      return TimePeriod.night;
    }
  }

  /// Get color palette for current time period
  static List<Color> getTimeBasedColors() {
    final period = getCurrentPeriod();

    switch (period) {
      case TimePeriod.morning:
        return [
          const Color(0xFFFF9966), // Warm orange
          const Color(0xFFFFD54F), // Yellow
          const Color(0xFFFF6B9D), // Pink
          const Color(0xFFFFA726), // Orange
        ];

      case TimePeriod.afternoon:
        return [
          const Color(0xFF42A5F5), // Bright blue
          const Color(0xFF66BB6A), // Green
          const Color(0xFFFFEB3B), // Yellow
          const Color(0xFF29B6F6), // Light blue
        ];

      case TimePeriod.evening:
        return [
          const Color(0xFF5C6BC0), // Cool blue
          const Color(0xFF7E57C2), // Purple
          const Color(0xFFFF7043), // Orange
          const Color(0xFFAB47BC), // Light purple
        ];

      case TimePeriod.night:
        return [
          const Color(0xFF7E57C2), // Deep purple
          const Color(0xFF5C6BC0), // Blue
          const Color(0xFF42A5F5), // Light blue
          const Color(0xFFFFD700), // Gold (stars)
        ];
    }
  }

  /// Get greeting message based on time
  static String getGreeting() {
    final period = getCurrentPeriod();

    switch (period) {
      case TimePeriod.morning:
        return 'Good morning';
      case TimePeriod.afternoon:
        return 'Good afternoon';
      case TimePeriod.evening:
        return 'Good evening';
      case TimePeriod.night:
        return 'Good night';
    }
  }

  /// Get emoji based on time
  static String getTimeEmoji() {
    final period = getCurrentPeriod();

    switch (period) {
      case TimePeriod.morning:
        return '🌅';
      case TimePeriod.afternoon:
        return '☀️';
      case TimePeriod.evening:
        return '🌆';
      case TimePeriod.night:
        return '🌙';
    }
  }

  /// Check if it's early in the day (before noon)
  static bool isEarlyDay() {
    return DateTime.now().hour < 12;
  }

  /// Check if it's late in the day (after 8 PM)
  static bool isLateDay() {
    return DateTime.now().hour >= 20;
  }

  /// Check if it's weekend
  static bool isWeekend() {
    final weekday = DateTime.now().weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// Format time as "HH:MM AM/PM"
  static String formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
