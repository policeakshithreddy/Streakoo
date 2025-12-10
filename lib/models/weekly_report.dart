/// Weekly streak achievement types
enum StreakAchievement {
  newRecord, // Hit a new personal best
  milestone7, // 7-day streak
  milestone14, // 14-day streak
  milestone30, // 30-day streak
  milestone100, // 100-day streak
  comeback, // Rebuilt streak after breaking
  perfectWeek, // 100% completion this week
}

/// Health metrics summary for the week
class WeeklyHealthStats {
  final int? averageSteps;
  final double? averageSleep; // hours
  final int? averageHeartRate;
  final int? stepsChange; // vs previous week (can be negative)
  final double? sleepChange;
  final int? heartRateChange;

  const WeeklyHealthStats({
    this.averageSteps,
    this.averageSleep,
    this.averageHeartRate,
    this.stepsChange,
    this.sleepChange,
    this.heartRateChange,
  });

  Map<String, dynamic> toJson() => {
        'averageSteps': averageSteps,
        'averageSleep': averageSleep,
        'averageHeartRate': averageHeartRate,
        'stepsChange': stepsChange,
        'sleepChange': sleepChange,
        'heartRateChange': heartRateChange,
      };

  factory WeeklyHealthStats.fromJson(Map<String, dynamic> json) {
    return WeeklyHealthStats(
      averageSteps: json['averageSteps'] as int?,
      averageSleep: (json['averageSleep'] as num?)?.toDouble(),
      averageHeartRate: json['averageHeartRate'] as int?,
      stepsChange: json['stepsChange'] as int?,
      sleepChange: (json['sleepChange'] as num?)?.toDouble(),
      heartRateChange: json['heartRateChange'] as int?,
    );
  }
}

class WeeklyReport {
  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalCompletions;
  final int totalExpected;
  final double completionRate; // 0.0 - 1.0
  final String? bestDay; // e.g., "Monday"
  final String? worstDay;
  final List<String> topHabits; // Top 3 performing habits
  final List<String> strugglingHabits; // Habits that need attention
  final String? aiSummary; // AI-generated weekly summary
  final Map<String, int> dailyCompletions; // Day name -> completion count

  // NEW: Health integration
  final WeeklyHealthStats? healthStats;

  // NEW: Week-over-week comparison
  final double? previousWeekRate; // For comparison
  final int xpEarned; // XP earned this week
  final int levelsGained; // Levels gained this week

  // NEW: Streak achievements
  final List<StreakAchievement> achievements;
  final int longestStreakThisWeek;
  final int? newPersonalBest; // If a new record was set

  WeeklyReport({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.totalCompletions,
    required this.totalExpected,
    required this.completionRate,
    this.bestDay,
    this.worstDay,
    List<String>? topHabits,
    List<String>? strugglingHabits,
    this.aiSummary,
    Map<String, int>? dailyCompletions,
    this.healthStats,
    this.previousWeekRate,
    this.xpEarned = 0,
    this.levelsGained = 0,
    List<StreakAchievement>? achievements,
    this.longestStreakThisWeek = 0,
    this.newPersonalBest,
  })  : topHabits = topHabits ?? [],
        strugglingHabits = strugglingHabits ?? [],
        dailyCompletions = dailyCompletions ?? {},
        achievements = achievements ?? [];

  // Get completion percentage (0-100)
  int get completionPercentage => (completionRate * 100).round();

  // Check if improved from last week
  bool get improved =>
      previousWeekRate != null && completionRate > previousWeekRate!;

  // Get percentage change from last week
  int? get percentageChange {
    if (previousWeekRate == null) return null;
    return ((completionRate - previousWeekRate!) * 100).round();
  }

