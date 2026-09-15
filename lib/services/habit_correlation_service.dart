import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

/// A correlation insight between two habits
class HabitCorrelation {
  final String habit1Id;
  final String habit1Name;
  final String habit1Emoji;
  final String habit2Id;
  final String habit2Name;
  final String habit2Emoji;
  final double correlationScore; // -1 to 1
  final int sampleSize;
  final String insight;

  const HabitCorrelation({
    required this.habit1Id,
    required this.habit1Name,
    required this.habit1Emoji,
    required this.habit2Id,
    required this.habit2Name,
    required this.habit2Emoji,
    required this.correlationScore,
    required this.sampleSize,
    required this.insight,
  });

  /// Is this a strong positive correlation?
  bool get isStrongPositive => correlationScore >= 0.5;

  /// Is this a moderate correlation?
  bool get isModerate =>
      correlationScore.abs() >= 0.3 && correlationScore.abs() < 0.5;

  /// Get correlation strength label
  String get strengthLabel {
    final abs = correlationScore.abs();
    if (abs >= 0.7) return 'Very Strong';
    if (abs >= 0.5) return 'Strong';
    if (abs >= 0.3) return 'Moderate';
    return 'Weak';
  }

  /// Get emoji representing strength
  String get strengthEmoji {
    final abs = correlationScore.abs();
    if (abs >= 0.7) return '⚡';
    if (abs >= 0.5) return '🔗';
    if (abs >= 0.3) return '↔️';
    return '∿';
  }
}

/// Service to analyze habit correlations
class HabitCorrelationService {
  HabitCorrelationService._();
  static final HabitCorrelationService instance = HabitCorrelationService._();

  static const String _prefsKey = 'habit_correlations_cache';
  static const int _minDaysForAnalysis = 14;

  List<HabitCorrelation> _cachedCorrelations = [];
  DateTime? _lastAnalysis;

  /// Get cached correlations
  List<HabitCorrelation> get correlations => _cachedCorrelations;

  /// Get top positive correlations
  List<HabitCorrelation> get topPositiveCorrelations {
    return _cachedCorrelations.where((c) => c.correlationScore > 0.3).toList()
      ..sort((a, b) => b.correlationScore.compareTo(a.correlationScore));
  }

