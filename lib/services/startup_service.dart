import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'smart_notification_service.dart';
import '../utils/animation_config.dart';
import 'health_checker_service.dart';
import 'weekly_challenge_service.dart';
import 'koo_care_service.dart';
import 'daily_brief_service.dart';
import '../utils/haptic_service.dart';
import 'local_notification_service.dart';
import 'smart_time_service.dart';
import 'daily_challenge_service.dart';
import 'seasonal_event_service.dart';
import 'habit_correlation_service.dart';
import 'competition_notification_service.dart';
import 'accountability_service.dart';
import '../models/streakoo_pet.dart';

/// Manages app startup initialization in multiple phases
/// Priority 1: Critical path - needed before UI renders
/// Priority 2: Background - can initialize after UI loads
class StartupService {
  StartupService._();
  static final StartupService instance = StartupService._();

  bool _isBackgroundInitComplete = false;
  bool get isBackgroundInitComplete => _isBackgroundInitComplete;

  /// Initialize critical services that must complete before UI renders
  /// This should complete in < 100ms - keep this minimal!
  /// Note: Firebase is now initialized in main.dart background phase
  Future<void> initializeCriticalServices() async {
    debugPrint('🚀 Starting critical initialization...');
    final sw = Stopwatch()..start();

    // Critical services are now minimal - Firebase moved to background
    // Only add truly critical items here that must block UI

    sw.stop();
    debugPrint('✅ Critical init complete in ${sw.elapsedMilliseconds}ms');
  }

  /// Initialize non-critical services in the background after UI loads
  /// This runs asynchronously and doesn't block the UI
  Future<void> initializeBackgroundServices(AppState appState) async {
    if (_isBackgroundInitComplete) {
      debugPrint('⚠️ Background services already initialized');
      return;
    }

    debugPrint('🔄 Starting background initialization...');
    final sw = Stopwatch()..start();

    // Run all background initializations in parallel
    await Future.wait([
      _initializeHapticService(),
      _initializeNotificationService(),
      _initializeAnimationConfig(),
      _initializeHealthChecker(appState),
      _initializeEngagementServices(appState),
    ], eagerError: false); // Continue even if some fail

    _isBackgroundInitComplete = true;
    sw.stop();
    debugPrint('✅ Background init complete in ${sw.elapsedMilliseconds}ms');
  }

  Future<void> _initializeHapticService() async {
    try {
      await HapticService.instance.initialize();
      debugPrint('✅ HapticService initialized');
    } catch (e) {
      debugPrint('⚠️ HapticService init failed: $e');
    }
  }

  Future<void> _initializeNotificationService() async {
    try {
      // Initialize both notification services
      // SmartNotificationService handles habit reminders, streak alerts, milestones
      await SmartNotificationService.instance.initialize();
      debugPrint('✅ SmartNotificationService initialized');

      // LocalNotificationService is used by DailyBriefService for morning/evening notifications
      await LocalNotificationService.init();
      debugPrint('✅ LocalNotificationService initialized');
    } catch (e) {
      debugPrint('⚠️ Notification services init failed: $e');
    }
  }

  Future<void> _initializeAnimationConfig() async {
    try {
      await AnimationConfig.instance.init();
      debugPrint('✅ AnimationConfig initialized');
    } catch (e) {
      debugPrint('⚠️ AnimationConfig init failed: $e');
    }
  }

  Future<void> _initializeHealthChecker(AppState appState) async {
    try {
      await HealthCheckerService.instance.checkHealthHabits(appState);
      debugPrint('✅ HealthCheckerService initialized');
    } catch (e) {
      debugPrint('⚠️ HealthCheckerService init failed: $e');
    }
  }

  Future<void> _initializeEngagementServices(AppState appState) async {
    try {
      // Initialize AI and gamification services
      await Future.wait([
        SmartTimeService.instance.init(),
        DailyChallengeService.instance.init(),
        SeasonalEventService.instance.init(),
        HabitCorrelationService.instance.init(),
        StreakooPetService.instance.init(),
      ], eagerError: false);
      debugPrint('✅ AI & Gamification services initialized');

      // Initialize engagement services in parallel
      await Future.wait([
        WeeklyChallengeService.instance.initialize(),
        KooCareService.instance.initialize(),
        AccountabilityService.instance.initialize(),
        CompetitionNotificationService.instance.initialize(),
      ], eagerError: false);

      // Analyze habit correlations if enough data
      if (appState.habits.length >= 2) {
        HabitCorrelationService.instance.analyzeCorrelations(appState.habits);
      }

      // Generate daily challenge if enabled and none exists
      if (DailyChallengeService.instance.isEnabled &&
          DailyChallengeService.instance.todayChallenge == null &&
          appState.habits.isNotEmpty) {
        await DailyChallengeService.instance
            .generateDailyChallenge(appState.habits);
      }

      // Schedule notifications based on user preferences
      await Future.wait([
        DailyBriefService.instance.scheduleDailyNotifications(
          morningEnabled: appState.morningQuotesEnabled,
          eveningEnabled: true, // Evening reflection always enabled for now
        ),
        WeeklyChallengeService.instance.scheduleMondayNotification(),
        WeeklyChallengeService.instance.scheduleProgressNotification(),
      ], eagerError: false);

      debugPrint('✅ Engagement services initialized');

      // Check competition notifications
      await CompetitionNotificationService.instance.checkAndNotify(appState);
    } catch (e) {
      debugPrint('⚠️ Engagement services init failed: $e');
    }
  }

  /// Load full app data in the background
  /// This is separated from critical path to improve startup time
  Future<void> loadFullAppData(AppState appState) async {
    debugPrint('📦 Loading full app data...');
    final sw = Stopwatch()..start();

    try {
      await appState.loadFullData();
      sw.stop();
      debugPrint('✅ Full data loaded in ${sw.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ Error loading full app data: $e');
    }
  }
}
