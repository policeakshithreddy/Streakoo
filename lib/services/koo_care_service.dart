import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../config/app_config.dart';
import 'groq_ai_service.dart';
import 'local_notification_service.dart';

/// Koo Care check-in types
enum CareCheckInType {
  gentleNudge, // 2 days inactive
  supportiveReach, // 5+ days inactive
  welcomeBack, // Returned after long absence
  celebration, // Completed after a struggle
}

/// Koo Care check-in message
class KooCareMessage {
  final String title;
  final String message;
  final CareCheckInType type;
  final DateTime timestamp;
  final bool wasShown;

  const KooCareMessage({
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.wasShown = false,
  });
}

class KooCareService {
  KooCareService._();
  static final KooCareService instance = KooCareService._();

  static const String _lastActiveKey = 'koo_last_active';
  static const String _lastCheckInKey = 'koo_last_checkin';
  static const int _careNotificationId = 9005;
  static const int _comebackNotificationId = 9006;

  DateTime? _lastActiveDate;
  DateTime? _lastCheckInDate;

  /// Initialize and load state
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final lastActiveStr = prefs.getString(_lastActiveKey);
    if (lastActiveStr != null) {
      _lastActiveDate = DateTime.parse(lastActiveStr);
    }

    final lastCheckInStr = prefs.getString(_lastCheckInKey);
    if (lastCheckInStr != null) {
      _lastCheckInDate = DateTime.parse(lastCheckInStr);
    }
  }

  /// Record user activity
  Future<void> recordActivity() async {
    _lastActiveDate = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActiveKey, _lastActiveDate!.toIso8601String());
  }

  /// Get number of inactive days
  int get inactiveDays {
    if (_lastActiveDate == null) return 0;
    return DateTime.now().difference(_lastActiveDate!).inDays;
  }

  /// Check if user needs a care message
  Future<KooCareMessage?> checkForCareMessage(List<Habit> habits) async {
    final now = DateTime.now();

    // Don't send more than one check-in per day
    if (_lastCheckInDate != null &&
        _lastCheckInDate!.day == now.day &&
        _lastCheckInDate!.month == now.month) {
      return null;
    }

    // Check for comeback (was inactive, now returning)
    if (inactiveDays >= 3) {
      return await _generateComebackMessage(inactiveDays);
    }

    // Check for inactivity
    if (inactiveDays >= 5) {
      return await _generateSupportiveMessage();
    } else if (inactiveDays >= 2) {
      return await _generateGentleNudge();
    }

    // Check for struggle pattern
    final struggleMessage = await _checkForStruggle(habits);
    if (struggleMessage != null) {
      return struggleMessage;
    }

    return null;
  }

  /// Mark check-in as shown
  Future<void> markCheckInShown() async {
    _lastCheckInDate = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckInKey, _lastCheckInDate!.toIso8601String());
  }

  /// Schedule care notification when user is inactive
  Future<void> scheduleCareNotification({
    required String title,
    required String body,
  }) async {
    await LocalNotificationService.scheduleDailyNotification(
      id: _careNotificationId,
      title: title,
      body: body,
      time: const TimeOfDay(hour: 10, minute: 0), // Mid-morning check-in
    );
  }

  /// Send immediate comeback notification
  Future<void> sendComebackNotification() async {
    await LocalNotificationService.scheduleDailyNotification(
      id: _comebackNotificationId,
      title: '✨ Welcome Back!',
      body: 'We missed you! Ready to pick up where you left off?',
      time: TimeOfDay.now(),
    );
  }

  Future<KooCareMessage> _generateGentleNudge() async {
    final message = await _generateAIMessage(
      type: CareCheckInType.gentleNudge,
      context: 'User has been inactive for 2 days.',
    );

    return KooCareMessage(
      title: 'Hey there 💙',
      message: message,
      type: CareCheckInType.gentleNudge,
      timestamp: DateTime.now(),
    );
  }

  Future<KooCareMessage> _generateSupportiveMessage() async {
    final message = await _generateAIMessage(
      type: CareCheckInType.supportiveReach,
      context: 'User has been inactive for 5+ days and may be struggling.',
    );

    return KooCareMessage(
      title: 'Missing you 💙',
      message: message,
      type: CareCheckInType.supportiveReach,
      timestamp: DateTime.now(),
    );
  }

  Future<KooCareMessage> _generateComebackMessage(int daysAway) async {
    final message = await _generateAIMessage(
      type: CareCheckInType.welcomeBack,
      context: 'User is returning after $daysAway days away.',
    );

    return KooCareMessage(
      title: 'Welcome Back! ✨',
      message: message,
      type: CareCheckInType.welcomeBack,
      timestamp: DateTime.now(),
    );
  }

  Future<KooCareMessage?> _checkForStruggle(List<Habit> habits) async {
    // Check if user has habits with broken streaks recently
    int brokenStreaks = 0;
    for (final habit in habits) {
      if (habit.streak == 0 && habit.completionDates.isNotEmpty) {
        brokenStreaks++;
      }
    }

    if (brokenStreaks >= 2) {
      final message = await _generateAIMessage(
        type: CareCheckInType.gentleNudge,
        context: 'User has $brokenStreaks broken streaks recently.',
      );

      return KooCareMessage(
        title: 'I noticed something 💙',
        message: message,
        type: CareCheckInType.gentleNudge,
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  Future<String> _generateAIMessage({
    required CareCheckInType type,
    required String context,
  }) async {
    if (!AppConfig.isApiConfigured || !AppConfig.useAIForCoaching) {
      return _getFallbackMessage(type);
    }

    try {
      String prompt;
      switch (type) {
        case CareCheckInType.gentleNudge:
          prompt =
              'Generate a gentle, caring check-in message for a habit app user who has been away for a couple days. Be warm, not pushy. Context: $context';
          break;
        case CareCheckInType.supportiveReach:
          prompt =
              'Generate a very supportive, empathetic message for someone who may be struggling with their habits. No guilt, only support. Context: $context';
          break;
        case CareCheckInType.welcomeBack:
          prompt =
              'Generate a warm, celebratory welcome back message. Be excited but not over the top. Context: $context';
          break;
        case CareCheckInType.celebration:
          prompt =
              'Generate a celebration message for someone who completed a habit after struggling. Context: $context';
          break;
      }

      final response = await GroqAIService.instance.generateResponse(
        systemPrompt:
            'You are Koo, a warm, empathetic habit coach. Write brief, genuine messages (2 sentences max) with 1-2 emojis. Be caring, never guilt-tripping.',
        userPrompt: prompt,
        maxTokens: 80,
        temperature: 0.8,
      );

      return response?.trim() ?? _getFallbackMessage(type);
    } catch (e) {
      debugPrint('Error generating care message: $e');
      return _getFallbackMessage(type);
    }
  }

  String _getFallbackMessage(CareCheckInType type) {
    switch (type) {
      case CareCheckInType.gentleNudge:
        return "Hey, just checking in. How are you doing? 💙 No pressure, just wanted to say hi.";
      case CareCheckInType.supportiveReach:
        return "I've been thinking about you. Life gets busy sometimes, and that's okay. I'm here whenever you're ready. 🌱";
      case CareCheckInType.welcomeBack:
        return "You're back! So glad to see you. Let's take it one step at a time. ✨";
      case CareCheckInType.celebration:
        return "Look at you go! That wasn't easy, but you did it. So proud of you! 🎉";
    }
  }
}
