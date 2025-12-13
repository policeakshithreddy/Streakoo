import '../services/health_service.dart';

/// Parsed data extracted from AI-generated habit goals
class ParsedGoalData {
  final String originalGoal;
  final double? healthGoalValue;
  final HealthMetricType? healthMetric;
  final String? suggestedReminderTime; // HH:MM format
  final String? timeOfDay; // morning, afternoon, evening, night
  final int? focusDuration; // Duration in minutes for focus mode

  const ParsedGoalData({
    required this.originalGoal,
    this.healthGoalValue,
    this.healthMetric,
    this.suggestedReminderTime,
    this.timeOfDay,
    this.focusDuration,
  });

  bool get hasHealthGoal => healthGoalValue != null && healthMetric != null;
  bool get hasReminder => suggestedReminderTime != null;
  bool get hasFocusDuration => focusDuration != null;

  @override
  String toString() {
    return 'ParsedGoalData(goal: $originalGoal, health: $healthGoalValue $healthMetric, reminder: $suggestedReminderTime, focus: $focusDuration min)';
  }
}

/// Service to parse AI-generated habit goals and extract structured data
class AiGoalParserService {
  static final instance = AiGoalParserService._();
  AiGoalParserService._();

  /// Parse a goal string and extract health metrics and reminder times
  ParsedGoalData parseGoal(String goal) {
    final lowercaseGoal = goal.toLowerCase();

    return ParsedGoalData(
      originalGoal: goal,
      healthGoalValue: _extractHealthValue(lowercaseGoal),
      healthMetric: _extractHealthMetric(lowercaseGoal),
      suggestedReminderTime: _extractReminderTime(lowercaseGoal),
      timeOfDay: _extractTimeOfDay(lowercaseGoal),
      focusDuration: _extractFocusDuration(lowercaseGoal),
    );
  }

  /// Extract numeric health goal value from text
  double? _extractHealthValue(String text) {
    // Pattern: number followed by space and unit
    // Examples: "10000 steps", "5 km", "30 minutes", "8 hours"

    final patterns = [
      // Steps: "10000 steps", "10,000 steps", "10k steps"
      RegExp(r'(\d+[,.]?\d*)\s*k?\s*steps?', caseSensitive: false),

      // Distance: "5 km", "5.5 km", "3 miles"
      RegExp(r'(\d+[.]?\d*)\s*(km|kilometers?|miles?|mi)',
          caseSensitive: false),

      // Duration: "30 minutes", "30 mins", "2 hours"
      RegExp(r'(\d+[.]?\d*)\s*(minutes?|mins?|hours?|hrs?)',
          caseSensitive: false),

      // General numbers for health metrics
      RegExp(r'(\d+[,.]?\d*)\s*(bpm|beats)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        var value = match.group(1)!;

        // Handle "k" suffix (e.g., "10k steps" = 10000)
        if (text.contains(
            RegExp('${value}\\s*k\\s*steps?', caseSensitive: false))) {
          value = value.replaceAll(',', '');
          return double.tryParse(value)! * 1000;
        }

        // Remove commas and parse
        value = value.replaceAll(',', '');
        return double.tryParse(value);
      }
    }

    return null;
  }

  /// Extract health metric type from text
  HealthMetricType? _extractHealthMetric(String text) {
    if (text.contains(RegExp(r'steps?', caseSensitive: false))) {
      return HealthMetricType.steps;
    }

    if (text.contains(
        RegExp(r'(km|kilometers?|miles?|distance)', caseSensitive: false))) {
      return HealthMetricType.distance;
    }

    if (text.contains(RegExp(r'(sleep|rest)', caseSensitive: false))) {
      return HealthMetricType.sleep;
    }

    if (text.contains(RegExp(r'(heart|bpm|beats)', caseSensitive: false))) {
      return HealthMetricType.heartRate;
    }

    if (text.contains(RegExp(r'(calories|cal|burned)', caseSensitive: false))) {
      return HealthMetricType.calories;
    }

    return null;
  }

