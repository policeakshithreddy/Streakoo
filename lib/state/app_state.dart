import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uuid/uuid.dart';

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
import '../services/firebase_service.dart';
import '../services/daily_brief_service.dart';
import '../services/smart_time_service.dart';
import '../models/streak_freeze.dart';
import '../models/loot_box.dart';
import '../models/pet_diary_entry.dart';

class AppState extends ChangeNotifier {
  AppState();

  // ----------------- Fields -----------------
  final List<Habit> _habits = [];
  final List<Map<String, dynamic>> _achievements = [];
  bool _isFirstRun = true;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _hasShownStreakWarningSession = false;
  bool _hasShownDuplicateWarningSession = false;
  bool _hideManualCompletionWarning = false;

  // Notification Preferences
  bool _morningQuotesEnabled = false; // Off by default
  bool _streakAlertsEnabled = true; // On by default
  bool _milestoneCelebrationEnabled = true; // On by default

  // Gamification
  int _totalXP = 0;
  UserLevel? _userLevel;
  String _petName = 'Your Pet'; // Default name

  // Mood tracking
  final List<MoodEntry> _moodHistory = [];
  String? _lastMoodCheckDate; // yyyy-MM-dd

  // Streak Freeze (Enhanced with level-based regeneration)
  int _streakFreezes = 0;
  StreakFreeze? _enhancedStreakFreeze; // New level-based freeze system
  final List<String> _frozenDates = []; // yyyy-MM-dd
  String? _lastMissedHabitDate; // yyyy-MM-dd
  String? _lastFreezeRegenDate; // yyyy-MM-dd - track last regeneration

  // Loot Boxes
  LootBox? _pendingLootBox; // Earned but not opened yet

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

  // Manual Health Logs - stores user-reported/goal-based health data
  // Format: { "2024-12-15": { "sleep": 7.0, "steps": 10000, ... } }
  final Map<String, Map<String, double>> _manualHealthLogs = {};

  // Track Focus Challenge rewards to prevent double-awarding
  bool _isSyncingHealth = false;

  // Pet Diary
  final List<PetDiaryEntry> _petDiary = [];

  // Achievement types for Wrapped events
  static const String typeChallengeCompletion = 'challenge_completion';
  static const String typeFocusChallenge = 'focus_challenge';
  static const String typeHealthChallenge = 'health_challenge';
  static const String typeStreakMilestone = 'streak_milestone';
  static const String typeLevelUp = 'level_up';

  final Map<String, List<int>> _awardedFocusMilestones =
      {}; // { "yyyy-MM-dd": [7, 15, 30] }

  Future<void> setHideManualCompletionWarning(bool enabled) async {
    _hideManualCompletionWarning = enabled;
    await _savePreferences();
    notifyListeners();
  }

  // ----------------- Getters -----------------
  List<Habit> get habits => List.unmodifiable(_habits);
  List<PetDiaryEntry> get petDiary => List.unmodifiable(_petDiary);

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

  // Notification Preferences Getters
  bool get morningQuotesEnabled => _morningQuotesEnabled;
  bool get streakAlertsEnabled => _streakAlertsEnabled;
  bool get milestoneCelebrationEnabled => _milestoneCelebrationEnabled;

  void markStreakWarningShown() {
    _hasShownStreakWarningSession = true;
    notifyListeners();
  }

  // Duplicate detection session tracking
  bool get hasShownDuplicateWarningSession => _hasShownDuplicateWarningSession;
  bool get hideManualCompletionWarning => _hideManualCompletionWarning;

  void markDuplicateWarningShown() {
    _hasShownDuplicateWarningSession = true;
    notifyListeners();
  }

  // Gamification getters
  int get totalXP => _totalXP;
  UserLevel get userLevel => _userLevel ?? UserLevel.fromTotalXP(0);
  String get petName => _petName;

  void setPetName(String name) {
    _petName = name;
    _savePreferences();
    notifyListeners();
  }

  // Mood getters
  List<MoodEntry> get moodHistory => List.unmodifiable(_moodHistory);

  // Streak Freeze getters
  int get streakFreezes => _streakFreezes;
  List<String> get frozenDates => List.unmodifiable(_frozenDates);
  StreakFreeze? get enhancedStreakFreeze => _enhancedStreakFreeze;

  // Loot Box getters
  LootBox? get pendingLootBox => _pendingLootBox;
  bool get hasPendingLootBox => _pendingLootBox != null;

  // Track recently frozen habits for animation
  final List<String> _recentlyFrozenHabitIds = [];
  bool get hasRecentlyFrozenHabits => _recentlyFrozenHabitIds.isNotEmpty;

  bool get hasMissedHabitToday {
    if (_lastMissedHabitDate == null) return false;
    return _lastMissedHabitDate == _getTodayKey();
  }

  List<String> consumeRecentlyFrozenHabits() {
    final list = List<String>.from(_recentlyFrozenHabitIds);
    _recentlyFrozenHabitIds.clear();
    notifyListeners();
    return list;
  }

  /// Initialize or update enhanced streak freeze based on level
  void _initializeEnhancedFreeze() {
    final level = _userLevel?.level ?? 1;

    if (_enhancedStreakFreeze == null) {
      // First time: create with current freezes
      _enhancedStreakFreeze = StreakFreeze(
        availableFreezes:
            _streakFreezes.clamp(0, StreakFreeze.getMaxFreezesForLevel(level)),
        maxFreezes: StreakFreeze.getMaxFreezesForLevel(level),
        lastRegenTime: DateTime.now(),
      );
    } else {
      // Update max based on new level
      _enhancedStreakFreeze = _enhancedStreakFreeze!.checkAndRegenerate(level);
    }

    // Sync with legacy field
    _streakFreezes = _enhancedStreakFreeze!.availableFreezes;
  }

