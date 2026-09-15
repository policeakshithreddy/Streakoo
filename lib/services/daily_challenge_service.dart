import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_challenge.dart';
import '../models/habit.dart';

/// Service to generate and manage daily challenges via notifications
class DailyChallengeService {
  DailyChallengeService._();
  static final DailyChallengeService instance = DailyChallengeService._();

  static const String _prefsKey = 'daily_challenge';
  static const String _enabledKey = 'daily_challenges_enabled';
  static const String _timeKey = 'daily_challenges_time';

  DailyChallenge? _todayChallenge;
  bool _enabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 7, minute: 0);

  final Random _random = Random();

  /// Initialize service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;

    // Load notification time
    final timeMinutes = prefs.getInt(_timeKey);
    if (timeMinutes != null) {
      _notificationTime = TimeOfDay(
        hour: timeMinutes ~/ 60,
        minute: timeMinutes % 60,
      );
    }

    // Load today's challenge
    final challengeJson = prefs.getString(_prefsKey);
    if (challengeJson != null) {
      try {
        final map = jsonDecode(challengeJson);
        _todayChallenge = DailyChallenge.fromJson(map);

        // Check if expired
        if (_todayChallenge!.isExpired) {
          _todayChallenge = null;
        }
      } catch (e) {
        debugPrint('⚠️ DailyChallengeService: Error loading challenge: $e');
      }
    }

    debugPrint('🎯 DailyChallengeService initialized (enabled: $_enabled)');
  }

  /// Whether daily challenges are enabled
  bool get isEnabled => _enabled;

  /// Notification time
  TimeOfDay get notificationTime => _notificationTime;

  /// Today's challenge (if any)
  DailyChallenge? get todayChallenge => _todayChallenge;

  /// Enable/disable daily challenges
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    debugPrint('🎯 Daily challenges ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set notification time
  Future<void> setNotificationTime(TimeOfDay time) async {
    _notificationTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeKey, time.hour * 60 + time.minute);
    debugPrint(
        '🎯 Challenge notification time set to ${time.hour}:${time.minute}');
  }

  /// Generate a new daily challenge based on user habits
  Future<DailyChallenge> generateDailyChallenge(List<Habit> habits) async {
    // Choose challenge type based on habits and day of week
    final type = _selectChallengeType(habits);
    final challenge = _createChallenge(type, habits);

    _todayChallenge = challenge;
    await _saveChallenge(challenge);

    debugPrint('🎯 Generated new challenge: ${challenge.title}');
    return challenge;
  }

  ChallengeType _selectChallengeType(List<Habit> habits) {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    // Weight-based selection
    final options = <ChallengeType, int>{};

    // Always available
    options[ChallengeType.perfectDay] = 20;
    options[ChallengeType.completionCount] = 30;

    // Time-based
    if (now.hour < 10) {
      options[ChallengeType.earlyBird] = 40;
    }

    // Weekend special
    if (isWeekend) {
      options[ChallengeType.weekendWarrior] = 35;
    }

    // Streak-based (if user has streaks)
    final hasStreaks = habits.any((h) => h.streak >= 3);
    if (hasStreaks) {
      options[ChallengeType.streakBoost] = 25;
      options[ChallengeType.consistency] = 20;
    }

    // Calculate total weight and pick
    final totalWeight = options.values.fold(0, (a, b) => a + b);
    var pick = _random.nextInt(totalWeight);

    for (final entry in options.entries) {
      pick -= entry.value;
      if (pick < 0) return entry.key;
    }

    return ChallengeType.completionCount;
  }

  DailyChallenge _createChallenge(ChallengeType type, List<Habit> habits) {
    final habitsCount = habits.length;

    switch (type) {
      case ChallengeType.perfectDay:
        return DailyChallenge(
          type: type,
          title: 'Perfect Day 🌟',
          description: 'Complete all $habitsCount habits today!',
          emoji: '🌟',
          xpReward: 200,
          targetValue: habitsCount,
        );

      case ChallengeType.earlyBird:
        final target = (habitsCount * 0.5).ceil().clamp(1, 5);
        return DailyChallenge(
          type: type,
          title: 'Early Bird 🌅',
          description: 'Complete $target habits before 10 AM',
          emoji: '🌅',
          xpReward: 150,
          targetValue: target,
        );

      case ChallengeType.completionCount:
        final target = (habitsCount * 0.7).ceil().clamp(2, habitsCount);
        return DailyChallenge(
          type: type,
          title: 'Habit Hunter 🎯',
          description: 'Complete at least $target habits today',
          emoji: '🎯',
          xpReward: 100,
          targetValue: target,
        );

      case ChallengeType.streakBoost:
        return DailyChallenge(
          type: type,
          title: 'Streak Guardian 🔥',
          description: 'Keep all your active streaks alive!',
          emoji: '🔥',
          xpReward: 175,
          targetValue: habits.where((h) => h.streak > 0).length,
        );

      case ChallengeType.weekendWarrior:
        return DailyChallenge(
          type: type,
          title: 'Weekend Warrior ⚔️',
          description: 'Don\'t let the weekend break your habits!',
          emoji: '⚔️',
          xpReward: 125,
          targetValue: (habitsCount * 0.6).ceil(),
        );

      case ChallengeType.consistency:
        // Find habit with longest streak
        final bestHabit = habits.reduce((a, b) => a.streak > b.streak ? a : b);
        return DailyChallenge(
          type: type,
          title: 'Consistency King 👑',
          description: 'Keep your "${bestHabit.name}" streak going!',
          emoji: '👑',
          xpReward: 150,
          targetValue: 1, // Just need to complete that habit
        );

      case ChallengeType.focusTaskMaster:
        return DailyChallenge(
          type: ChallengeType.completionCount,
          title: 'Goal Getter 💪',
          description: 'Complete 3 habits today',
          emoji: '💪',
          xpReward: 100,
          targetValue: 3,
        );
    }
  }

  /// Get notification message for today's challenge
  String getChallengeNotificationMessage() {
    if (_todayChallenge == null) return '';

    final c = _todayChallenge!;
    return '${c.emoji} Today\'s Challenge: ${c.title}\n${c.description}\nReward: +${c.xpReward} XP';
  }

  /// Check and update challenge progress
  Future<void> updateProgress(List<Habit> habits) async {
    if (_todayChallenge == null || _todayChallenge!.isCompleted) return;

    int progress = 0;
    final type = _todayChallenge!.type;

    switch (type) {
      case ChallengeType.perfectDay:
      case ChallengeType.completionCount:
      case ChallengeType.weekendWarrior:
        progress = habits.where((h) => h.completedToday).length;
        break;

      case ChallengeType.earlyBird:
        // Count completions before 10 AM (stored in habit)
        progress = habits.where((h) => h.completedToday).length;
        // Note: For accurate early bird tracking, would need completion timestamps
        break;

      case ChallengeType.streakBoost:
        // Count maintained streaks
        progress = habits.where((h) => h.streak > 0 && h.completedToday).length;
        break;

      case ChallengeType.consistency:
        // Check if target habit is completed
        progress = habits.any((h) => h.completedToday) ? 1 : 0;
        break;

      case ChallengeType.focusTaskMaster:
        progress = habits.where((h) => h.completedToday).length;
        break;
    }

    final isCompleted = progress >= _todayChallenge!.targetValue;

    _todayChallenge = _todayChallenge!.copyWith(
      currentProgress: progress,
      isCompleted: isCompleted,
    );

    await _saveChallenge(_todayChallenge!);

    if (isCompleted) {
      debugPrint('🎉 Challenge completed! +${_todayChallenge!.xpReward} XP');
    }
  }

  /// Get XP reward if challenge is completed
  int? getCompletedReward() {
    if (_todayChallenge?.isCompleted == true) {
      return _todayChallenge!.xpReward;
    }
    return null;
  }

  Future<void> _saveChallenge(DailyChallenge challenge) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(challenge.toJson()));
  }

  /// Clear today's challenge (for testing)
  Future<void> clearChallenge() async {
    _todayChallenge = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
