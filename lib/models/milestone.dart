enum MilestoneType {
  streak,
  weekComplete,
  personalBest,
  halfwayPoint,
  challengeComplete,
}

enum CelebrationType {
  minimal, // Small toast notification
  confetti, // Confetti animation
  fullScreen, // Full celebration overlay
}

class WeekStats {
  final int completedDays;
  final int totalDays;
  final double completionRate;
  final int stepsAverage;
  final double sleepAverage;

  WeekStats({
    required this.completedDays,
    required this.totalDays,
    required this.completionRate,
    required this.stepsAverage,
    required this.sleepAverage,
  });

  Map<String, dynamic> toJson() => {
        'completedDays': completedDays,
        'totalDays': totalDays,
        'completionRate': completionRate,
        'stepsAverage': stepsAverage,
        'sleepAverage': sleepAverage,
      };

  factory WeekStats.fromJson(Map<String, dynamic> json) => WeekStats(
        completedDays: json['completedDays'],
        totalDays: json['totalDays'],
        completionRate: json['completionRate'],
        stepsAverage: json['stepsAverage'],
        sleepAverage: json['sleepAverage'],
      );
}

class Milestone {
  final String id;
  final MilestoneType type;
  final String title;
  final String description;
  final String icon;
  final CelebrationType celebration;
  final DateTime achievedAt;
  final Map<String, dynamic>? data;
  final int? improvement; // Percentage improvement for personal bests

  Milestone({
    String? id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    this.celebration = CelebrationType.minimal,
    DateTime? achievedAt,
    this.data,
    this.improvement,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        achievedAt = achievedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'icon': icon,
        'celebration': celebration.name,
        'achievedAt': achievedAt.toIso8601String(),
        'data': data,
        'improvement': improvement,
      };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'],
        type: MilestoneType.values.firstWhere((e) => e.name == json['type']),
        title: json['title'],
        description: json['description'],
        icon: json['icon'],
        celebration: CelebrationType.values
            .firstWhere((e) => e.name == json['celebration']),
        achievedAt: DateTime.parse(json['achievedAt']),
        data: json['data'],
        improvement: json['improvement'],
      );
}
