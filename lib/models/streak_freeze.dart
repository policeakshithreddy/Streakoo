import 'dart:convert';

/// Streak Freeze system - protects users from accidentally breaking streaks
/// Regeneration rate and max tokens depend on user level
class StreakFreeze {
  final int availableFreezes;
  final int maxFreezes;
  final DateTime lastRegenTime;
  final List<FreezeUsage> usageHistory;

  StreakFreeze({
    required this.availableFreezes,
    required this.maxFreezes,
    required this.lastRegenTime,
    this.usageHistory = const [],
  });

  /// Get max freezes based on user level
  static int getMaxFreezesForLevel(int level) {
    if (level >= 40) return 4;
    if (level >= 30) return 3;
    if (level >= 20) return 3;
    if (level >= 10) return 2;
    return 1;
  }

  /// Get regeneration duration based on user level
  static Duration getRegenDurationForLevel(int level) {
    if (level >= 40) return const Duration(days: 7); // 1 per week
    if (level >= 30) return const Duration(days: 10); // 1 per 10 days
    if (level >= 20) return const Duration(days: 14); // 1 per 2 weeks
    if (level >= 10) return const Duration(days: 14); // 1 per 2 weeks
    return const Duration(days: 7); // 1 per week
  }

  /// Check if a freeze can be used
  bool get canUseFreeze => availableFreezes > 0;

  /// Calculate next regeneration time
  DateTime nextRegenTime(int level) {
    return lastRegenTime.add(getRegenDurationForLevel(level));
  }

  /// Days until next freeze regenerates
  int daysUntilNextFreeze(int level) {
    if (availableFreezes >= maxFreezes) return -1; // Already at max
    final next = nextRegenTime(level);
    final now = DateTime.now();
    if (next.isBefore(now)) return 0;
    return next.difference(now).inDays + 1;
  }

  /// Use a freeze for a specific habit
  StreakFreeze useFreeze(String habitId, String habitName) {
    if (!canUseFreeze) return this;

    final newUsage = FreezeUsage(
      habitId: habitId,
      habitName: habitName,
      usedAt: DateTime.now(),
    );

    return StreakFreeze(
      availableFreezes: availableFreezes - 1,
      maxFreezes: maxFreezes,
      lastRegenTime: lastRegenTime,
      usageHistory: [...usageHistory, newUsage],
    );
  }

  /// Check for regeneration and return updated freeze
  StreakFreeze checkAndRegenerate(int level) {
    final now = DateTime.now();
    final regenDuration = getRegenDurationForLevel(level);
    final newMax = getMaxFreezesForLevel(level);

    // Count how many regenerations have occurred since last regen time
    int regenerations = 0;
    DateTime checkTime = lastRegenTime;

    while (checkTime.add(regenDuration).isBefore(now) &&
        (availableFreezes + regenerations) < newMax) {
      regenerations++;
      checkTime = checkTime.add(regenDuration);
    }

    if (regenerations > 0) {
      return StreakFreeze(
        availableFreezes: (availableFreezes + regenerations).clamp(0, newMax),
        maxFreezes: newMax,
        lastRegenTime: checkTime,
        usageHistory: usageHistory,
      );
    }

    // Update max if level changed
    if (maxFreezes != newMax) {
      return StreakFreeze(
        availableFreezes: availableFreezes.clamp(0, newMax),
        maxFreezes: newMax,
        lastRegenTime: lastRegenTime,
        usageHistory: usageHistory,
      );
    }

    return this;
  }

  /// Create initial freeze state for a user
  factory StreakFreeze.initial(int level) {
    return StreakFreeze(
      availableFreezes: 1, // Everyone starts with 1
      maxFreezes: getMaxFreezesForLevel(level),
      lastRegenTime: DateTime.now(),
      usageHistory: [],
    );
  }

  /// Create from JSON
  factory StreakFreeze.fromJson(Map<String, dynamic> json) {
    return StreakFreeze(
      availableFreezes: json['availableFreezes'] as int? ?? 1,
      maxFreezes: json['maxFreezes'] as int? ?? 1,
      lastRegenTime: json['lastRegenTime'] != null
          ? DateTime.parse(json['lastRegenTime'] as String)
          : DateTime.now(),
      usageHistory: (json['usageHistory'] as List<dynamic>?)
              ?.map((e) => FreezeUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'availableFreezes': availableFreezes,
      'maxFreezes': maxFreezes,
      'lastRegenTime': lastRegenTime.toIso8601String(),
      'usageHistory': usageHistory.map((e) => e.toJson()).toList(),
    };
  }

  /// Serialize to string for storage
  String serialize() => jsonEncode(toJson());

  /// Deserialize from string
  factory StreakFreeze.deserialize(String data) {
    return StreakFreeze.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  StreakFreeze copyWith({
    int? availableFreezes,
    int? maxFreezes,
    DateTime? lastRegenTime,
    List<FreezeUsage>? usageHistory,
  }) {
    return StreakFreeze(
      availableFreezes: availableFreezes ?? this.availableFreezes,
      maxFreezes: maxFreezes ?? this.maxFreezes,
      lastRegenTime: lastRegenTime ?? this.lastRegenTime,
      usageHistory: usageHistory ?? this.usageHistory,
    );
  }
}

/// Record of when a freeze was used
class FreezeUsage {
  final String habitId;
  final String habitName;
  final DateTime usedAt;

  FreezeUsage({
    required this.habitId,
    required this.habitName,
    required this.usedAt,
  });

  factory FreezeUsage.fromJson(Map<String, dynamic> json) {
    return FreezeUsage(
      habitId: json['habitId'] as String,
      habitName: json['habitName'] as String,
      usedAt: DateTime.parse(json['usedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habitId': habitId,
      'habitName': habitName,
      'usedAt': usedAt.toIso8601String(),
    };
  }
}
