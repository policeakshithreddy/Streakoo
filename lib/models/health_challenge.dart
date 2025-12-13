enum ChallengeType {
  weightManagement,
  heartHealth,
  nutritionWellness,
  activityStrength,
}

class HealthChallenge {
  final String id;
  final ChallengeType type;
  final String title;
  final String description;
  final DateTime startDate;
  final int durationWeeks;
  final Map<String, dynamic> goals; // e.g., {'targetWeight': 70.0}
  final Map<String, dynamic> aiPlan; // The full JSON plan from AI
  final List<ChallengeHabit> recommendedHabits;

  // Progress Tracking
  final Map<String, dynamic>? baselineMetrics; // Initial measurements
  final List<Map<String, dynamic>>? progressSnapshots; // Weekly check-ins
  final List<Map<String, dynamic>>? surveyResponses; // Survey answers

  HealthChallenge({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.startDate,
    required this.durationWeeks,
    required this.goals,
    required this.aiPlan,
    required this.recommendedHabits,
    this.baselineMetrics,
    this.progressSnapshots,
    this.surveyResponses,
  });

  // Getters for convenience
  String get weeklyFocus => aiPlan['weeklyFocus'] ?? 'Stay consistent';
  String get nutritionalTip => aiPlan['nutritionalGuidelines'] ?? '';
  String get aiInsight => aiPlan['aiExplanation'] ?? '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'durationWeeks': durationWeeks,
      'goals': goals,
      'aiPlan': aiPlan,
      'recommendedHabits': recommendedHabits.map((h) => h.toJson()).toList(),
      'baselineMetrics': baselineMetrics,
      'progressSnapshots': progressSnapshots,
      'surveyResponses': surveyResponses,
    };
  }

  HealthChallenge copyWith({
    String? id,
    ChallengeType? type,
    String? title,
    String? description,
    DateTime? startDate,
    int? durationWeeks,
    Map<String, dynamic>? goals,
    Map<String, dynamic>? aiPlan,
    List<ChallengeHabit>? recommendedHabits,
    Map<String, dynamic>? baselineMetrics,
    List<Map<String, dynamic>>? progressSnapshots,
    List<Map<String, dynamic>>? surveyResponses,
  }) {
    return HealthChallenge(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      goals: goals ?? this.goals,
      aiPlan: aiPlan ?? this.aiPlan,
      recommendedHabits: recommendedHabits ?? this.recommendedHabits,
      baselineMetrics: baselineMetrics ?? this.baselineMetrics,
      progressSnapshots: progressSnapshots ?? this.progressSnapshots,
      surveyResponses: surveyResponses ?? this.surveyResponses,
    );
  }

  factory HealthChallenge.fromJson(Map<String, dynamic> json) {
    return HealthChallenge(
      id: json['id'],
      type: ChallengeType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      durationWeeks: json['durationWeeks'],
      goals: json['goals'] ?? {},
      aiPlan: json['aiPlan'] ?? {},
      recommendedHabits: (json['recommendedHabits'] as List?)
              ?.map((h) => ChallengeHabit.fromJson(h))
              .toList() ??
          [],
      baselineMetrics: json['baselineMetrics'],
      progressSnapshots: (json['progressSnapshots'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      surveyResponses: (json['surveyResponses'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

class ChallengeHabit {
  final String name;
  final String emoji;
  final String frequency; // 'daily', 'weekly'
  final String? healthMetric; // 'steps', 'weight', etc.
  final double? targetValue;

  ChallengeHabit({
    required this.name,
    required this.emoji,
    required this.frequency,
    this.healthMetric,
    this.targetValue,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'emoji': emoji,
        'frequency': frequency,
        'healthMetric': healthMetric,
        'targetValue': targetValue,
      };

  factory ChallengeHabit.fromJson(Map<String, dynamic> json) {
    return ChallengeHabit(
      name: json['name'],
      emoji: json['emoji'],
      frequency: json['frequency'],
      healthMetric: json['healthMetric'],
      targetValue: (json['targetValue'] as num?)?.toDouble(),
    );
  }
}
