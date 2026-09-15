import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize timezone database
      tzdata.initializeTimeZones();

      // Set local timezone location based on device timezone
      final String timeZoneName = _getDeviceTimeZoneName();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        // Fallback to UTC if timezone not found
        debugPrint(
            '⚠️ Timezone "$timeZoneName" not found, falling back to UTC');
        tz.setLocalLocation(tz.UTC);
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      );

      await _plugin.initialize(initSettings);
      _initialized = true;
      debugPrint(
          '✅ LocalNotificationService initialized with timezone: $timeZoneName');
    } catch (e) {
      debugPrint('❌ LocalNotificationService init failed: $e');
    }
  }

  /// Get device timezone name
  static String _getDeviceTimeZoneName() {
    try {
      // Get the timezone offset and try to find a matching timezone
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Common timezone mappings based on offset
      if (Platform.localeName.contains('IN') ||
          offset.inHours == 5 && offset.inMinutes == 30) {
        return 'Asia/Kolkata';
      }

      // Try to get timezone name from platform
      // Fallback based on offset
      final hours = offset.inHours;
      if (hours >= -12 && hours <= 14) {
        // Common timezone mappings
        final timezoneMap = {
          -12: 'Etc/GMT+12',
          -11: 'Pacific/Pago_Pago',
          -10: 'Pacific/Honolulu',
          -9: 'America/Anchorage',
          -8: 'America/Los_Angeles',
          -7: 'America/Denver',
          -6: 'America/Chicago',
          -5: 'America/New_York',
          -4: 'America/Halifax',
          -3: 'America/Sao_Paulo',
          -2: 'Atlantic/South_Georgia',
          -1: 'Atlantic/Azores',
          0: 'Europe/London',
          1: 'Europe/Paris',
          2: 'Europe/Kiev',
          3: 'Europe/Moscow',
          4: 'Asia/Dubai',
          5: 'Asia/Karachi',
          6: 'Asia/Dhaka',
          7: 'Asia/Bangkok',
          8: 'Asia/Singapore',
          9: 'Asia/Tokyo',
          10: 'Australia/Sydney',
          11: 'Pacific/Noumea',
          12: 'Pacific/Auckland',
        };
        return timezoneMap[hours] ?? 'UTC';
      }
      return 'UTC';
    } catch (e) {
      return 'UTC';
    }
  }

  static int _idFromString(String id) => id.hashCode;

  /// Schedules a daily reminder 5 minutes before [time].
  static Future<void> scheduleDailyReminder({
    required String habitId,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!_initialized) {
      debugPrint(
          '⚠️ LocalNotificationService not initialized, skipping scheduling');
      return;
    }

    try {
      final now = tz.TZDateTime.now(tz.local);

      // target time today
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      ).subtract(const Duration(minutes: 5));

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'habit_daily',
        'Habit Daily Reminder',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();

      const platformDetails = NotificationDetails(
          android: androidDetails, iOS: iosDetails, macOS: iosDetails);

      await _plugin.zonedSchedule(
        _idFromString(habitId),
        title,
        body,
        scheduled,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to schedule daily reminder: $e');
    }
  }

  /// Schedules a generic daily notification at [time].
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!_initialized) {
      debugPrint(
          '⚠️ LocalNotificationService not initialized, skipping scheduling');
      return;
    }

    try {
      final now = tz.TZDateTime.now(tz.local);

      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'challenge_daily',
        'Health Challenge Updates',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();

      const platformDetails = NotificationDetails(
          android: androidDetails, iOS: iosDetails, macOS: iosDetails);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to schedule daily notification: $e');
    }
  }

  static Future<void> cancelReminder(String habitId) async {
    await _plugin.cancel(_idFromString(habitId));
  }

  /// Cancel a notification by its ID
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Show an immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'team_updates_channel',
      'Team Updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.show(id, title, body, platformDetails, payload: payload);
  }
}
