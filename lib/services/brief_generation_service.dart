import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'weekly_report_service.dart';

import '../services/supabase_service.dart';

class BriefGenerationService {
  final WeeklyReportService _reportService;

  BriefGenerationService() : _reportService = WeeklyReportService.instance;

  /// Checks and generates briefs/reports if needed
  Future<void> checkAndGenerate(BuildContext context) async {
    final appState = context.read<AppState>();

    await _checkDailyBrief(appState);
    await _checkWeeklyReport(appState);
  }

  Future<void> _checkDailyBrief(AppState appState) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if already generated today
    if (appState.lastDailyBriefDate != null) {
      final last = appState.lastDailyBriefDate!;
      if (last.year == today.year &&
          last.month == today.month &&
          last.day == today.day) {
        return; // Already done today
      }
    }

    // Generate Daily Brief logic would go here
    // Currently Daily Brief is generated on-the-fly in CoachOverviewScreen
    // But we mark it as "checked" so we don't re-trigger animations or expensive logic
    appState.updateLastDailyBriefDate(now);
    debugPrint('✅ Daily brief check completed for $today');
  }

  Future<void> _checkWeeklyReport(AppState appState) async {
    final now = DateTime.now();

    // Weekly reports are generated for the PREVIOUS week
    // We typically check this on Sundays or Mondays

    // Find the start of the current week (assuming Monday start)
    // weekday: Mon=1, Sun=7
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekStartDay = DateTime(
        currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);

    // The report we want to generate is for the week ENDING yesterday (or today if it's Sunday)
    // Actually, let's say we generate a report for a week once that week is fully over.
    // So if today is Monday, we generate for the week that ended yesterday (Sunday).

    // Let's define a "week ID" as the Monday of that week.
    // We want to ensure we have a report for the *previous* week.

    final previousWeekStart =
        currentWeekStartDay.subtract(const Duration(days: 7));

    // Check if user existed during that week
    final supabase = SupabaseService();
    final user = supabase.currentUser;
    if (user != null) {
      final createdAt = DateTime.parse(user.createdAt);
      // If user joined AFTER the previous week ended (i.e., after the start of THIS week),
      // then they weren't around for the previous week.
      // We allow if they joined DURING the previous week.
      if (createdAt.isAfter(currentWeekStartDay)) {
        debugPrint('Skipping weekly report: User joined after this week ended.');
        return;
      }
    }

    // Check if we already have a report for this previous week
    final hasReport = appState.weeklyReports.any((r) =>
        r.weekStart.year == previousWeekStart.year &&
        r.weekStart.month == previousWeekStart.month &&
        r.weekStart.day == previousWeekStart.day);

    if (hasReport) {
      return; // Already have it
    }

    // If we don't have it, AND the previous week is actually in the past (it is),
    // AND we have data for it (at least some habits existed), generate it.

    // Only generate if we have habits
    if (appState.habits.isEmpty) return;

    debugPrint(
        '📊 Generating weekly report for week of ${previousWeekStart.toString().split(' ')[0]}...');

    try {
      final report = await _reportService.generateWeeklyReport(
        habits: appState.habits,
        weekStart: previousWeekStart,
      );

      appState.addWeeklyReport(report);
      debugPrint('✅ Weekly report generated and saved!');
    } catch (e) {
      debugPrint('❌ Failed to generate weekly report: $e');
    }
  }
}
