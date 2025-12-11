import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../config/app_config.dart';
import 'groq_ai_service.dart';
import 'notification_permission_service.dart';

enum NotificationType {
  soft, // Gentle reminder
  hard, // Urgent reminder for missed habits
  challenge, // Challenge-specific
  weekly, // Weekly summary
  streak, // Streak at risk
  focusReminder, // End of day focus task reminder
}

class HabitPattern {
  final String habitId;
  final List<int> completionHours; // Hours of completion (0-23)
  final int skipCount; // Consecutive skips
  final double completionRate; // 0.0 - 1.0
  final DateTime? lastCompletion;
  final int priority; // 1-5 (5 = highest)

  HabitPattern({
    required this.habitId,
    required this.completionHours,
    required this.skipCount,
    required this.completionRate,
    this.lastCompletion,
    required this.priority,
  });

  // Determine optimal reminder time
  int get suggestedReminderHour {
    if (completionHours.isEmpty) return 9; // Default morning

    // Calculate average completion hour
    final sum = completionHours.reduce((a, b) => a + b);
    final avg = sum / completionHours.length;

    // Remind 1 hour before usual completion time
    return (avg - 1).round().clamp(6, 22);
  }

  bool get isAtRisk => skipCount >= 2;
  bool get isHighPriority => completionRate > 0.8 && priority >= 4;
}

class NotificationEngine {
  NotificationEngine._();
  static final NotificationEngine instance = NotificationEngine._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _channelsCreated = false;

  // Track habit patterns
  final Map<String, HabitPattern> _patterns = {};

  /// Check if notification engine is ready
  bool get isInitialized => _initialized;

  // Rate limiting keys
  static const _lastFocusScheduleKey = 'last_focus_schedule_date';
  static const _lastPredictiveScheduleKey = 'last_predictive_schedule_date';
  // ignore: unused_field - reserved for per-habit rate limiting
  static const _lastHabitScheduleKey = 'last_habit_schedule_';

  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;

    debugPrint('🔔 Initializing Notification Engine...');

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Create notification channels for Android (required for Android 8+, critical for 13+)
      if (!_channelsCreated) {
        await _createNotificationChannels();
        _channelsCreated = true;
      }

      // Check if permissions have been granted
      final permissionService = NotificationPermissionService.instance;
      final hasPermission = await permissionService.areNotificationsEnabled();

      if (!hasPermission) {
        debugPrint('⚠️ Notification permissions not granted yet');
        // Request permissions
        final granted = await permissionService.requestPermissions();
        if (!granted) {
          debugPrint('❌ Notification permissions denied by user');
          return;
        }
        debugPrint('✅ Notification permissions granted');
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      _initialized = true;

      debugPrint('✅ Notification Engine Initialized');
    } catch (e) {
      debugPrint('❌ Notification Engine initialization failed: $e');
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) return;

    // Main habit reminders channel
    const habitChannel = AndroidNotificationChannel(
      'streakoo_reminders',
      'Habit Reminders',
      description: 'Daily reminders for your habits',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // High priority alerts channel
    const alertChannel = AndroidNotificationChannel(
      'streakoo_alerts',
      'Streak Alerts',
      description: 'Urgent alerts when your streak is at risk',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Focus task channel
    const focusChannel = AndroidNotificationChannel(
      'streakoo_focus',
      'Focus Task Reminders',
      description: 'End of day reminders for focus tasks',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidImplementation.createNotificationChannel(habitChannel);
    await androidImplementation.createNotificationChannel(alertChannel);
    await androidImplementation.createNotificationChannel(focusChannel);

    debugPrint('✅ Notification channels created');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // Could navigate to specific habit here
  }

  /// Send a test notification (for debugging)
  Future<void> sendTestNotification() async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'streakoo_reminders',
      'Habit Reminders',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '🔔 Test Notification',
      'Streakoo notifications are working! 🎉',
      details,
    );

    debugPrint('✅ Test notification sent');
  }

  // Update habit pattern based on completion
  void updatePattern(Habit habit) {
    final now = DateTime.now();
    final currentHour = now.hour;

    final existing = _patterns[habit.id];
    final completionHours = existing?.completionHours ?? [];

    // Track completion hour
    if (habit.completedToday && !completionHours.contains(currentHour)) {
      completionHours.add(currentHour);
      if (completionHours.length > 30) {
        completionHours.removeAt(0); // Keep last 30
      }
    }

    // Calculate skip count
    final skipCount = _calculateSkipCount(habit);

    // Calculate completion rate
    final completionRate = habit.completionDates.isEmpty
        ? 0.0
        : habit.streak / habit.completionDates.length;

    // Determine priority
    final priority = _calculatePriority(habit, completionRate);

    _patterns[habit.id] = HabitPattern(
      habitId: habit.id,
      completionHours: completionHours,
      skipCount: skipCount,
      completionRate: completionRate,
      lastCompletion: habit.completedToday ? now : existing?.lastCompletion,
      priority: priority,
    );

    debugPrint(
        '📊 Updated pattern for ${habit.name}: Priority $priority, Skip count: $skipCount');
  }

