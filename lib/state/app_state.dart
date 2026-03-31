import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../models/user_level.dart';
import '../models/mood_tracker.dart';
import '../models/weekly_report.dart';
import '../services/supabase_service.dart';
import '../services/local_notification_service.dart';
import '../services/milestone_detector.dart';
import '../services/home_widget_service.dart';
import '../services/ai_health_coach_service.dart';
import '../models/ai_insight.dart';
import '../services/health_service.dart';
import '../models/health_challenge.dart';
import '../models/milestone.dart';
import '../services/sync_service.dart';
import '../widgets/streak_sync_confirmation_dialog.dart';

class AppState extends ChangeNotifier {
  AppState();

  // ----------------- Fields -----------------
  final List<Habit> _habits = [];
  final List<Map<String, dynamic>> _achievements = [];
  bool _isFirstRun = true;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _hasShownStreakWarningSession = false;

  // Gamification
  int _totalXP = 0;
  UserLevel? _userLevel;

  // Mood tracking
  final List<MoodEntry> _moodHistory = [];
  String? _lastMoodCheckDate; // yyyy-MM-dd

  // Streak Freeze
  int _streakFreezes = 0;
  final List<String> _frozenDates = []; // yyyy-MM-dd

  // Cloud backup
  String? _lastBackupDate; // yyyy-MM-dd

  // AI Brief & Reports
  final List<WeeklyReport> _weeklyReports = [];
  DateTime? _lastDailyBriefDate;
  DateTime? _lastWeeklyReportDate;

  // AI Caching
  List<AIInsight> _cachedInsights = [];
  DateTime? _lastInsightsGenDate;
  String? _cachedCurrentWeekSummary;
  DateTime? _lastSummaryGenDate;

  // Health Challenge
  HealthChallenge? _activeHealthChallenge;

  // Milestones
  final List<Milestone> _achievedMilestones = [];
  final List<String> _shownMilestoneIds =
      []; // Track which milestones were already shown

  // ----------------- Getters -----------------
  List<Habit> get habits => List.unmodifiable(_habits);

  // Sorted habits: focus tasks first (by priority), then regular tasks
  List<Habit> get sortedHabits {
    final sorted = [..._habits];
    sorted.sort((a, b) {
      // Focus tasks come first
      if (a.isFocusTask && !b.isFocusTask) return -1;
      if (!a.isFocusTask && b.isFocusTask) return 1;

      // Within focus tasks, sort by priority (lower number = higher priority)
      if (a.isFocusTask && b.isFocusTask) {
        final priorityA = a.focusTaskPriority ?? 999;
        final priorityB = b.focusTaskPriority ?? 999;
        return priorityA.compareTo(priorityB);
      }

      // Regular tasks keep original order (maintain insertion order)
      return 0;
    });
    return List.unmodifiable(sorted);
  }

  List<Map<String, dynamic>> get achievements =>
      List.unmodifiable(_achievements);
  bool get isFirstRun => _isFirstRun;
  ThemeMode get themeMode => _themeMode;
  bool get hasShownStreakWarningSession => _hasShownStreakWarningSession;

  void markStreakWarningShown() {
    _hasShownStreakWarningSession = true;
    notifyListeners();
  }

  // Gamification getters
  int get totalXP => _totalXP;
  UserLevel get userLevel => _userLevel ?? UserLevel.fromTotalXP(0);

  // Mood getters
  List<MoodEntry> get moodHistory => List.unmodifiable(_moodHistory);

  // Streak Freeze getters
  int get streakFreezes => _streakFreezes;
  List<String> get frozenDates => List.unmodifiable(_frozenDates);

  // Track recently frozen habits for animation
  final List<String> _recentlyFrozenHabitIds = [];
  bool get hasRecentlyFrozenHabits => _recentlyFrozenHabitIds.isNotEmpty;

  List<String> consumeRecentlyFrozenHabits() {
    final list = List<String>.from(_recentlyFrozenHabitIds);
    _recentlyFrozenHabitIds.clear();
    notifyListeners();
    return list;
  }

  // AI Brief Getters
  List<WeeklyReport> get weeklyReports => List.unmodifiable(_weeklyReports);
  DateTime? get lastDailyBriefDate => _lastDailyBriefDate;
  DateTime? get lastWeeklyReportDate => _lastWeeklyReportDate;

  // AI Caching Getters
  List<AIInsight> get cachedInsights => List.unmodifiable(_cachedInsights);
  String? get cachedCurrentWeekSummary => _cachedCurrentWeekSummary;

  // Health Challenge Getter
  HealthChallenge? get activeHealthChallenge => _activeHealthChallenge;

  // Milestone Getters
  List<Milestone> get achievedMilestones =>
      List.unmodifiable(_achievedMilestones);
  Milestone? get latestMilestone =>
      _achievedMilestones.isEmpty ? null : _achievedMilestones.last;

  // Health Challenge Setter with Cloud Sync
  Future<void> setActiveHealthChallenge(HealthChallenge? challenge) async {
    _activeHealthChallenge = challenge;
    notifyListeners();

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    if (challenge != null) {
      await prefs.setString(
          'activeHealthChallenge', jsonEncode(challenge.toJson()));

      // Sync to cloud if cloud backup is enabled
      final cloudBackupEnabled = prefs.getBool('cloudBackupEnabled') ?? false;
      if (cloudBackupEnabled) {
        try {
          final supabase = SupabaseService();
          await supabase.syncHealthChallenge(challenge.toJson());
        } catch (e) {
          debugPrint('⚠️  Cloud sync failed: $e');
        }
      }
    } else {
      // Clear challenge
      await prefs.remove('activeHealthChallenge');
    }
  }

