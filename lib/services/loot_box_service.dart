import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/loot_box.dart';
import '../models/habit.dart';

/// Service for managing loot boxes and rewards
class LootBoxService {
  static final LootBoxService instance = LootBoxService._();
  LootBoxService._();

  static const _prefsKeyPendingBoxes = 'pending_loot_boxes';
  static const _prefsKeyOpenedBoxes = 'opened_loot_boxes';
  static const _prefsKeyActiveMultiplier = 'active_xp_multiplier';
  static const _prefsKeyUnlockedThemes = 'unlocked_themes';
  static const _prefsKeyUnlockedAvatars = 'unlocked_avatars';
  static const _prefsKeyTriggerHistory = 'loot_box_trigger_history';

  List<LootBox> _pendingBoxes = [];
  List<LootBox> _openedBoxes = [];
  XpMultiplier? _activeMultiplier;
  List<String> _unlockedThemes = [];
  List<String> _unlockedAvatars = [];
  Map<String, DateTime> _triggerHistory = {};

  List<LootBox> get pendingBoxes => _pendingBoxes;
  bool get hasPendingBoxes => _pendingBoxes.isNotEmpty;
  XpMultiplier? get activeMultiplier =>
      _activeMultiplier?.isActive == true ? _activeMultiplier : null;
  List<String> get unlockedThemes => _unlockedThemes;
  List<String> get unlockedAvatars => _unlockedAvatars;

  /// Get effective XP multiplier (returns 1 if no active multiplier)
  int get xpMultiplier => activeMultiplier?.multiplier ?? 1;

  /// Initialize service and load from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load pending boxes
    final pendingJson = prefs.getString(_prefsKeyPendingBoxes);
    if (pendingJson != null) {
      final list = jsonDecode(pendingJson) as List;
      _pendingBoxes =
          list.map((e) => LootBox.fromJson(e as Map<String, dynamic>)).toList();
    }

    // Load opened boxes (history)
    final openedJson = prefs.getString(_prefsKeyOpenedBoxes);
    if (openedJson != null) {
      final list = jsonDecode(openedJson) as List;
      _openedBoxes =
          list.map((e) => LootBox.fromJson(e as Map<String, dynamic>)).toList();
    }

    // Load active multiplier
    final multiplierJson = prefs.getString(_prefsKeyActiveMultiplier);
    if (multiplierJson != null) {
      _activeMultiplier = XpMultiplier.fromJson(
          jsonDecode(multiplierJson) as Map<String, dynamic>);
      // Clear if expired
      if (!_activeMultiplier!.isActive) {
        _activeMultiplier = null;
        await prefs.remove(_prefsKeyActiveMultiplier);
      }
    }

    // Load unlocked items
    _unlockedThemes = prefs.getStringList(_prefsKeyUnlockedThemes) ?? [];
    _unlockedAvatars = prefs.getStringList(_prefsKeyUnlockedAvatars) ?? [];

    // Load trigger history
    final historyJson = prefs.getString(_prefsKeyTriggerHistory);
    if (historyJson != null) {
      final map = jsonDecode(historyJson) as Map<String, dynamic>;
      _triggerHistory = map.map(
        (key, value) => MapEntry(key, DateTime.parse(value as String)),
      );
    }