  int _calculateSkipCount(Habit habit) {
    if (habit.completedToday) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (habit.completionDates.isEmpty) return 0;

    final lastCompletionStr = habit.completionDates.last;
    final lastCompletion = DateTime.parse(lastCompletionStr);
    final lastDay =
        DateTime(lastCompletion.year, lastCompletion.month, lastCompletion.day);

    return today.difference(lastDay).inDays;
  }

  int _calculatePriority(Habit habit, double completionRate) {
    // Priority 1-5 based on:
    // - Current streak
    // - Completion rate
    // - Challenge status

    if (habit.challengeTargetDays != null && !habit.challengeCompleted) {
      return 5; // Challenge habits are highest priority
    }

    if (completionRate > 0.9 && habit.streak > 20) return 5;
    if (completionRate > 0.7 && habit.streak > 10) return 4;
    if (completionRate > 0.5) return 3;
    if (completionRate > 0.3) return 2;
    return 1;
  }

  // Schedule notification for a habit
  Future<void> scheduleHabitReminder(
    Habit habit, {
    NotificationType type = NotificationType.soft,
    String? customMessage,
  }) async {
    if (!_initialized) await initialize();

    // 1. Check if reminders are enabled
    if (!habit.reminderEnabled || habit.reminderTime == null) {
      return;
    }

    // 2. Parse time and calculate 5 minutes before
    final timeParts = habit.reminderTime!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Calculate schedule time (5 mins before)
    var scheduledHour = hour;
    var scheduledMinute = minute - 5;

    if (scheduledMinute < 0) {
      scheduledMinute += 60;
      scheduledHour -= 1;
      if (scheduledHour < 0) scheduledHour += 24;
    }

    // 3. Generate notification message
    final pattern = _patterns[habit.id];
    final message = customMessage ??
        await _generateNotificationMessage(habit, type, pattern);

    // 4. Schedule for each active day
    final now = tz.TZDateTime.now(tz.local);

    // Cancel existing notifications for this habit first to avoid duplicates
    await cancelHabitReminder(habit.id);

    for (final day in habit.frequencyDays) {
      // Calculate next occurrence of this day
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        scheduledHour,
        scheduledMinute,
      );

      // Adjust to the correct day of week
      while (scheduledDate.weekday != day) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // If time passed for today, move to next week
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      // Unique ID for each day: hash + day
      final notificationId = habit.id.hashCode + day;

      await _notifications.zonedSchedule(
        notificationId,
        'You\'re almost there! 🚀',
        message,
        scheduledDate,
        _getNotificationDetails(type),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      debugPrint(
          '🔔 Scheduled for "${habit.name}" on day $day at $scheduledHour:${scheduledMinute.toString().padLeft(2, '0')}');
    }
  }

  Future<String> _generateNotificationMessage(
    Habit habit,
    NotificationType type,
    HabitPattern? pattern,
  ) async {
    // Use AI if configured
    if (AppConfig.isApiConfigured && AppConfig.useAIForCoaching) {
      try {
        final context = _buildAIContext(habit, type, pattern);
        final aiMessage = await GroqAIService.instance.generateResponse(
          systemPrompt:
              '''You are a motivational habit coach. Generate a short, encouraging push notification message (max 60 characters).
Be personal, use the habit name, mention streak if relevant, be energetic but not pushy.''',
          userPrompt: context,
          maxTokens: 30,
          temperature: 0.8,
        );

        if (aiMessage != null && aiMessage.isNotEmpty) {
          return aiMessage.trim().replaceAll('"', '');
        }
      } catch (e) {
        debugPrint('AI notification generation failed: $e');
      }
    }

    // Fallback messages
    return _getFallbackMessage(habit, type, pattern);
  }