  /// Extract reminder time from text based on time-of-day keywords
  String? _extractReminderTime(String text) {
    // Check for specific times first (e.g., "9:00", "09:00 AM")
    final timePattern =
        RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?', caseSensitive: false);
    final timeMatch = timePattern.firstMatch(text);

    if (timeMatch != null) {
      var hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      final ampm = timeMatch.group(3)?.toLowerCase();

      // Convert to 24-hour format
      if (ampm == 'pm' && hour != 12) {
        hour += 12;
      } else if (ampm == 'am' && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    // Fall back to time-of-day keywords
    final timeOfDay = _extractTimeOfDay(text);
    if (timeOfDay != null) {
      return _timeOfDayToReminderTime(timeOfDay);
    }

    return null;
  }

  /// Extract time-of-day keyword from text
  String? _extractTimeOfDay(String text) {
    if (text.contains(
        RegExp(r'\bmorning\b|\bam\b|\bearly\b', caseSensitive: false))) {
      return 'morning';
    }

    if (text.contains(
        RegExp(r'\bafternoon\b|\bnoon\b|\bmidday\b', caseSensitive: false))) {
      return 'afternoon';
    }

    if (text.contains(
        RegExp(r'\bevening\b|\bpm\b|\bdusk\b', caseSensitive: false))) {
      return 'evening';
    }

    if (text.contains(
        RegExp(r'\bnight\b|\bbedtime\b|\blate\b', caseSensitive: false))) {
      return 'night';
    }

    return null;
  }

  /// Extract focus duration in minutes from text
  /// Examples: "10 min yoga", "30 minutes stretch", "5-minute meditation"
  int? _extractFocusDuration(String text) {
    // Pattern: number followed by "min" or "minute" (for activities like yoga, meditation, stretching)
    // Match patterns like: "10 min", "30 minutes", "5-minute"
    final patterns = [
      // "10 min", "30 mins"
      RegExp(r'(\d+)\s*mins?(?!\s*(?:walk|run|jog|cycle))',
          caseSensitive: false),

      // "30 minutes", "5-minute"
      RegExp(r'(\d+)[\s-]*minutes?(?!\s*(?:walk|run|jog|cycle))',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final minutes = int.tryParse(match.group(1)!);
        // Only accept reasonable focus durations (5-120 minutes)
        if (minutes != null && minutes >= 5 && minutes <= 120) {
          return minutes;
        }
      }
    }

    return null;
  }

  /// Convert time-of-day to specific reminder time (HH:MM)
  String _timeOfDayToReminderTime(String timeOfDay) {
    switch (timeOfDay) {
      case 'morning':
        return '09:00';
      case 'afternoon':
        return '14:00';
      case 'evening':
        return '18:00';
      case 'night':
        return '21:00';
      default:
        return '09:00';
    }
  }

  /// Get a friendly display string for the reminder time
  String getReminderDisplayTime(String time24) {
    final parts = time24.split(':');
    var hour = int.parse(parts[0]);
    final minute = parts[1];

    final ampm = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    return '$hour:$minute $ampm';
  }

  /// Get a friendly display string for health goal
  String getHealthGoalDisplayString(double value, HealthMetricType type) {
    final unit = switch (type) {
      HealthMetricType.steps => 'steps',
      HealthMetricType.distance => 'km',
      HealthMetricType.sleep => 'hours',
      HealthMetricType.heartRate => 'bpm',
      HealthMetricType.calories => 'calories',
    };

    final valueStr = switch (type) {
      HealthMetricType.steps => value.toInt().toString(),
      HealthMetricType.heartRate => value.toInt().toString(),
      HealthMetricType.calories => value.toInt().toString(),
      _ => value.toStringAsFixed(1),
    };

    return '$valueStr $unit';
  }
}
