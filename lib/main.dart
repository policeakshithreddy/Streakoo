import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:streakoo/models/app_settings.dart';
import 'package:streakoo/models/habit.dart';
import 'package:streakoo/providers/app_provider.dart';
import 'package:streakoo/providers/habit_provider.dart';
import 'package:streakoo/screens/wrapper.dart';
import 'package:streakoo/utils/constants.dart';

Future<void> main() async {
  // 1. Initialize Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Attach a global error handler to capture uncaught Flutter errors and
  // Zone errors. This helps diagnose crashes that produce a black screen.
  FlutterError.onError = (details) {
    // Print to console; in production consider sending to a logging service.
    FlutterError.dumpErrorToConsole(details);
  };

  // 2. Initialize Hive
  await Hive.initFlutter();

  // 3. Register Hive Adapters
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(AppSettingsAdapter());

  // 4. Open Hive Boxes
  await Hive.openBox<Habit>(kHabitBoxName);
  await Hive.openBox<AppSettings>(kAppSettingsBoxName);

  // 5. Run the App inside a guarded zone to catch uncaught async errors.
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    // Log the error. In production, forward to crash reporting.
    // For now, print so developers running `flutter run` can see the trace.
    // ignore: avoid_print
    print('Uncaught async error: $error');
    // ignore: avoid_print
    print(stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider to provide both AppProvider and HabitProvider
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppProvider()),
        ChangeNotifierProvider(create: (context) => HabitProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, app, _) {
          return MaterialApp(
            title: 'Streakoo',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: AppColors.darkTheme,
            themeMode: app.themeMode,
            home: const Wrapper(),
          );
        },
      ),
    );
  }
}
