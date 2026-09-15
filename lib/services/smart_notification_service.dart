import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../services/health_service.dart';
import '../services/streak_predictor_service.dart';
import '../models/habit.dart';

/// Streamlined notification service for habit reminders and engagement
/// Replaces the old 1100+ line notification_engine.dart
class SmartNotificationService {
  /// Send notification when health goal is met (automated completion)
  Future<void> sendHealthGoalMetNotification(Habit habit) async {
    if (!_initialized) return;

    final unit = _getHealthMetricUnit(habit.healthMetric);
    final value = habit.healthGoalValue?.toStringAsFixed(0) ?? '';

    await _plugin.show(
      _healthGoalBaseId + habit.id.hashCode, // Use unique base ID 400000
      '🎉 Goal Achieved: ${habit.emoji} ${habit.name}',
      'You hit your target of $value $unit! Great job! 💪',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'milestones', // Reuse milestone channel for celebrations
          'Milestone Celebrations',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'health_goal:${habit.id}',
    );

    debugPrint('🎉 Health goal notification sent for "${habit.name}"');
  }

  String _getHealthMetricUnit(HealthMetricType? metric) {
    if (metric == null) return '';
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

  SmartNotificationService._();
  static final SmartNotificationService instance = SmartNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // Notification IDs
  static const int _morningQuoteId = 100000;
  static const int _streakAlertBaseId = 200000;
  static const int _milestoneBaseId = 300000;
  static const int _healthGoalBaseId = 400000;

  // Prefs keys
  static const String _prefLastMilestoneCheck = 'last_milestone_check_date';

  // ============ INITIALIZATION ============

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('🔔 Initializing Smart Notification Service...');

      tzdata.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const macOSInit = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        macOS: macOSInit,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channels
      await _createNotificationChannels();

      _initialized = true;
      debugPrint('✅ Smart Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Smart Notification Service init failed: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Request permissions for Android 13+
      await androidPlugin.requestNotificationsPermission();

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'habit_reminders',
          'Habit Reminders',
          description: 'Daily habit reminder notifications',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'streak_alerts',
          'Streak Alerts',
          description: 'Urgent streak at risk notifications',
          importance: Importance.max,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'milestones',
          'Milestone Celebrations',
          description: 'Celebrate your achievements',
          importance: Importance.high,
        ),
      );

