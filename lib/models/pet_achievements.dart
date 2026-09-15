import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Pet achievement
class PetAchievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int xpReward;
  final bool Function(PetAchievementStats) checkUnlocked;

  const PetAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.xpReward,
    required this.checkUnlocked,
  });
}

/// Stats used to check achievement unlocks
class PetAchievementStats {
  final int totalCompletions;
  final int longestStreak;
  final int daysWithPet;
  final int totalFeedCount;
  final int totalPlayCount;
  final int currentLevel;

  const PetAchievementStats({
    this.totalCompletions = 0,
    this.longestStreak = 0,
    this.daysWithPet = 0,
    this.totalFeedCount = 0,
    this.totalPlayCount = 0,
    this.currentLevel = 1,
  });
}

/// Pet diary entry
class PetDiaryEntry {
  final DateTime date;
  final String event;
  final String emoji;

  PetDiaryEntry({
    required this.date,
    required this.event,
    required this.emoji,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'event': event,
        'emoji': emoji,
      };

  factory PetDiaryEntry.fromJson(Map<String, dynamic> json) => PetDiaryEntry(
        date: DateTime.parse(json['date']),
        event: json['event'],
        emoji: json['emoji'],
      );
}

/// Pet achievements and diary service
class PetAchievementService {
  static final instance = PetAchievementService._();
  PetAchievementService._();

  static const String _achievementsKey = 'pet_unlocked_achievements';
  static const String _diaryKey = 'pet_diary_entries';
  static const String _statsKey = 'pet_stats';

  Set<String> _unlockedAchievementIds = {};
  List<PetDiaryEntry> _diaryEntries = [];
  PetAchievementStats _stats = const PetAchievementStats();

  Set<String> get unlockedAchievementIds => _unlockedAchievementIds;
  List<PetDiaryEntry> get diaryEntries => _diaryEntries;
  PetAchievementStats get stats => _stats;

  // All achievements
  static final List<PetAchievement> achievements = [
    PetAchievement(
      id: 'first_steps',
      name: 'First Steps',
      description: 'Complete your first habit',
      emoji: '👣',
      xpReward: 10,
      checkUnlocked: (s) => s.totalCompletions >= 1,
    ),
    PetAchievement(
      id: 'week_warrior',
      name: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      emoji: '🗓️',
      xpReward: 50,
      checkUnlocked: (s) => s.longestStreak >= 7,
    ),
    PetAchievement(
      id: 'month_master',
      name: 'Month Master',
      description: 'Maintain a 30-day streak',
      emoji: '📅',
      xpReward: 200,
      checkUnlocked: (s) => s.longestStreak >= 30,
    ),
    PetAchievement(
      id: 'caring_owner',
      name: 'Caring Owner',
      description: 'Feed your pet 10 times',
      emoji: '🍖',
      xpReward: 30,
      checkUnlocked: (s) => s.totalFeedCount >= 10,
    ),
    PetAchievement(
      id: 'playful_friend',
      name: 'Playful Friend',
      description: 'Play with your pet 10 times',
      emoji: '🎾',
      xpReward: 30,
      checkUnlocked: (s) => s.totalPlayCount >= 10,
    ),
    PetAchievement(
      id: 'habit_hero',
      name: 'Habit Hero',
      description: 'Complete 50 habits total',
      emoji: '🦸',
      xpReward: 100,
      checkUnlocked: (s) => s.totalCompletions >= 50,
    ),
    PetAchievement(
      id: 'consistency_champion',
      name: 'Consistency Champion',
      description: 'Complete 100 habits total',
      emoji: '🏆',
      xpReward: 200,
      checkUnlocked: (s) => s.totalCompletions >= 100,
    ),
    PetAchievement(
      id: 'dedicated',
      name: 'Dedicated',
      description: 'Spend 14 days with your pet',
      emoji: '💕',
      xpReward: 50,
      checkUnlocked: (s) => s.daysWithPet >= 14,
    ),
    PetAchievement(
      id: 'level_10',
      name: 'Rising Star',
      description: 'Reach level 10',
      emoji: '⭐',
      xpReward: 100,
      checkUnlocked: (s) => s.currentLevel >= 10,
    ),
    PetAchievement(
      id: 'level_25',
      name: 'Superstar',
      description: 'Reach level 25',
      emoji: '🌟',
      xpReward: 250,
      checkUnlocked: (s) => s.currentLevel >= 25,
    ),
    PetAchievement(
      id: 'level_50',
      name: 'Legend',
      description: 'Reach level 50',
      emoji: '👑',
      xpReward: 500,
      checkUnlocked: (s) => s.currentLevel >= 50,
    ),
  ];

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();