  /// Check for freeze regeneration (call on app open)
  void checkFreezeRegeneration() {
    if (_enhancedStreakFreeze == null) {
      _initializeEnhancedFreeze();
    } else {
      final level = _userLevel?.level ?? 1;
      final updated = _enhancedStreakFreeze!.checkAndRegenerate(level);
      if (updated.availableFreezes != _enhancedStreakFreeze!.availableFreezes) {
        _enhancedStreakFreeze = updated;
        _streakFreezes = updated.availableFreezes;
        _lastFreezeRegenDate = _getTodayKey();
        _savePreferences();
        notifyListeners();
      }
    }
  }

  /// Use a streak freeze for a habit
  bool useEnhancedFreeze(String habitId, String habitName) {
    if (_enhancedStreakFreeze == null || !_enhancedStreakFreeze!.canUseFreeze) {
      return false;
    }

    _enhancedStreakFreeze =
        _enhancedStreakFreeze!.useFreeze(habitId, habitName);
    _streakFreezes = _enhancedStreakFreeze!.availableFreezes;

    // Record the frozen date so it appears on the heatmap and preserves streak!
    final today = _getTodayKey();
    if (!_frozenDates.contains(today)) {
      _frozenDates.add(today);
    }

    _savePreferences();
    notifyListeners();
    return true;
  }

  /// Award extra freeze (from loot box or challenge completion)
  void awardExtraFreeze(int count) {
    debugPrint('🧊 awardExtraFreeze called with count: $count');
    debugPrint('🧊 Current freezes before: $_streakFreezes');

    if (_enhancedStreakFreeze == null) {
      _initializeEnhancedFreeze();
    }

    final level = _userLevel?.level ?? 1;
    final maxFreezes = StreakFreeze.getMaxFreezesForLevel(level);
    final currentCount =
        _enhancedStreakFreeze?.availableFreezes ?? _streakFreezes;
    final newCount = (currentCount + count)
        .clamp(0, maxFreezes + 5); // Allow 5 over max from rewards

    if (_enhancedStreakFreeze != null) {
      _enhancedStreakFreeze =
          _enhancedStreakFreeze!.copyWith(availableFreezes: newCount);
    }
    _streakFreezes = newCount;

    debugPrint('🧊 New freezes after award: $_streakFreezes');

    _savePreferences();
    notifyListeners();
  }

  /// Set pending loot box (earned from milestone)
  void setPendingLootBox(LootBox lootBox) {
    _pendingLootBox = lootBox;
    notifyListeners();
  }

  /// Clear pending loot box (after opening)
  void clearPendingLootBox() {
    _pendingLootBox = null;
    notifyListeners();
  }

  /// Check if a streak milestone triggers a loot box
  LootBox? checkStreakLootBox(
      int newStreak, int previousStreak, String habitId) {
    LootBoxTrigger? trigger;

    if (newStreak >= 100 && previousStreak < 100) {
      trigger = LootBoxTrigger.streak100;
    } else if (newStreak >= 30 && previousStreak < 30) {
      trigger = LootBoxTrigger.streak30;
    } else if (newStreak >= 7 && previousStreak < 7) {
      trigger = LootBoxTrigger.streak7;
    }

    if (trigger != null) {
      final lootBox = LootBox(
        id: '${trigger.name}_${DateTime.now().millisecondsSinceEpoch}',
        trigger: trigger,
        earnedAt: DateTime.now(),
      );
      _pendingLootBox = lootBox;
      notifyListeners();
      return lootBox;
    }

    return null;
  }

