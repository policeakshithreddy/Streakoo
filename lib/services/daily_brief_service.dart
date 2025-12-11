import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../config/app_config.dart';
import 'groq_ai_service.dart';
import 'health_service.dart';
import 'local_notification_service.dart';

/// Model for daily brief data
class DailyBrief {
  final String greeting;
  final int pendingHabitsCount;
  final List<String> pendingHabitNames;
  final String motivationalMessage;
  final String? healthTip;
  final int? todaySteps;
  final double? todaySleep;
  final DateTime generatedAt;

  const DailyBrief({
    required this.greeting,
    required this.pendingHabitsCount,
    required this.pendingHabitNames,
    required this.motivationalMessage,
    this.healthTip,
    this.todaySteps,
    this.todaySleep,
    required this.generatedAt,
  });
}

/// Model for evening reflection data
class EveningReflection {
  final int completedCount;
  final int totalCount;
  final List<String> completedHabits;
  final List<String> missedHabits;
  final String reflectionPrompt;
  final String celebrationMessage;
  final int? todaySteps;
  final DateTime generatedAt;

  const EveningReflection({
    required this.completedCount,
    required this.totalCount,
    required this.completedHabits,
    required this.missedHabits,
    required this.reflectionPrompt,
    required this.celebrationMessage,
    this.todaySteps,
    required this.generatedAt,
  });

  double get completionRate => totalCount > 0 ? completedCount / totalCount : 0;
}

class DailyBriefService {
  DailyBriefService._();
  static final DailyBriefService instance = DailyBriefService._();

  // Notification IDs
  static const int _morningBriefNotificationId = 9001;
  static const int _eveningReflectionNotificationId = 9002;

  /// Generate morning brief
  Future<DailyBrief> generateMorningBrief(List<Habit> habits) async {
    final now = DateTime.now();
    final greeting = _getTimeBasedGreeting();

    // Find habits scheduled for today that aren't completed
    final todayWeekday = now.weekday;
    final pendingHabits = habits
        .where(
            (h) => h.frequencyDays.contains(todayWeekday) && !h.completedToday)
        .toList();

    // Get health data
    final healthService = HealthService.instance;
    int? todaySteps;
    double? todaySleep;

    try {
      todaySteps = await healthService.getTodaySteps();
      todaySleep = await healthService.getTodaySleep();
    } catch (e) {
      debugPrint('Error fetching health data for brief: $e');
    }

    // Generate motivational message
    final motivationalMessage = await _generateMotivationalMessage(
      pendingCount: pendingHabits.length,
      todaySteps: todaySteps,
      todaySleep: todaySleep,
    );

    // Generate health tip if we have data
    String? healthTip;
    if (todaySleep != null && todaySleep < 7) {
      healthTip =
          "You slept ${todaySleep.toStringAsFixed(1)} hours. Try to get 7-8 hours tonight! 😴";
    } else if (todaySteps != null && todaySteps < 2000) {
      healthTip =
          "Start your day with a short walk! Even 10 minutes helps. 🚶‍♀️";
    }

    return DailyBrief(
      greeting: greeting,
      pendingHabitsCount: pendingHabits.length,
      pendingHabitNames:
          pendingHabits.take(3).map((h) => "${h.emoji} ${h.name}").toList(),
      motivationalMessage: motivationalMessage,
      healthTip: healthTip,
      todaySteps: todaySteps,
      todaySleep: todaySleep,
      generatedAt: now,
    );
  }

  /// Generate evening reflection
  Future<EveningReflection> generateEveningReflection(
      List<Habit> habits) async {
    final now = DateTime.now();
    final todayWeekday = now.weekday;

    // Find habits scheduled for today
    final todayHabits =
        habits.where((h) => h.frequencyDays.contains(todayWeekday)).toList();

    final completedHabits = todayHabits.where((h) => h.completedToday).toList();
    final missedHabits = todayHabits.where((h) => !h.completedToday).toList();

    // Get health data
    final healthService = HealthService.instance;
    int? todaySteps;
    try {
      todaySteps = await healthService.getTodaySteps();
    } catch (e) {
      debugPrint('Error fetching health data: $e');
    }

    // Generate reflection prompt
    final reflectionPrompt = await _generateReflectionPrompt(
      completedCount: completedHabits.length,
      totalCount: todayHabits.length,
      missedHabitNames: missedHabits.map((h) => h.name).toList(),
    );

    // Generate celebration message
    final celebrationMessage = _getCelebrationMessage(
      completedHabits.length,
      todayHabits.length,
    );

    return EveningReflection(
      completedCount: completedHabits.length,
      totalCount: todayHabits.length,
      completedHabits:
          completedHabits.map((h) => "${h.emoji} ${h.name}").toList(),
      missedHabits: missedHabits.map((h) => "${h.emoji} ${h.name}").toList(),
      reflectionPrompt: reflectionPrompt,
      celebrationMessage: celebrationMessage,
      todaySteps: todaySteps,
      generatedAt: now,
    );
  }

