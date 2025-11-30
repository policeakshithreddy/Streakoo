import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

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

  // Track habit patterns
  final Map<String, HabitPattern> _patterns = {};

  Future<void> initialize() async {
    if (_initialized) return;

    print('🔔 Initializing Notification Engine...');

    // Initialize timezone
    tz.initializeTimeZones();

    // Check if permissions have been granted
    final permissionService = NotificationPermissionService.instance;
    final hasPermission = await permissionService.areNotificationsEnabled();

    if (!hasPermission) {
      print('⚠️ Notification permissions not granted yet');
      // Don't initialize fully if no permissions
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;

    print('✅ Notification Engine Initialized');
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

    print(
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      print(
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
        print('AI notification generation failed: $e');
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

  // Schedule end-of-day reminders for focus tasks
  Future<void> scheduleFocusTaskReminders(List<Habit> habits) async {
    if (!_initialized) await initialize();

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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('🔔 Scheduled focus reminder for "${habit.name}" at 9 PM');
    }
  }

  // Get pattern for a habit
  HabitPattern? getPattern(String habitId) => _patterns[habitId];

  // Clear all patterns (for testing)
  void clearPatterns() => _patterns.clear();
}