  // Check if it's current week
  bool get isCurrentWeek {
    final now = DateTime.now();
    return now.isAfter(weekStart) &&
        now.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  // Check if it was a perfect week
  bool get isPerfectWeek => completionRate >= 0.99;

  // Get week display string (e.g., "Nov 19 - Nov 25")
  String get weekDisplayString {
    final startMonth = _monthName(weekStart.month);
    final endMonth = _monthName(weekEnd.month);

    if (weekStart.month == weekEnd.month) {
      return '$startMonth ${weekStart.day} - ${weekEnd.day}';
    } else {
      return '$startMonth ${weekStart.day} - $endMonth ${weekEnd.day}';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'totalCompletions': totalCompletions,
      'totalExpected': totalExpected,
      'completionRate': completionRate,
      'bestDay': bestDay,
      'worstDay': worstDay,
      'topHabits': topHabits,
      'strugglingHabits': strugglingHabits,
      'aiSummary': aiSummary,
      'dailyCompletions': dailyCompletions,
      'healthStats': healthStats?.toJson(),
      'previousWeekRate': previousWeekRate,
      'xpEarned': xpEarned,
      'levelsGained': levelsGained,
      'achievements': achievements.map((a) => a.name).toList(),
      'longestStreakThisWeek': longestStreakThisWeek,
      'newPersonalBest': newPersonalBest,
    };
  }

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      id: json['id'] as String,
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      totalCompletions: json['totalCompletions'] as int,
      totalExpected: json['totalExpected'] as int,
      completionRate: (json['completionRate'] as num).toDouble(),
      bestDay: json['bestDay'] as String?,
      worstDay: json['worstDay'] as String?,
      topHabits: (json['topHabits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      strugglingHabits: (json['strugglingHabits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      aiSummary: json['aiSummary'] as String?,
      dailyCompletions: Map<String, int>.from(
        json['dailyCompletions'] as Map? ?? {},
      ),
      healthStats: json['healthStats'] != null
          ? WeeklyHealthStats.fromJson(
              json['healthStats'] as Map<String, dynamic>)
          : null,
      previousWeekRate: (json['previousWeekRate'] as num?)?.toDouble(),
      xpEarned: json['xpEarned'] as int? ?? 0,
      levelsGained: json['levelsGained'] as int? ?? 0,
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((a) => StreakAchievement.values.firstWhere(
                    (e) => e.name == a,
                    orElse: () => StreakAchievement.newRecord,
                  ))
              .toList() ??
          [],
      longestStreakThisWeek: json['longestStreakThisWeek'] as int? ?? 0,
      newPersonalBest: json['newPersonalBest'] as int?,
    );
  }

  WeeklyReport copyWith({
    String? id,
    DateTime? weekStart,
    DateTime? weekEnd,
    int? totalCompletions,
    int? totalExpected,
    double? completionRate,
    String? bestDay,
    String? worstDay,
    List<String>? topHabits,
    List<String>? strugglingHabits,
    String? aiSummary,
    Map<String, int>? dailyCompletions,
    WeeklyHealthStats? healthStats,
    double? previousWeekRate,
    int? xpEarned,
    int? levelsGained,
    List<StreakAchievement>? achievements,
    int? longestStreakThisWeek,
    int? newPersonalBest,
  }) {
    return WeeklyReport(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      totalExpected: totalExpected ?? this.totalExpected,
      completionRate: completionRate ?? this.completionRate,
      bestDay: bestDay ?? this.bestDay,
      worstDay: worstDay ?? this.worstDay,
      topHabits: topHabits ?? this.topHabits,
      strugglingHabits: strugglingHabits ?? this.strugglingHabits,
      aiSummary: aiSummary ?? this.aiSummary,
      dailyCompletions: dailyCompletions ?? this.dailyCompletions,
      healthStats: healthStats ?? this.healthStats,
      previousWeekRate: previousWeekRate ?? this.previousWeekRate,
      xpEarned: xpEarned ?? this.xpEarned,
      levelsGained: levelsGained ?? this.levelsGained,
      achievements: achievements ?? this.achievements,
      longestStreakThisWeek:
          longestStreakThisWeek ?? this.longestStreakThisWeek,
      newPersonalBest: newPersonalBest ?? this.newPersonalBest,
    );
  }
}