  /// Schedule morning brief notification
  Future<void> scheduleMorningBrief(
      {TimeOfDay time = const TimeOfDay(hour: 8, minute: 0)}) async {
    await LocalNotificationService.scheduleDailyNotification(
      id: _morningBriefNotificationId,
      title: '☀️ Good Morning!',
      body: 'Rise and shine! Check your habits for today.',
      time: time,
    );
    debugPrint('Morning brief scheduled for ${time.hour}:${time.minute}');
  }

  /// Schedule evening reflection notification
  Future<void> scheduleEveningReflection(
      {TimeOfDay time = const TimeOfDay(hour: 20, minute: 0)}) async {
    await LocalNotificationService.scheduleDailyNotification(
      id: _eveningReflectionNotificationId,
      title: '🌙 Time to Reflect',
      body: 'How did today go? Take a moment to review.',
      time: time,
    );
    debugPrint('Evening reflection scheduled for ${time.hour}:${time.minute}');
  }

  /// Schedule both daily notifications
  Future<void> scheduleDailyNotifications({
    TimeOfDay morningTime = const TimeOfDay(hour: 8, minute: 0),
    TimeOfDay eveningTime = const TimeOfDay(hour: 20, minute: 0),
  }) async {
    await scheduleMorningBrief(time: morningTime);
    await scheduleEveningReflection(time: eveningTime);
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning! ☀️';
    } else if (hour < 17) {
      return 'Good afternoon! 🌤️';
    } else {
      return 'Good evening! 🌙';
    }
  }

  Future<String> _generateMotivationalMessage({
    required int pendingCount,
    int? todaySteps,
    double? todaySleep,
  }) async {
    if (!AppConfig.isApiConfigured || !AppConfig.useAIForCoaching) {
      return _getFallbackMotivation(pendingCount);
    }

    try {
      String context = 'Pending habits today: $pendingCount. ';
      if (todaySleep != null) {
        context += 'Slept ${todaySleep.toStringAsFixed(1)} hours. ';
      }
      if (todaySteps != null && todaySteps > 0) {
        context += 'Already walked $todaySteps steps. ';
      }

      final response = await GroqAIService.instance.generateResponse(
        systemPrompt:
            'You are Wind, a calm, supportive habit guide. Generate a brief, personalized morning motivation in 1-2 sentences with emojis.',
        userPrompt: 'Generate a morning motivation for someone with: $context',
        maxTokens: 60,
        temperature: 0.8,
      );

      return response?.trim() ?? _getFallbackMotivation(pendingCount);
    } catch (e) {
      debugPrint('Error generating motivation: $e');
      return _getFallbackMotivation(pendingCount);
    }
  }

  String _getFallbackMotivation(int pendingCount) {
    if (pendingCount == 0) {
      return "You're all caught up! Enjoy your day! 🎉";
    } else if (pendingCount == 1) {
      return "Just 1 habit to tackle today. You've got this! 💪";
    } else if (pendingCount <= 3) {
      return "$pendingCount habits await. Small wins lead to big changes! ✨";
    } else {
      return "A full day ahead with $pendingCount habits. Take it one step at a time! 🚀";
    }
  }

  Future<String> _generateReflectionPrompt({
    required int completedCount,
    required int totalCount,
    required List<String> missedHabitNames,
  }) async {
    if (!AppConfig.isApiConfigured || !AppConfig.useAIForCoaching) {
      return _getFallbackReflection(completedCount, totalCount);
    }

    try {
      String context =
          'Completed $completedCount of $totalCount habits today. ';
      if (missedHabitNames.isNotEmpty) {
        context += 'Missed: ${missedHabitNames.join(", ")}. ';
      }

      final response = await GroqAIService.instance.generateResponse(
        systemPrompt:
            'You are Wind, a calm, supportive habit guide. Generate a brief evening reflection prompt (1-2 sentences) that is encouraging regardless of performance. Use emojis.',
        userPrompt: 'Generate an evening reflection for: $context',
        maxTokens: 60,
        temperature: 0.7,
      );

      return response?.trim() ??
          _getFallbackReflection(completedCount, totalCount);
    } catch (e) {
      debugPrint('Error generating reflection: $e');
      return _getFallbackReflection(completedCount, totalCount);
    }
  }

  String _getFallbackReflection(int completed, int total) {
    final rate = total > 0 ? completed / total : 0.0;

    if (rate >= 1.0) {
      return "Perfect day! 🌟 What made today work so well?";
    } else if (rate >= 0.7) {
      return "Great progress today! 💪 What's one thing you're proud of?";
    } else if (rate >= 0.5) {
      return "Halfway there! 📈 What will help you tomorrow?";
    } else {
      return "Tomorrow is a fresh start 🌱 Be kind to yourself.";
    }
  }

  String _getCelebrationMessage(int completed, int total) {
    final rate = total > 0 ? completed / total : 0.0;

    if (rate >= 1.0) {
      return "🎉 Perfect day! All $total habits complete!";
    } else if (rate >= 0.8) {
      return "🔥 Amazing! You completed $completed of $total habits!";
    } else if (rate >= 0.5) {
      return "💪 Good effort! $completed habits done today.";
    } else if (completed > 0) {
      return "✨ Every step counts! $completed habit${completed > 1 ? 's' : ''} complete.";
    } else {
      return "🌱 Tomorrow is a new opportunity.";
    }
  }
}
