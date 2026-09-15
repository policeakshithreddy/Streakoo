import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../firebase_options.dart';

/// Central service for Firebase initialization and management
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;
  FirebaseAnalytics? _analytics;
  FirebaseRemoteConfig? _remoteConfig;

  bool get isInitialized => _initialized;
  FirebaseAnalytics? get analytics => _analytics;
  FirebaseRemoteConfig? get remoteConfig => _remoteConfig;

  /// Initialize all Firebase services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('🔥 Initializing Firebase...');

      // Initialize Firebase Core with platform-specific options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase Core initialized');

      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;
      await _analytics?.setAnalyticsCollectionEnabled(true);
      debugPrint('✅ Firebase Analytics initialized');

      // Initialize Crashlytics
      await _initializeCrashlytics();
      debugPrint('✅ Firebase Crashlytics initialized');

      // Initialize Remote Config
      await _initializeRemoteConfig();
      debugPrint('✅ Firebase Remote Config initialized');

      _initialized = true;
      debugPrint('🔥 Firebase fully initialized!');
    } catch (e, stackTrace) {
      debugPrint('❌ Firebase initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - app should work without Firebase
    }
  }

  Future<void> _initializeCrashlytics() async {
    // Pass all uncaught errors to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Enable collection in release mode only
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  Future<void> _initializeRemoteConfig() async {
    _remoteConfig = FirebaseRemoteConfig.instance;

    // Set defaults
    await _remoteConfig?.setDefaults({
      'morning_quote_enabled': true,
      'streak_milestone_notifications': true,
      'weekly_progress_notifications': true,
      'smart_timing_enabled': true,
      'wrapped_enabled': false,
      'wrapped_start_date': '2024-12-01',
      'daily_motivational_quote':
          'Small daily improvements lead to big results! 💪',
    });

    // Fetch and activate with 1 hour cache
    await _remoteConfig?.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    try {
      await _remoteConfig?.fetchAndActivate();
      debugPrint('📡 Remote Config fetched and activated');
    } catch (e) {
      debugPrint('⚠️ Remote Config fetch failed (using defaults): $e');
    }
  }

  // ============ ANALYTICS EVENTS ============

  /// Log when user completes a habit
  Future<void> logHabitCompleted({
    required String habitId,
    required String habitName,
    required String category,
    required int streak,
    bool isHealthTracked = false,
  }) async {
    await _analytics?.logEvent(
      name: 'habit_completed',
      parameters: {
        'habit_id': habitId,
        'habit_name': habitName,
        'category': category,
        'streak': streak,
        'is_health_tracked': isHealthTracked.toString(),
      },
    );
  }

  /// Log when user creates a new habit
  Future<void> logHabitCreated({
    required String habitName,
    required String category,
    bool hasReminder = false,
    bool isHealthTracked = false,
    bool isFocusTask = false,
  }) async {
    await _analytics?.logEvent(
      name: 'habit_created',
      parameters: {
        'habit_name': habitName,
        'category': category,
        'has_reminder': hasReminder.toString(),
        'is_health_tracked': isHealthTracked.toString(),
        'is_focus_task': isFocusTask.toString(),
      },
    );
  }

  /// Log streak milestone achieved
  Future<void> logStreakMilestone({
    required String habitName,
    required int streakDays,
  }) async {
    await _analytics?.logEvent(
      name: 'streak_milestone',
      parameters: {
        'habit_name': habitName,
        'streak_days': streakDays,
      },
    );
  }

  /// Log when user opens a specific screen
  Future<void> logScreenView(String screenName) async {
    await _analytics?.logScreenView(screenName: screenName);
  }

  /// Log user sign in
  Future<void> logLogin(String method) async {
    await _analytics?.logLogin(loginMethod: method);
  }

  /// Log onboarding completion
  Future<void> logOnboardingComplete() async {
    await _analytics?.logEvent(name: 'onboarding_complete');
  }

  /// Log Year in Review opened
  Future<void> logYearInReviewOpened(int year) async {
    await _analytics?.logEvent(
      name: 'year_in_review_opened',
      parameters: {'year': year},
    );
  }

  /// Log feature usage
  Future<void> logFeatureUsed(String featureName) async {
    await _analytics?.logEvent(
      name: 'feature_used',
      parameters: {'feature': featureName},
    );
  }

  // ============ REMOTE CONFIG VALUES ============

  bool get morningQuoteEnabled =>
      _remoteConfig?.getBool('morning_quote_enabled') ?? true;

  bool get streakMilestoneNotificationsEnabled =>
      _remoteConfig?.getBool('streak_milestone_notifications') ?? true;

  bool get weeklyProgressNotificationsEnabled =>
      _remoteConfig?.getBool('weekly_progress_notifications') ?? true;

  bool get smartTimingEnabled =>
      _remoteConfig?.getBool('smart_timing_enabled') ?? true;

  bool get wrappedEnabled => _remoteConfig?.getBool('wrapped_enabled') ?? false;

  String get wrappedStartDate =>
      _remoteConfig?.getString('wrapped_start_date') ?? '2024-12-01';

  String get dailyMotivationalQuote =>
      _remoteConfig?.getString('daily_motivational_quote') ??
      'Small daily improvements lead to big results! 💪';

  // ============ USER PROPERTIES ============

  /// Set user properties for segmentation
  Future<void> setUserProperties({
    int? totalHabits,
    int? longestStreak,
    String? subscriptionStatus,
  }) async {
    if (totalHabits != null) {
      await _analytics?.setUserProperty(
        name: 'total_habits',
        value: totalHabits.toString(),
      );
    }
    if (longestStreak != null) {
      await _analytics?.setUserProperty(
        name: 'longest_streak',
        value: longestStreak.toString(),
      );
    }
    if (subscriptionStatus != null) {
      await _analytics?.setUserProperty(
        name: 'subscription_status',
        value: subscriptionStatus,
      );
    }
  }

  /// Set user ID for cross-device tracking
  Future<void> setUserId(String? userId) async {
    await _analytics?.setUserId(id: userId);
    if (userId != null) {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }

  // ============ CRASHLYTICS ============

  /// Log error to Crashlytics
  Future<void> logError(dynamic error, StackTrace? stackTrace,
      {String? reason}) async {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
    );
  }

  /// Add custom log message to Crashlytics
  void logMessage(String message) {
    FirebaseCrashlytics.instance.log(message);
  }

  /// Set custom key-value for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    await FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
  }
}
