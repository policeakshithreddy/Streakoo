import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/app_state.dart';
import '../services/groq_ai_service.dart';
import '../config/app_config.dart';

/// Pet stages that evolve based on user level
enum PetStage {
  egg(0, 'Egg', '🥚'),
  hatchling(2, 'Hatchling', '🐣'),
  baby(5, 'Baby', '🐥'),
  teen(10, 'Teen', '🐤'),
  adult(20, 'Adult', '🐔'),
  master(35, 'Master', '🐓'),
  legendary(50, 'Legendary', '🦅');

  final int requiredLevel;
  final String name;
  final String emoji;

  const PetStage(this.requiredLevel, this.name, this.emoji);

  /// Get the stage for a given level
  static PetStage forLevel(int level) {
    PetStage result = egg;
    for (final stage in PetStage.values) {
      if (level >= stage.requiredLevel) {
        result = stage;
      }
    }
    return result;
  }

  /// Get next stage or null if at max
  PetStage? get nextStage {
    final idx = PetStage.values.indexOf(this);
    if (idx < PetStage.values.length - 1) {
      return PetStage.values[idx + 1];
    }
    return null;
  }

  /// Levels until next stage
  int levelsUntilNext(int currentLevel) {
    final next = nextStage;
    if (next == null) return 0;
    return (next.requiredLevel - currentLevel).clamp(0, 999);
  }
}

/// Pet moods based on recent activity
enum PetMood {
  excited('Excited', '✨', 'Great job! Keep going!'),
  happy('Happy', '😊', 'Your pet is loving the progress!'),
  content('Content', '😌', 'Doing well, keep it up!'),
  neutral('Neutral', '😐', 'Complete a habit to cheer me up!'),
  sleepy('Sleepy', '😴', "I haven't seen you in a while..."),
  worried('Worried', '😟', 'Your streaks need attention!'),
  disappointed('Disappointed', '😢', 'Oh no! We missed a goal...');

  final String name;
  final String emoji;
  final String message;

  const PetMood(this.name, this.emoji, this.message);
}

/// The evolving pet companion
class StreakooPet {
  final PetStage stage;
  final PetMood mood;
  final int happinessLevel; // 0-100
  final DateTime lastInteraction;
  final int totalCompletionsToday;
  final String? customName;
  final double progressWithinLevel; // 0.0 - 1.0 progress in current level

  StreakooPet({
    required this.stage,
    required this.mood,
    required this.happinessLevel,
    required this.lastInteraction,
    this.totalCompletionsToday = 0,
    this.customName,
    this.progressWithinLevel = 0.0,
  });

  /// Create a pet based on current user state
  factory StreakooPet.fromUserState({
    required int userLevel,
    required int completionsToday,
    required int totalHabits,
    required int streaksAtRisk,
    DateTime? lastCompletion,
    bool hasMissedHabitToday = false,
    double progressWithinLevel = 0.0,
  }) {
    final stage = PetStage.forLevel(userLevel);
    final mood = _calculateMood(
      completionsToday: completionsToday,
      totalHabits: totalHabits,
      streaksAtRisk: streaksAtRisk,
      lastCompletion: lastCompletion,
      hasMissedHabitToday: hasMissedHabitToday,
    );
    final happiness = _calculateHappiness(
      completionsToday: completionsToday,
      totalHabits: totalHabits,
      streaksAtRisk: streaksAtRisk,
    );

    return StreakooPet(
      stage: stage,
      mood: mood,
      happinessLevel: happiness,
      lastInteraction: lastCompletion ?? DateTime.now(),
      totalCompletionsToday: completionsToday,
      progressWithinLevel: progressWithinLevel,
    );
  }

