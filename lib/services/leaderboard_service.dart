import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/user_score.dart';
import '../services/supabase_service.dart';
import 'dart:math';

/// Service to calculate and manage leaderboard scores
class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  static LeaderboardService get instance => _instance;

  final SupabaseService _supabase = SupabaseService();

  /// Calculate total score for a user
  int calculateTotalScore({
    required int dailyCompletions,
    required int longestStreak,
    required double completionRate,
    required int totalXP,
  }) {
    // Base score: 10 points per completion
    final baseScore = dailyCompletions * 10;

    // Streak bonus: 5 points per day in longest streak
    final streakBonus = longestStreak * 5;

    // Consistency bonus: Completion rate as percentage × 2
    final consistencyBonus = ((completionRate * 100) * 2).round();

    // Achievement bonus: Direct XP value
    final achievementBonus = totalXP;

    final total = baseScore + streakBonus + consistencyBonus + achievementBonus;

    debugPrint(
        '📊 Score calculated: $total (base: $baseScore, streak: $streakBonus, consistency: $consistencyBonus, xp: $achievementBonus)');

    return total;
  }

  /// Calculate score from habit list
  UserScore calculateScoreFromHabits({
    required String userId,
    required String username,
    required List<Habit> habits,
    required int totalXP,
  }) {
    if (habits.isEmpty) {
      return UserScore(
        userId: userId,
        username: username,
        totalScore: 0,
        dailyCompletions: 0,
        longestStreak: 0,
        completionRate: 0.0,
        totalXP: totalXP,
        currentWeekScore: 0,
        lastUpdated: DateTime.now(),
      );
    }

    // Calculate metrics
    final dailyCompletions = habits.fold<int>(
      0,
      (sum, habit) => sum + habit.completionDates.length,
    );

    final longestStreak = habits.map((h) => h.streak).reduce(max);

    // Calculate overall completion rate
    final now = DateTime.now();
    final daysTracking = 30; // Last 30 days
    final possibleCompletions = habits.length * daysTracking;

    int actualCompletions = 0;
    for (final habit in habits) {
      final last30Days = now.subtract(const Duration(days: 30));
      actualCompletions += habit.completionDates.where((dateStr) {
        try {
          final date = DateTime.parse(dateStr);
          return date.isAfter(last30Days);
        } catch (e) {
          return false;
        }
      }).length;
    }

    final completionRate =
        possibleCompletions > 0 ? actualCompletions / possibleCompletions : 0.0;

    // Calculate total score
    final totalScore = calculateTotalScore(
      dailyCompletions: dailyCompletions,
      longestStreak: longestStreak,
      completionRate: completionRate,
      totalXP: totalXP,
    );

    // Calculate weekly score (last 7 days)
    int weeklyCompletions = 0;
    final weekAgo = now.subtract(const Duration(days: 7));
    for (final habit in habits) {
      weeklyCompletions += habit.completionDates.where((dateStr) {
        try {
          final date = DateTime.parse(dateStr);
          return date.isAfter(weekAgo);
        } catch (e) {
          return false;
        }
      }).length;
    }
    final currentWeekScore = weeklyCompletions * 10; // Simplified weekly score

    return UserScore(
      userId: userId,
      username: username,
      totalScore: totalScore,
      dailyCompletions: dailyCompletions,
      longestStreak: longestStreak,
      completionRate: completionRate,
      totalXP: totalXP,
      currentWeekScore: currentWeekScore,
      lastUpdated: DateTime.now(),
    );
  }

  /// Sync user score to Supabase
  Future<void> syncScoreToCloud(UserScore score) async {
    if (!_supabase.isAuthenticated) {
      debugPrint('⚠️ Not authenticated, skipping score sync');
      return;
    }

    try {
      await _supabase.client.from('user_scores').upsert(score.toJson());
      debugPrint('✅ Score synced to cloud: ${score.totalScore} pts');
    } catch (e) {
      debugPrint('❌ Failed to sync score: $e');
    }
  }

  /// Fetch global leaderboard
  Future<List<LeaderboardEntry>> fetchGlobalLeaderboard(
      {int limit = 100}) async {
    if (!_supabase.isAuthenticated) return [];

    try {
      final response = await _supabase.client
          .from('user_scores')
          .select()
          .order('total_score', ascending: false)
          .limit(limit);

      final currentUserId = _supabase.currentUser?.id;

      return (response as List).asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final userScore = UserScore.fromJson(data);

        return LeaderboardEntry(
          userScore: userScore,
          rank: index + 1,
          isCurrentUser: userScore.userId == currentUserId,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Fetch weekly leaderboard
  Future<List<LeaderboardEntry>> fetchWeeklyLeaderboard(
      {int limit = 100}) async {
    if (!_supabase.isAuthenticated) return [];

    try {
      final response = await _supabase.client
          .from('user_scores')
          .select()
          .order('current_week_score', ascending: false)
          .limit(limit);

      final currentUserId = _supabase.currentUser?.id;

      return (response as List).asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final userScore = UserScore.fromJson(data);

        return LeaderboardEntry(
          userScore: userScore,
          rank: index + 1,
          isCurrentUser: userScore.userId == currentUserId,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching weekly leaderboard: $e');
      return [];
    }
  }

  /// Get user's current rank
  Future<int?> getUserRank(String userId) async {
    if (!_supabase.isAuthenticated) return null;

    try {
      final response = await _supabase.client
          .from('user_scores')
          .select()
          .order('total_score', ascending: false);

      final rank = (response as List).indexWhere(
        (entry) => entry['user_id'] == userId,
      );

      return rank >= 0 ? rank + 1 : null;
    } catch (e) {
      debugPrint('❌ Error fetching user rank: $e');
      return null;
    }
  }
}