  /// Check for level-up loot box
  LootBox? checkLevelUpLootBox(int newLevel, int previousLevel) {
    LootBoxTrigger? trigger;

    if (newLevel % 10 == 0 && previousLevel % 10 != 0) {
      trigger = LootBoxTrigger.levelUp10;
    } else if (newLevel % 5 == 0 && previousLevel % 5 != 0) {
      trigger = LootBoxTrigger.levelUp5;
    }

    if (trigger != null) {
      final lootBox = LootBox(
        id: '${trigger.name}_${DateTime.now().millisecondsSinceEpoch}',
        trigger: trigger,
        earnedAt: DateTime.now(),
      );
      _pendingLootBox = lootBox;
      notifyListeners();
      return lootBox;
    }

    return null;
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

  // Manual Health Log Getters and Helpers
  /// Get manually logged health data for a specific date and metric
  double? getManualHealthLog(String dateKey, String metricType) {
    return _manualHealthLogs[dateKey]?[metricType];
  }

  /// Get all manual health logs
  Map<String, Map<String, double>> get manualHealthLogs =>
      Map.unmodifiable(_manualHealthLogs);

  /// Log a manual health metric (called when user completes a health habit with goal)
  void _logManualHealthMetric(
      String dateKey, HealthMetricType metric, double value) {
    _manualHealthLogs[dateKey] ??= {};
    final metricKey = metric.name; // 'sleep', 'steps', etc.

    // Keep the higher value if already logged (user might complete multiple habits)
    final existing = _manualHealthLogs[dateKey]![metricKey] ?? 0;
    if (value > existing) {
      _manualHealthLogs[dateKey]![metricKey] = value;
      debugPrint('📊 Manual health log: $dateKey - $metricKey = $value');
    }
  }

  /// Get sleep hours for a date (manual log or from habits)
  double getManualSleepHours(DateTime date) {
    final dateKey = _dateToKey(date);
    return _manualHealthLogs[dateKey]?['sleep'] ?? 0.0;
  }

  /// Get steps for a date (manual log or from habits)
  int getManualSteps(DateTime date) {
    final dateKey = _dateToKey(date);
    return (_manualHealthLogs[dateKey]?['steps'] ?? 0).toInt();
  }

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
    final durationWeeks = _activeHealthChallenge!.durationWeeks;

    // 0. Award streak freezes based on challenge duration!
    // Align with 2/3/6 rule: 1 week (7d) = 2, 2 weeks (14d+) = 3, 4 weeks (30d+) = 6
    int freezeReward = 0;
    if (durationWeeks >= 4) {
      freezeReward = 6;
    } else if (durationWeeks >= 2) {
      freezeReward = 3;
    } else if (durationWeeks >= 1) {
      freezeReward = 2;
    }

    if (freezeReward > 0) {
      awardExtraFreeze(freezeReward);
      debugPrint('🏆 Challenge reward: +$freezeReward streak freeze(s)!');
    }

    // 0b. Archive for Wrapped Events before deletion
    _addAchievement(
      habitName: _activeHealthChallenge!.title,
      habitEmoji: '💪', // Default health emoji
      challengeDays: _activeHealthChallenge!.durationWeeks * 7,
      completedDate: DateTime.now().toIso8601String().split('T').first,
      type: typeHealthChallenge,
    );

    // 0c. Pet Diary Entry
    final petName = _petName.isNotEmpty ? _petName : 'Your pet';
    _addPetDiaryEntry(
      'MISSION ACCOMPLISHED! $petName is so proud of our progress in the "${_activeHealthChallenge!.title}". We are getting stronger every day! 💪🏆',
      '🥳',
      PetDiaryEntryType.challengeCompleted,
    );

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

  /// Overwrite local habits with a specific list (used for Sync Conflict Resolution)
  Future<void> overwriteHabits(List<Habit> newHabits) async {
    _habits.clear();
    _habits.addAll(newHabits);
    await _savePreferences();
    notifyListeners();
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
  static const _prefsKeyHideManualCompletionWarning =
      'hide_manual_completion_warning';
  static const _prefsKeyFirstRun = 'isFirstRun';
  static const _prefsKeyTheme = 'themeMode';
  static const _prefsKeyTotalXP = 'totalXP';
  static const _prefsKeyMoodHistory = 'moodHistory_v1';
  static const _prefsKeyUserLevel = 'userLevel_v1';
  static const _prefsKeyLastMoodCheck = 'lastMoodCheckDate';
  static const _prefsKeyLastMissedHabit = 'last_missed_habit_date';
  static const _prefsKeyWeeklyReports = 'weekly_reports';
  static const _prefsKeyLastDailyBrief = 'last_daily_brief';
  static const _prefsKeyLastWeeklyReport = 'last_weekly_report';
  static const _prefsKeyLastBackup = 'lastBackupDate';
  static const _prefsKeyActiveChallenge = 'active_challenge_v1';
  static const _prefsKeyAchievedMilestones = 'achieved_milestones';
  static const _prefsKeyShownMilestones = 'shown_milestone_ids';
  static const _prefsKeyPetName = 'streakoo_pet_name';

  // Notification Preferences Keys
  static const _prefsKeyMorningQuotes = 'notification_morning_quotes';
  static const _prefsKeyStreakAlerts = 'notification_streak_alerts';
  static const _prefsKeyMilestoneCelebration =
      'notification_milestone_celebration';

  // ----------------- Load / Save -----------------
  /// Load only essential preferences needed before UI renders
  /// This is the critical path - keep it as fast as possible
  Future<void> loadEssentialPreferences() async {
    debugPrint('⚡ Loading essential preferences...');
    final sw = Stopwatch()..start();

    final prefs = await SharedPreferences.getInstance();

    _petName = prefs.getString(_prefsKeyPetName) ?? 'Your Pet';

    // Only load what's absolutely necessary for the initial screen
    _isFirstRun = prefs.getBool(_prefsKeyFirstRun) ?? true;

    final themeStr = prefs.getString(_prefsKeyTheme);
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }

    notifyListeners();
    sw.stop();
    debugPrint('✅ Essential preferences loaded in ${sw.elapsedMilliseconds}ms');
  }

  /// Load all app data in the background after UI is rendered
  /// This can be called asynchronously without blocking the UI
  Future<void> loadFullData() async {
    debugPrint('📦 Loading full app data...');
    final sw = Stopwatch()..start();

    final prefs = await SharedPreferences.getInstance();

    // Load habits
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

      // REPAIR: Check for duplicate IDs which caused completion issues
      final hasRepairs = _repairDuplicateIds();
      if (hasRepairs) {
        debugPrint('🛠️ Repaired duplicate habit IDs');
        await _savePreferences();
      }

      // IMPORTANT: Recalculate completedToday based on today's date
      // This ensures habits reset properly each day
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      for (var i = 0; i < _habits.length; i++) {
        final habit = _habits[i];
        final isCompletedToday = habit.completionDates.contains(todayKey);
        if (habit.completedToday != isCompletedToday) {
          _habits[i] = habit.copyWith(completedToday: isCompletedToday);
          debugPrint(
              '📅 Reset completedToday for "${habit.name}": ${habit.completedToday} -> $isCompletedToday');
        }
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
    _lastBackupDate = prefs.getString(_prefsKeyLastBackup);

    // Load Streak Freezes
    // Load Streak Freezes - Give 2 freebeez for new users!
    if (prefs.containsKey('streak_freezes')) {
      _streakFreezes = prefs.getInt('streak_freezes') ?? 0;
    } else {
      _streakFreezes = 2; // Default for new users
    }
    final frozenJson = prefs.getString('frozen_dates');
    if (frozenJson != null) {
      try {
        final list = jsonDecode(frozenJson) as List;
        _frozenDates.clear();
        _frozenDates.addAll(list.map((e) => e as String));
      } catch (_) {}
    }

    // Load enhanced streak freeze
    final enhancedFreezeJson = prefs.getString('enhanced_streak_freeze');
    if (enhancedFreezeJson != null) {
      try {
        _enhancedStreakFreeze = StreakFreeze.deserialize(enhancedFreezeJson);
      } catch (_) {}
    }

    // NEW: Backfill rewards for existing users who already completed challenges or reached streaks
    await _backfillLegacyRewards(prefs);
    _lastFreezeRegenDate = prefs.getString('last_freeze_regen_date');

    // Initialize or check regeneration
    checkFreezeRegeneration();

    // Check and reset streaks for missed days
    _lastMissedHabitDate = prefs.getString(_prefsKeyLastMissedHabit);
    _checkAndResetStreaks();
    _recalculateAllStreaks();

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

    // Load Notification Preferences
    _morningQuotesEnabled = prefs.getBool(_prefsKeyMorningQuotes) ?? false;
    _streakAlertsEnabled = prefs.getBool(_prefsKeyStreakAlerts) ?? true;
    _milestoneCelebrationEnabled =
        prefs.getBool(_prefsKeyMilestoneCelebration) ?? true;
    _hideManualCompletionWarning =
        prefs.getBool(_prefsKeyHideManualCompletionWarning) ?? false;
    debugPrint(
        '🔔 Notification prefs loaded - Morning: $_morningQuotesEnabled, Streak: $_streakAlertsEnabled, Milestone: $_milestoneCelebrationEnabled');

    // Load Pet Diary
    final petDiaryJson = prefs.getString('pet_diary');
    if (petDiaryJson != null && petDiaryJson.isNotEmpty) {
      try {
        final list = jsonDecode(petDiaryJson) as List;
        _petDiary
          ..clear()
          ..addAll(list
              .map((e) => PetDiaryEntry.fromJson(e as Map<String, dynamic>)));
      } catch (e) {
        debugPrint('Error loading pet diary: $e');
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

    // Perform daily cloud backup if needed (non-blocking)
    checkAndPerformDailyBackup().catchError((e) {
      debugPrint('Auto-backup error: $e');
    });

    // Check and update daily AI insight for active challenge
    checkAndUpdateDailyInsight().catchError((e) {
      debugPrint('Auto-insight update error: $e');
    });

    notifyListeners();
    sw.stop();
    debugPrint('✅ Full data loaded in ${sw.elapsedMilliseconds}ms');
  }

  /// Legacy method - loads all preferences synchronously
  /// Kept for compatibility, but prefer loadEssentialPreferences + loadFullData
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _isFirstRun = prefs.getBool(_prefsKeyFirstRun) ?? true;

    final themeStr = switch (_themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_prefsKeyTheme, themeStr);

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

      // IMPORTANT: Recalculate completedToday based on today's date
      // This ensures habits reset properly each day
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      for (var i = 0; i < _habits.length; i++) {
        final habit = _habits[i];
        final isCompletedToday = habit.completionDates.contains(todayKey);
        if (habit.completedToday != isCompletedToday) {
          _habits[i] = habit.copyWith(completedToday: isCompletedToday);
        }
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

    // Load Notification Preferences
    _morningQuotesEnabled = prefs.getBool(_prefsKeyMorningQuotes) ?? false;
    _streakAlertsEnabled = prefs.getBool(_prefsKeyStreakAlerts) ?? true;
    _milestoneCelebrationEnabled =
        prefs.getBool(_prefsKeyMilestoneCelebration) ?? true;
    _hideManualCompletionWarning =
        prefs.getBool(_prefsKeyHideManualCompletionWarning) ?? false;

    // Load Manual Health Logs
    final healthLogsJson = prefs.getString('manual_health_logs');
    if (healthLogsJson != null) {
      try {
        final decoded = jsonDecode(healthLogsJson) as Map<String, dynamic>;
        _manualHealthLogs.clear();
        decoded.forEach((dateKey, metrics) {
          _manualHealthLogs[dateKey] = Map<String, double>.from(
            (metrics as Map)
                .map((k, v) => MapEntry(k as String, (v as num).toDouble())),
          );
        });
        debugPrint(
            '📊 Loaded ${_manualHealthLogs.length} manual health log entries');
      } catch (e) {
        debugPrint('Error loading manual health logs: $e');
      }
    }

    // Load Pet Diary
    final petDiaryJson = prefs.getString('pet_diary');
    if (petDiaryJson != null && petDiaryJson.isNotEmpty) {
      try {
        final list = jsonDecode(petDiaryJson) as List;
        _petDiary
          ..clear()
          ..addAll(list
              .map((e) => PetDiaryEntry.fromJson(e as Map<String, dynamic>)));
      } catch (e) {
        debugPrint('Error loading pet diary: $e');
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
    final todayKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    bool shouldSave = false;
    bool usedFreezeToday = false;

    for (var i = 0; i < _habits.length; i++) {
      final habit = _habits[i];

      if (habit.completionDates.isEmpty) continue;

      // Get the last completion date
      final lastCompletionStr = habit.completionDates.last;
      final lastCompletion = DateTime.parse(lastCompletionStr);
      final lastDay = DateTime(
        lastCompletion.year,
        lastCompletion.month,
        lastCompletion.day,
      );

      // If completed today or already processed yesterday, streak is fine
      if (lastDay.isAtSameMomentAs(today) ||
          lastDay.isAtSameMomentAs(yesterday)) {
        continue;
      }

      // If we are here, the habit was missed yesterday (or earlier)
      // Check if we can freeze it
      final daysDifference = today.difference(lastDay).inDays;
      if (daysDifference > 1) {
        bool protectedByFreeze = false;

        // ONLY focus tasks are eligible for freeze protection
        if (habit.isFocusTask) {
          // Check if yesterday is already frozen
          if (_frozenDates.contains(yesterdayKey)) {
            protectedByFreeze = true;
            debugPrint(
                '❄️ Focus task "${habit.name}" protected by existing freeze');
          } else if (_streakFreezes > 0 && !usedFreezeToday) {
            // Auto-use freeze if available and not already used today
            _streakFreezes--;
            _frozenDates.add(yesterdayKey);
            _recentlyFrozenHabitIds.add(habit.id);
            protectedByFreeze = true;
            usedFreezeToday = true;
            debugPrint(
                '🧊 Used freeze for "${habit.name}" (Focus Task). Freezes left: $_streakFreezes');
            shouldSave = true;
          }
        }

        if (protectedByFreeze) {
          // Streak saved! Just mark as not completed today
          // Also track frozen date for challenge if applicable
          List<String>? newChallengeFrozenDates;
          if (habit.challengeTargetDays != null && !habit.challengeCompleted) {
            newChallengeFrozenDates = [
              ...habit.challengeFrozenDates,
              yesterdayKey
            ];
            debugPrint(
                '❄️ Frozen date $yesterdayKey added to challenge for "${habit.name}"');
          }
          _habits[i] = habit.copyWith(
            completedToday: false,
            challengeFrozenDates: newChallengeFrozenDates,
          );
          shouldSave = true;
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

          // Mark as missed habit for pet emotion
          _lastMissedHabitDate = todayKey;
          shouldSave = true;
        }
      }
      // If it's a new day (but not more than 1 day), just mark as not completed today
      else if (daysDifference == 1) {
        _habits[i] = habit.copyWith(
          completedToday: false,
        );
        // No need to save here usually, but if we change 'completedToday', we might want to?
        // Actually completedToday is transient often, but let's be safe.
        // Wait, completedToday is stored in JSON usually? No, "runtime only".
        // But for UI updates we need notifyListeners.
      }
    }

    if (shouldSave) {
      _savePreferences();
      notifyListeners();
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
    // Sync achievements to cloud
    await SupabaseService().upsertAchievements(_achievements);

    // Save User Level
    if (_userLevel != null) {
      await prefs.setString(
          _prefsKeyUserLevel, jsonEncode(_userLevel!.toJson()));
    }
    // Also save totalXP for backup/compatibility
    await prefs.setInt(_prefsKeyTotalXP, _totalXP);
    await prefs.setString(_prefsKeyPetName, _petName);

    final moodEncoded =
        jsonEncode(_moodHistory.map((m) => m.toJson()).toList());
    await prefs.setString(_prefsKeyMoodHistory, moodEncoded);

    if (_lastMoodCheckDate != null) {
      await prefs.setString(_prefsKeyLastMoodCheck, _lastMoodCheckDate!);
    }

    await prefs.setInt('streak_freezes', _streakFreezes);
    await prefs.setString('frozen_dates', jsonEncode(_frozenDates));

    // Save enhanced streak freeze
    if (_enhancedStreakFreeze != null) {
      await prefs.setString(
          'enhanced_streak_freeze', _enhancedStreakFreeze!.serialize());
    }
    if (_lastFreezeRegenDate != null) {
      await prefs.setString('last_freeze_regen_date', _lastFreezeRegenDate!);
    }

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

    // Save Manual Health Logs
    if (_manualHealthLogs.isNotEmpty) {
      await prefs.setString(
          'manual_health_logs', jsonEncode(_manualHealthLogs));
    }

    // Save Notification Preferences
    await prefs.setBool(_prefsKeyMorningQuotes, _morningQuotesEnabled);
    await prefs.setBool(_prefsKeyStreakAlerts, _streakAlertsEnabled);
    await prefs.setBool(
        _prefsKeyMilestoneCelebration, _milestoneCelebrationEnabled);
    await prefs.setBool(
        _prefsKeyHideManualCompletionWarning, _hideManualCompletionWarning);

    // Save Focus Challenge Milestone tracking
    await prefs.setString(
        'awarded_focus_milestones', jsonEncode(_awardedFocusMilestones));

    // Save Pet Diary
    final diaryEncoded = jsonEncode(_petDiary.map((e) => e.toJson()).toList());
    await prefs.setString('pet_diary', diaryEncoded);

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

  // Notification Preference Setters
  Future<void> setMorningQuotesEnabled(bool enabled) async {
    _morningQuotesEnabled = enabled;
    await _savePreferences();

    // Reschedule morning brief notification based on new preference
    try {
      await DailyBriefService.instance.scheduleMorningBrief(enabled: enabled);
    } catch (e) {
      debugPrint('⚠️ Failed to reschedule morning brief: $e');
    }

    notifyListeners();
  }

  Future<void> setStreakAlertsEnabled(bool enabled) async {
    _streakAlertsEnabled = enabled;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setMilestoneCelebrationEnabled(bool enabled) async {
    _milestoneCelebrationEnabled = enabled;
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

    // Track with Firebase Analytics
    FirebaseService.instance.logHabitCreated(
      habitName: habit.name,
      category: habit.category,
      hasReminder: habit.reminderEnabled,
      isHealthTracked: habit.isHealthTracked,
      isFocusTask: habit.isFocusTask,
    );
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

  /// Merge two habits into one, keeping the primary and deleting the secondary
  Future<void> mergeHabits(
      String primaryId, String secondaryId, Habit mergedHabit) async {
    final primaryIndex = _habits.indexWhere((h) => h.id == primaryId);
    final secondaryIndex = _habits.indexWhere((h) => h.id == secondaryId);

    if (primaryIndex == -1 || secondaryIndex == -1) {
      debugPrint('❌ Merge failed: habit not found');
      return;
    }

    // Update primary habit with merged data
    _habits[primaryIndex] = mergedHabit;

    // Delete secondary habit
    final secondaryHabit = _habits[secondaryIndex];
    _habits.removeAt(secondaryIndex);

    _savePreferences();
    notifyListeners();

    // Sync changes to cloud
    final supabase = SupabaseService();
    await supabase.upsertHabit(mergedHabit);
    if (supabase.isAuthenticated) {
      try {
        await supabase.deleteHabit(secondaryHabit.id);
        debugPrint(
            '✅ Merged habits: "${mergedHabit.name}" (deleted duplicate)');
      } catch (e) {
        debugPrint('⚠️ Failed to delete duplicate from cloud: $e');
      }
    }
  }

  /// Reset challenge progress for a set of habits and start a new target
  Future<void> resetChallengeForHabits(
      List<String> habitIds, int newTargetDays) async {
    bool changed = false;

    // Record achievement before resetting if it was completed
    final focusHabits = _habits.where((h) => h.isFocusTask).toList();
    final isAggregateReset = habitIds.length == focusHabits.length &&
        habitIds.every((id) => focusHabits.any((h) => h.id == id));

    if (isAggregateReset) {
      // It's a focus challenge reset. If it was completed, record it.
      // (Wait, we'll rely on the individual achievements or the aggregate one added in _checkAndAwardFocusChallengeReward)
    }

    for (var i = 0; i < _habits.length; i++) {
      if (habitIds.contains(_habits[i].id)) {
        _habits[i] = _habits[i].copyWith(
          challengeProgress: 0,
          challengeCompleted: false,
          challengeTargetDays: newTargetDays,
          challengeFrozenDates: [],
        );
        changed = true;
      }
    }

    if (changed) {
      _savePreferences();
      notifyListeners();

      // Sync all changed habits to cloud
      await SupabaseService().syncHabitsToCloud(
          _habits.where((h) => habitIds.contains(h.id)).toList());
    }
  }

  void _checkAndAwardFocusChallengeReward(String todayKey) {
    final focusHabits = _habits.where((h) => h.isFocusTask).toList();
    if (focusHabits.isEmpty) return;

    // Calculate aggregate streak ONLY if all completed today
    bool allDoneToday = focusHabits.every((h) => h.completedToday);
    if (!allDoneToday) return;

    // We can't really use the same streak calculation as PetScreen easily without duplication,
    // but we can check if each habit has reached its target today.

    // For simplicity, let's say the Focus Challenge rewards happen when all focus habits
    // hit common milestones: 7, 15, 30.

    // Find common milestone hit today
    final streaks = focusHabits.map((h) => h.streak).toList();
    final minStreak = streaks.reduce((a, b) => a < b ? a : b);

    // If the lowest streak hit a milestone, reward!
    if ([7, 15, 30].contains(minStreak)) {
      final milestonesToday = _awardedFocusMilestones[todayKey] ?? [];
      if (!milestonesToday.contains(minStreak)) {
        // Milestone hit for the first time today!
        int freezesToAward = minStreak == 7 ? 2 : (minStreak == 15 ? 3 : 6);

        awardExtraFreeze(freezesToAward);

        _addAchievement(
          habitName: 'Focus Challenge',
          habitEmoji: '🎯',
          challengeDays: minStreak,
          completedDate: todayKey,
          type: typeFocusChallenge,
        );

        milestonesToday.add(minStreak);
        _awardedFocusMilestones[todayKey] = milestonesToday;
        _savePreferences();
      }
    }
  }

  // ----------------- Completion / streaks -----------------
  Future<void> completeHabit(Habit habit, {bool isAiTriggered = false}) async {
    try {
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index == -1) {
        debugPrint('❌ completeHabit: Habit not found with ID ${habit.id}');
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final current = _habits[index];

      // Log completion source
      if (isAiTriggered) {
        debugPrint('🤖 AI-triggered completion for "${current.name}"');
      } else {
        debugPrint('👆 Manual completion for "${current.name}"');
      }

      // Already done today?
      final isAlreadyCompletedToday =
          current.completionDates.contains(todayKey);

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

      // Capture previous streak for milestone checks
      final previousStreak = current.streak;

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

          awardExtraFreeze(freezesToAward);

          // Create achievement for completed challenge
          _addAchievement(
            habitName: current.name,
            habitEmoji: current.emoji,
            challengeDays: current.challengeTargetDays!,
            completedDate: todayKey,
            type: typeChallengeCompletion,
          );

          // Pet Diary: Challenge Completed
          final petName = _petName.isNotEmpty ? _petName : 'Your pet';
          _addPetDiaryEntry(
            'HUGE WIN! $petName watched you finish the ${current.challengeTargetDays}-day challenge for "${current.name}". You are a legend! 🏆✨',
            '🔥',
            PetDiaryEntryType.challengeCompleted,
          );
        }
      }

      // Check for Aggregate Focus Challenge Reward
      if (current.isFocusTask) {
        _checkAndAwardFocusChallengeReward(todayKey);

        // Pet Diary: Focus Task Completed
        final petName = _petName.isNotEmpty ? _petName : 'Your pet';
        _addPetDiaryEntry(
          '$petName saw you crush your focus task "${current.name}"! He is feeling extra motivated now. 🎯🦾',
          '😎',
          PetDiaryEntryType.focusTaskCompleted,
        );
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

        // Check for level-up loot box (every 5 or 10 levels)
        checkLevelUpLootBox(newLevel, oldLevel);

        // Update freeze max based on new level
        _initializeEnhancedFreeze();
      }

      // Check for streak milestone loot box
      checkStreakLootBox(newStreak, previousStreak, habit.id);

      // Re-find index after potential awaits
      final finalIndex = _habits.indexWhere((h) => h.id == updated.id);
      if (finalIndex != -1) {
        _habits[finalIndex] = updated;
      }

      // Debug: Verify streak updated
      debugPrint(
          '✅ Habit "${updated.name}" completed! Streak: ${updated.streak} days');

      // Log health metric if this is a health-tracked habit with a goal
      // For stats: use actual health data (not just the goal)
      if (updated.healthGoalValue != null && updated.healthMetric != null) {
        // Try to get actual health value; fall back to goal for manual completions
        double valueToLog = updated.healthGoalValue!;
        if (isAiTriggered) {
          // AI-triggered means we have actual health data
          try {
            final actualValue = await HealthService.instance
                .getCurrentValue(updated.healthMetric!);
            valueToLog = actualValue;
          } catch (e) {
            debugPrint('⚠️ Could not fetch actual health value: $e');
          }
        }
        _logManualHealthMetric(todayKey, updated.healthMetric!, valueToLog);
      }

      _savePreferences();
      notifyListeners();

      // Sync to cloud (Habit + User Level)
      final supabase = SupabaseService();
      supabase.upsertHabit(updated);
      if (_userLevel != null) {
        supabase.upsertUserLevel(_userLevel!, _totalXP);
      }

      // Track with Firebase Analytics
      FirebaseService.instance.logHabitCompleted(
        habitId: updated.id,
        habitName: updated.name,
        category: updated.category,
        streak: updated.streak,
        isHealthTracked: updated.isHealthTracked,
      );

      // Record completion time for smart suggestions
      SmartTimeService.instance.recordCompletion(updated.id);

      // Track streak milestones
      if ([7, 14, 21, 30, 50, 100, 365].contains(updated.streak)) {
        FirebaseService.instance.logStreakMilestone(
          habitName: updated.name,
          streakDays: updated.streak,
        );
      }

      // Check for milestones if there's an active challenge
      if (_activeHealthChallenge != null) {
        await _checkForNewMilestones();
      }
    } catch (e, stack) {
      debugPrint('❌ Error completing habit "${habit.name}": $e');
      debugPrint(stack.toString());
      // Re-throw to let UI know something went wrong
      rethrow;
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

    // Deduct XP using the proper method that preserves avatar data
    final xpToDeduct = current.actualXP;

    if (_userLevel != null) {
      final oldLevel = _userLevel!.level;
      final oldXp = _userLevel!.currentXP;
      _userLevel!.removeXP(xpToDeduct);
      _totalXP = (_totalXP - xpToDeduct).clamp(0, _totalXP);
      debugPrint(
          '📉 XP: $oldXp -> ${_userLevel!.currentXP}, Level: $oldLevel -> ${_userLevel!.level}');
    } else {
      _totalXP = (_totalXP - xpToDeduct).clamp(0, _totalXP);
    }

    _habits[index] = current.copyWith(
      completedToday: false,
      completionDates: newCompletionDates,
      streak: newStreak,
    );

    debugPrint(
        '↩️ Habit "${current.name}" uncompleted. Streak: $newStreak, XP deducted: $xpToDeduct');

    _savePreferences();
    notifyListeners();

    // Sync to cloud
    SupabaseService().upsertHabit(_habits[index]);
    if (_userLevel != null) {
      SupabaseService().upsertUserLevel(_userLevel!, _totalXP);
    }
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
    DateTime? lastDate;

    for (final date in sortedDates) {
      final day = DateTime(date.year, date.month, date.day);

      if (lastDate == null) {
        // First completion date (usually today or recent)
        streak = 1;
        lastDate = day;
      } else {
        // Find how many days between these completions
        int difference = lastDate.difference(day).inDays;

        if (difference == 1) {
          // Consecutive completion
          streak++;
          lastDate = day;
        } else if (difference == 0) {
          // Same day completion (duplicate)
          continue;
        } else {
          // Gap of more than 1 day. Check if all days in between were frozen.
          bool allFrozen = true;
          for (int i = 1; i < difference; i++) {
            final checkDate = lastDate.subtract(Duration(days: i));
            final checkKey = _dateToKey(checkDate);
            if (!_frozenDates.contains(checkKey)) {
              allFrozen = false;
              break;
            }
          }

          if (allFrozen) {
            // All days in the gap were frozen, count this previous completion as consecutive
            streak++;
            lastDate = day;
          } else {
            // True gap found, streak broken
            break;
          }
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
    String? type,
  }) {
    final badge = challengeDays <= 7
        ? '🥉'
        : challengeDays <= 15
            ? '🥈'
            : '🥇';

    final achievement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'habitName': habitName,
      'habitEmoji': habitEmoji,
      'challengeDays': challengeDays,
      'badge': badge,
      'completedDate': completedDate,
      'type': type ?? 'general',
    };

    _achievements.add(achievement);
    _savePreferences();
  }

  void _addLevelUpAchievement(int level) {
    final achievement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'habitName': 'Level Up!',
      'habitEmoji': '⭐',
      'challengeDays': level,
      'badge': '🎖️',
      'completedDate': _getTodayKey(),
      'type': typeLevelUp,
    };
    _achievements.add(achievement);

    // Pet Diary: Level Up
    final petName = _petName.isNotEmpty ? _petName : 'Your pet';
    _addPetDiaryEntry(
      'LEVEL UP! You reached level $level! $petName is so proud of your growth and dedication. Keep shining! ✨',
      '🥳',
      PetDiaryEntryType.levelUp,
    );
  }

  void _addPetDiaryEntry(
      String message, String moodEmoji, PetDiaryEntryType type) {
    final entry = PetDiaryEntry(
      id: const Uuid().v4(),
      date: DateTime.now(),
      message: message,
      moodEmoji: moodEmoji,
      type: type,
    );
    _petDiary.insert(0, entry);
    if (_petDiary.length > 50) _petDiary.removeLast(); // Keep only last 50
    _savePreferences();
    notifyListeners();
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
        'type': typeStreakMilestone,
      };
      _achievements.add(achievement);

      // Pet Diary: Milestone
      final petName = _petName.isNotEmpty ? _petName : 'Your pet';
      _addPetDiaryEntry(
        'INCREDIBLE! ${habit.name} reached a ${habit.streak}-day streak. $petName is doing a happy dance! 🕺✨',
        '🌟',
        PetDiaryEntryType.milestoneReached,
      );
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

  int get completedTodayCount => _habits.where((h) => h.completedToday).length;

  int get totalStreaks => _habits.fold<int>(0, (sum, h) => sum + h.streak);

  bool get allCompletedToday =>
      _habits.isNotEmpty && _habits.every((h) => h.completedToday);

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
    // If we already generated an insight today, skip
    if (_activeHealthChallenge!.aiPlan['lastInsightDate'] == today) return;

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

      default:
        return null;
    }
  }

  Future<void> syncHealthHabits() async {
    if (_isSyncingHealth) return;
    _isSyncingHealth = true;

    try {
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
            // Auto-complete the habit
            await completeHabit(habit, isAiTriggered: true);
            debugPrint('✅ Auto-completed health habit: ${habit.name}');
          }
        } catch (e) {
          debugPrint('❌ Error syncing habit ${habit.name}: $e');
        }
      }
    } finally {
      _isSyncingHealth = false;
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

      // Trust cloud data - only recalculate streaks for internal consistency
      // DO NOT call _checkAndResetStreaks() here as it would reset streaks based on local time
      // The cloud data already has the correct streaks from when user last used the app
      _recalculateAllStreaks();
      debugPrint('✅ Recalculated streaks from cloud data');

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

  /// Fix duplicate IDs in habits list
  /// (Legacy bug where templates created habits with same timestamp ID)
  /// Backfill streak freeze rewards for users who have already reached milestones
  Future<void> _backfillLegacyRewards(SharedPreferences prefs) async {
    const flagKey = 'legacy_rewards_backfilled_v2';
    if (prefs.getBool(flagKey) ?? false) return;

    debugPrint('💎 Checking for legacy streak rewards to backfill...');
    int totalNewFreezes = 0;

    for (final habit in _habits) {
      // 1. Check for COMPLETED challenges that were never rewarded
      if (habit.challengeCompleted && habit.challengeTargetDays != null) {
        int reward = 1;
        if (habit.challengeTargetDays == 7) reward = 2;
        if (habit.challengeTargetDays == 15) reward = 3;
        if (habit.challengeTargetDays == 30) reward = 6;

        totalNewFreezes += reward;
        debugPrint(
            '💎 Backfilling $reward freezes for COMPLETED ${habit.challengeTargetDays}-day challenge on "${habit.name}"');
      }

      // 2. Check for HIGH streaks that passed milestones (if challenge not completed yet)
      if (!habit.challengeCompleted) {
        if (habit.streak >= 30) {
          totalNewFreezes += 6;
        } else if (habit.streak >= 15) {
          totalNewFreezes += 3;
        } else if (habit.streak >= 7) {
          totalNewFreezes += 2;
        }
        if (habit.streak >= 7) {
          debugPrint(
              '💎 Backfilling freezes based on current streak of ${habit.streak} for "${habit.name}"');
        }
      }
    }

    if (totalNewFreezes > 0) {
      awardExtraFreeze(totalNewFreezes);
      debugPrint(
          '🎉 Backfilled total of $totalNewFreezes streak freezes representing your hard work!');
    }

    await prefs.setBool(flagKey, true);
  }

  bool _repairDuplicateIds() {
    final seenIds = <String>{};
    bool changed = false;

    for (int i = 0; i < _habits.length; i++) {
      final habit = _habits[i];
      if (seenIds.contains(habit.id)) {
        // Found duplicate! Generate new unique ID
        final newId = const Uuid().v4();
        debugPrint(
            '🔧 Fixing duplicate ID: ${habit.id} -> $newId (${habit.name})');

        // Create new replacement habit with unique ID
        _habits[i] = Habit(
          id: newId,
          name: habit.name,
          emoji: habit.emoji,
          category: habit.category,
          streak: habit.streak,
          completedToday: habit.completedToday,
          completionDates: habit.completionDates,
          challengeTargetDays: habit.challengeTargetDays,
          challengeProgress: habit.challengeProgress,
          challengeCompleted: habit.challengeCompleted,
          triggerAnimation: habit.triggerAnimation,
          isFocusTask: habit.isFocusTask,
          focusTaskPriority: habit.focusTaskPriority,
          xpValue: habit.xpValue,
          difficulty: habit.difficulty,
          customColor: habit.customColor,
          customIcon: habit.customIcon,
          reminderTime: habit.reminderTime,
          frequencyDays: habit.frequencyDays,
          reminderEnabled: habit.reminderEnabled,
          isHealthTracked: habit.isHealthTracked,
          healthMetric: habit.healthMetric,
          healthGoalValue: habit.healthGoalValue,
          habitGoal: habit.habitGoal,
          focusModeDuration: habit.focusModeDuration,
        );
        changed = true;
      } else {
        seenIds.add(habit.id);
      }
    }
    return changed;
  }
}
