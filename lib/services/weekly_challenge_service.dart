import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/weekly_challenge.dart';
import '../models/habit.dart';
import 'local_notification_service.dart';

class WeeklyChallengeService {
  WeeklyChallengeService._();
  static final WeeklyChallengeService instance = WeeklyChallengeService._();

  static const String _challengeKey = 'weekly_challenge';
  static const int _mondayChallengeNotificationId = 9003;
  static const int _progressNotificationId = 9004;

  WeeklyChallenge? _currentChallenge;

  /// Get current challenge
  WeeklyChallenge? get currentChallenge => _currentChallenge;

  /// Initialize and load saved challenge
  Future<void> initialize() async {
    await _loadChallenge();

    // Check if we need a new challenge (new week)
    if (_currentChallenge == null || !_currentChallenge!.isActive) {
      await generateNewChallenge();
    }
  }

  /// Generate a new weekly challenge
  Future<WeeklyChallenge> generateNewChallenge({List<Habit>? habits}) async {
    final now = DateTime.now();
    final monday = _getMonday(now);
    final sunday = monday.add(const Duration(days: 6));

    // Get all templates
    final templates = ChallengeTemplates.getTemplates(monday, sunday);

    // Pick a random challenge (can be made smarter based on user history)
    final random = Random();
    final selectedChallenge = templates[random.nextInt(templates.length)];

    _currentChallenge = selectedChallenge;
    await _saveChallenge();

    debugPrint('Generated new challenge: ${selectedChallenge.title}');
    return selectedChallenge;
  }

  /// Update challenge progress based on habits
  Future<void> updateProgress(List<Habit> habits) async {
    if (_currentChallenge == null || _currentChallenge!.isCompleted) return;

    double newProgress = 0.0;

    switch (_currentChallenge!.type) {
      case ChallengeType.perfectWeek:
        newProgress = _calculatePerfectWeekProgress(habits);
        break;
      case ChallengeType.consistencyKing:
        newProgress = _calculateConsistencyProgress(habits);
        break;
      case ChallengeType.streakBuilder:
        newProgress = _calculateStreakProgress(habits);
        break;
      case ChallengeType.healthHero:
        // Health hero progress would need health service integration
        newProgress = _currentChallenge!.currentProgress;
        break;
      case ChallengeType.earlyBird:
        newProgress = _currentChallenge!.currentProgress;
        break;
      case ChallengeType.focusMaster:
        newProgress = _currentChallenge!.currentProgress;
        break;
    }

    final isNowComplete = newProgress >= _currentChallenge!.targetProgress;

    _currentChallenge = _currentChallenge!.copyWith(
      currentProgress: newProgress,
      isCompleted: isNowComplete,
    );

    await _saveChallenge();

    // Check for completion
    if (isNowComplete) {
      debugPrint(
          'Challenge completed! XP reward: ${_currentChallenge!.xpReward}');
    }
  }

  double _calculatePerfectWeekProgress(List<Habit> habits) {
    final monday = _getMonday(DateTime.now());
    final now = DateTime.now();

    int totalExpected = 0;
    int totalCompleted = 0;

    for (final habit in habits) {
      for (int i = 0; i <= now.weekday - 1; i++) {
        final day = monday.add(Duration(days: i));
        if (habit.frequencyDays.contains(day.weekday)) {
          totalExpected++;
          final dayKey = _formatDateKey(day);
          if (habit.completionDates.contains(dayKey)) {
            totalCompleted++;
          }
        }
      }
    }

    return totalExpected > 0 ? totalCompleted / totalExpected : 0.0;
  }

  double _calculateConsistencyProgress(List<Habit> habits) {
    // Count consecutive days with at least one completion
    int maxConsecutive = 0;
    int currentConsecutive = 0;

    final monday = _getMonday(DateTime.now());
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      if (day.isAfter(DateTime.now())) break;

      final dayKey = _formatDateKey(day);
      bool anyCompleted = habits.any((h) =>
          h.frequencyDays.contains(day.weekday) &&
          h.completionDates.contains(dayKey));

      if (anyCompleted) {
        currentConsecutive++;
        maxConsecutive = max(maxConsecutive, currentConsecutive);
      } else {
        currentConsecutive = 0;
      }
    }

    return maxConsecutive.toDouble();
  }

  double _calculateStreakProgress(List<Habit> habits) {
    int maxStreak = 0;
    for (final habit in habits) {
      if (habit.streak > maxStreak) {
        maxStreak = habit.streak;
      }
    }
    return maxStreak.toDouble();
  }

  /// Schedule Monday challenge notification
  Future<void> scheduleMondayNotification() async {
    await LocalNotificationService.scheduleDailyNotification(
      id: _mondayChallengeNotificationId,
      title: '🎯 New Weekly Challenge!',
      body: 'Your challenge is ready. Complete it for bonus XP!',
      time: const TimeOfDay(hour: 9, minute: 0),
    );
  }

  /// Send progress notification (Thursday check-in)
  Future<void> scheduleProgressNotification() async {
    await LocalNotificationService.scheduleDailyNotification(
      id: _progressNotificationId,
      title: '📊 Challenge Progress',
      body: 'Check how close you are to completing your weekly challenge!',
      time: const TimeOfDay(hour: 18, minute: 0),
    );
  }

  Future<void> _loadChallenge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_challengeKey);
      if (json != null) {
        _currentChallenge = WeeklyChallenge.fromJson(jsonDecode(json));
      }
    } catch (e) {
      debugPrint('Error loading challenge: $e');
    }
  }

  Future<void> _saveChallenge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentChallenge != null) {
        await prefs.setString(
            _challengeKey, jsonEncode(_currentChallenge!.toJson()));
      }
    } catch (e) {
      debugPrint('Error saving challenge: $e');
    }
  }

  DateTime _getMonday(DateTime date) {
    final daysFromMonday = (date.weekday - DateTime.monday) % 7;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));
  }

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
