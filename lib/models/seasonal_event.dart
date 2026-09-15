import 'package:flutter/material.dart';

/// Types of seasonal events
enum SeasonalEventType {
  spring('Spring Refresh', '🌸'),
  summer('Summer Challenge', '☀️'),
  winter('Winter Warmth', '❄️');

  final String defaultName;
  final String emoji;

  const SeasonalEventType(this.defaultName, this.emoji);
}

/// A seasonal event with special badges and bonuses
class SeasonalEvent {
  final String id;
  final SeasonalEventType type;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<SeasonalBadge> exclusiveBadges;
  final double xpMultiplier;
  final Color primaryColor;
  final Color secondaryColor;

  const SeasonalEvent({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.exclusiveBadges,
    this.xpMultiplier = 1.0,
    required this.primaryColor,
    required this.secondaryColor,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  double get progressPercent {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;

    final totalDuration = endDate.difference(startDate).inSeconds;
    final elapsed = now.difference(startDate).inSeconds;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }
}

/// A badge exclusive to a seasonal event
class SeasonalBadge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final BadgeRequirement requirement;
  final int xpReward;
  final bool isUnlocked;

  const SeasonalBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.requirement,
    this.xpReward = 100,
    this.isUnlocked = false,
  });

  SeasonalBadge copyWith({bool? isUnlocked}) {
    return SeasonalBadge(
      id: id,
      name: name,
      emoji: emoji,
      description: description,
      requirement: requirement,
      xpReward: xpReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

/// Requirements to unlock a badge
class BadgeRequirement {
  final BadgeRequirementType type;
  final int targetValue;

  const BadgeRequirement({
    required this.type,
    required this.targetValue,
  });
}

enum BadgeRequirementType {
  completeHabits('Complete habits', 'habit'),
  maintainStreak('Maintain streak', 'day'),
  perfectDays('Perfect days', 'day'),
  totalXP('Earn XP', 'XP');

  final String label;
  final String unit;

  const BadgeRequirementType(this.label, this.unit);
}

/// Get seasonal events - returns only the current season's event
/// Spring: Mar 20 - Jun 20
/// Summer: Jun 21 - Sep 22
/// Winter: Dec 21 - Mar 19
List<SeasonalEvent> getSeasonalEvents() {
  final now = DateTime.now();
  final year = now.year;

  return [
    // Spring Refresh (March 20 - June 20)
    SeasonalEvent(
      id: 'spring_$year',
      type: SeasonalEventType.spring,
      name: 'Spring Refresh 🌸',
      description: 'Bloom into better habits this spring!',
      startDate: DateTime(year, 3, 20),
      endDate: DateTime(year, 6, 20, 23, 59, 59),
      xpMultiplier: 1.3,
      primaryColor: const Color(0xFFFF69B4),
      secondaryColor: const Color(0xFF98FB98),
      exclusiveBadges: [
        const SeasonalBadge(
          id: 'spring_bloom',
          name: 'Spring Bloom',
          emoji: '🌷',
          description: 'Complete 30 habits during spring',
          requirement: BadgeRequirement(
            type: BadgeRequirementType.completeHabits,
            targetValue: 30,
          ),
          xpReward: 200,
        ),
        const SeasonalBadge(
          id: 'fresh_start',
          name: 'Fresh Start',
          emoji: '🌱',
          description: 'Maintain a 14-day streak',
          requirement: BadgeRequirement(
            type: BadgeRequirementType.maintainStreak,
            targetValue: 14,
          ),
          xpReward: 300,
        ),
      ],
    ),

    // Summer Challenge (June 21 - September 22)
    SeasonalEvent(
      id: 'summer_$year',
      type: SeasonalEventType.summer,
      name: 'Summer Challenge ☀️',
      description: 'Stay strong through summer!',
      startDate: DateTime(year, 6, 21),
      endDate: DateTime(year, 9, 22, 23, 59, 59),
      xpMultiplier: 1.5,
      primaryColor: const Color(0xFFFFA500),
      secondaryColor: const Color(0xFF00CED1),
      exclusiveBadges: [
        const SeasonalBadge(
          id: 'summer_warrior',
          name: 'Summer Warrior',
          emoji: '🏖️',
          description: 'Complete 50 habits during summer',
          requirement: BadgeRequirement(
            type: BadgeRequirementType.completeHabits,
            targetValue: 50,
          ),
          xpReward: 300,
        ),
        const SeasonalBadge(
          id: 'heat_streak',
          name: 'Heat Streak',
          emoji: '🔥',
          description: 'Maintain a 21-day streak',
          requirement: BadgeRequirement(
            type: BadgeRequirementType.maintainStreak,
            targetValue: 21,
          ),
          xpReward: 400,
        ),
        const SeasonalBadge(
          id: 'summer_champion',
          name: 'Summer Champion',
          emoji: '🏆',
          description: 'Achieve 10 perfect days',
          requirement: BadgeRequirement(
            type: BadgeRequirementType.perfectDays,
            targetValue: 10,
          ),
          xpReward: 500,
        ),
      ],
    ),

    // Winter Warmth (December 21 - March 19)
    SeasonalEvent(
      id: 'winter_$year',
      type: SeasonalEventType.winter,
      name: 'Winter Warmth ❄️',
      description: 'Keep the fire burning through winter!',
      startDate: DateTime(year, 12, 21),
      endDate: DateTime(year + 1, 3, 19, 23, 59, 59),
      xpMultiplier: 2.0,
      primaryColor: const Color(0xFF00BFFF),
      secondaryColor: const Color(0xFFE6E6FA),
      exclusiveBadges: [
        const SeasonalBadge(
          id: 'winter_warrior',
          name: 'Winter Warrior',
          emoji: '⛄',
          description: 'Complete 40 habits during winter',
          requirement: BadgeRequirement(
            type: BadgeRequirementType.completeHabits,
            targetValue: 40,
          ),
          xpReward: 250,
        ),
        const SeasonalBadge(
          id: 'frost_streak',
          name: 'Frost Streak',
          emoji: '🧊',
          description: 'Maintain a 30-day streak',
          requirement: BadgeRequirement(
            type: BadgeRequirementType.maintainStreak,
            targetValue: 30,
          ),
          xpReward: 500,
        ),
        const SeasonalBadge(
          id: 'new_year_champion',
          name: 'New Year Champion',
          emoji: '🎆',
          description: 'Earn 2000 XP during winter',
          requirement: BadgeRequirement(
            type: BadgeRequirementType.totalXP,
            targetValue: 2000,
          ),
          xpReward: 750,
        ),
      ],
    ),
  ];
}

/// Get only the currently active seasonal event (if any)
SeasonalEvent? getActiveSeasonalEvent() {
  for (final event in getSeasonalEvents()) {
    if (event.isActive) {
      return event;
    }
  }
  return null;
}