    // Load unlocked achievements
    final achievementsList = prefs.getStringList(_achievementsKey) ?? [];
    _unlockedAchievementIds = achievementsList.toSet();

    // Load diary entries
    final diaryJson = prefs.getStringList(_diaryKey) ?? [];
    _diaryEntries = diaryJson
        .map((json) => PetDiaryEntry.fromJson(jsonDecode(json)))
        .toList();

    // Load stats
    final statsJson = prefs.getString(_statsKey);
    if (statsJson != null) {
      final map = jsonDecode(statsJson);
      _stats = PetAchievementStats(
        totalCompletions: map['totalCompletions'] ?? 0,
        longestStreak: map['longestStreak'] ?? 0,
        daysWithPet: map['daysWithPet'] ?? 0,
        totalFeedCount: map['totalFeedCount'] ?? 0,
        totalPlayCount: map['totalPlayCount'] ?? 0,
        currentLevel: map['currentLevel'] ?? 1,
      );
    }

    debugPrint(
        '🏆 Pet achievements loaded: ${_unlockedAchievementIds.length} unlocked');
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _achievementsKey, _unlockedAchievementIds.toList());
    await prefs.setStringList(
      _diaryKey,
      _diaryEntries.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await prefs.setString(
        _statsKey,
        jsonEncode({
          'totalCompletions': _stats.totalCompletions,
          'longestStreak': _stats.longestStreak,
          'daysWithPet': _stats.daysWithPet,
          'totalFeedCount': _stats.totalFeedCount,
          'totalPlayCount': _stats.totalPlayCount,
          'currentLevel': _stats.currentLevel,
        }));
  }

  /// Update stats and check for new achievements
  Future<List<PetAchievement>> updateStats({
    int? totalCompletions,
    int? longestStreak,
    int? daysWithPet,
    bool incrementFeed = false,
    bool incrementPlay = false,
    int? currentLevel,
  }) async {
    _stats = PetAchievementStats(
      totalCompletions: totalCompletions ?? _stats.totalCompletions,
      longestStreak: longestStreak ?? _stats.longestStreak,
      daysWithPet: daysWithPet ?? _stats.daysWithPet,
      totalFeedCount:
          incrementFeed ? _stats.totalFeedCount + 1 : _stats.totalFeedCount,
      totalPlayCount:
          incrementPlay ? _stats.totalPlayCount + 1 : _stats.totalPlayCount,
      currentLevel: currentLevel ?? _stats.currentLevel,
    );

    // Check for newly unlocked achievements
    final newlyUnlocked = <PetAchievement>[];
    for (final achievement in achievements) {
      if (!_unlockedAchievementIds.contains(achievement.id) &&
          achievement.checkUnlocked(_stats)) {
        _unlockedAchievementIds.add(achievement.id);
        newlyUnlocked.add(achievement);

        // Add diary entry
        addDiaryEntry(
          '🏆 Unlocked: ${achievement.name}',
          achievement.emoji,
        );
      }
    }

    await saveState();
    return newlyUnlocked;
  }

  /// Add diary entry
  void addDiaryEntry(String event, String emoji) {
    _diaryEntries.insert(
        0,
        PetDiaryEntry(
          date: DateTime.now(),
          event: event,
          emoji: emoji,
        ));

    // Keep only last 50 entries
    if (_diaryEntries.length > 50) {
      _diaryEntries = _diaryEntries.take(50).toList();
    }
  }

  bool isAchievementUnlocked(String id) => _unlockedAchievementIds.contains(id);

  List<PetAchievement> get unlockedAchievements => achievements
      .where((a) => _unlockedAchievementIds.contains(a.id))
      .toList();

  List<PetAchievement> get lockedAchievements => achievements
      .where((a) => !_unlockedAchievementIds.contains(a.id))
      .toList();
}
