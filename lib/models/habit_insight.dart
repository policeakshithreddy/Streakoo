/// Types of habit insights
enum InsightType {
  weekdayPattern, // "You complete X 80% more on weekdays"
  timeOfDay, // "Your best time is 7-9 AM"
  streakWarning, // "You usually skip on Fridays"
  motivation, // "You're on fire!"
  correlation, // "When you do X, you also do Y"
  decline, // "Your completion rate dropped 20%"
  improvement, // "You improved 30% this week!"
}

/// A single habit insight with metadata
class HabitInsight {
  final String habitId;
  final String habitName;
  final String habitEmoji;
  final InsightType type;
  final String message;
  final double confidence; // 0.0 to 1.0
  final Map<String, dynamic> metadata;
  final DateTime generatedAt;

  const HabitInsight({
    required this.habitId,
    required this.habitName,
    required this.habitEmoji,
    required this.type,
    required this.message,
    required this.confidence,
    required this.metadata,
    required this.generatedAt,
  });

  /// Get icon for insight type
  String get icon {
    switch (type) {
      case InsightType.weekdayPattern:
        return '📅';
      case InsightType.timeOfDay:
        return '⏰';
      case InsightType.streakWarning:
        return '⚠️';
      case InsightType.motivation:
        return '🎉';
      case InsightType.correlation:
        return '🔗';
      case InsightType.decline:
        return '📉';
      case InsightType.improvement:
        return '📈';
    }
  }

  /// Get color for insight type
  String get colorHex {
    switch (type) {
      case InsightType.motivation:
      case InsightType.improvement:
        return '#4CAF50'; // Green
      case InsightType.streakWarning:
      case InsightType.decline:
        return '#FF9800'; // Orange
      default:
        return '#8B5CF6'; // Purple
    }
  }
}
