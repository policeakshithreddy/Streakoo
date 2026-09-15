import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import 'groq_ai_service.dart';

/// Service for suggesting habit stacks (linking habits together)
/// Based on the "habit stacking" concept from Atomic Habits
class HabitStackingService {
  static final HabitStackingService instance = HabitStackingService._();
  HabitStackingService._();

  static const _prefsKeyStacks = 'habit_stacks';

  List<HabitStack> _savedStacks = [];
  List<HabitStack> get savedStacks => _savedStacks;

  /// Initialize and load saved stacks
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final stacksJson = prefs.getString(_prefsKeyStacks);
    if (stacksJson != null) {
      final list = jsonDecode(stacksJson) as List;
      _savedStacks = list
          .map((e) => HabitStack.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  /// Suggest habit stacks based on completion patterns
  List<HabitStackSuggestion> suggestStacks(List<Habit> habits) {
    final suggestions = <HabitStackSuggestion>[];

    // Find habits that are often completed together
    for (int i = 0; i < habits.length; i++) {
      for (int j = i + 1; j < habits.length; j++) {
        final habitA = habits[i];
        final habitB = habits[j];

        // Calculate correlation score
        final correlation = _calculateCorrelation(habitA, habitB);

        if (correlation > 0.6) {
          // Strong correlation
          // Determine which should come first based on typical order
          final (trigger, target) = _determineOrder(habitA, habitB);

          suggestions.add(HabitStackSuggestion(
            triggerHabit: trigger,
            targetHabit: target,
            correlationScore: correlation,
            cuePhrase: _generateDefaultCue(trigger, target),
          ));
        }
      }
    }

    // Sort by correlation score
    suggestions
        .sort((a, b) => b.correlationScore.compareTo(a.correlationScore));

    return suggestions.take(5).toList(); // Top 5 suggestions
  }

  /// Calculate how often two habits are completed on the same day
  double _calculateCorrelation(Habit habitA, Habit habitB) {
    if (habitA.completionDates.isEmpty || habitB.completionDates.isEmpty) {
      return 0.0;
    }

    final setA = habitA.completionDates.toSet();
    final setB = habitB.completionDates.toSet();

    // Count common completion dates
    final commonDates = setA.intersection(setB).length;
    final totalDates = setA.union(setB).length;

    if (totalDates == 0) return 0.0;

    return commonDates / totalDates;
  }

  /// Determine which habit should trigger which based on typical patterns
  (Habit trigger, Habit target) _determineOrder(Habit habitA, Habit habitB) {
    // Heuristics for ordering:
    // 1. Morning habits trigger others
    // 2. Exercise habits often come first
    // 3. Meditation/mindfulness often comes first
    // 4. Reading often comes last

    int scoreA = _getTriggerPriority(habitA);
    int scoreB = _getTriggerPriority(habitB);

    if (scoreA >= scoreB) {
      return (habitA, habitB);
    } else {
      return (habitB, habitA);
    }
  }

  /// Get priority score for being a trigger (higher = more likely to be trigger)
  int _getTriggerPriority(Habit habit) {
    int score = 0;
    final nameLower = habit.name.toLowerCase();

    // Morning routines
    if (nameLower.contains('wake') || nameLower.contains('morning')) {
      score += 10;
    }
    if (nameLower.contains('coffee') || nameLower.contains('breakfast')) {
      score += 8;
    }

    // Exercise
    if (nameLower.contains('exercise') || nameLower.contains('workout')) {
      score += 7;
    }
    if (nameLower.contains('gym') || nameLower.contains('run')) {
      score += 7;
    }

    // Mindfulness
    if (nameLower.contains('meditat') || nameLower.contains('mindful')) {
      score += 6;
    }

    // Grooming
    if (nameLower.contains('shower') || nameLower.contains('brush')) {
      score += 5;
    }

    // Work-related
    if (nameLower.contains('work') || nameLower.contains('email')) {
      score += 3;
    }

    // Evening/end activities get low priority (should be targets, not triggers)
    if (nameLower.contains('read') || nameLower.contains('journal')) {
      score -= 2;
    }
    if (nameLower.contains('sleep') || nameLower.contains('bed')) {
      score -= 5;
    }

    return score;
  }

  /// Generate a default cue phrase
  String _generateDefaultCue(Habit trigger, Habit target) {
    return 'After I ${_verbify(trigger.name)}, I will ${_verbify(target.name)}';
  }

  /// Convert habit name to verb form
  String _verbify(String habitName) {
    final lower = habitName.toLowerCase();

    // Already starts with verb
    if (lower.startsWith('do ') ||
        lower.startsWith('make ') ||
        lower.startsWith('take ') ||
        lower.startsWith('read ') ||
        lower.startsWith('write ') ||
        lower.startsWith('practice ')) {
      return lower;
    }

    // Common patterns
    if (lower.contains('meditation')) return 'meditate';
    if (lower.contains('exercise')) return 'exercise';
    if (lower.contains('reading')) return 'read';
    if (lower.contains('running')) return 'go for a run';
    if (lower.contains('walking')) return 'go for a walk';
    if (lower.contains('journaling')) return 'journal';
    if (lower.contains('workout')) return 'workout';

    // Default: just return the name
    return 'do "$habitName"';
  }

  /// Save a habit stack
  Future<void> saveStack(HabitStack stack) async {
    _savedStacks.add(stack);
    await _save();
  }

  /// Remove a habit stack
  Future<void> removeStack(String stackId) async {
    _savedStacks.removeWhere((s) => s.id == stackId);
    await _save();
  }

  /// Save to storage
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKeyStacks,
      jsonEncode(_savedStacks.map((e) => e.toJson()).toList()),
    );
  }

  /// Generate AI-powered cue phrase (uses Groq)
  Future<String> generateAICuePhrase(Habit trigger, Habit target) async {
    try {
      final response = await GroqAIService.instance.generateChatResponse(
        messages: [
          {
            'role': 'system',
            'content':
                '''You are a habit coach. Generate a short, actionable habit stacking cue phrase.
Format: "After I [trigger habit], I will [target habit] because [brief reason]."
Keep it under 20 words. Make it personal and motivating.'''
          },
          {
            'role': 'user',
            'content': 'Trigger: ${trigger.name}\nTarget: ${target.name}'
          }
        ],
      );

      return response ?? _generateDefaultCue(trigger, target);
    } catch (e) {
      debugPrint('Failed to generate AI cue: $e');
      return _generateDefaultCue(trigger, target);
    }
  }
}

/// A suggestion for stacking two habits together
class HabitStackSuggestion {
  final Habit triggerHabit;
  final Habit targetHabit;
  final double correlationScore;
  final String cuePhrase;

  HabitStackSuggestion({
    required this.triggerHabit,
    required this.targetHabit,
    required this.correlationScore,
    required this.cuePhrase,
  });
}

/// A saved habit stack
class HabitStack {
  final String id;
  final String triggerHabitId;
  final String targetHabitId;
  final String cuePhrase;
  final DateTime createdAt;
  final bool isActive;

  HabitStack({
    required this.id,
    required this.triggerHabitId,
    required this.targetHabitId,
    required this.cuePhrase,
    required this.createdAt,
    this.isActive = true,
  });

  factory HabitStack.fromJson(Map<String, dynamic> json) => HabitStack(
        id: json['id'] as String,
        triggerHabitId: json['triggerHabitId'] as String,
        targetHabitId: json['targetHabitId'] as String,
        cuePhrase: json['cuePhrase'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'triggerHabitId': triggerHabitId,
        'targetHabitId': targetHabitId,
        'cuePhrase': cuePhrase,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };
}
