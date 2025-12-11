import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/nav_wrapper.dart';
import 'screens/welcome_screen.dart';
import 'services/health_checker_service.dart';
import 'services/local_notification_service.dart';
import 'config/env.dart';
import 'utils/animation_config.dart';
import 'services/weekly_challenge_service.dart';
import 'services/koo_care_service.dart';
import 'services/daily_brief_service.dart';
import 'utils/haptic_service.dart'; // Added by instruction

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===== SUPABASE CONFIGURATION =====
  // TODO: Replace with your Supabase credentials
  // Get these from: https://app.supabase.com/project/_/settings/api
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  // ==================================

  // Initialize haptic feedback (safe - won't crash if fails)
  try {
    await HapticService.instance.initialize();
  } catch (e) {
    debugPrint('⚠️ HapticService init failed: $e');
  }

  final appState = AppState();
  await appState.loadPreferences();

  // Initialize notifications (may fail on Android 13+ without permission)
  try {
    await LocalNotificationService.init();
  } catch (e) {
    debugPrint('⚠️ LocalNotificationService init failed: $e');
  }

  // Initialize animation config (detects device capability)
  try {
    await AnimationConfig.instance.init();
  } catch (e) {
    debugPrint('⚠️ AnimationConfig init failed: $e');
  }

  // Start periodic health data checking (every 15 minutes)
  // Wrapped in try-catch - Health Connect may not be available
  try {
    HealthCheckerService.instance.startPeriodicCheck(appState);
  } catch (e) {
    debugPrint('⚠️ HealthCheckerService init failed: $e');
  }

  // Initialize Engagement Services (wrapped for safety)
  try {
    await WeeklyChallengeService.instance.initialize();
  } catch (e) {
    debugPrint('⚠️ WeeklyChallengeService init failed: $e');
  }

  try {
    await KooCareService.instance.initialize();
  } catch (e) {
    debugPrint('⚠️ KooCareService init failed: $e');
  }

  // Schedule Engagement Notifications (may fail without notification permission)
  try {
    await DailyBriefService.instance.scheduleDailyNotifications();
    await WeeklyChallengeService.instance.scheduleMondayNotification();
    await WeeklyChallengeService.instance.scheduleProgressNotification();
  } catch (e) {
    debugPrint('⚠️ Notification scheduling failed: $e');
  }

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const StreakooApp(),
    ),
  );
}

class StreakooApp extends StatelessWidget {
  const StreakooApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Streakoo',
      theme: AppTheme.light.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: AppTheme.dark.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: appState.themeMode, // User can now switch themes
      home: _getInitialScreen(appState),
    );
  }

  Widget _getInitialScreen(AppState appState) {
    // Check if user is authenticated (session exists)
    final supabase = Supabase.instance.client;
    final isAuthenticated = supabase.auth.currentSession != null;

    // If authenticated, go to main app (even if isFirstRun is true due to hot reload)
    if (isAuthenticated) {
      return const NavWrapper();
    }

    // Not authenticated - check if first run
    return appState.isFirstRun ? const WelcomeScreen() : const NavWrapper();
  }
}
