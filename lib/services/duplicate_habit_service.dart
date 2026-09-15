import 'package:flutter/foundation.dart';
import '../models/habit.dart';

/// Result of duplicate detection - a pair of potentially duplicate habits
class DuplicateHabitPair {
  final Habit habit1;
  final Habit habit2;
  final double similarityScore;
  final String matchReason; // 'name', 'emoji_category', 'both'

  const DuplicateHabitPair({
    required this.habit1,
    required this.habit2,
    required this.similarityScore,
    required this.matchReason,
  });

  /// Determine which habit is likely the "original" (older, more completions)
  Habit get originalHabit {
    // Prefer habit with more completion dates
    if (habit1.completionDates.length > habit2.completionDates.length) {
      return habit1;
    }
    if (habit2.completionDates.length > habit1.completionDates.length) {
      return habit2;
    }
    // Prefer habit with higher streak
    if (habit1.streak > habit2.streak) return habit1;
    if (habit2.streak > habit1.streak) return habit2;
    // Prefer habit created first (lower ID timestamp)
    final id1 = int.tryParse(habit1.id) ?? 0;
    final id2 = int.tryParse(habit2.id) ?? 0;
    return id1 < id2 ? habit1 : habit2;
  }

  Habit get duplicateHabit => originalHabit == habit1 ? habit2 : habit1;
}

/// Options for merging two habits
class MergeOptions {
  final String keepGoalFrom; // 'primary', 'secondary', 'combine'
  final String keepReminderFrom; // 'primary', 'secondary', 'none'
  final String keepHealthGoalFrom; // 'primary', 'secondary', 'none'

  const MergeOptions({
    this.keepGoalFrom = 'primary',
    this.keepReminderFrom = 'primary',
    this.keepHealthGoalFrom = 'primary',
  });

  /// Default: keep all automations from primary (original) habit
  static const MergeOptions keepPrimary = MergeOptions();

  /// Keep automations from secondary (duplicate) habit
  static const MergeOptions keepSecondary = MergeOptions(
    keepGoalFrom: 'secondary',
    keepReminderFrom: 'secondary',
    keepHealthGoalFrom: 'secondary',
  );
}

/// Request for a single merge operation (used for batch processing)
class MergeRequest {
  final String primaryId;
  final String secondaryId;
  final MergeOptions options;

  const MergeRequest({
    required this.primaryId,
    required this.secondaryId,
    required this.options,
  });
}

/// Service for detecting and merging duplicate habits
class DuplicateHabitService {
  DuplicateHabitService._();
  static final DuplicateHabitService instance = DuplicateHabitService._();

  /// Similarity threshold for name matching (0.0 - 1.0)
  static const double _similarityThreshold = 0.8;

  /// Detect duplicates in a list of habits
  List<DuplicateHabitPair> detectDuplicates(List<Habit> habits) {
    final duplicates = <DuplicateHabitPair>[];
    final processedPairs = <String>{};

    for (int i = 0; i < habits.length; i++) {
      for (int j = i + 1; j < habits.length; j++) {
        final habit1 = habits[i];
        final habit2 = habits[j];

        // Create unique pair key to avoid duplicates
        final pairKey = _createPairKey(habit1.id, habit2.id);
        if (processedPairs.contains(pairKey)) continue;
        processedPairs.add(pairKey);

        // Check for duplicates
        final pair = _checkDuplicate(habit1, habit2);
        if (pair != null) {
          duplicates.add(pair);
        }
      }
    }

    debugPrint(
        '🔍 Duplicate detection: found ${duplicates.length} potential duplicates');
    return duplicates;
  }

