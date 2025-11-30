import '../services/health_service.dart';

class Habit {
  // Core
  final String id;
  String name;
  String emoji;
  String category; // e.g. Health, Study, Sleep

  // Health tracking
  bool isHealthTracked; // true if auto-tracked via health data
  HealthMetricType? healthMetric; // steps, sleep, etc.
  double? healthGoalValue; // e.g., 10000 for steps

  // Streak + completion
  int streak;
  bool completedToday;
  List<String> completionDates; // ISO yyyy-MM-dd strings

  // Challenge system (optional)
  int? challengeTargetDays; // 7 / 15 / 30
  int challengeProgress;
  bool challengeCompleted;

  // Animation flag (for Lottie etc.)
  bool triggerAnimation;

  // Focus Task System
  bool isFocusTask; // true if this is a priority task for streak freeze
  int? focusTaskPriority; // ordering in focus list (lower = higher priority)

  // Gamification (XP)
  int xpValue; // XP awarded per completion
  String difficulty; // 'easy', 'medium', 'hard'

  // Customization
  String? customColor; // Hex color string
  String? customIcon; // Icon name or code
  String? reminderTime; // "HH:mm" 24-hour format
  List<int> frequencyDays; // 1=Mon, 7=Sun
  bool reminderEnabled;

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    this.category = 'General',
    this.streak = 0,
    this.completedToday = false,
    List<String>? completionDates,
    this.challengeTargetDays,
    this.challengeProgress = 0,
    this.challengeCompleted = false,
    this.triggerAnimation = false,
    this.isFocusTask = false,
    this.focusTaskPriority,
    this.xpValue = 10,
    this.difficulty = 'medium',
    this.customColor,
    this.customIcon,
    this.reminderTime,
    List<int>? frequencyDays,
    this.reminderEnabled = false,
    this.isHealthTracked = false,
    this.healthMetric,
    this.healthGoalValue,
  })  : completionDates = completionDates ?? [],
        frequencyDays = frequencyDays ?? [1, 2, 3, 4, 5, 6, 7];

  // JSON helpers
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      category: json['category'] as String? ?? 'General',
      streak: json['streak'] as int? ?? 0,
      completedToday: json['completedToday'] as bool? ?? false,
      completionDates: (json['completionDates'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      challengeTargetDays: json['challengeTargetDays'] as int?,
      challengeProgress: json['challengeProgress'] as int? ?? 0,
      challengeCompleted: json['challengeCompleted'] as bool? ?? false,
      triggerAnimation: json['triggerAnimation'] as bool? ?? false,
      isFocusTask: json['isFocusTask'] as bool? ?? false,
      focusTaskPriority: json['focusTaskPriority'] as int?,
      xpValue: json['xpValue'] as int? ?? 10,
      difficulty: json['difficulty'] as String? ?? 'medium',
      customColor: json['customColor'] as String?,
      customIcon: json['customIcon'] as String?,
      reminderTime: json['reminderTime'] as String?,
      frequencyDays: (json['frequencyDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4, 5, 6, 7],
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      isHealthTracked: json['isHealthTracked'] as bool? ?? false,
      healthMetric: json['healthMetric'] != null
          ? HealthMetricType.values[json['healthMetric'] as int]
          : null,
      healthGoalValue: json['healthGoalValue'] as double?,
    );
  }

  Habit copyWith({
    String? name,
    String? emoji,
    String? category,
    int? streak,
    bool? completedToday,
    List<String>? completionDates,
    int? challengeTargetDays,
    int? challengeProgress,
    bool? challengeCompleted,
    bool? triggerAnimation,
    bool? isFocusTask,
    int? focusTaskPriority,
    int? xpValue,
    String? difficulty,
    String? customColor,
    String? customIcon,
    String? reminderTime,
    List<int>? frequencyDays,
    bool? reminderEnabled,
    bool? isHealthTracked,
    HealthMetricType? healthMetric,
    double? healthGoalValue,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      streak: streak ?? this.streak,
      completedToday: completedToday ?? this.completedToday,
      completionDates: completionDates ?? this.completionDates,
      challengeTargetDays: challengeTargetDays ?? this.challengeTargetDays,
      challengeProgress: challengeProgress ?? this.challengeProgress,
      challengeCompleted: challengeCompleted ?? this.challengeCompleted,
      triggerAnimation: triggerAnimation ?? this.triggerAnimation,
      isFocusTask: isFocusTask ?? this.isFocusTask,
      focusTaskPriority: focusTaskPriority ?? this.focusTaskPriority,
      xpValue: xpValue ?? this.xpValue,
      difficulty: difficulty ?? this.difficulty,
      customColor: customColor ?? this.customColor,
      customIcon: customIcon ?? this.customIcon,
      reminderTime: reminderTime ?? this.reminderTime,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isHealthTracked: isHealthTracked ?? this.isHealthTracked,
      healthMetric: healthMetric ?? this.healthMetric,
      healthGoalValue: healthGoalValue ?? this.healthGoalValue,
    );
  }

  Map<String, dynamic> toJson({bool forStorage = false}) {
    final json = {
      'id': id,
      'name': name,
      'emoji': emoji,
      'category': category,
      'streak': streak,
      'completionDates': completionDates,
      'challengeTargetDays': challengeTargetDays,
      'challengeProgress': challengeProgress,
      'challengeCompleted': challengeCompleted,
      'isFocusTask': isFocusTask,
      'focusTaskPriority': focusTaskPriority,
      'xpValue': xpValue,
      'difficulty': difficulty,
      'customColor': customColor,
      'customIcon': customIcon,
      'reminderTime': reminderTime,
      'frequencyDays': frequencyDays,
      'reminderEnabled': reminderEnabled,
      'isHealthTracked': isHealthTracked,
      'healthMetric': healthMetric?.index,
      'healthGoalValue': healthGoalValue,
    };

    // Include transient/runtime fields only for local storage, not for database
    if (!forStorage) {
      json['completedToday'] = completedToday;
      json['triggerAnimation'] = triggerAnimation;
    }

    return json;
  }

  // Get XP multiplier based on difficulty
  double get xpMultiplier {
    switch (difficulty) {
      case 'easy':
        return 0.8;
      case 'hard':
        return 1.5;
      default:
        return 1.0;
    }
  }

  // Calculate actual XP awarded for completion
  int get actualXP => (xpValue * xpMultiplier).round();

  // Check if this is a sports habit
  bool get isSportsHabit => category == 'Sports';

  // Check if this habit can be manually completed
  // Sports habits can only be completed via health data or AI
  bool get canManuallyComplete => !isSportsHabit;
}
