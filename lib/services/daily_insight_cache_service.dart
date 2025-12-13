import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_health_coach_service.dart';

/// Service to cache AI-generated daily insights and refresh them each morning
class DailyInsightCacheService {
  static final DailyInsightCacheService instance = DailyInsightCacheService._();
  DailyInsightCacheService._();

  final _aiService = AIHealthCoachService.instance;

  // SharedPreferences keys
  static const _keyInsightText = 'daily_insight_text';
  static const _keyInsightDate = 'daily_insight_date';
  static const _keyInsightTimestamp = 'daily_insight_timestamp';

  // Morning refresh window (6 AM - 10 AM)
  static const _morningStartHour = 6;
  static const _morningEndHour = 10;

  /// Get cached insight if still valid for today, otherwise generate new one
  Future<String?> getDailyInsight({
    required List<int> weeklySteps,
    required List<double> weeklySleep,
    required int habitsCompleted,
    required int currentStreak,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we should refresh the insight
      if (await shouldRefreshInsight()) {
        debugPrint('🔄 Generating new daily insight...');
        return await generateAndCacheInsight(
          weeklySteps: weeklySteps,
          weeklySleep: weeklySleep,
          habitsCompleted: habitsCompleted,
          currentStreak: currentStreak,
        );
      }

      // Return cached insight if still valid
      final cachedInsight = prefs.getString(_keyInsightText);
      if (cachedInsight != null && cachedInsight.isNotEmpty) {
        debugPrint('✅ Using cached daily insight');
        return cachedInsight;
      }

      // No cache found, generate new one
      debugPrint('🆕 No cached insight found, generating...');
      return await generateAndCacheInsight(
        weeklySteps: weeklySteps,
        weeklySleep: weeklySleep,
        habitsCompleted: habitsCompleted,
        currentStreak: currentStreak,
      );
    } catch (e) {
      debugPrint('Error getting daily insight: $e');
      return null;
    }
  }

  /// Determine if insight should be refreshed
  Future<bool> shouldRefreshInsight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Get last generation date
      final lastDateStr = prefs.getString(_keyInsightDate);
      if (lastDateStr == null) {
        return true; // No cache, needs generation
      }

      final lastDate = DateTime.parse(lastDateStr);
      final today = DateTime(now.year, now.month, now.day);
      final cachedDay = DateTime(lastDate.year, lastDate.month, lastDate.day);

      // If it's a different day, check if we're in the morning window
      if (today.isAfter(cachedDay)) {
        // New day - check if we're in morning refresh window
        final currentHour = now.hour;
        if (currentHour >= _morningStartHour && currentHour < _morningEndHour) {
          debugPrint(
              '☀️ Morning refresh time ($currentHour:00), refreshing insight');
          return true;
        }
        // If past morning window but different day, still refresh
        if (currentHour >= _morningEndHour) {
          debugPrint('📅 New day detected, refreshing insight');
          return true;
        }
      }

      return false; // Same day or before morning window
    } catch (e) {
      debugPrint('Error checking refresh status: $e');
      return true; // On error, refresh to be safe
    }
  }

  /// Generate new insight and cache it
  Future<String> generateAndCacheInsight({
    required List<int> weeklySteps,
    required List<double> weeklySleep,
    required int habitsCompleted,
    required int currentStreak,
  }) async {
    try {
      // Generate new insight using AI service
      final insight = await _aiService.generateSmartInsight(
        weeklySteps: weeklySteps,
        weeklySleep: weeklySleep,
        habitsCompleted: habitsCompleted,
        currentStreak: currentStreak,
      );

      // Cache the insight with timestamp
      await _cacheInsight(insight);

      return insight;
    } catch (e) {
      debugPrint('Error generating and caching insight: $e');

      // Try to return cached insight as fallback
      final prefs = await SharedPreferences.getInstance();
      final cachedInsight = prefs.getString(_keyInsightText);

      return cachedInsight ??
          "Keep pushing forward! Consistency is the key to achieving your health goals! 💪";
    }
  }

  /// Cache insight with current timestamp
  Future<void> _cacheInsight(String insight) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setString(_keyInsightText, insight);
      await prefs.setString(_keyInsightDate, now.toIso8601String());
      await prefs.setInt(_keyInsightTimestamp, now.millisecondsSinceEpoch);

      debugPrint('💾 Cached daily insight at ${now.hour}:${now.minute}');
    } catch (e) {
      debugPrint('Error caching insight: $e');
    }
  }

  /// Get the timestamp of when the current insight was generated
  Future<DateTime?> getInsightGenerationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_keyInsightTimestamp);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('Error getting insight timestamp: $e');
    }
    return null;
  }

  /// Clear cached insight (useful for testing)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInsightText);
      await prefs.remove(_keyInsightDate);
      await prefs.remove(_keyInsightTimestamp);
      debugPrint('🗑️ Cleared daily insight cache');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cached insight without regenerating (for display purposes)
  Future<String?> getCachedInsightOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyInsightText);
    } catch (e) {
      debugPrint('Error getting cached insight: $e');
      return null;
    }
  }
}
