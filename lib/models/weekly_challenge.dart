import 'package:uuid/uuid.dart';

/// Types of weekly challenges
enum ChallengeType {
  perfectWeek, // Complete 100% of habits
  streakBuilder, // Build a streak of X days
  consistencyKing, // Complete habits X days in a row
  earlyBird, // Complete all habits before noon
  healthHero, // Hit step/sleep goals
  focusMaster, // Complete a specific habit every day
}

/// Weekly challenge model
class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final ChallengeType type;
  final double targetProgress; // 1.0 = 100%
  final double currentProgress;
  final int xpReward;
  final bool isCompleted;
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.targetProgress,
    this.currentProgress = 0.0,
    required this.xpReward,
    this.isCompleted = false,
    required this.weekStart,
    required this.weekEnd,
  });

  /// Progress percentage (0-100)
  int get progressPercentage =>
      (currentProgress / targetProgress * 100).clamp(0, 100).round();

  /// Check if challenge is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(weekStart) &&
        now.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  /// Days remaining in the challenge
  int get daysRemaining {
    final now = DateTime.now();
    return weekEnd.difference(now).inDays.clamp(0, 7);
  }

  WeeklyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    ChallengeType? type,
    double? targetProgress,
    double? currentProgress,
    int? xpReward,
    bool? isCompleted,
    DateTime? weekStart,
    DateTime? weekEnd,
  }) {
    return WeeklyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      targetProgress: targetProgress ?? this.targetProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'type': type.name,
      'targetProgress': targetProgress,
      'currentProgress': currentProgress,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
    };
  }

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) {
    return WeeklyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.perfectWeek,
      ),
      targetProgress: (json['targetProgress'] as num).toDouble(),
      currentProgress: (json['currentProgress'] as num?)?.toDouble() ?? 0.0,
      xpReward: json['xpReward'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
    );
  }
}

/// Pre-defined challenge templates
class ChallengeTemplates {
  static List<WeeklyChallenge> getTemplates(
      DateTime weekStart, DateTime weekEnd) {
    const uuid = Uuid();

    return [
      WeeklyChallenge(
        id: uuid.v4(),
        title: 'Perfect Week',
        description: 'Complete 100% of your scheduled habits this week',
        emoji: '🏆',
        type: ChallengeType.perfectWeek,
        targetProgress: 1.0,
        xpReward: 500,
        weekStart: weekStart,
        weekEnd: weekEnd,
      ),
      WeeklyChallenge(
        id: uuid.v4(),
        title: 'Consistency King',
        description: 'Complete habits 5 days in a row',
        emoji: '👑',
        type: ChallengeType.consistencyKing,
        targetProgress: 5.0,
        xpReward: 300,
        weekStart: weekStart,
        weekEnd: weekEnd,
      ),
      WeeklyChallenge(
        id: uuid.v4(),
        title: 'Streak Builder',
        description: 'Reach a 7-day streak on any habit',
        emoji: '🔥',
        type: ChallengeType.streakBuilder,
        targetProgress: 7.0,
        xpReward: 400,
        weekStart: weekStart,
        weekEnd: weekEnd,
      ),
      WeeklyChallenge(
        id: uuid.v4(),
        title: 'Health Hero',
        description: 'Hit your step goal 5 days this week',
        emoji: '💪',
        type: ChallengeType.healthHero,
        targetProgress: 5.0,
        xpReward: 350,
        weekStart: weekStart,
        weekEnd: weekEnd,
      ),
      WeeklyChallenge(
        id: uuid.v4(),
        title: 'Early Bird',
        description: 'Complete all habits before noon, 3 days this week',
        emoji: '🌅',
        type: ChallengeType.earlyBird,
        targetProgress: 3.0,
        xpReward: 250,
        weekStart: weekStart,
        weekEnd: weekEnd,
      ),
    ];
  }
}
