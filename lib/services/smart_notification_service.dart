import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/habit_insight.dart';
import 'habit_insights_service.dart';

/// Service to deliver habit insights as smart notifications
class SmartNotificationService {
  static final SmartNotificationService _instance =
      SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  static SmartNotificationService get instance => _instance;

  /// Send weekly insights notification
  Future<void> sendWeeklyInsights(List<Habit> habits) async {
    try {
      final insights = HabitInsightsService.instance.generateInsights(habits);
      if (insights.isEmpty) return;

      // Get top 3 most actionable insights
      final topInsights =
          HabitInsightsService.instance.getTopInsights(insights);

      if (topInsights.isEmpty) return;

      // Create notification with first insight
      final primaryInsight = topInsights.first;

      // Note: Actual notification scheduling would go here
      // For now, just log the insight that would be sent
      debugPrint('📬 Would send weekly insight: ${primaryInsight.message}');
    } catch (e) {
      debugPrint('❌ Error sending weekly insights: $e');
    }
  }

  /// Send a single insight as notification
  Future<void> sendInsight(HabitInsight insight) async {
    try {
      // Note: Actual notification scheduling would go here
      // For now, just log the insight
      debugPrint('📬 Would send insight: ${insight.message}');
    } catch (e) {
      debugPrint('❌ Error sending insight: $e');
    }
  }

  /// Schedule daily insights check (call from app initialization)
  Future<void> scheduleDailyInsightsCheck() async {
    // This would be called once per day
    // You could use a cron-like service or check on app open
    debugPrint('✅ Daily insights check scheduled');
  }
}
