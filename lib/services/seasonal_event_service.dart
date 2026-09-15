import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/seasonal_event.dart';

/// Service to manage seasonal events and track badge progress
class SeasonalEventService {
  SeasonalEventService._();
  static final SeasonalEventService instance = SeasonalEventService._();

  static const String _badgesKey = 'seasonal_badges';

  SeasonalEvent? _activeEvent;
  Map<String, bool> _unlockedBadges = {};
  Map<String, int> _badgeProgress = {};

  /// Currently active event (if any)
  SeasonalEvent? get activeEvent => _activeEvent;

  /// Check if there's an active event
  bool get hasActiveEvent => _activeEvent != null;

  /// XP multiplier from active event (1.0 if none)
  double get xpMultiplier => _activeEvent?.xpMultiplier ?? 1.0;

  /// Initialize service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load unlocked badges
    final badgesJson = prefs.getString(_badgesKey);
    if (badgesJson != null) {
      try {
        _unlockedBadges = Map<String, bool>.from(jsonDecode(badgesJson));
      } catch (e) {
        debugPrint('⚠️ SeasonalEventService: Error loading badges: $e');
      }
    }

    // Load badge progress
    final progressJson = prefs.getString('${_badgesKey}_progress');
    if (progressJson != null) {
      try {
        _badgeProgress = Map<String, int>.from(jsonDecode(progressJson));
      } catch (e) {
        debugPrint('⚠️ SeasonalEventService: Error loading progress: $e');
      }
    }

    // Check for active event using the new function
    _activeEvent = getActiveSeasonalEvent();

    debugPrint(
        '🎄 SeasonalEventService initialized (active: ${_activeEvent?.name ?? 'none'})');
  }

  /// Get all events
  List<SeasonalEvent> get allEvents => getSeasonalEvents();

  /// Check if a badge is unlocked
  bool isBadgeUnlocked(String badgeId) => _unlockedBadges[badgeId] ?? false;

  /// Get badge progress (0.0 - 1.0)
  double getBadgeProgress(String badgeId, int targetValue) {
    final current = _badgeProgress[badgeId] ?? 0;
    return (current / targetValue).clamp(0.0, 1.0);
  }

  /// Update progress for all active event badges
  Future<List<SeasonalBadge>> updateProgress({
    required int habitsCompletedToday,
    required int currentStreak,
    required int perfectDaysThisEvent,
    required int xpEarnedThisEvent,
  }) async {
    if (_activeEvent == null) return [];

    List<SeasonalBadge> newlyUnlocked = [];

    for (final badge in _activeEvent!.exclusiveBadges) {
      if (isBadgeUnlocked(badge.id)) continue;

      int progress = 0;
      bool unlocked = false;

      switch (badge.requirement.type) {
        case BadgeRequirementType.completeHabits:
          final stored = _badgeProgress[badge.id] ?? 0;
          progress = stored + habitsCompletedToday;
          unlocked = progress >= badge.requirement.targetValue;
          break;

        case BadgeRequirementType.maintainStreak:
          progress = currentStreak;
          unlocked = progress >= badge.requirement.targetValue;
          break;

        case BadgeRequirementType.perfectDays:
          progress = perfectDaysThisEvent;
          unlocked = progress >= badge.requirement.targetValue;
          break;

        case BadgeRequirementType.totalXP:
          progress = xpEarnedThisEvent;
          unlocked = progress >= badge.requirement.targetValue;
          break;
      }

      _badgeProgress[badge.id] = progress;

      if (unlocked) {
        _unlockedBadges[badge.id] = true;
        newlyUnlocked.add(badge);
        debugPrint('🏅 Badge unlocked: ${badge.name}!');
      }
    }

    await _save();
    return newlyUnlocked;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_badgesKey, jsonEncode(_unlockedBadges));
    await prefs.setString('${_badgesKey}_progress', jsonEncode(_badgeProgress));
  }

  /// Get all unlocked badges
  List<SeasonalBadge> get allUnlockedBadges {
    final badges = <SeasonalBadge>[];
    for (final event in getSeasonalEvents()) {
      for (final badge in event.exclusiveBadges) {
        if (isBadgeUnlocked(badge.id)) {
          badges.add(badge);
        }
      }
    }
    return badges;
  }

  /// Get event theme colors for UI
  (Color, Color)? get eventThemeColors {
    if (_activeEvent == null) return null;
    return (_activeEvent!.primaryColor, _activeEvent!.secondaryColor);
  }
}
