import 'dart:math';

/// Rarity tiers for loot box rewards
enum LootBoxRarity {
  common, // 50% - XP boosts
  uncommon, // 25% - Streak shields
  rare, // 15% - Theme unlocks
  epic, // 8% - Avatar unlocks
  legendary, // 2% - XP multipliers
}

/// Types of rewards that can drop from loot boxes
enum RewardType {
  xpBoost, // +25, +50, +100 XP
  streakShield, // +1 streak freeze token
  themeUnlock, // Unlock a theme (Ocean, Forest, Space)
  avatarUnlock, // Unlock a special avatar
  xpMultiplier, // 2x XP for 24 hours
}

/// Extension for rarity display properties
extension LootBoxRarityX on LootBoxRarity {
  String get name {
    switch (this) {
      case LootBoxRarity.common:
        return 'Common';
      case LootBoxRarity.uncommon:
        return 'Uncommon';
      case LootBoxRarity.rare:
        return 'Rare';
      case LootBoxRarity.epic:
        return 'Epic';
      case LootBoxRarity.legendary:
        return 'Legendary';
    }
  }

  String get emoji {
    switch (this) {
      case LootBoxRarity.common:
        return '⚪';
      case LootBoxRarity.uncommon:
        return '🟢';
      case LootBoxRarity.rare:
        return '🔵';
      case LootBoxRarity.epic:
        return '🟣';
      case LootBoxRarity.legendary:
        return '🟡';
    }
  }

  int get colorValue {
    switch (this) {
      case LootBoxRarity.common:
        return 0xFFB0BEC5; // Grey
      case LootBoxRarity.uncommon:
        return 0xFF4CAF50; // Green
      case LootBoxRarity.rare:
        return 0xFF2196F3; // Blue
      case LootBoxRarity.epic:
        return 0xFF9C27B0; // Purple
      case LootBoxRarity.legendary:
        return 0xFFFFD700; // Gold
    }
  }

  /// Weight for random selection (higher = more common)
  int get weight {
    switch (this) {
      case LootBoxRarity.common:
        return 50;
      case LootBoxRarity.uncommon:
        return 25;
      case LootBoxRarity.rare:
        return 15;
      case LootBoxRarity.epic:
        return 8;
      case LootBoxRarity.legendary:
        return 2;
    }
  }
}

/// A reward that can be obtained from a loot box
class LootBoxReward {
  final RewardType type;
  final LootBoxRarity rarity;
  final int value; // XP amount, multiplier value, or asset index
  final String name;
  final String emoji;
  final String? assetPath; // For themes/avatars

  const LootBoxReward({
    required this.type,
    required this.rarity,
    required this.value,
    required this.name,
    required this.emoji,
    this.assetPath,
  });

  String get description {
    switch (type) {
      case RewardType.xpBoost:
        return '+$value XP instantly!';
      case RewardType.streakShield:
        return '+$value Streak Freeze token!';
      case RewardType.themeUnlock:
        return 'Unlocked $name theme!';
      case RewardType.avatarUnlock:
        return 'Unlocked $name avatar!';
      case RewardType.xpMultiplier:
        return '${value}x XP for 24 hours!';
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'rarity': rarity.index,
        'value': value,
        'name': name,
        'emoji': emoji,
        'assetPath': assetPath,
      };

  factory LootBoxReward.fromJson(Map<String, dynamic> json) => LootBoxReward(
        type: RewardType.values[json['type'] as int],
        rarity: LootBoxRarity.values[json['rarity'] as int],
        value: json['value'] as int,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        assetPath: json['assetPath'] as String?,
      );
}

/// Triggers that can open a loot box
enum LootBoxTrigger {
  streak7, // 7-day streak milestone
  streak30, // 30-day streak milestone
  streak100, // 100-day streak milestone
  levelUp5, // Every 5 levels
  levelUp10, // Every 10 levels
  perfectWeek, // All habits completed all week
  completions100, // 100 total completions
  dailyBonus, // Daily login/completion bonus
}

extension LootBoxTriggerX on LootBoxTrigger {
  String get name {
    switch (this) {
      case LootBoxTrigger.streak7:
        return '7-Day Streak!';
      case LootBoxTrigger.streak30:
        return '30-Day Streak!';
      case LootBoxTrigger.streak100:
        return '100-Day Streak!';
      case LootBoxTrigger.levelUp5:
        return 'Level Milestone!';
      case LootBoxTrigger.levelUp10:
        return 'Major Level Up!';
      case LootBoxTrigger.perfectWeek:
        return 'Perfect Week!';
      case LootBoxTrigger.completions100:
        return '100 Completions!';
      case LootBoxTrigger.dailyBonus:
        return 'Daily Bonus!';
    }
  }

  String get emoji {
    switch (this) {
      case LootBoxTrigger.streak7:
        return '🔥';
      case LootBoxTrigger.streak30:
        return '🔥🔥';
      case LootBoxTrigger.streak100:
        return '🔥🔥🔥';
      case LootBoxTrigger.levelUp5:
        return '⬆️';
      case LootBoxTrigger.levelUp10:
        return '🚀';
      case LootBoxTrigger.perfectWeek:
        return '💯';
      case LootBoxTrigger.completions100:
        return '🎯';
      case LootBoxTrigger.dailyBonus:
        return '🎁';
    }
  }