  /// Initialize service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    if (cached != null) {
      try {
        final data = jsonDecode(cached);
        _lastAnalysis = DateTime.tryParse(data['lastAnalysis'] ?? '');
      } catch (e) {
        debugPrint('⚠️ HabitCorrelationService: Error loading cache: $e');
      }
    }
    debugPrint('🔗 HabitCorrelationService initialized');
  }

  /// Analyze correlations between habits
  Future<List<HabitCorrelation>> analyzeCorrelations(List<Habit> habits) async {
    if (habits.length < 2) return [];

    // Check if we have enough data
    final maxDays = habits.map((h) => h.completionDates.length).reduce(max);
    if (maxDays < _minDaysForAnalysis) {
      debugPrint(
          '🔗 Not enough data for correlation analysis (need $_minDaysForAnalysis days)');
      return [];
    }

    final correlations = <HabitCorrelation>[];

    // Compare all pairs of habits
    for (int i = 0; i < habits.length; i++) {
      for (int j = i + 1; j < habits.length; j++) {
        final habit1 = habits[i];
        final habit2 = habits[j];

        final correlation = _calculateCorrelation(habit1, habit2);
        if (correlation != null && correlation.correlationScore.abs() >= 0.25) {
          correlations.add(correlation);
        }
      }
    }

    // Sort by absolute correlation score
    correlations.sort(
        (a, b) => b.correlationScore.abs().compareTo(a.correlationScore.abs()));

    _cachedCorrelations = correlations;
    _lastAnalysis = DateTime.now();
    await _saveCache();

    debugPrint('🔗 Found ${correlations.length} significant correlations');
    return correlations;
  }

  HabitCorrelation? _calculateCorrelation(Habit habit1, Habit habit2) {
    // Get completion dates as sets for fast lookup
    final dates1 = habit1.completionDates.toSet();
    final dates2 = habit2.completionDates.toSet();

    // Find all unique dates
    final allDates = {...dates1, ...dates2};
    if (allDates.length < _minDaysForAnalysis) return null;

    // Calculate co-occurrence
    int bothCompleted = 0;
    int onlyFirst = 0;
    int onlySecond = 0;
    int neitherCompleted = 0;

    // Use last 60 days for analysis
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 60));
    final cutoffStr = _formatDate(cutoff);

    for (final date in allDates) {
      if (date.compareTo(cutoffStr) < 0) continue;

      final in1 = dates1.contains(date);
      final in2 = dates2.contains(date);

      if (in1 && in2) {
        bothCompleted++;
      } else if (in1) {
        onlyFirst++;
      } else if (in2) {
        onlySecond++;
      } else {
        neitherCompleted++;
      }
    }

    final total = bothCompleted + onlyFirst + onlySecond + neitherCompleted;
    if (total < _minDaysForAnalysis) return null;

    // Calculate Phi coefficient (correlation for binary variables)
    final n11 = bothCompleted.toDouble();
    final n10 = onlyFirst.toDouble();
    final n01 = onlySecond.toDouble();
    final n00 = neitherCompleted.toDouble();

    final r1 = n11 + n10;
    final r2 = n01 + n00;
    final c1 = n11 + n01;
    final c2 = n10 + n00;

    if (r1 == 0 || r2 == 0 || c1 == 0 || c2 == 0) return null;

    final phi = (n11 * n00 - n10 * n01) / sqrt(r1 * r2 * c1 * c2);

    // Generate insight text
    final insight = _generateInsight(habit1, habit2, phi, bothCompleted, total);

    return HabitCorrelation(
      habit1Id: habit1.id,
      habit1Name: habit1.name,
      habit1Emoji: habit1.emoji,
      habit2Id: habit2.id,
      habit2Name: habit2.name,
      habit2Emoji: habit2.emoji,
      correlationScore: phi,
      sampleSize: total,
      insight: insight,
    );
  }

  String _generateInsight(
      Habit habit1, Habit habit2, double phi, int coOccurrences, int total) {
    final percent = ((coOccurrences / total) * 100).round();

    if (phi >= 0.7) {
      return '${habit1.emoji} ${habit1.name} and ${habit2.emoji} ${habit2.name} are best buddies! They happen together $percent% of the time.';
    } else if (phi >= 0.5) {
      return 'When you complete ${habit1.emoji} ${habit1.name}, you\'re much more likely to also complete ${habit2.emoji} ${habit2.name}!';
    } else if (phi >= 0.3) {
      return '${habit1.emoji} ${habit1.name} seems to support ${habit2.emoji} ${habit2.name}. Consider stacking them!';
    } else if (phi <= -0.5) {
      return '${habit1.emoji} ${habit1.name} and ${habit2.emoji} ${habit2.name} rarely happen on the same day. Might be competing for time.';
    } else if (phi <= -0.3) {
      return 'Interesting: ${habit1.emoji} ${habit1.name} and ${habit2.emoji} ${habit2.name} tend to happen on different days.';
    } else {
      return '${habit1.emoji} ${habit1.name} and ${habit2.emoji} ${habit2.name} are independent - no strong link found.';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get habit stacking suggestions based on correlations
  List<String> getStackingSuggestions() {
    final suggestions = <String>[];

    for (final corr in topPositiveCorrelations.take(3)) {
      suggestions.add(
          'Try stacking ${corr.habit1Emoji} ${corr.habit1Name} → ${corr.habit2Emoji} ${corr.habit2Name}');
    }

    return suggestions;
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey,
        jsonEncode({
          'lastAnalysis': _lastAnalysis?.toIso8601String(),
        }));
  }

  /// Get a summary insight card
  String? getSummaryInsight() {
    if (_cachedCorrelations.isEmpty) return null;

    final best = topPositiveCorrelations.firstOrNull;
    if (best == null) return null;

    final percentStr = '${(best.correlationScore * 100).round()}%';
    return '${best.habit1Emoji} ${best.habit1Name} + ${best.habit2Emoji} ${best.habit2Name}: $percentStr linked';
  }
}