  String _buildAIContext(
    Habit habit,
    NotificationType type,
    HabitPattern? pattern,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Habit: ${habit.name} ${habit.emoji}');
    buffer.writeln('Category: ${habit.category}');
    buffer.writeln('Current streak: ${habit.streak} days');
    buffer.writeln('Notification type: ${type.name}');

    if (pattern != null) {
      buffer.writeln('Skip count: ${pattern.skipCount}');
      buffer.writeln(
          'Completion rate: ${(pattern.completionRate * 100).toStringAsFixed(0)}%');
      buffer.writeln('Priority: ${pattern.priority}/5');
    }

    if (habit.challengeTargetDays != null) {
      buffer.writeln(
          'Challenge: ${habit.challengeProgress}/${habit.challengeTargetDays} days');
    }

    if (type == NotificationType.focusReminder) {
      buffer.writeln(
          'IMPORTANT: This is a FOCUS TASK. If missed, it will use a streak freeze!');
      buffer.writeln('Time is running out (End of Day).');
    }

    buffer.writeln('\nCreate a motivating push notification message.');
    return buffer.toString();
  }

  String _getFallbackMessage(
    Habit habit,
    NotificationType type,
    HabitPattern? pattern,
  ) {
    switch (type) {
      case NotificationType.soft:
        return '${habit.emoji} Time for "${habit.name}"! Keep the momentum going 🔥';

      case NotificationType.hard:
        if (pattern?.isAtRisk == true) {
          return '⚠️ Don\'t lose your ${habit.streak}-day streak on "${habit.name}"! You got this 💪';
        }
        return '${habit.emoji} "${habit.name}" is waiting! Let\'s do this 🚀';

      case NotificationType.challenge:
        final remaining =
            (habit.challengeTargetDays ?? 0) - habit.challengeProgress;
        return '🎯 Challenge update: $remaining days left on "${habit.name}"! Almost there 🔥';

      case NotificationType.streak:
        return '🔥 Your ${habit.streak}-day "${habit.name}" streak needs you today!';

      case NotificationType.weekly:
        return '📊 Weekly review ready! See how you did this week 🌟';

      case NotificationType.focusReminder:
        return '❄️ Don\'t freeze! Complete "${habit.name}" to save your streak! ⭐';
    }
  }

