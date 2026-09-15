import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that learns optimal reminder times from user completion patterns
class SmartTimeService {
  SmartTimeService._();
  static final SmartTimeService instance = SmartTimeService._();

  static const String _prefsKey = 'smart_time_data';

  // Stores completion times per habit: {habitId: [hour1, hour2, ...]}
  Map<String, List<int>> _completionHours = {};

  // Minimum completions needed before suggesting
  static const int _minCompletionsForSuggestion = 5;

  /// Initialize service and load stored data
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data != null) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        _completionHours = decoded.map(
          (k, v) => MapEntry(k, List<int>.from(v)),
        );
        debugPrint(
            '📊 SmartTimeService: Loaded ${_completionHours.length} habit time patterns');
      } catch (e) {
        debugPrint('⚠️ SmartTimeService: Error loading data: $e');
        _completionHours = {};
      }
    }
  }

  /// Record a habit completion time
  Future<void> recordCompletion(String habitId) async {
    final now = DateTime.now();
    final hour = now.hour;

    _completionHours[habitId] ??= [];
    _completionHours[habitId]!.add(hour);

    // Keep only last 30 completions per habit
    if (_completionHours[habitId]!.length > 30) {
      _completionHours[habitId] = _completionHours[habitId]!.sublist(
        _completionHours[habitId]!.length - 30,
      );
    }

    await _save();
    debugPrint(
        '⏰ SmartTimeService: Recorded completion for $habitId at $hour:00');
  }

  /// Get suggested reminder time for a habit
  TimeOfDay? getSuggestedTime(String habitId) {
    final hours = _completionHours[habitId];
    if (hours == null || hours.length < _minCompletionsForSuggestion) {
      return null; // Not enough data
    }

    // Calculate most frequent hour
    final frequency = <int, int>{};
    for (final hour in hours) {
      frequency[hour] = (frequency[hour] ?? 0) + 1;
    }

    // Find the most common hour
    int bestHour = hours.first;
    int maxCount = 0;
    frequency.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        bestHour = hour;
      }
    });

    // Suggest 30 minutes before the most common completion time
    int suggestedHour = bestHour;
    int suggestedMinute = 30;

    // If best hour is 0 (midnight), suggest 23:30
    if (bestHour == 0) {
      suggestedHour = 23;
      suggestedMinute = 30;
    } else {
      suggestedHour = bestHour - 1;
      suggestedMinute = 30;
    }

    return TimeOfDay(hour: suggestedHour, minute: suggestedMinute);
  }

  /// Get suggestion confidence (percentage of completions at best hour)
  double getSuggestionConfidence(String habitId) {
    final hours = _completionHours[habitId];
    if (hours == null || hours.isEmpty) return 0.0;

    final frequency = <int, int>{};
    for (final hour in hours) {
      frequency[hour] = (frequency[hour] ?? 0) + 1;
    }

    final maxCount = frequency.values.reduce((a, b) => a > b ? a : b);
    return (maxCount / hours.length * 100).clamp(0.0, 100.0);
  }

  /// Get all habits with time suggestions
  Map<String, TimeOfDay> getAllSuggestions() {
    final suggestions = <String, TimeOfDay>{};
    for (final habitId in _completionHours.keys) {
      final suggestion = getSuggestedTime(habitId);
      if (suggestion != null) {
        suggestions[habitId] = suggestion;
      }
    }
    return suggestions;
  }

  /// Get completion pattern summary for a habit
  String getPatternSummary(String habitId) {
    final hours = _completionHours[habitId];
    if (hours == null || hours.isEmpty) {
      return 'No data yet';
    }

    if (hours.length < _minCompletionsForSuggestion) {
      return '${hours.length}/$_minCompletionsForSuggestion completions tracked';
    }

    final suggestion = getSuggestedTime(habitId);
    if (suggestion == null) return 'Analyzing patterns...';

    final confidence = getSuggestionConfidence(habitId);

    if (confidence >= 70) {
      return 'You usually complete this around ${_getTimeRange(suggestion)}';
    } else if (confidence >= 40) {
      return 'Often completed around ${_getTimeRange(suggestion)}';
    } else {
      return 'Varies - most common: ${_getTimeRange(suggestion)}';
    }
  }

  String _getTimeRange(TimeOfDay time) {
    // Return a range like "7-8 AM"
    final startHour = time.hour;
    final endHour = (startHour + 2) % 24;

    String formatHour(int h) {
      final period = h >= 12 ? 'PM' : 'AM';
      final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$hour $period';
    }

    return '${formatHour(startHour)} - ${formatHour(endHour)}';
  }

  /// Clear all data for a habit
  Future<void> clearHabitData(String habitId) async {
    _completionHours.remove(habitId);
    await _save();
  }

  /// Clear all data
  Future<void> clearAll() async {
    _completionHours.clear();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_completionHours));
  }
}