  String _createPairKey(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  DuplicateHabitPair? _checkDuplicate(Habit habit1, Habit habit2) {
    // Calculate name similarity
    final nameSimilarity = calculateSimilarity(
      habit1.name.toLowerCase().trim(),
      habit2.name.toLowerCase().trim(),
    );

    // Check emoji + category match
    final emojiMatch = habit1.emoji == habit2.emoji;
    final categoryMatch = habit1.category == habit2.category;
    final emojiCategoryMatch = emojiMatch && categoryMatch;

    // Determine if duplicate
    bool isDuplicate = false;
    String matchReason = '';

    if (nameSimilarity >= _similarityThreshold && emojiCategoryMatch) {
      isDuplicate = true;
      matchReason = 'both';
    } else if (nameSimilarity >= _similarityThreshold) {
      isDuplicate = true;
      matchReason = 'name';
    } else if (emojiCategoryMatch && nameSimilarity >= 0.5) {
      // Lower threshold if emoji+category match
      isDuplicate = true;
      matchReason = 'emoji_category';
    }

    if (isDuplicate) {
      debugPrint(
          '  ⚠️ Duplicate found: "${habit1.name}" <-> "${habit2.name}" (similarity: ${nameSimilarity.toStringAsFixed(2)}, reason: $matchReason)');
      return DuplicateHabitPair(
        habit1: habit1,
        habit2: habit2,
        similarityScore: nameSimilarity,
        matchReason: matchReason,
      );
    }

    return null;
  }

  /// Calculate string similarity using Levenshtein distance
  /// Returns a value between 0.0 (completely different) and 1.0 (identical)
  double calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLen = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLen);
  }

  int _levenshteinDistance(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;

    // Create matrix
    final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    // Initialize first column and row
    for (int i = 0; i <= m; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      d[0][j] = j;
    }

    // Fill in the rest
    for (int j = 1; j <= n; j++) {
      for (int i = 1; i <= m; i++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1, // deletion
          d[i][j - 1] + 1, // insertion
          d[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return d[m][n];
  }

  /// Merge two habits into one, applying the given options
  Habit mergeHabits(Habit primary, Habit secondary, MergeOptions options) {
    // Determine field values based on options
    String? habitGoal;
    switch (options.keepGoalFrom) {
      case 'secondary':
        habitGoal = secondary.habitGoal ?? primary.habitGoal;
        break;
      case 'combine':
        if (primary.habitGoal != null && secondary.habitGoal != null) {
          habitGoal = '${primary.habitGoal}\n${secondary.habitGoal}';
        } else {
          habitGoal = primary.habitGoal ?? secondary.habitGoal;
        }
        break;
      default: // 'primary'
        habitGoal = primary.habitGoal ?? secondary.habitGoal;
    }

    String? reminderTime;
    bool reminderEnabled;
    switch (options.keepReminderFrom) {
      case 'secondary':
        reminderTime = secondary.reminderTime ?? primary.reminderTime;
        reminderEnabled = secondary.reminderEnabled || primary.reminderEnabled;
        break;
      case 'none':
        reminderTime = null;
        reminderEnabled = false;
        break;
      default: // 'primary'
        reminderTime = primary.reminderTime ?? secondary.reminderTime;
        reminderEnabled = primary.reminderEnabled || secondary.reminderEnabled;
    }

    bool isHealthTracked;
    double? healthGoalValue;
    var healthMetric = primary.healthMetric;
    switch (options.keepHealthGoalFrom) {
      case 'secondary':
        isHealthTracked = secondary.isHealthTracked || primary.isHealthTracked;
        healthGoalValue = secondary.healthGoalValue ?? primary.healthGoalValue;
        healthMetric = secondary.healthMetric ?? primary.healthMetric;
        break;
      case 'none':
        isHealthTracked = false;
        healthGoalValue = null;
        healthMetric = null;
        break;
      default: // 'primary'
        isHealthTracked = primary.isHealthTracked || secondary.isHealthTracked;
        healthGoalValue = primary.healthGoalValue ?? secondary.healthGoalValue;
        healthMetric = primary.healthMetric ?? secondary.healthMetric;
    }

    // Merge completion dates (union of both)
    final mergedDates = <String>{
      ...primary.completionDates,
      ...secondary.completionDates,
    }.toList()
      ..sort();

    // Keep higher streak
    final mergedStreak =
        primary.streak > secondary.streak ? primary.streak : secondary.streak;

    // Merge challenge progress
    final mergedChallengeProgress =
        primary.challengeProgress > secondary.challengeProgress
            ? primary.challengeProgress
            : secondary.challengeProgress;

    return primary.copyWith(
      habitGoal: habitGoal,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      isHealthTracked: isHealthTracked,
      healthGoalValue: healthGoalValue,
      healthMetric: healthMetric,
      completionDates: mergedDates,
      streak: mergedStreak,
      challengeProgress: mergedChallengeProgress,
      focusModeDuration:
          primary.focusModeDuration ?? secondary.focusModeDuration,
    );
  }
}