  static PetMood _calculateMood({
    required int completionsToday,
    required int totalHabits,
    required int streaksAtRisk,
    DateTime? lastCompletion,
    bool hasMissedHabitToday = false,
  }) {
    // Check for disappointed state (missed habit)
    if (hasMissedHabitToday) return PetMood.disappointed;
    // Check for worried state first
    if (streaksAtRisk > 2) return PetMood.worried;

    // Check for sleepy (no completion in 24+ hours)
    if (lastCompletion != null) {
      final hoursSince = DateTime.now().difference(lastCompletion).inHours;
      if (hoursSince > 24) return PetMood.sleepy;
    }

    // Calculate completion percentage
    if (totalHabits == 0) return PetMood.neutral;
    final percentage = completionsToday / totalHabits;

    if (percentage >= 1.0) return PetMood.excited;
    if (percentage >= 0.75) return PetMood.happy;
    if (percentage >= 0.5) return PetMood.content;
    if (percentage > 0) return PetMood.neutral;

    return PetMood.neutral;
  }

  static int _calculateHappiness({
    required int completionsToday,
    required int totalHabits,
    required int streaksAtRisk,
  }) {
    if (totalHabits == 0) return 50;

    // Base happiness from completions
    int happiness = ((completionsToday / totalHabits) * 80).round();

    // Penalty for at-risk streaks
    happiness -= streaksAtRisk * 10;

    // Bonus for completing all
    if (completionsToday >= totalHabits) {
      happiness += 20;
    }

    return happiness.clamp(0, 100);
  }

  /// Get display emoji combining stage and mood
  String get displayEmoji =>
      mood == PetMood.excited ? '${stage.emoji}${mood.emoji}' : stage.emoji;

  /// Get display name
  String get displayName => customName ?? stage.name;

  /// Get progress to next stage (0.0 - 1.0)
  /// Now accounts for XP progress within the current level!
  double progressToNextStage(int currentLevel) {
    final next = stage.nextStage;
    if (next == null) return 1.0;

    final levelsInCurrentStage = currentLevel - stage.requiredLevel;
    final levelsNeeded = next.requiredLevel - stage.requiredLevel;

    // Calculate total progress: (levels completed in stage + current level fraction) / total levels needed
    // e.g. Stage Egg (0->2). Current Level 0, 50% XP.
    // levelsInCurrentStage = 0. levelsNeeded = 2.
    // (0 + 0.5) / 2 = 0.25 (25%)
    final totalProgress =
        (levelsInCurrentStage + progressWithinLevel) / levelsNeeded;

    return totalProgress.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'stage': stage.name,
        'mood': mood.name,
        'happinessLevel': happinessLevel,
        'lastInteraction': lastInteraction.toIso8601String(),
        'totalCompletionsToday': totalCompletionsToday,
        'customName': customName,
        'progressWithinLevel': progressWithinLevel,
      };

