import 'package:flutter/foundation.dart';
import '../models/year_in_review.dart';
import 'supabase_service.dart';

/// Cloud-based service for Year in Review
/// Fetches pre-calculated wrapped data from Supabase
/// or triggers server-side generation via Edge Functions
class YearInReviewCloudService {
  static final YearInReviewCloudService _instance =
      YearInReviewCloudService._internal();
  factory YearInReviewCloudService() => _instance;
  YearInReviewCloudService._internal();

  static YearInReviewCloudService get instance => _instance;

  final _supabase = SupabaseService();

  /// Check if a Year in Review exists for the given year
  Future<bool> hasYearInReview(int year) async {
    try {
      if (!_supabase.isAuthenticated) return false;

      final data = await _supabase.client
          .from('year_in_review')
          .select('id')
          .eq('user_id', _supabase.currentUser!.id)
          .eq('year', year)
          .maybeSingle();

      return data != null;
    } catch (e) {
      debugPrint('❌ Error checking year in review existence: $e');
      return false;
    }
  }

  /// Fetch Year in Review data from Supabase
  Future<YearInReview?> fetchYearInReview(int year) async {
    try {
      if (!_supabase.isAuthenticated) {
        debugPrint('⚠️ User not authenticated');
        return null;
      }

      debugPrint('📊 Fetching Year in Review for $year from cloud...');

      final data = await _supabase.client
          .from('year_in_review')
          .select()
          .eq('user_id', _supabase.currentUser!.id)
          .eq('year', year)
          .maybeSingle();

      if (data == null) {
        debugPrint('ℹ️ No Year in Review found for $year');
        return null;
      }

      debugPrint('✅ Year in Review fetched successfully');
      return _mapToYearInReview(data);
    } catch (e) {
      debugPrint('❌ Error fetching year in review: $e');
      return null;
    }
  }

  /// Generate Year in Review by calling Edge Function
  /// This triggers server-side processing
  Future<YearInReview?> generateYearInReview(int year) async {
    try {
      if (!_supabase.isAuthenticated) {
        throw 'User not authenticated';
      }

      debugPrint('🚀 Generating Year in Review for $year via Edge Function...');

      // Call Edge Function to generate the review
      final response = await _supabase.client.functions.invoke(
        'generate-year-in-review',
        body: {
          'year': year,
        },
      );

      if (response.status != 200) {
        throw 'Edge Function returned status ${response.status}';
      }

      debugPrint('✅ Year in Review generated successfully');

      // Fetch the newly generated data
      return await fetchYearInReview(year);
    } catch (e) {
      debugPrint('❌ Error generating year in review: $e');
      rethrow;
    }
  }

  /// Delete Year in Review data for a specific year
  /// (For user cleanup or admin purposes)
  Future<void> deleteYearInReview(int year) async {
    try {
      if (!_supabase.isAuthenticated) {
        throw 'User not authenticated';
      }

      await _supabase.client
          .from('year_in_review')
          .delete()
          .eq('user_id', _supabase.currentUser!.id)
          .eq('year', year);

      debugPrint('✅ Year in Review deleted for $year');
    } catch (e) {
      debugPrint('❌ Error deleting year in review: $e');
      rethrow;
    }
  }

  /// Get all available years with Year in Review data
  Future<List<int>> getAvailableYears() async {
    try {
      if (!_supabase.isAuthenticated) return [];

      final data = await _supabase.client
          .from('year_in_review')
          .select('year')
          .eq('user_id', _supabase.currentUser!.id)
          .order('year', ascending: false);

      return (data as List).map((e) => e['year'] as int).toList();
    } catch (e) {
      debugPrint('❌ Error fetching available years: $e');
      return [];
    }
  }

  /// Map Supabase data to YearInReview model
  YearInReview _mapToYearInReview(Map<String, dynamic> data) {
    return YearInReview(
      year: data['year'] as int,
      totalCompletions: data['total_completions'] as int,
      longestStreak: data['longest_streak'] as int,
      mostConsistentHabit: data['most_consistent_habit'] as String,
      mostConsistentEmoji: data['most_consistent_emoji'] as String,
      totalXP: data['total_xp'] as int,
      bestMonth: data['best_month'] as String,
      avgCompletionRate: (data['avg_completion_rate'] as num).toDouble(),
      habitBreakdown: Map<String, int>.from(data['habit_breakdown'] as Map),
      totalDaysActive: data['total_days_active'] as int,
      perfectDays: data['perfect_days'] as int,
    );
  }
  // ============ WRAPPED 2025 LOGIC ============

  /// Get the date when user first opened Wrapped 2025
  Future<DateTime?> getWrappedStartDate(int year) async {
    try {
      if (!_supabase.isAuthenticated) return null;

      final data = await _supabase.client
          .from('user_settings')
          .select('wrapped_${year}_start_date')
          .eq('user_id', _supabase.currentUser!.id)
          .maybeSingle();

      if (data == null || data['wrapped_${year}_start_date'] == null) {
        return null;
      }

      return DateTime.parse(data['wrapped_${year}_start_date']);
    } catch (e) {
      debugPrint('⚠️ Error fetching wrapped start date: $e');
      return null;
    }
  }

  /// Set the start date for Wrapped (first access)
  Future<void> setWrappedStartDate(int year) async {
    try {
      if (!_supabase.isAuthenticated) return;

      // Check if already set
      final existing = await getWrappedStartDate(year);
      if (existing != null) return;

      await _supabase.client.from('user_settings').upsert({
        'user_id': _supabase.currentUser!.id,
        'wrapped_${year}_start_date': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Wrapped start date set for $year');
    } catch (e) {
      debugPrint('❌ Error setting wrapped start date: $e');
      // If table missing, we might need to handle that, but assuming user_settings exists
    }
  }

  /// Delete Wrapped data (expiration logic)
  Future<void> deleteWrappedData(int year) async {
    try {
      if (!_supabase.isAuthenticated) return;

      // 1. Delete the actual wrapped stats
      await deleteYearInReview(year);

      // 2. Clear the start date tracking (optional, or keep it to prevent re-opening)
      // We'll keep the start date but the data will be gone, effectively "expiring" it
      // Actually, plan says "delete wrapped data".

      // Let's also remove the start date so if they somehow access it again, it's a fresh state (though expected behavior is "it's gone")
      // But for "expiration", we want to BLOCK access.
      // So we keep the start date to know it expired, but delete the data.

      debugPrint('🧹 Wrapped data cleaned up (Expired)');
    } catch (e) {
      debugPrint('❌ Error deleting wrapped data: $e');
    }
  }
}
