import 'health_challenge.dart';

enum NudgeType {
  activityDrop,
  sleepPoor,
  milestoneReady,
  consistencyBonus,
}

enum NudgeSeverity {
  low,
  medium,
  high,
  positive,
}

class SmartNudge {
  final NudgeType type;
  final String title;
  final String message;
  final String ctaText;
  final NudgeSeverity severity;
  final ChallengeType? recommendedChallenge;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  SmartNudge({
    required this.type,
    required this.title,
    required this.message,
    this.ctaText = 'Take Action',
    this.severity = NudgeSeverity.medium,
    this.recommendedChallenge,
    DateTime? createdAt,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'message': message,
        'ctaText': ctaText,
        'severity': severity.name,
        'recommendedChallenge': recommendedChallenge?.name,
        'createdAt': createdAt.toIso8601String(),
        'metadata': metadata,
      };

  factory SmartNudge.fromJson(Map<String, dynamic> json) => SmartNudge(
        type: NudgeType.values.firstWhere((e) => e.name == json['type']),
        title: json['title'],
        message: json['message'],
        ctaText: json['ctaText'] ?? 'Take Action',
        severity:
            NudgeSeverity.values.firstWhere((e) => e.name == json['severity']),
        recommendedChallenge: json['recommendedChallenge'] != null
            ? ChallengeType.values
                .firstWhere((e) => e.name == json['recommendedChallenge'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        metadata: json['metadata'],
      );
}
