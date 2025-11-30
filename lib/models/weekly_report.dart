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
  })  : topHabits = topHabits ?? [],
        strugglingHabits = strugglingHabits ?? [],
        dailyCompletions = dailyCompletions ?? {};

  // Get completion percentage (0-100)
  int get completionPercentage => (completionRate * 100).round();

  // Check if it's current week
  bool get isCurrentWeek {
    final now = DateTime.now();
    return now.isAfter(weekStart) &&
        now.isBefore(weekEnd.add(const Duration(days: 1)));
  }

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
    };
  }

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      id: json['id'] as String,
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      totalCompletions: json['totalCompletions'] as int,
      totalExpected: json['totalExpected'] as int,
      completionRate: json['completionRate'] as double,
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
    );
  }
}
