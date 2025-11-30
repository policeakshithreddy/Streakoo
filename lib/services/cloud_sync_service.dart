import 'package:flutter/foundation.dart';
import '../models/habit.dart';

/// Future-ready cloud sync service.
/// Currently does nothing except log calls.
class CloudSyncService {
  static Future<void> pushHabits(List<Habit> habits) async {
    debugPrint(
      '[CloudSync] pushHabits called with ${habits.length} habits (stub).',
    );

    // TODO: integrate Supabase/Firebase/Appwrite here.
  }

  static Future<List<Habit>> pullHabits() async {
    debugPrint('[CloudSync] pullHabits called (stub).');
    // TODO: download from cloud later.
    return [];
  }
}