  NotificationDetails _getNotificationDetails(NotificationType type) {
    final priority =
        type == NotificationType.hard || type == NotificationType.streak
            ? Priority.high
            : Priority.defaultPriority;

    final androidDetails = AndroidNotificationDetails(
      'streakoo_reminders',
      'Habit Reminders',
      channelDescription: 'Notifications for your daily habits',
      importance: type == NotificationType.hard
          ? Importance.high
          : Importance.defaultImportance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
      playSound: type != NotificationType.soft,
      enableVibration: type != NotificationType.soft,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // Schedule all active habits
  Future<void> scheduleAllHabits(List<Habit> habits) async {
    for (final habit in habits) {
      if (habit.completedToday) continue; // Skip already completed

      final pattern = _patterns[habit.id];
      final type = _determineNotificationType(habit, pattern);

      await scheduleHabitReminder(habit, type: type);
    }
  }

  NotificationType _determineNotificationType(
    Habit habit,
    HabitPattern? pattern,
  ) {
    // Challenge habits get challenge notifications
    if (habit.challengeTargetDays != null && !habit.challengeCompleted) {
      return NotificationType.challenge;
    }

    // At-risk habits get hard notifications
    if (pattern?.isAtRisk == true || habit.streak > 5) {
      return NotificationType.streak;
    }

    // High priority habits get soft reminders
    return NotificationType.soft;
  }

  // Cancel notification for a habit
  Future<void> cancelHabitReminder(String habitId) async {
    // Cancel for all possible days
    for (var i = 1; i <= 7; i++) {
      await _notifications.cancel(habitId.hashCode + i);
    }
    // Also cancel the old single ID just in case
    await _notifications.cancel(habitId.hashCode);
  }

  // Send weekly summary notification
  Future<void> sendWeeklySummary({
    required int habitsCompleted,
    required int habitsMissed,
    required int totalStreaks,
  }) async {
    if (!_initialized) await initialize();

    final message =
        'This week: $habitsCompleted done, $habitsMissed missed. Total streaks: $totalStreaks 🔥';

    await _notifications.show(
      999999, // Unique ID for weekly summary
      'Your Weekly Summary 📊',
      message,
      _getNotificationDetails(NotificationType.weekly),
    );
  }

  // Schedule end-of-day reminders for focus tasks (RATE LIMITED)
  Future<void> scheduleFocusTaskReminders(List<Habit> habits) async {
    if (!_initialized) await initialize();

    // Check if already scheduled today
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastScheduled = prefs.getString(_lastFocusScheduleKey);

    if (lastScheduled == today) {
      debugPrint('🔕 Focus reminders already scheduled today, skipping');
      return;
    }

    final focusTasks =
        habits.where((h) => h.isFocusTask && !h.completedToday).toList();

    for (final habit in focusTasks) {
      // Schedule for 9 PM today if not already passed, otherwise tomorrow
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        21, // 9 PM
        0,
      );

      if (scheduledDate.isBefore(now)) {
        // If it's already past 9 PM, don't schedule for today
        // We only want to remind for *today's* incomplete tasks
        continue;
      }

      // Generate AI message
      final pattern = _patterns[habit.id];
      final message = await _generateNotificationMessage(
          habit, NotificationType.focusReminder, pattern);

      await _notifications.zonedSchedule(
        habit.id.hashCode + 999, // Unique ID for focus reminder
        '❄️ Focus Task Alert!',
        message,
        scheduledDate,
        _getNotificationDetails(NotificationType.hard), // High priority
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('🔔 Scheduled focus reminder for "${habit.name}" at 9 PM');
    }

    // Mark as scheduled for today
    await prefs.setString(_lastFocusScheduleKey, today);
  }

  // Get pattern for a habit
  HabitPattern? getPattern(String habitId) => _patterns[habitId];

  // Clear all patterns (for testing)
  void clearPatterns() => _patterns.clear();

  /// Schedule predictive warnings for at-risk streaks (RATE LIMITED)
  /// Uses StreakPredictorService to analyze habits and send proactive notifications
  Future<void> schedulePredictiveWarnings(List<Habit> habits) async {
    if (!_initialized) await initialize();

    // Check if already scheduled today
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastScheduled = prefs.getString(_lastPredictiveScheduleKey);

    if (lastScheduled == today) {
      debugPrint('🔕 Predictive warnings already scheduled today, skipping');
      return;
    }

    // Import dynamically to avoid circular dependencies
    final predictions = _analyzeHabitsForPrediction(habits);

    for (final prediction in predictions) {
      if (!prediction['shouldWarn']) continue;

      final habitId = prediction['habitId'] as String;
      final habitName = prediction['habitName'] as String;
      final emoji = prediction['emoji'] as String;
      final streak = prediction['streak'] as int;
      final reason = prediction['reason'] as String;
      final riskLevel = prediction['riskLevel'] as String;

      // Schedule warning notification for 6 PM if not completed
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        18, // 6 PM
        0,
      );

      // If past 6 PM, skip for today
      if (scheduledTime.isBefore(now)) continue;

      // Build notification message
      String title;
      String body;

      if (riskLevel == 'critical') {
        title = '🚨 Streak Emergency!';
        body = '$emoji $habitName - $streak day streak at risk! $reason';
      } else {
        title = '⚠️ Streak Reminder';
        body = '$emoji Don\'t forget $habitName today! $reason';
      }

      await _notifications.zonedSchedule(
        habitId.hashCode + 888, // Unique ID for predictive warning
        title,
        body,
        scheduledTime,
        _getNotificationDetails(NotificationType.streak),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('🔮 Scheduled predictive warning for "$habitName" at 6 PM');
    }

    // Mark as scheduled for today
    await prefs.setString(_lastPredictiveScheduleKey, today);
  }

  /// Simple habit analysis for predictions (avoids circular import)
  List<Map<String, dynamic>> _analyzeHabitsForPrediction(List<Habit> habits) {
    final results = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final habit in habits) {
      if (habit.streak == 0 || habit.completedToday) continue;

      // Parse completion dates
      final dates = habit.completionDates
          .map((s) => DateTime.tryParse(s))
          .whereType<DateTime>()
          .toList();

      if (dates.isEmpty) continue;

      final daysSinceLastCompletion = today.difference(dates.last).inDays;

      // Calculate risk
      double riskScore = 0.0;
      String reason = '';

      if (daysSinceLastCompletion == 0 && now.hour >= 14) {
        riskScore = now.hour >= 20 ? 0.6 : 0.3;
        reason = 'Getting late in the day';
      } else if (daysSinceLastCompletion == 1) {
        riskScore = 0.7;
        reason = 'Yesterday was missed';
      } else if (daysSinceLastCompletion >= 2) {
        riskScore = 0.9;
        reason = 'Multiple days missed';
      }

      // Amplify risk for long streaks
      if (habit.streak > 30) riskScore *= 1.2;

      riskScore = riskScore.clamp(0.0, 1.0);

      if (riskScore >= 0.5) {
        results.add({
          'habitId': habit.id,
          'habitName': habit.name,
          'emoji': habit.emoji,
          'streak': habit.streak,
          'reason': reason,
          'riskLevel': riskScore >= 0.7 ? 'critical' : 'high',
          'shouldWarn': true,
        });
      }
    }

    return results;
  }
}