  factory StreakooPet.fromJson(Map<String, dynamic> json) {
    return StreakooPet(
      stage: PetStage.values.firstWhere(
        (s) => s.name == json['stage'],
        orElse: () => PetStage.egg,
      ),
      mood: PetMood.values.firstWhere(
        (m) => m.name == json['mood'],
        orElse: () => PetMood.neutral,
      ),
      happinessLevel: json['happinessLevel'] ?? 50,
      lastInteraction:
          DateTime.tryParse(json['lastInteraction'] ?? '') ?? DateTime.now(),
      totalCompletionsToday: json['totalCompletionsToday'] ?? 0,
      customName: json['customName'],
      progressWithinLevel:
          (json['progressWithinLevel'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Service to manage pet state
class StreakooPetService {
  StreakooPetService._();
  static final StreakooPetService instance = StreakooPetService._();

  static const String _prefsKey = 'streakoo_pet';
  static const String _hatchingKey = 'streakoo_pet_has_hatched';
  String? _customName;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customName = prefs.getString('${_prefsKey}_name');
    debugPrint('🐾 StreakooPetService initialized');
  }

  /// Set custom pet name
  Future<void> setCustomName(String name) async {
    _customName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefsKey}_name', name);
  }

  String? get customName => _customName;

  /// Check if user has seen the hatching animation
  Future<bool> hasSeenHatching() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hatchingKey) ?? false;
  }

  /// Mark hatching animation as seen
  Future<void> markHatchingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hatchingKey, true);
    debugPrint('🐣 Hatching animation marked as seen');
  }

  /// Reset hatching state (for testing/debugging)
  Future<void> resetHatchingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hatchingKey);
    debugPrint('🔄 Hatching state reset');
  }

  // ============ EVOLUTION TRACKING ============
  static const String _lastSeenStageKey = 'streakoo_pet_last_seen_stage';
  PetStage? _pendingEvolution;

  /// Check if there's a pending evolution the user hasn't seen
  bool get hasPendingEvolution => _pendingEvolution != null;
  PetStage? get pendingEvolution => _pendingEvolution;

  /// Check and update evolution state based on current level
  Future<void> checkEvolution(int currentLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenIndex = prefs.getInt(_lastSeenStageKey) ?? 0;
    final lastSeenStage =
        PetStage.values[lastSeenIndex.clamp(0, PetStage.values.length - 1)];
    final currentStage = PetStage.forLevel(currentLevel);

    if (currentStage.index > lastSeenStage.index) {
      _pendingEvolution = currentStage;
      debugPrint(
          '🌟 Evolution pending: ${lastSeenStage.name} → ${currentStage.name}');
    } else {
      _pendingEvolution = null;
    }
  }

  /// Mark evolution as seen (user watched animation)
  Future<void> markEvolutionSeen(PetStage stage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSeenStageKey, stage.index);
    _pendingEvolution = null;
    debugPrint('✅ Evolution to ${stage.name} marked as seen');
  }

  /// Get previous stage for animation
  Future<PetStage?> getPreviousStage() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenIndex = prefs.getInt(_lastSeenStageKey) ?? 0;
    return PetStage.values[lastSeenIndex.clamp(0, PetStage.values.length - 1)];
  }

  // ============ AI THOUGHTS ============

  /// Generate a context-aware thought from the pet
  Future<String> generatePetThought(AppState state) async {
    // 1. Try AI generation if enabled and configured
    if (AppConfig.isApiConfigured && AppConfig.useAIForCoaching) {
      try {
        final thought = await _generateAiThought(state);
        if (thought != null) return thought;
      } catch (e) {
        debugPrint('⚠️ AI Thought generation failed: $e');
      }
    }

    // 2. Fallback to smart templates
    return _generateSmartTemplate(state);
  }

  Future<String?> _generateAiThought(AppState state) async {
    final petName = state.petName;
    final streak = state.sortedHabits.isEmpty
        ? 0
        : state.sortedHabits
            .map((h) => h.streak)
            .reduce((a, b) => a > b ? a : b);
    final completed = state.habits.where((h) => h.completedToday).length;
    final total = state.habits.length;
    final missed = state.hasMissedHabitToday;

    final prompt = '''
You are "$petName", a loyal evolving pet chicken 🐔.
The user has completed $completed out of $total habits today.
Their best streak is $streak days.
${missed ? "They missed a habit today and are sad." : "They are doing great!"}

Write a VERY SHORT (max 10 words) cute/funny thought bubble message to the user.
Be supportive, funny, or hungry. Use 1 emoji.
''';

    // Use Groq service directly or via a specific method
    // Assuming GroqAIService has a generic generation method
    return GroqAIService.instance.generateResponse(
      systemPrompt: "You are a cute pet chicken. Keep it under 10 words.",
      userPrompt: prompt,
      maxTokens: 30,
      temperature: 0.9,
    );
  }

  String _generateSmartTemplate(AppState state) {
    if (state.hasMissedHabitToday) {
      return "It's okay! We'll do better tomorrow! 🐣";
    }

    final completed = state.habits.where((h) => h.completedToday).length;
    final total = state.habits.length;

    if (total > 0 && completed == total) {
      return "You're on fire today! 🔥";
    }

    if (completed > 0) {
      return "Keep going! You're doing great! 💪";
    }

    return "I believe in you! Let's start! 🚀";
  }
}
