import 'package:flutter/material.dart';

/// Type of reward earned
enum RewardType {
  streakFreeze,
  badge,
  xpBonus,
  theme,
  feature,
}

/// Represents a reward earned from leveling up
class LevelReward {
  final RewardType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int? quantity; // For streak freezes, XP, etc.
  final String? badge; // Badge name/ID
  final bool isNew; // Is this a new unlock?

  const LevelReward({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.quantity,
    this.badge,
    this.isNew = true,
  });

  /// Create a streak freeze reward
  factory LevelReward.streakFreeze({int count = 1}) {
    return LevelReward(
      type: RewardType.streakFreeze,
      title: 'Streak Freeze${count > 1 ? ' x$count' : ''}',
      description:
          'Protect your streak for ${count > 1 ? '$count days' : '1 day'} if you miss a habit',
      icon: Icons.ac_unit,
      color: const Color(0xFF4FC3F7),
      quantity: count,
    );
  }

  /// Create a badge reward
  factory LevelReward.badge({
    required String badgeName,
    required String description,
  }) {
    return LevelReward(
      type: RewardType.badge,
      title: badgeName,
      description: description,
      icon: Icons.military_tech,
      color: const Color(0xFFFFD700),
      badge: badgeName,
    );
  }

  /// Create an XP bonus reward
  factory LevelReward.xpBonus({required int amount}) {
    return LevelReward(
      type: RewardType.xpBonus,
      title: '+$amount XP Bonus',
      description: 'Bonus XP for reaching this level',
      icon: Icons.stars,
      color: const Color(0xFFFFA726),
      quantity: amount,
    );
  }

  /// Create a theme unlock reward
  factory LevelReward.theme({required String themeName}) {
    return LevelReward(
      type: RewardType.theme,
      title: '$themeName Theme Unlocked',
      description: 'New celebration theme available!',
      icon: Icons.palette,
      color: const Color(0xFF9C27B0),
      badge: themeName,
    );
  }

  /// Create a feature unlock reward
  factory LevelReward.feature({
    required String featureName,
    required String description,
  }) {
    return LevelReward(
      type: RewardType.feature,
      title: featureName,
      description: description,
      icon: Icons.auto_awesome,
      color: const Color(0xFF4CAF50),
    );
  }

  /// Get rewards for a specific level
  static List<LevelReward> getRewardsForLevel(int level) {
    final rewards = <LevelReward>[];

    // Always give a streak freeze at multiples of 7 levels
    if (level % 7 == 0) {
      rewards.add(LevelReward.streakFreeze(count: level ~/ 7));
    }

    // Level-specific rewards
    switch (level) {
      case 2:
        rewards.add(LevelReward.badge(
          badgeName: 'Beginner',
          description: 'Your journey begins!',
        ));
        break;

      case 5:
        rewards.add(LevelReward.theme(themeName: 'Cosmic'));
        break;

      case 10:
        rewards.add(LevelReward.badge(
          badgeName: 'Dedicated',
          description: 'You\'re getting serious!',
        ));
        rewards.add(LevelReward.xpBonus(amount: 100));
        break;

      case 15:
        rewards.add(LevelReward.theme(themeName: 'Zen'));
        break;

      case 20:
        rewards.add(LevelReward.badge(
          badgeName: 'Champion',
          description: 'A true habit champion!',
        ));
        rewards.add(LevelReward.xpBonus(amount: 200));
        break;

      case 25:
        rewards.add(LevelReward.theme(themeName: 'Fire'));
        break;

      case 30:
        rewards.add(LevelReward.badge(
          badgeName: 'Master',
          description: 'You\'ve mastered the art of habits!',
        ));
        rewards.add(LevelReward.xpBonus(amount: 300));
        break;

      case 50:
        rewards.add(LevelReward.badge(
          badgeName: 'Legend',
          description: 'Your dedication is legendary!',
        ));
        rewards.add(LevelReward.xpBonus(amount: 500));
        rewards.add(LevelReward.streakFreeze(count: 5));
        break;

      case 100:
        rewards.add(LevelReward.badge(
          badgeName: 'Immortal',
          description: 'LEGENDARY STATUS ACHIEVED!',
        ));
        rewards.add(LevelReward.xpBonus(amount: 1000));
        rewards.add(LevelReward.streakFreeze(count: 10));
        break;
    }

    return rewards;
  }

  /// Check if a level has special rewards
  static bool hasSpecialRewards(int level) {
    final rewards = getRewardsForLevel(level);
    return rewards.isNotEmpty;
  }
}