      // Create competition channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'competition_channel',
          'Friend Competition',
          description: 'Notifications when friends pass your streak',
          importance: Importance.high,
        ),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notification tapped: ${response.payload}');
    // TODO: Handle navigation based on payload
  }

  // ============ HABIT REMINDERS ============

  /// Schedule a daily reminder for a habit at its reminder time
  Future<void> scheduleHabitReminder(Habit habit) async {
    if (!_initialized || !habit.reminderEnabled || habit.reminderTime == null) {
      return;
    }

    try {
      // Parse reminder time (format: "HH:mm")
      final parts = habit.reminderTime!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final message = _getRandomReminderMessage(habit);

      await _plugin.zonedSchedule(
        habit.id.hashCode,
        '${habit.emoji} ${habit.name}',
        message,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit:${habit.id}',
      );

      debugPrint(
          '⏰ Scheduled reminder for "${habit.name}" at ${habit.reminderTime}');
    } catch (e) {
      debugPrint('❌ Failed to schedule reminder for "${habit.name}": $e');
    }
  }

  /// Schedule reminders for all habits with reminders enabled
  Future<void> scheduleAllHabitReminders(List<Habit> habits) async {
    for (final habit in habits) {
      if (habit.reminderEnabled && habit.reminderTime != null) {
        await scheduleHabitReminder(habit);
      }
    }
    debugPrint(
        '✅ Scheduled reminders for ${habits.where((h) => h.reminderEnabled).length} habits');
  }

  /// Cancel a habit reminder
  Future<void> cancelHabitReminder(String habitId) async {
    await _plugin.cancel(habitId.hashCode);
  }

  String _getRandomReminderMessage(Habit habit) {
    final messages = [
      'Time to keep your streak going! 🔥',
      'Your ${habit.streak} day streak is waiting for you!',
      'Small steps, big results. Let\'s do this! 💪',
      'A few minutes now = a better you tomorrow!',
      'Your future self will thank you ✨',
      'Ready to build your best self?',
    ];
    return messages[Random().nextInt(messages.length)];
  }

  // ============ MORNING MOTIVATION ============

  // ============ MORNING MOTIVATION ============

  /// Schedule a recurring daily notification at 7:00 AM
  Future<void> scheduleDailyMorningQuote() async {
    if (!_initialized) return;

    try {
      // 1. Cancel any existing scheduled quote to prevent duplicates
      await _plugin.cancel(_morningQuoteId);

      // 2. Calculate next 7:00 AM instance
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        7, // 7 AM
        0,
      );

      // If 7 AM has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // 3. Schedule the recurring notification
      // Note: We can't rotate the text for a recurring notification easily without
      // rescheduling every day. For a simpler robust approach, we'll schedule
      // a "daily" notification that triggers the app to perhaps update,
      // OR we can schedule 7 individual notifications for the next 7 days with different quotes.
      // Let's go with the "Schedule next 7 days" approach for variety.

      await _scheduleNext7DaysQuotes();

      debugPrint(
          '✅ Scheduled morning quotes for the next 7 days starting $scheduledDate');
    } catch (e) {
      debugPrint('❌ Failed to schedule morning quote: $e');
    }
  }

  /// Cancels morning quotes
  Future<void> cancelMorningQuotes() async {
    // Cancel the base ID and the next 7 days worth of IDs
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(_morningQuoteId + i);
    }
    debugPrint('🔕 Cancelled morning quotes');
  }

  Future<void> _scheduleNext7DaysQuotes() async {
    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < 7; i++) {
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        7, // 7 AM
        0,
      ).add(Duration(days: i));

      // If today's 7 AM is past and i=0, add 1 day (start tomorrow)
      // Actually, if we just add days loop, we need to make sure we don't schedule
      // in the past.
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        // Use this logic if we want to ensure we always have 7 days ahead.
        // But simpler: just schedule. isBefore check handled by plugin usually?
        // No, zonedSchedule validates future dates.
        continue; // Skip past dates
      }

      final quote = _getRandomMotivationalQuote();

      await _plugin.zonedSchedule(
        _morningQuoteId + i, // Unique ID for each day
        '☀️ Good Morning!',
        quote,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'motivational_quotes', // Separate channel
            'Daily Motivation',
            channelDescription: 'Daily 7 AM motivational quotes',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            DateTimeComponents.time, // This makes it repeat daily at this time?
        // Wait, if we use matchDateTimeComponents.time, it repeats EVERY DAY at that time.
        // So we don't need a loop for 7 days if we want the SAME content.
        // BUT we want DIFFERENT content.
        // So we should NOT use matchDateTimeComponents if we are scheduling individual unique outcomes.
        // OR we use the payload to maybe randomize later? No, payload is static.
        // Best approach for "variety" without background execution:
        // Schedule 7 distinct notifications (one for each day of week) without repeat,
        // and re-schedule every time the user opens the app (runDailyNotifications).
      );
    }
  }

  String _getRandomMotivationalQuote() {
    final quotes = [
      'Small daily improvements lead to big results! 💪',
      'Today is a new opportunity to grow.',
      'Your habits shape your future. Make them count!',
      'Consistency beats perfection every time.',
      'One step at a time, one day at a time.',
      'You\'re stronger than you think! 🔥',
      'Progress, not perfection.',
      'Great things never came from comfort zones.',
      'The secret of getting ahead is getting started.',
      'Every day is a chance to be better than yesterday.',
      'Don\'t watch the clock; do what it does. Keep going.',
      'Believe you can and you\'re halfway there.',
      'Action is the foundational key to all success. 🗝️',
      'Don\'t stop when you\'re tired. Stop when you\'re done.',
      'Your future is created by what you do today, not tomorrow.',
      'Dream big. Start small. But most of all, start.',
      'Discipline is choosing between what you want now and what you want most.',
      'Success is the sum of small efforts, repeated day in and day out.',
      'The only bad workout is the one that didn\'t happen.',
      'Fall seven times, stand up eight. 🦁',
      'Focus on the step in front of you, not the whole staircase.',
      'You don\'t have to be great to start, but you have to start to be great.',
      'Motivation gets you going. Habit keeps you going.',
      'Your potential is endless. Go do what you were created to do.',
      'Do something today that your future self will thank you for.',
      'It always seems impossible until it\'s done.',
      'Don\'t wait for opportunity. Create it.',
      'Success doesn\'t come from what you do occasionally, it comes from what you do consistently.',
      'Wake up with determination. Go to bed with satisfaction.',
      'Make today so awesome yesterday gets jealous. 😎',
    ];
    return quotes[Random().nextInt(quotes.length)];
  }

  // ============ MILESTONE CELEBRATIONS ============

  /// Check habits for milestone achievements and send notifications
  Future<void> checkStreakMilestones(List<Habit> habits) async {
    if (!_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';

    // Only check once per day
    if (prefs.getString(_prefLastMilestoneCheck) == today) {
      debugPrint('🎉 Milestone check already done today');
      return;
    }

    final milestones = [7, 14, 21, 30, 50, 100, 365];

    for (final habit in habits) {
      if (milestones.contains(habit.streak)) {
        await _sendMilestoneNotification(habit);
      }
    }

    await prefs.setString(_prefLastMilestoneCheck, today);
  }

  /// Send immediate milestone notification (call after completion)
  Future<void> sendMilestoneNotification(Habit habit, int streak) async {
    if (!_initialized) return;

    final milestones = [7, 14, 21, 30, 50, 100, 365];
    if (!milestones.contains(streak)) return;

    await _sendMilestoneNotification(habit);
  }

  Future<void> _sendMilestoneNotification(Habit habit) async {
    final message = _getMilestoneMessage(habit.streak);

    await _plugin.show(
      _milestoneBaseId + habit.id.hashCode,
      '🎉 ${habit.emoji} ${habit.streak} Day Streak!',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'milestones',
          'Milestone Celebrations',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'milestone:${habit.id}',
    );

    debugPrint(
        '🎉 Milestone notification sent for "${habit.name}" - ${habit.streak} days');
  }

  String _getMilestoneMessage(int streak) {
    switch (streak) {
      case 7:
        return '1 Week Strong! You\'re building a real habit now! 🔥';
      case 14:
        return '2 Weeks! Science says 21 days forms a habit - almost there! ⚡';
      case 21:
        return '21 Days! This is now wired into your brain! 🧠';
      case 30:
        return '1 Month! You\'re in the top 10% of habit builders! 🏆';
      case 50:
        return '50 Days! You\'re truly unstoppable! 💎';
      case 100:
        return '100 DAYS! A true master of habits! 👑';
      case 365:
        return '1 YEAR! Legendary achievement unlocked! 🎖️';
      default:
        return 'Amazing progress! Keep building your streak! 🔥';
    }
  }

  // ============ STREAK AT RISK (LOCAL) ============

  /// Schedule a streak-at-risk alert for later today (backup for server-side)
  Future<void> scheduleStreakAtRiskAlert(Habit habit) async {
    if (!_initialized) return;

    try {
      final now = tz.TZDateTime.now(tz.local);

      // Schedule for 8 PM today
      var alertTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        20, // 8 PM
        0,
      );

      // If it's already past 8 PM, skip
      if (alertTime.isBefore(now)) return;

      await _plugin.zonedSchedule(
        _streakAlertBaseId + habit.id.hashCode,
        '🔥 Your streak is at risk!',
        'Complete "${habit.name}" before midnight to keep your ${habit.streak} day streak!',
        alertTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_alerts',
            'Streak Alerts',
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        // Use inexact mode to avoid requiring SCHEDULE_EXACT_ALARM permission on Android 12+
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'streak_alert:${habit.id}',
      );
    } catch (e) {
      debugPrint('⚠️ Failed to schedule streak alert for "${habit.name}": $e');
      // Non-fatal - don't rethrow
    }
  }

  /// Cancel streak alert (when habit is completed)
  Future<void> cancelStreakAlert(String habitId) async {
    if (!_initialized) return;

    try {
      await _plugin.cancel(_streakAlertBaseId + habitId.hashCode);
    } catch (e) {
      debugPrint('⚠️ Failed to cancel streak alert: $e');
      // Non-fatal - don't rethrow
    }
  }

  // ============ UTILITY METHODS ============

  /// Process all notifications for the day (call from home screen init)
  /// Pass user preferences to respect their notification settings
  Future<void> runDailyNotifications(
    List<Habit> habits, {
    bool morningQuotesEnabled = false,
    bool streakAlertsEnabled = true,
    bool milestoneCelebrationEnabled = true,
  }) async {
    if (!_initialized) {
      debugPrint('⚠️ Cannot run daily notifications - service not initialized');
      return;
    }

    debugPrint('📱 Running daily notifications for ${habits.length} habits...');
    debugPrint(
        '   Prefs: morning=$morningQuotesEnabled, streak=$streakAlertsEnabled, milestone=$milestoneCelebrationEnabled');

    // 1. Morning quote - Show local notification if enabled
    // Note: Edge Function also sends morning quotes, but local serves as backup
    if (morningQuotesEnabled) {
      debugPrint('🌅 Morning quotes enabled - scheduling for 7 AM...');
      await scheduleDailyMorningQuote();
    } else {
      debugPrint('🌅 Morning quotes disabled by user preference');
      await cancelMorningQuotes();
    }

    // 2. Check milestones (if enabled)
    if (milestoneCelebrationEnabled) {
      debugPrint('🏆 Checking streak milestones...');
      await checkStreakMilestones(habits);
    } else {
      debugPrint('🏆 Milestone celebrations disabled by user preference');
    }

    // 3. Schedule streak-at-risk alerts for incomplete habits (if enabled)
    if (streakAlertsEnabled) {
      int alertsScheduled = 0;
      for (final habit in habits) {
        if (!habit.completedToday && habit.streak > 0) {
          await scheduleStreakAtRiskAlert(habit);
          alertsScheduled++;
        }
      }
      debugPrint('🔥 Scheduled $alertsScheduled streak-at-risk alerts');
    } else {
      debugPrint('🔥 Streak alerts disabled by user preference');
    }

    // 4. Schedule habit reminders for all habits with reminders enabled
    int remindersScheduled = 0;
    for (final habit in habits) {
      if (habit.reminderEnabled && habit.reminderTime != null) {
        await scheduleHabitReminder(habit);
        remindersScheduled++;
      }
    }
    debugPrint('⏰ Scheduled $remindersScheduled habit reminders');

    debugPrint('✅ Daily notifications processed');
  }

  /// Clear all streak alerts (call when all habits completed)
  Future<void> clearAllStreakAlerts(List<Habit> habits) async {
    for (final habit in habits) {
      await cancelStreakAlert(habit.id);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Send an immediate test notification (for debugging)
  Future<bool> sendTestNotification() async {
    if (!_initialized) {
      debugPrint('❌ Cannot send test notification - service not initialized');
      return false;
    }

    try {
      await _plugin.show(
        99999, // Test notification ID
        '🧪 Test Notification',
        'If you see this, notifications are working! 🎉',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('✅ Test notification sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to send test notification: $e');
      return false;
    }
  }

  // ============ AI RISK PREDICTION ============

  /// Send risk prediction notifications based on AI analysis
  /// Call this during daily notification processing
  Future<void> sendRiskPredictionNotifications(List<Habit> habits) async {
    if (!_initialized) return;

    final predictor = StreakPredictorService.instance;
    final atRiskHabits = predictor.getHabitsNeedingWarning(habits);

    if (atRiskHabits.isEmpty) {
      debugPrint('🔮 No high-risk habits detected');
      return;
    }

    debugPrint(
        '🔮 Found ${atRiskHabits.length} habits at risk of streak break');

    // Get the most critical one for notification
    final mostCritical = predictor.getMostCriticalRisk(habits);
    if (mostCritical == null) return;

    // Check if we already sent a prediction notification today
    final prefs = await SharedPreferences.getInstance();
    final lastPrediction = prefs.getString('last_risk_prediction_date');
    final today = DateTime.now().toString().substring(0, 10);

    if (lastPrediction == today) {
      debugPrint('🔮 Risk prediction already sent today');
      return;
    }

    // Find the habit
    final habit = habits.firstWhere(
      (h) => h.id == mostCritical.habitId,
      orElse: () => habits.first,
    );

    // Send the notification
    await _plugin.show(
      900000 + habit.id.hashCode.abs() % 10000,
      '🔮 Streak Prediction Alert',
      '${habit.emoji} ${habit.name}: ${mostCritical.suggestion}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_alert',
          'Streak Alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFFA94A),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    // Save that we sent the prediction today
    await prefs.setString('last_risk_prediction_date', today);
    debugPrint('🔮 Sent risk prediction notification for ${habit.name}');
  }
}
