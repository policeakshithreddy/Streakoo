import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import 'supabase_service.dart';

/// Cloud sync service connecting habit operations to Supabase.
class CloudSyncService {
  static final SupabaseService _supabase = SupabaseService();

  static Future<void> pushHabits(List<Habit> habits) async {
    if (!_supabase.isAuthenticated) {
      debugPrint('[CloudSync] User not authenticated. Skipping push.');
      return;
    }

    try {
      await _supabase.syncHabitsToCloud(habits);
      debugPrint('[CloudSync] Successfully pushed ${habits.length} habits to Supabase.');
    } catch (e) {
      debugPrint('[CloudSync] Error pushing habits to Supabase: $e');
    }
  }

  static Future<List<Habit>> pullHabits() async {
    if (!_supabase.isAuthenticated) {
      debugPrint('[CloudSync] User not authenticated. Returning empty list.');
      return [];
    }

    try {
      final habits = await _supabase.fetchHabitsFromCloud();
      debugPrint('[CloudSync] Successfully pulled ${habits.length} habits from Supabase.');
      return habits;
    } catch (e) {
      debugPrint('[CloudSync] Error pulling habits from Supabase: $e');
      return [];
    }
  }
}
