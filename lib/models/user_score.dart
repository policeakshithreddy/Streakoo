/// User's leaderboard score data
class UserScore {
  final String userId;
  final String username;
  final int totalScore;
  final int dailyCompletions;
  final int longestStreak;
  final double completionRate;
  final int totalXP;
  final int currentWeekScore;
  final DateTime lastUpdated;
  final bool isPublic;

  const UserScore({
    required this.userId,
    required this.username,
    required this.totalScore,
    required this.dailyCompletions,
    required this.longestStreak,
    required this.completionRate,
    required this.totalXP,
    required this.currentWeekScore,
    required this.lastUpdated,
    this.isPublic = true,
  });

  factory UserScore.fromJson(Map<String, dynamic> json) {
    return UserScore(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 'Anonymous',
      totalScore: json['total_score'] as int? ?? 0,
      dailyCompletions: json['daily_completions'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      totalXP: json['total_xp'] as int? ?? 0,
      currentWeekScore: json['current_week_score'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      isPublic: json['is_public'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'total_score': totalScore,
      'daily_completions': dailyCompletions,
      'longest_streak': longestStreak,
      'completion_rate': completionRate,
      'total_xp': totalXP,
      'current_week_score': currentWeekScore,
      'last_updated': lastUpdated.toIso8601String(),
      'is_public': isPublic,
    };
  }

  /// Get rank badge emoji
  String getRankBadge(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return rank <= 10 ? '⭐' : '📊';
    }
  }

  /// Get score tier name
  String get scoreTier {
    if (totalScore >= 10000) return 'Legend';
    if (totalScore >= 5000) return 'Master';
    if (totalScore >= 2500) return 'Expert';
    if (totalScore >= 1000) return 'Advanced';
    if (totalScore >= 500) return 'Intermediate';
    return 'Beginner';
  }
}

/// Leaderboard entry with rank
class LeaderboardEntry {
  final UserScore userScore;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userScore,
    required this.rank,
    this.isCurrentUser = false,
  });

  String get rankBadge => userScore.getRankBadge(rank);
}
