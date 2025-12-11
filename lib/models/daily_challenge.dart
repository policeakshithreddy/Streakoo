/// Daily challenge model for gamification
class DailyChallenge {
  final String id;
  final ChallengeType type;
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
  final int targetValue;
  final int currentProgress;
  final DateTime expiresAt;
  final bool isCompleted;

  DailyChallenge({
    String? id,
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
    required this.targetValue,
    this.currentProgress = 0,
    DateTime? expiresAt,
    this.isCompleted = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        expiresAt = expiresAt ?? _getEndOfDay(DateTime.now());

  static DateTime _getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  double get progressPercent => (currentProgress / targetValue).clamp(0.0, 1.0);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  DailyChallenge copyWith({
    ChallengeType? type,
    String? title,
    String? description,
    String? emoji,
    int? xpReward,
    int? targetValue,
    int? currentProgress,
    DateTime? expiresAt,
    bool? isCompleted,
  }) {
    return DailyChallenge(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      xpReward: xpReward ?? this.xpReward,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'emoji': emoji,
        'xpReward': xpReward,
        'targetValue': targetValue,
        'currentProgress': currentProgress,
        'expiresAt': expiresAt.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
        id: json['id'],
        type: ChallengeType.values.firstWhere((e) => e.name == json['type']),
        title: json['title'],
        description: json['description'],
        emoji: json['emoji'],
        xpReward: json['xpReward'],
        targetValue: json['targetValue'],
        currentProgress: json['currentProgress'] ?? 0,
        expiresAt: DateTime.parse(json['expiresAt']),
        isCompleted: json['isCompleted'] ?? false,
      );
}

enum ChallengeType {
  perfectDay, // Complete all habits
  streakBoost, // Maintain X day streak
  earlyBird, // Complete before 10 AM
  completionCount, // Complete X habits
  focusTaskMaster, // Complete all focus tasks
  weekendWarrior, // Complete on weekend
  consistency, // Complete same habit X days in row
}

/// Challenge difficulty for XP rewards
enum ChallengeDifficulty {
  easy(50),
  medium(100),
  hard(200),
  epic(500);

  final int baseXP;
  const ChallengeDifficulty(this.baseXP);
}