  /// Completes the current health challenge and cleans up associated data
  Future<void> completeCurrentHealthChallenge() async {
    if (_activeHealthChallenge == null) return;

    final challengeId = _activeHealthChallenge!.id;

    // 1. Delete from Cloud
    try {
      final supabase = SupabaseService();
      if (supabase.isAuthenticated) {
        await supabase.deleteHealthChallenge(challengeId);
        debugPrint('✅ Cloud challenge deleted: $challengeId');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to delete cloud challenge: $e');
    }

    // 2. Clear Local Challenge State
    _activeHealthChallenge = null;

    // 3. Clear Weekly Reports (per user request)
    _weeklyReports.clear();
    _lastWeeklyReportDate = null;

    // 4. Update SharedPrefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyActiveChallenge);
    await prefs.remove(_prefsKeyWeeklyReports);
    await prefs.remove(_prefsKeyLastWeeklyReport);

    // 5. Notify UI
    notifyListeners();
    debugPrint('🎉 Challenge completed & data cleaned up');
  }

  bool get needsMoodCheckIn {
    final today = _getTodayKey();
    return _lastMoodCheckDate != today;
  }

  MoodEntry? get todayMood {
    if (_moodHistory.isEmpty) return null;
    final today = _getTodayKey();
    for (final entry in _moodHistory.reversed) {
      final entryDate = _dateToKey(entry.timestamp);
      if (entryDate == today) return entry;
    }
    return null;
  }

  // ----------------- Prefs keys -----------------
  static const _prefsKeyHabits = 'habits_v1';
  static const _prefsKeyAchievements = 'achievements_v1';
  static const _prefsKeyFirstRun = 'isFirstRun';
  static const _prefsKeyTheme = 'themeMode';
  static const _prefsKeyTotalXP = 'totalXP';
  static const _prefsKeyMoodHistory = 'moodHistory_v1';
  static const _prefsKeyUserLevel = 'userLevel_v1';
  static const _prefsKeyLastMoodCheck = 'lastMoodCheckDate';
  static const _prefsKeyWeeklyReports = 'weekly_reports';
  static const _prefsKeyLastDailyBrief = 'last_daily_brief';
  static const _prefsKeyLastWeeklyReport = 'last_weekly_report';
  static const _prefsKeyLastBackup = 'lastBackupDate';
  static const _prefsKeyActiveChallenge = 'active_challenge_v1';
  static const _prefsKeyAchievedMilestones = 'achieved_milestones';
  static const _prefsKeyShownMilestones = 'shown_milestone_ids';

  // ----------------- Load / Save -----------------
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _isFirstRun = prefs.getBool(_prefsKeyFirstRun) ?? true;

    final themeStr = prefs.getString(_prefsKeyTheme);
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }

