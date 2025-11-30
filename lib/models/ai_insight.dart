import 'package:flutter/material.dart';

enum InsightType {
  pattern, // Behavioral pattern detected
  correlation, // Habit correlation found
  recommendation, // Personalized suggestion
  warning, // Habit at risk
  achievement, // Milestone reached
}

class AIInsight {
  final String id;
  final DateTime createdAt;
  final InsightType type;
  final String title;
  final String description;
  final String? actionText;
  final double confidence; // 0.0 - 1.0

  AIInsight({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.title,
    required this.description,
    this.actionText,
    this.confidence = 0.8,
  });

  // Get icon for insight type
  IconData get icon {
    switch (type) {
      case InsightType.pattern:
        return Icons.lightbulb_outline;
      case InsightType.correlation:
        return Icons.link;
      case InsightType.recommendation:
        return Icons.tips_and_updates_outlined;
      case InsightType.warning:
        return Icons.warning_amber_outlined;
      case InsightType.achievement:
        return Icons.celebration_outlined;
    }
  }

  // Get color gradient for insight type
  List<Color> get gradientColors {
    switch (type) {
      case InsightType.pattern:
        return [const Color(0xFF4A90E2), const Color(0xFF50C9FF)];
      case InsightType.correlation:
        return [const Color(0xFF9B59B6), const Color(0xFFBB6BD9)];
      case InsightType.recommendation:
        return [const Color(0xFFFFA94A), const Color(0xFFFFCB74)];
      case InsightType.warning:
        return [const Color(0xFFE74C3C), const Color(0xFFFF6B6B)];
      case InsightType.achievement:
        return [const Color(0xFF27AE60), const Color(0xFF2ECC71)];
    }
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'type': type.index,
      'title': title,
      'description': description,
      'actionText': actionText,
      'confidence': confidence,
    };
  }

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: InsightType.values[json['type'] as int],
      title: json['title'] as String,
      description: json['description'] as String,
      actionText: json['actionText'] as String?,
      confidence: json['confidence'] as double? ?? 0.8,
    );
  }

  AIInsight copyWith({
    String? id,
    DateTime? createdAt,
    InsightType? type,
    String? title,
    String? description,
    String? actionText,
    double? confidence,
  }) {
    return AIInsight(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      actionText: actionText ?? this.actionText,
      confidence: confidence ?? this.confidence,
    );
  }
}