    debugPrint(
        '🎁 LootBoxService initialized: ${_pendingBoxes.length} pending');
  }

  /// Save state to storage
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _prefsKeyPendingBoxes,
      jsonEncode(_pendingBoxes.map((e) => e.toJson()).toList()),
    );

    await prefs.setString(
      _prefsKeyOpenedBoxes,
      jsonEncode(_openedBoxes
          .take(50)
          .map((e) => e.toJson())
          .toList()), // Keep last 50
    );

    if (_activeMultiplier != null && _activeMultiplier!.isActive) {
      await prefs.setString(
        _prefsKeyActiveMultiplier,
        jsonEncode(_activeMultiplier!.toJson()),
      );
    } else {
      await prefs.remove(_prefsKeyActiveMultiplier);
    }

    await prefs.setStringList(_prefsKeyUnlockedThemes, _unlockedThemes);
    await prefs.setStringList(_prefsKeyUnlockedAvatars, _unlockedAvatars);

    await prefs.setString(
      _prefsKeyTriggerHistory,
      jsonEncode(_triggerHistory.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      )),
    );
  }

  /// Check if a loot box should be triggered and create it if so
  LootBox? checkAndTrigger({
    required Habit habit,
    required int newStreak,
    required int previousStreak,
    required int userLevel,
    required int previousLevel,
    required int totalCompletions,
    required bool isPerfectWeek,
  }) {
    LootBoxTrigger? trigger;

    // Check streak milestones
    if (newStreak >= 100 && previousStreak < 100) {
      trigger = LootBoxTrigger.streak100;
    } else if (newStreak >= 30 && previousStreak < 30) {
      trigger = LootBoxTrigger.streak30;
    } else if (newStreak >= 7 && previousStreak < 7) {
      trigger = LootBoxTrigger.streak7;
    }

    // Check level milestones
    if (trigger == null) {
      if (userLevel >= 10 && previousLevel < 10 && (userLevel % 10 == 0)) {
        trigger = LootBoxTrigger.levelUp10;
      } else if (userLevel % 5 == 0 && previousLevel % 5 != 0) {
        trigger = LootBoxTrigger.levelUp5;
      }
    }

    // Check perfect week (called at end of week)
    if (trigger == null && isPerfectWeek) {
      trigger = LootBoxTrigger.perfectWeek;
    }

    // Check total completions milestone
    if (trigger == null &&
        totalCompletions >= 100 &&
        totalCompletions - 1 < 100) {
      trigger = LootBoxTrigger.completions100;
    }

    if (trigger != null) {
      // Check if we already triggered this today
      final triggerKey = '${trigger.name}_${habit.id}';
      final lastTriggered = _triggerHistory[triggerKey];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (lastTriggered != null) {
        final lastDate = DateTime(
          lastTriggered.year,
          lastTriggered.month,
          lastTriggered.day,
        );
        if (lastDate == today) {
          debugPrint('🎁 Loot box already triggered today for $triggerKey');
          return null;
        }
      }

      // Create and queue the loot box
      final lootBox = LootBox(
        id: '${trigger.name}_${DateTime.now().millisecondsSinceEpoch}',
        trigger: trigger,
        earnedAt: DateTime.now(),
      );

      _pendingBoxes.add(lootBox);
      _triggerHistory[triggerKey] = now;
      _save();

      debugPrint('🎁 Loot box earned: ${trigger.name}');
      return lootBox;
    }

    return null;
  }

  /// Open a pending loot box and get the reward
  Future<LootBoxReward> openBox(LootBox box) async {
    // Generate reward
    final reward = LootBox.generateReward(box.trigger);

    // Apply reward
    await _applyReward(reward);

    // Move to opened list
    final openedBox = box.open(reward);
    _pendingBoxes.removeWhere((b) => b.id == box.id);
    _openedBoxes.insert(0, openedBox);

    await _save();

    debugPrint(
        '🎁 Opened ${box.trigger.name}: ${reward.name} (${reward.rarity.name})');
    return reward;
  }

  /// Apply a reward
  Future<void> _applyReward(LootBoxReward reward) async {
    switch (reward.type) {
      case RewardType.xpBoost:
        // XP is handled by AppState when reward is claimed
        break;

      case RewardType.streakShield:
        // Streak freeze is handled by AppState when reward is claimed
        break;

      case RewardType.themeUnlock:
        if (reward.assetPath != null &&
            !_unlockedThemes.contains(reward.assetPath)) {
          _unlockedThemes.add(reward.assetPath!);
        }
        break;

      case RewardType.avatarUnlock:
        if (reward.assetPath != null &&
            !_unlockedAvatars.contains(reward.assetPath)) {
          _unlockedAvatars.add(reward.assetPath!);
        }
        break;

      case RewardType.xpMultiplier:
        _activeMultiplier = XpMultiplier(
          multiplier: reward.value,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );
        break;
    }
  }

  /// Check if theme is unlocked
  bool isThemeUnlocked(String themePath) => _unlockedThemes.contains(themePath);

  /// Check if avatar is unlocked
  bool isAvatarUnlocked(String avatarPath) =>
      _unlockedAvatars.contains(avatarPath);

  /// Get next pending box (first in queue)
  LootBox? get nextPendingBox =>
      _pendingBoxes.isNotEmpty ? _pendingBoxes.first : null;

  /// Clear all data (for logout)
  Future<void> clear() async {
    _pendingBoxes.clear();
    _openedBoxes.clear();
    _activeMultiplier = null;
    _unlockedThemes.clear();
    _unlockedAvatars.clear();
    _triggerHistory.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyPendingBoxes);
    await prefs.remove(_prefsKeyOpenedBoxes);
    await prefs.remove(_prefsKeyActiveMultiplier);
    await prefs.remove(_prefsKeyUnlockedThemes);
    await prefs.remove(_prefsKeyUnlockedAvatars);
    await prefs.remove(_prefsKeyTriggerHistory);
  }
}