    final habitsJson = prefs.getString(_prefsKeyHabits);
    if (habitsJson != null && habitsJson.isNotEmpty) {
      try {
        final list = jsonDecode(habitsJson) as List;
        _habits
          ..clear()
          ..addAll(list.map((e) => Habit.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        // ignore corrupt data
      }
    }

    // Load achievements
    final achievementsJson = prefs.getString(_prefsKeyAchievements);
    if (achievementsJson != null && achievementsJson.isNotEmpty) {
      try {
        final list = jsonDecode(achievementsJson) as List;
        _achievements
          ..clear()
          ..addAll(list.map((e) => e as Map<String, dynamic>));
      } catch (_) {
        // ignore corrupt data
      }
    }

    // Load User Level
    final userLevelJson = prefs.getString(_prefsKeyUserLevel);
    if (userLevelJson != null && userLevelJson.isNotEmpty) {
      try {
        _userLevel = UserLevel.fromJson(jsonDecode(userLevelJson));
      } catch (_) {
        _userLevel = UserLevel.fromTotalXP(0);
      }
    } else {
      // Fallback for migration: try to load totalXP
      _totalXP = prefs.getInt(_prefsKeyTotalXP) ?? 0;
      _userLevel = UserLevel.fromTotalXP(_totalXP);
    }
    // Sync totalXP with userLevel for backward compatibility if needed,
    // but we should rely on userLevel now.

    // Load mood history
    final moodJson = prefs.getString(_prefsKeyMoodHistory);
    if (moodJson != null && moodJson.isNotEmpty) {
      try {
        final list = jsonDecode(moodJson) as List;
        _moodHistory
          ..clear()
          ..addAll(
              list.map((e) => MoodEntry.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        // ignore corrupt data
      }
    }

    _lastMoodCheckDate = prefs.getString(_prefsKeyLastMoodCheck);

    // Load last backup date
    _lastBackupDate = prefs.getString(_prefsKeyLastBackup);

    // Check and reset streaks for missed days
    _checkAndResetStreaks();

    // Load Streak Freezes
    _streakFreezes = prefs.getInt('streak_freezes') ?? 0;
    final frozenJson = prefs.getString('frozen_dates');
    if (frozenJson != null) {
      try {
        final list = jsonDecode(frozenJson) as List;
        _frozenDates.clear();
        _frozenDates.addAll(list.map((e) => e as String));
      } catch (_) {}
    }

    // Check and reset streaks for missed days
    _checkAndResetStreaks();

    // Recalculate all streaks from scratch to ensure accuracy
    _recalculateAllStreaks();

    // Perform daily cloud backup if needed (non-blocking)
    checkAndPerformDailyBackup().catchError((e) {
      debugPrint('Auto-backup error: $e');
    });

    // Check and update daily AI insight for active challenge
    checkAndUpdateDailyInsight().catchError((e) {
      debugPrint('Auto-insight update error: $e');
    });

    // Load Weekly Reports
    final reportsJson = prefs.getString(_prefsKeyWeeklyReports);
    if (reportsJson != null && reportsJson.isNotEmpty) {
      try {
        final list = jsonDecode(reportsJson) as List;
        _weeklyReports
          ..clear()
          ..addAll(list
              .map((e) => WeeklyReport.fromJson(e as Map<String, dynamic>)));
      } catch (e) {
        debugPrint('Error loading weekly reports: $e');
      }
    }

    // Load generation dates
    final lastDaily = prefs.getString(_prefsKeyLastDailyBrief);
    if (lastDaily != null) {
      _lastDailyBriefDate = DateTime.tryParse(lastDaily);
    }

    final lastWeekly = prefs.getString(_prefsKeyLastWeeklyReport);
    if (lastWeekly != null) {
      _lastWeeklyReportDate = DateTime.tryParse(lastWeekly);
    }

    if (lastWeekly != null) {
      _lastWeeklyReportDate = DateTime.tryParse(lastWeekly);
    }

    // Load Active Challenge
    final challengeJson = prefs.getString(_prefsKeyActiveChallenge);
    if (challengeJson != null) {
      try {
        _activeHealthChallenge =
            HealthChallenge.fromJson(jsonDecode(challengeJson));
      } catch (e) {
        debugPrint('Error loading active challenge: $e');
      }
    }

    // Load Milestones
    final milestonesJson = prefs.getString(_prefsKeyAchievedMilestones);
    if (milestonesJson != null && milestonesJson.isNotEmpty) {
      try {
        final list = jsonDecode(milestonesJson) as List;
        _achievedMilestones
          ..clear()
          ..addAll(
              list.map((e) => Milestone.fromJson(e as Map<String, dynamic>)));
      } catch (e) {
        debugPrint('Error loading milestones: $e');
      }
    }

    final shownIdsJson = prefs.getString(_prefsKeyShownMilestones);
    if (shownIdsJson != null) {
      try {
        final list = jsonDecode(shownIdsJson) as List;
        _shownMilestoneIds.clear();
        _shownMilestoneIds.addAll(list.map((e) => e as String));
      } catch (e) {
        debugPrint('Error loading shown milestone IDs: $e');
      }
    }

    // Initialize and update home screen widget with current data
    await HomeWidgetService.initialize();
    final completedToday = _habits.where((h) => h.completedToday).length;
    final totalHabits = _habits.length;
    final maxStreak = _habits.isEmpty
        ? 0
        : _habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    await HomeWidgetService.updateWidgetData(
      completedHabits: completedToday,
      totalHabits: totalHabits,
      currentStreak: maxStreak,
      steps: 0, // Steps will be updated when health data syncs
    );

    notifyListeners();
  }

  // AI Brief Helpers
  void updateLastDailyBriefDate(DateTime date) {
    _lastDailyBriefDate = date;
    _savePreferences();

    notifyListeners();
  }

  void addWeeklyReport(WeeklyReport report) {
    // Check if report already exists (by ID or week start)
    final exists = _weeklyReports.any((r) => r.id == report.id);
    if (!exists) {
      _weeklyReports.insert(0, report); // Add to top
      _lastWeeklyReportDate = DateTime.now();
      _savePreferences();
      notifyListeners();
    }
  }

  // AI Caching Helpers
  bool get shouldRefreshInsights {
    if (_cachedInsights.isEmpty) return true;
    if (_lastInsightsGenDate == null) return true;
    return DateTime.now().difference(_lastInsightsGenDate!).inHours >=
        4; // Update every 4 hours
  }

  bool get shouldRefreshWeeklySummary {
    if (_cachedCurrentWeekSummary == null) return true;
    if (_lastSummaryGenDate == null) return true;
    return DateTime.now().difference(_lastSummaryGenDate!).inHours >=
        12; // Update every 12 hours
  }

  Future<void> updateCachedInsights(List<AIInsight> insights) async {
    _cachedInsights = insights;
    _lastInsightsGenDate = DateTime.now();
    await _savePreferences();
    notifyListeners();
  }

  Future<void> updateCachedWeeklySummary(String summary) async {
    _cachedCurrentWeekSummary = summary;
    _lastSummaryGenDate = DateTime.now();
    await _savePreferences();
    notifyListeners();
  }

  void _recalculateAllStreaks() {
    for (var i = 0; i < _habits.length; i++) {
      final h = _habits[i];
      final correctStreak = _calculateStreak(h.completionDates);
      if (h.streak != correctStreak) {
        debugPrint(
            '🔧 Fixing streak for ${h.name}: ${h.streak} -> $correctStreak');
        _habits[i] = h.copyWith(streak: correctStreak);
      }
    }
  }

  void _checkAndResetStreaks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    bool usedFreezeToday = false;

    for (var i = 0; i < _habits.length; i++) {
      final habit = _habits[i];

      if (habit.completionDates.isEmpty) continue;

      // Get the last completion date
      final lastCompletionStr = habit.completionDates.last;
      final lastCompletion = DateTime.parse(lastCompletionStr);
      final lastDay = DateTime(
          lastCompletion.year, lastCompletion.month, lastCompletion.day);

      // Calculate days difference
      final daysDifference = today.difference(lastDay).inDays;

      // If more than 1 day has passed, reset the streak OR use freeze
      if (daysDifference > 1) {
        bool protectedByFreeze = false;

        // ONLY focus tasks are eligible for freeze protection
        if (habit.isFocusTask && daysDifference == 2) {
          // Check if yesterday is already frozen or if we have freezes
          if (_frozenDates.contains(yesterdayKey)) {
            protectedByFreeze = true;
            debugPrint(
                '❄️ Focus task "${habit.name}" protected by existing freeze');
          } else if (_streakFreezes > 0) {
            // Use a freeze!
            if (!usedFreezeToday) {
              _streakFreezes--;
              _frozenDates.add(yesterdayKey);
              usedFreezeToday = true;
              _recentlyFrozenHabitIds.add(habit.id); // Trigger animation
              debugPrint(
                  '❄️ Used freeze to protect focus task "${habit.name}"');
            }
            protectedByFreeze = true;
          }
        }

        if (protectedByFreeze) {
          // Streak saved! Just mark as not completed today
          _habits[i] = habit.copyWith(
            completedToday: false,
          );
        } else {
          // Reset streak
          if (habit.isFocusTask) {
            debugPrint(
                '💔 Focus task "${habit.name}" streak reset (no freezes available)');
          } else {
            debugPrint(
                '📉 Regular task "${habit.name}" streak reset (not protected)');
          }
          _habits[i] = habit.copyWith(
            streak: 0,
            completedToday: false,
          );
        }
      }
      // If it's a new day (but not more than 1 day), just mark as not completed today
      else if (daysDifference == 1) {
        _habits[i] = habit.copyWith(
          completedToday: false,
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_prefsKeyFirstRun, _isFirstRun);

    final themeStr = switch (_themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_prefsKeyTheme, themeStr);

    final encoded = jsonEncode(_habits.map((h) => h.toJson()).toList());
    await prefs.setString(_prefsKeyHabits, encoded);

    final achievementsEncoded = jsonEncode(_achievements);
    await prefs.setString(_prefsKeyAchievements, achievementsEncoded);

    // Save User Level
    if (_userLevel != null) {
      await prefs.setString(
          _prefsKeyUserLevel, jsonEncode(_userLevel!.toJson()));
    }
    // Also save totalXP for backup/compatibility
    await prefs.setInt(_prefsKeyTotalXP, _totalXP);

    final moodEncoded =
        jsonEncode(_moodHistory.map((m) => m.toJson()).toList());
    await prefs.setString(_prefsKeyMoodHistory, moodEncoded);

    if (_lastMoodCheckDate != null) {
      await prefs.setString(_prefsKeyLastMoodCheck, _lastMoodCheckDate!);
    }

    await prefs.setInt('streak_freezes', _streakFreezes);
    await prefs.setString('frozen_dates', jsonEncode(_frozenDates));

    // Save Weekly Reports
    final reportsEncoded =
        jsonEncode(_weeklyReports.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKeyWeeklyReports, reportsEncoded);

    // Save generation dates
    if (_lastDailyBriefDate != null) {
      await prefs.setString(
          _prefsKeyLastDailyBrief, _lastDailyBriefDate!.toIso8601String());
    }
    if (_lastWeeklyReportDate != null) {
      await prefs.setString(
          _prefsKeyLastWeeklyReport, _lastWeeklyReportDate!.toIso8601String());
    }

    if (_lastWeeklyReportDate != null) {
      await prefs.setString(
          _prefsKeyLastWeeklyReport, _lastWeeklyReportDate!.toIso8601String());
    }

    // Save Active Challenge
    if (_activeHealthChallenge != null) {
      await prefs.setString(_prefsKeyActiveChallenge,
          jsonEncode(_activeHealthChallenge!.toJson()));
    } else {
      await prefs.remove(_prefsKeyActiveChallenge);
    }

    // Save Milestones
    final milestonesEncoded =
        jsonEncode(_achievedMilestones.map((m) => m.toJson()).toList());
    await prefs.setString(_prefsKeyAchievedMilestones, milestonesEncoded);

    await prefs.setString(
        _prefsKeyShownMilestones, jsonEncode(_shownMilestoneIds));

    // Update Home Screen Widget
    try {
      final completedToday = _habits.where((h) => h.completedToday).length;
      final totalHabits = _habits.length;
      // Calculate max streak among all habits for the "Fire" display
      final maxStreak = _habits.isEmpty
          ? 0
          : _habits
              .map((h) => h.streak)
              .reduce((curr, next) => curr > next ? curr : next);

      // Get steps from HealthService cache or 0
      const steps =
          0; // We'll need to fetch this properly or pass it in, for now 0 to avoid async complexity here

      await HomeWidgetService.updateWidgetData(
        completedHabits: completedToday,
        totalHabits: totalHabits,
        currentStreak: maxStreak,
        steps: steps,
      );
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  // ... (existing methods)

  Future<void> setFirstRunComplete() async {
    _isFirstRun = false;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _savePreferences();
    notifyListeners();
  }

  // ----------------- Habit CRUD -----------------
  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    _savePreferences();
    notifyListeners();

    // Sync to cloud
    await SupabaseService().upsertHabit(habit);
  }

  Future<void> updateHabit(Habit updated) async {
    final index = _habits.indexWhere((h) => h.id == updated.id);
    if (index == -1) return;
    _habits[index] = updated;
    _savePreferences();
    notifyListeners();

    // Sync to cloud (Habit + User Level)
    final supabase = SupabaseService();
    await supabase.upsertHabit(updated);
    if (_userLevel != null) {
      await supabase.upsertUserLevel(_userLevel!, _totalXP);
    }
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    _savePreferences();
    notifyListeners();

    // Sync deletion to cloud if authenticated
    final supabase = SupabaseService();
    if (supabase.isAuthenticated) {
      try {
        await supabase.deleteHabit(id);
        debugPrint('✅ Habit deleted from cloud: $id');
      } catch (e) {
        debugPrint('❌ Failed to delete habit from cloud: $e');
        // We don't rethrow here to keep local deletion successful
      }
    }
  }

  void reorderHabits(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final habit = _habits.removeAt(oldIndex);
    _habits.insert(newIndex, habit);
    _savePreferences();
    notifyListeners();
  }

  // ----------------- Completion / streaks -----------------
  Future<void> completeHabit(Habit habit, {bool isAiTriggered = false}) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index == -1) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final current = _habits[index];

    // Prevent manual completion of health-tracked habits with goals
    if (!isAiTriggered && !current.canManuallyComplete) {
      debugPrint(
          '⚠️ Cannot manually complete health-tracked habit "${current.name}". It will auto-complete when your health goal is met.');
      return;
    }

    // Log completion source
    if (isAiTriggered) {
      debugPrint('🤖 AI-triggered completion for "${current.name}"');
    } else {
      debugPrint('👆 Manual completion for "${current.name}"');
    }

    // Already done today?
    final isAlreadyCompletedToday = current.completionDates.contains(todayKey);

    if (isAlreadyCompletedToday) {
      debugPrint(
          'ℹ️ Habit "${current.name}" already completed today. Skipping XP/progress rewards.');
      // Just update the UI state, don't award XP or progress again
      _habits[index] = current.copyWith(completedToday: true);
      notifyListeners();

      // Sync to cloud
      SupabaseService().upsertHabit(_habits[index]);
      return;
    }

    // Create new completion dates list (immutable)
    final newCompletionDates = [...current.completionDates, todayKey];

    // Calculate robust streak based on dates
    final newStreak = _calculateStreak(newCompletionDates);

    // Note: Removed automatic 7-day streak freeze reward
    // Freezes are now only awarded on challenge completion

    // Award XP (only for NEW completions)
    final xpGained = current.actualXP;
    final oldLevel = userLevel.level;

    // Update UserLevel
    _userLevel ??= UserLevel.fromTotalXP(_totalXP);
    _userLevel!.addXP(xpGained);
    _totalXP += xpGained; // Keep tracking total XP just in case

    final newLevel = userLevel.level;

    // Calculate new challenge progress
    int newChallengeProgress = current.challengeProgress;
    bool newChallengeCompleted = current.challengeCompleted;

    if (current.challengeTargetDays != null && !current.challengeCompleted) {
      newChallengeProgress += 1;
      if (newChallengeProgress >= current.challengeTargetDays!) {
        newChallengeCompleted = true;

        // Reward: Streak Freeze for completing challenge
        // Award freezes based on challenge duration
        int freezesToAward = 1; // default
        if (current.challengeTargetDays == 7) {
          freezesToAward = 2;
        } else if (current.challengeTargetDays == 15) {
          freezesToAward = 3;
        } else if (current.challengeTargetDays == 30) {
          freezesToAward = 6;
        }

        _streakFreezes += freezesToAward;

        // Create achievement for completed challenge
        _addAchievement(
          habitName: current.name,
          habitEmoji: current.emoji,
          challengeDays: current.challengeTargetDays!,
          completedDate: todayKey,
        );
      }
    }
    // Create NEW habit instance with updated values (IMMUTABLE UPDATE)
    final updated = current.copyWith(
      completedToday: true,
      streak: newStreak,
      completionDates: newCompletionDates,
      challengeProgress: newChallengeProgress,
      challengeCompleted: newChallengeCompleted,
    );

    // Check for streak milestones
    _checkStreakMilestone(updated);

    // Check for level up
    if (newLevel > oldLevel) {
      _addLevelUpAchievement(newLevel);
    }

    // Replace with NEW habit instance
    _habits[index] = updated;
    // Debug: Verify streak updated
    debugPrint(
        '✅ Habit "${updated.name}" completed! Streak: ${updated.streak} days');

    _savePreferences();
    notifyListeners();

    // Sync to cloud (Habit + User Level)
    final supabase = SupabaseService();
    supabase.upsertHabit(updated);
    if (_userLevel != null) {
      supabase.upsertUserLevel(_userLevel!, _totalXP);
    }

    // Check for milestones if there's an active challenge
    if (_activeHealthChallenge != null) {
      await _checkForNewMilestones();
    }
  }

  /// Skip a habit for the day (user swiped left)
  /// This marks it as "not done" but doesn't break the streak until the day ends
  void skipHabit(Habit habit) {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index == -1) return;

    final current = _habits[index];

    // If already completed today, don't allow skipping
    if (current.completedToday) {
      debugPrint(
          'ℹ️ Habit "${current.name}" already completed today. Cannot skip.');
      return;
    }

    debugPrint('⏭️ Habit "${current.name}" marked as skipped for today');

    // Just mark as acknowledged but not completed
    // The streak won't break until the next day check
    _habits[index] = current.copyWith(
      completedToday: false,
    );

    _savePreferences();
    notifyListeners();
  }

  /// Uncomplete a habit (toggle off) - for when user wants to undo completion
  void uncompleteHabit(Habit habit) {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index == -1) return;

    final current = _habits[index];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // If not completed today, nothing to undo
    if (!current.completedToday) {
      debugPrint(
          'ℹ️ Habit "${current.name}" was not completed today. Nothing to undo.');
      return;
    }

    // Remove today from completion dates
    final newCompletionDates =
        current.completionDates.where((d) => d != todayKey).toList();

    // Recalculate streak
    final newStreak = _calculateStreak(newCompletionDates);

    // Deduct XP (but don't go below 0)
    final xpToDeduct = current.actualXP;
    _totalXP = (_totalXP - xpToDeduct).clamp(0, _totalXP);
    _userLevel = UserLevel.fromTotalXP(_totalXP);

    _habits[index] = current.copyWith(
      completedToday: false,
      completionDates: newCompletionDates,
      streak: newStreak,
    );

    debugPrint(
        '↩️ Habit "${current.name}" uncompleted. Streak: $newStreak, XP deducted: $xpToDeduct');

    _savePreferences();
    notifyListeners();
  }

  /// Check for new milestones based on current challenge progress
  Future<List<Milestone>> _checkForNewMilestones() async {
    if (_activeHealthChallenge == null) return [];

    // Get challenge habits
    final challengeHabits = _habits.where((h) {
      // Simple check - in a real app you'd track which habits are part of the challenge
      return h.category == 'Health' || h.category == 'Sports';
    }).toList();

    // Gather today's metrics
    final todayMetrics = <String, dynamic>{};
    try {
      final healthService = HealthService.instance;
      todayMetrics['steps'] = await healthService.getStepCount(DateTime.now());
      todayMetrics['sleep'] = await healthService.getSleepHours(DateTime.now());
    } catch (e) {
      // Health data might not be available
    }

    // Get historical data for personal bests
    final prefs = await SharedPreferences.getInstance();
    final historicalData = <String, dynamic>{
      'allTimeMaxSteps': prefs.getInt('allTimeMaxSteps') ?? 0,
    };

    // Update personal best if needed
    final todaySteps = todayMetrics['steps'] as int? ?? 0;
    if (todaySteps > historicalData['allTimeMaxSteps']!) {
      await prefs.setInt('allTimeMaxSteps', todaySteps);
    }

    // Detect new milestones
    final newMilestones = MilestoneDetector.checkForMilestones(
      challenge: _activeHealthChallenge!,
      todayMetrics: todayMetrics,
      historicalData: historicalData,
      challengeHabits: challengeHabits,
    );

    // Filter out already shown milestones
    final unseenMilestones = newMilestones.where((m) {
      return !_shownMilestoneIds.contains(m.id);
    }).toList();

    // Add to achieved milestones and mark as shown
    for (final milestone in unseenMilestones) {
      _achievedMilestones.add(milestone);
      _shownMilestoneIds.add(milestone.id);
    }

    if (unseenMilestones.isNotEmpty) {
      await _savePreferences();
      notifyListeners();
    }

    return unseenMilestones;
  }

  /// Public method to manually check for milestones (can be called from UI)
  Future<List<Milestone>> checkForNewMilestones() async {
    return await _checkForNewMilestones();
  }

  // Helper to calculate streak from dates
  int _calculateStreak(List<String> dates) {
    if (dates.isEmpty) return 0;

    // Sort dates just in case
    final sortedDates = dates.map((d) => DateTime.parse(d)).toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    int streak = 0;
    // final today = DateTime(now.year, now.month, now.day); // Unused

    // Check if the most recent date is today or yesterday
    // If the last completion was before yesterday, streak is broken (but this function is called after adding today)

    DateTime? lastDate;

    for (final date in sortedDates) {
      final day = DateTime(date.year, date.month, date.day);

      if (lastDate == null) {
        // First date (should be today if we just completed it)
        streak = 1;
        lastDate = day;
      } else {
        final difference = lastDate.difference(day).inDays;

        if (difference == 1) {
          // Consecutive day
          streak++;
          lastDate = day;
        } else if (difference == 0) {
          // Same day (duplicate?), ignore
          continue;
        } else {
          // Gap found, stop counting
          break;
        }
      }
    }

    return streak;
  }

  void _addAchievement({
    required String habitName,
    required String habitEmoji,
    required int challengeDays,
    required String completedDate,
  }) {
    final badge = challengeDays == 7
        ? '🥉'
        : challengeDays == 15
            ? '🥈'
            : '🥇';

    final achievement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'habitName': habitName,
      'habitEmoji': habitEmoji,
      'challengeDays': challengeDays,
      'badge': badge,
      'completedDate': completedDate,
    };

    _achievements.add(achievement);
  }

