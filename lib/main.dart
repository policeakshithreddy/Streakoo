import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/nav_wrapper.dart';
import 'screens/welcome_screen.dart';
import 'config/env.dart';
import 'services/startup_service.dart';
import 'services/firebase_service.dart';
import 'services/fcm_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 App startup initiated...');
  final totalStopwatch = Stopwatch()..start();

  // ===== CRITICAL PATH - Must complete before UI renders =====
  final criticalStopwatch = Stopwatch()..start();

  // 1. Initialize Supabase (required for auth state) - ~50ms
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // 2. Create AppState and load essential data + habits - ~100ms
  final appState = AppState();
  await appState.loadEssentialPreferences();

  // 3. Load habits immediately so they show when app opens
  // This is important for user experience - habits should be visible instantly
  // MOVED TO BACKGROUND for faster startup performance
  // await appState.loadFullData();

  criticalStopwatch.stop();
  debugPrint(
      '✅ Critical path complete in ${criticalStopwatch.elapsedMilliseconds}ms');
  // ============================================================

  // Start the app UI with habits already loaded
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const StreakooApp(),
    ),
  );

  // ===== BACKGROUND INITIALIZATION - Happens after UI is visible =====
  // Services and non-essential tasks run after UI renders
  Future.microtask(() async {
    debugPrint('🔄 Starting background initialization...');
    final bgStopwatch = Stopwatch()..start();

    // Phase 0: Load heavy app data (habits, history, etc)
    // This allows the UI to render the skeleton/loading state first
    await StartupService.instance.loadFullAppData(appState);

    // Phase 1: Initialize Firebase (needed for analytics)
    try {
      await FirebaseService.instance.initialize();
      await FCMNotificationService.instance.initialize();
    } catch (e) {
      debugPrint('⚠️ Firebase/FCM init failed (non-blocking): $e');
    }

    // Phase 2: Initialize background services
    await StartupService.instance.initializeBackgroundServices(appState);

    bgStopwatch.stop();
    totalStopwatch.stop();
    debugPrint(
        '✅ Background init complete in ${bgStopwatch.elapsedMilliseconds}ms');
    debugPrint(
        '🎉 App fully initialized in ${totalStopwatch.elapsedMilliseconds}ms');
  });
  // ==============================================================
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
      scrollBehavior: const CupertinoScrollBehavior(),
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