  /// Minimum rarity guarantee for this trigger
  LootBoxRarity get minimumRarity {
    switch (this) {
      case LootBoxTrigger.streak100:
        return LootBoxRarity.epic;
      case LootBoxTrigger.streak30:
      case LootBoxTrigger.levelUp10:
        return LootBoxRarity.rare;
      case LootBoxTrigger.perfectWeek:
        return LootBoxRarity.uncommon;
      default:
        return LootBoxRarity.common;
    }
  }
}

/// A loot box that can be opened to get rewards
class LootBox {
  final String id;
  final LootBoxTrigger trigger;
  final DateTime earnedAt;
  final bool isOpened;
  final LootBoxReward? reward; // Set after opening

  LootBox({
    required this.id,
    required this.trigger,
    required this.earnedAt,
    this.isOpened = false,
    this.reward,
  });

  /// Open the loot box and get a reward
  LootBox open(LootBoxReward reward) {
    return LootBox(
      id: id,
      trigger: trigger,
      earnedAt: earnedAt,
      isOpened: true,
      reward: reward,
    );
  }

  /// Generate a reward based on trigger rarity weights
  static LootBoxReward generateReward(LootBoxTrigger trigger) {
    final random = Random();
    final minimumRarity = trigger.minimumRarity;

    // Filter rarities based on minimum
    final eligibleRarities = LootBoxRarity.values
        .where((r) => r.index >= minimumRarity.index)
        .toList();

    // Calculate weights
    final totalWeight =
        eligibleRarities.fold<int>(0, (sum, r) => sum + r.weight);
    var roll = random.nextInt(totalWeight);

    LootBoxRarity selectedRarity = eligibleRarities.last;
    for (final rarity in eligibleRarities) {
      roll -= rarity.weight;
      if (roll < 0) {
        selectedRarity = rarity;
        break;
      }
    }

    // Generate reward based on rarity
    return _generateRewardForRarity(selectedRarity, random);
  }

  static LootBoxReward _generateRewardForRarity(
      LootBoxRarity rarity, Random random) {
    switch (rarity) {
      case LootBoxRarity.common:
        // XP Boost: 25, 50, or 75
        final xpValues = [25, 50, 75];
        final xp = xpValues[random.nextInt(xpValues.length)];
        return LootBoxReward(
          type: RewardType.xpBoost,
          rarity: rarity,
          value: xp,
          name: 'XP Boost',
          emoji: '⚡',
        );

      case LootBoxRarity.uncommon:
        // Streak Shield
        return const LootBoxReward(
          type: RewardType.streakShield,
          rarity: LootBoxRarity.uncommon,
          value: 1,
          name: 'Streak Shield',
          emoji: '🛡️',
        );

      case LootBoxRarity.rare:
        // Theme Unlock
        final themes = [
          ('Ocean', '🌊', 'themes/ocean'),
          ('Forest', '🌲', 'themes/forest'),
          ('Space', '🚀', 'themes/space'),
          ('Sunset', '🌅', 'themes/sunset'),
        ];
        final theme = themes[random.nextInt(themes.length)];
        return LootBoxReward(
          type: RewardType.themeUnlock,
          rarity: rarity,
          value: 0,
          name: theme.$1,
          emoji: theme.$2,
          assetPath: theme.$3,
        );

      case LootBoxRarity.epic:
        // Avatar Unlock
        final avatars = [
          ('Golden Phoenix', '🦅', 'avatars/golden_phoenix'),
          ('Diamond Cat', '💎', 'avatars/diamond_cat'),
          ('Cosmic Dragon', '🐉', 'avatars/cosmic_dragon'),
          ('Rainbow Unicorn', '🦄', 'avatars/rainbow_unicorn'),
        ];
        final avatar = avatars[random.nextInt(avatars.length)];
        return LootBoxReward(
          type: RewardType.avatarUnlock,
          rarity: rarity,
          value: 0,
          name: avatar.$1,
          emoji: avatar.$2,
          assetPath: avatar.$3,
        );

      case LootBoxRarity.legendary:
        // 2x XP Multiplier for 24 hours
        return const LootBoxReward(
          type: RewardType.xpMultiplier,
          rarity: LootBoxRarity.legendary,
          value: 2,
          name: 'Double XP',
          emoji: '✨',
        );
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trigger': trigger.index,
        'earnedAt': earnedAt.toIso8601String(),
        'isOpened': isOpened,
        'reward': reward?.toJson(),
      };

  factory LootBox.fromJson(Map<String, dynamic> json) => LootBox(
        id: json['id'] as String,
        trigger: LootBoxTrigger.values[json['trigger'] as int],
        earnedAt: DateTime.parse(json['earnedAt'] as String),
        isOpened: json['isOpened'] as bool? ?? false,
        reward: json['reward'] != null
            ? LootBoxReward.fromJson(json['reward'] as Map<String, dynamic>)
            : null,
      );
}

/// Tracks active XP multipliers
class XpMultiplier {
  final int multiplier;
  final DateTime expiresAt;

  XpMultiplier({
    required this.multiplier,
    required this.expiresAt,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  Duration get remainingTime => expiresAt.difference(DateTime.now());

  Map<String, dynamic> toJson() => {
        'multiplier': multiplier,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory XpMultiplier.fromJson(Map<String, dynamic> json) => XpMultiplier(
        multiplier: json['multiplier'] as int,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}