  void _addLevelUpAchievement(int level) {
    final achievement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'habitName': 'Level Up!',
      'habitEmoji': '⭐',
      'challengeDays': level,
      'badge': '🎖️',
      'completedDate': _getTodayKey(),
      'type': 'level_up',
    };
    _achievements.add(achievement);
  }

  void _checkStreakMilestone(Habit habit) {
    final milestones = [7, 14, 30, 50, 100];
    if (milestones.contains(habit.streak)) {
      final achievement = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'habitName': '${habit.name} - ${habit.streak} Day Streak!',
        'habitEmoji': '🔥',
        'challengeDays': habit.streak,
        'badge': habit.streak >= 100
            ? '💎'
            : habit.streak >= 50
                ? '🥇'
                : '🔥',
        'completedDate': _getTodayKey(),
        'type': 'streak_milestone',
      };
      _achievements.add(achievement);
    }
  }

  void clearAnimationFlag(String habitId) {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;
    _habits[index].triggerAnimation = false;
    notifyListeners();
  }

  // ----------------- Stats helpers -----------------
  int get totalHabits => _habits.length;

  int get totalCompletions =>
      _habits.fold<int>(0, (sum, h) => sum + h.completionDates.length);

  int get completedTodayCount => _habits.where((h) => h.completedToday).length;

  int get totalStreaks => _habits.fold<int>(0, (sum, h) => sum + h.streak);

  bool get allCompletedToday =>
      _habits.isNotEmpty && _habits.every((h) => h.completedToday);

  Map<String, dynamic> getWeeklyStats() {
    if (_habits.isEmpty) {
      return {'consistency': 0.0, 'completedCount': 0};
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(const Duration(days: 6));
    int completedCount = 0;
    int expectedCount = 0;

    for (final habit in _habits) {
      final frequencyDays = habit.frequencyDays; // [1..7]

      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final weekday = day.weekday;

        if (frequencyDays.contains(weekday)) {
          expectedCount++;

          final dateKey = _dateToKey(day);
          if (habit.completionDates.contains(dateKey)) {
            completedCount++;
          }
        }
      }
    }

    final consistency =
        expectedCount > 0 ? (completedCount / expectedCount) * 100 : 0.0;

    return {
      'consistency': consistency,
      'completedCount': completedCount,
    };
  }

  int longestPerfectDayStreak() {
    if (_habits.isEmpty) return 0;

    final allDates = <String>{};
    for (final habit in _habits) {
      allDates.addAll(habit.completionDates);
    }

    if (allDates.isEmpty) return 0;

    final sortedDates = allDates.map((d) => DateTime.parse(d)).toList()
      ..sort((a, b) => a.compareTo(b)); // Oldest first

    final startDate = sortedDates.first;
    final endDate = sortedDates.last;

    int maxStreak = 0;
    int currentStreak = 0;

    // Iterate day by day from start to end
    for (var date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      final dateKey = _dateToKey(date);
      final weekday = date.weekday;

      final expectedHabits =
          _habits.where((h) => h.frequencyDays.contains(weekday)).toList();

      // If no habits expected, it counts as keeping the streak alive (rest day)
      // If habits expected, must complete all of them
      bool isPerfect = true;
      if (expectedHabits.isNotEmpty) {
        final completedCount = expectedHabits
            .where((h) => h.completionDates.contains(dateKey))
            .length;
        if (completedCount != expectedHabits.length) {
          isPerfect = false;
        }
      }

      if (isPerfect) {
        currentStreak++;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }

    return maxStreak;
  }

  Map<String, int> completionHeatmap() {
    final map = <String, int>{};
    for (final h in _habits) {
      for (final day in h.completionDates) {
        map[day] = (map[day] ?? 0) + 1;
      }
    }
    return map;
  }

  // ----------------- Mood tracking -----------------
  void addMoodEntry(MoodEntry entry) {
    _moodHistory.add(entry);
    _lastMoodCheckDate = _dateToKey(entry.timestamp);
    _savePreferences();
    notifyListeners();
  }

  MoodAnalysis getMoodAnalysis({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recentMoods =
        _moodHistory.where((m) => m.timestamp.isAfter(cutoff)).toList();
    return MoodAnalysis.fromEntries(recentMoods);
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return _dateToKey(now);
  }

  String _dateToKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> resetAll() async {
    _habits.clear();
    _achievements.clear();
    _moodHistory.clear();
    _totalXP = 0;
    _userLevel = UserLevel.fromTotalXP(0);
    _lastMoodCheckDate = null;
    _isFirstRun = true;
    await _savePreferences();
    notifyListeners();
  }

  // ----------------- CLOUD BACKUP -----------------

  /// Manual backup to cloud
  Future<void> backupToCloud() async {
    final supabase = SupabaseService();

    if (!supabase.isAuthenticated) {
      throw Exception('Please sign in to backup your data');
    }

    // Sync all data to Supabase
    await supabase.syncHabitsToCloud(_habits);

    if (_userLevel != null) {
      await supabase.syncUserLevelToCloud(_userLevel!);
    }

    if (_activeHealthChallenge != null) {
      await supabase.syncHealthChallenge(_activeHealthChallenge!.toJson());
    }

    // Update last backup date
    _lastBackupDate = _getTodayKey();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyLastBackup, _lastBackupDate!);
  }

  /// Automatic daily backup - call this during app initialization
  Future<void> checkAndPerformDailyBackup() async {
    final supabase = SupabaseService();

    // Only auto-backup if user is signed in
    if (!supabase.isAuthenticated) return;

    final today = _getTodayKey();

    // Check if we already backed up today
    if (_lastBackupDate == today) return;

    try {
      await backupToCloud();
      debugPrint('✅ Daily auto-backup completed');
    } catch (e) {
      debugPrint('❌ Daily auto-backup failed: $e');
    }
  }

  /// Check and update daily AI insight for active challenge
  Future<void> checkAndUpdateDailyInsight() async {
    if (_activeHealthChallenge == null) return;

    final today = _getTodayKey();
    final lastInsightDate = _activeHealthChallenge!.aiPlan['lastInsightDate'];

    // If we already generated an insight today, skip
    if (lastInsightDate == today) return;

    debugPrint('🧠 generating daily AI insight...');

    try {
      final healthService = HealthService.instance;
      final aiService = AIHealthCoachService.instance;

      List<int> weeklySteps = [];
      List<double> weeklySleep = [];

      // Fetch last 7 days metrics
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        weeklySteps.add(await healthService.getStepCount(date));
        weeklySleep.add(await healthService.getSleepHours(date));
      }

      final habitsCompleted = _habits.where((h) => h.completedToday).length;
      final currentStreak = _habits.isEmpty
          ? 0
          : _habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

      final newInsight = await aiService.generateSmartInsight(
        weeklySteps: weeklySteps,
        weeklySleep: weeklySleep,
        habitsCompleted: habitsCompleted,
        currentStreak: currentStreak,
      );

      // Update challenge with new insight
      // Clone the plan map to be safe
      final updatedPlan =
          Map<String, dynamic>.from(_activeHealthChallenge!.aiPlan);
      updatedPlan['aiExplanation'] = newInsight;
      updatedPlan['lastInsightDate'] = today; // Mark as updated for today

      final updatedChallenge =
          _activeHealthChallenge!.copyWith(aiPlan: updatedPlan);

      await setActiveHealthChallenge(updatedChallenge);
      debugPrint('✅ Daily AI insight updated: $newInsight');
    } catch (e) {
      debugPrint('❌ Error updating daily AI insight: $e');
    }
  }

  // ----------------- HEALTH CHALLENGES -----------------
  void startChallenge(HealthChallenge challenge) {
    _activeHealthChallenge = challenge;

    // Add recommended habits
    for (var h in challenge.recommendedHabits) {
      final habit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString() + h.name,
        name: h.name,
        emoji: h.emoji,
        frequencyDays: [1, 2, 3, 4, 5, 6, 7], // Default to daily
        isHealthTracked: h.healthMetric != null && h.healthMetric != 'none',
        healthMetric: _parseMetric(h.healthMetric),
        healthGoalValue: h.targetValue,
        category: 'Health',
      );
      addHabit(habit);
    }

    _savePreferences();
    notifyListeners();
  }

  void endChallenge() {
    _activeHealthChallenge = null;
    _savePreferences();
    notifyListeners();
  }

  HealthMetricType? _parseMetric(String? metric) {
    switch (metric) {
      case 'steps':
        return HealthMetricType.steps;
      case 'sleep':
        return HealthMetricType.sleep;
      case 'distance':
        return HealthMetricType.distance;
      case 'calories':
        return HealthMetricType.calories;
      case 'heartRate':
        return HealthMetricType.heartRate;
      default:
        return null;
    }
  }

  Future<void> syncHealthHabits() async {
    debugPrint('🔄 Syncing health habits...');
    final healthService = HealthService.instance;

    // Check permissions first
    final hasAccess = await healthService.hasHealthDataAccess();
    if (!hasAccess) {
      debugPrint('⚠️ No health data access. Skipping sync.');
      return;
    }

    for (final habit in _habits) {
      if (!habit.isHealthTracked || habit.healthMetric == null) continue;

      // Skip if already completed today
      if (habit.completedToday) continue;

      try {
        final currentValue =
            await healthService.getCurrentValue(habit.healthMetric!);
        final goal = habit.healthGoalValue ?? 0;

        debugPrint(
            '❤️ Health Check: ${habit.name} (${habit.healthMetric?.name}) - Current: $currentValue / Goal: $goal');

        if (currentValue >= goal) {
          completeHabit(habit, isAiTriggered: true);
          debugPrint('✅ Auto-completed health habit: ${habit.name}');
        }
      } catch (e) {
        debugPrint('❌ Error syncing habit ${habit.name}: $e');
      }
    }
  }

  // Check if all habits completed (for celebration)
  bool wasAllCompletedBeforeThis(Habit completedHabit) {
    final allOthersCompleted = _habits
        .where((h) => h.id != completedHabit.id)
        .every((h) => h.completedToday);
    return allOthersCompleted;
  }
  // ============ DATA RESTORATION ============

  Future<void> restoreDataFromCloud() async {
    final supabase = SupabaseService();
    if (!supabase.isAuthenticated) return;

    debugPrint('🔄 Starting data restoration from cloud...');

    try {
      // 1. Fetch Habits
      debugPrint('📥 Fetching habits from cloud...');
      final cloudHabits = await supabase.fetchHabitsFromCloud();
      if (cloudHabits.isNotEmpty) {
        _habits.clear();
        _habits.addAll(cloudHabits);
        debugPrint('✅ Restored ${cloudHabits.length} habits');
      } else {
        debugPrint('ℹ️ No habits found in cloud');
      }

      // 2. Fetch User Level
      debugPrint('📥 Fetching user level from cloud...');
      final cloudLevel = await supabase.fetchUserLevelFromCloud();
      if (cloudLevel != null) {
        _userLevel = cloudLevel;

        // Calculate total XP based on level and current XP
        int completedLevelsXP = 0;
        for (int i = 1; i < cloudLevel.level; i++) {
          completedLevelsXP += i * 100;
        }
        _totalXP = completedLevelsXP + cloudLevel.currentXP;
        debugPrint('✅ Restored user level: ${cloudLevel.level}');
      } else {
        debugPrint('ℹ️ No user level found in cloud');
      }

      // 3. Fetch Health Challenge
      debugPrint('📥 Fetching health challenge from cloud...');
      final cloudChallengeData = await supabase.fetchHealthChallenge();
      if (cloudChallengeData != null) {
        try {
          _activeHealthChallenge = HealthChallenge.fromJson(cloudChallengeData);
          debugPrint('✅ Restored active health challenge');
        } catch (e) {
          debugPrint('⚠️ Error parsing cloud challenge: $e');
        }
      } else {
        debugPrint('ℹ️ No health challenge found in cloud');
      }

      // 4. Mark as not first run
      _isFirstRun = false;

      // 5. Save everything locally
      await _savePreferences();
      debugPrint('✅ Saved restored data locally');

      // Recalculate streaks to ensure they are up to date
      _checkAndResetStreaks();
      _recalculateAllStreaks();
      debugPrint('✅ Recalculated streaks');

      notifyListeners();

      // 6. Reschedule notifications
      for (final habit in _habits) {
        if (habit.reminderEnabled && habit.reminderTime != null) {
          final parts = habit.reminderTime!.split(':');
          if (parts.length == 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            await LocalNotificationService.scheduleDailyReminder(
              habitId: habit.id,
              title: 'Time for ${habit.name}!',
              body: 'Keep your streak alive 🔥',
              time: TimeOfDay(hour: hour, minute: minute),
            );
          }
        }
      }
      debugPrint(
          '✅ Rescheduled ${_habits.where((h) => h.reminderEnabled).length} notifications');
      debugPrint('🎉 Data restoration complete!');
    } catch (e, stackTrace) {
      debugPrint('❌ Error during data restoration: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - allow the app to continue with whatever data was restored
      // The user can still use the app, they just might not have all their data
    }
  }

  /// Handle sync conflicts after login/app open
  /// Call this from the main app after authentication and loading data
  /// Pass BuildContext to show dialog if needed
  Future<void> handleSyncConflicts(BuildContext context) async {
    try {
      debugPrint('🔄 Checking for sync conflicts...');

      // Perform sync and get conflict result
      final conflictResult = await SyncService.instance.syncOnAppOpen(
        _habits,
        userLevel,
      );

      // If no conflicts, we're done
      if (!conflictResult.hasStreakConflicts) {
        debugPrint('✅ No streak conflicts detected');
        return;
      }

      // Show confirmation dialog in context
      if (!context.mounted) return;

      final userChoice = await StreakSyncConfirmationDialog.show(
        context,
        conflictResult,
      );

      // User chose to import cloud streaks
      if (userChoice == true) {
        debugPrint('✅ User chose to import cloud streaks');

        // Apply cloud streaks to local habits
        for (final cloudHabit in conflictResult.cloudHabits) {
          final index = _habits.indexWhere((h) => h.id == cloudHabit.id);
          if (index != -1) {
            _habits[index] = _habits[index].copyWith(
              streak: cloudHabit.streak,
              completionDates: cloudHabit.completionDates,
            );
          }
        }

        await _savePreferences();
        notifyListeners();
        debugPrint('✅ Cloud streaks applied successfully');
      } else {
        debugPrint('❌ User chose to keep local streaks');
      }
    } catch (e) {
      debugPrint('❌ Error handling sync conflicts: $e');
    }
  }
}
