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

  final appState = AppState();
  await appState.loadPreferences();
  await LocalNotificationService.init();

  // Start periodic health data checking (every 15 minutes)
  HealthCheckerService.instance.startPeriodicCheck(appState);

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
