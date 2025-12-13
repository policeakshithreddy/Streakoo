import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';

enum HealthMetricType {
  steps,
  sleep,
  distance,
  calories,
  heartRate,
}

class HealthService {
  HealthService._() {
    // Configure Health Connect for Android
    if (Platform.isAndroid) {
      _health.configure();
    }
  }
  static final HealthService instance = HealthService._();

  final Health _health = Health();
  bool _isAuthorized = false;

  // Mock data flag - true if not on iOS/Android
  bool get _useMockData => !Platform.isIOS && !Platform.isAndroid;

  // Platform checks
  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS;

  /// Open Health Connect settings on Android
  Future<void> openHealthConnectSettings() async {
    if (Platform.isAndroid) {
      try {
        // Try to open Health Connect app directly via deep link
        final healthConnectUrl =
            Uri.parse('android-app://com.google.android.apps.healthdata');
        if (await canLaunchUrl(healthConnectUrl)) {
          await launchUrl(healthConnectUrl,
              mode: LaunchMode.externalApplication);
        } else {
          // Fallback: Open in Play Store to install/update Health Connect
          await _health.installHealthConnect();
        }
      } catch (e) {
        debugPrint('Error opening Health Connect settings: $e');
        // Fallback to Play Store
        await _health.installHealthConnect();
      }
    }
  }

  /// Check if health data connection is available
  Future<bool> checkHealthConnection() async {
    if (_useMockData) return true;
    try {
      final types = [HealthDataType.STEPS];
      final hasPermissions = await _health.hasPermissions(types);
      return hasPermissions ?? false;
    } catch (e) {
      debugPrint('Error checking health connection: $e');
      return false;
    }
  }

  /// Get current authorization status
  Future<bool> getAuthorizationStatus() async {
    if (_useMockData) return true;
    return _isAuthorized;
  }

  /// Check if we have access to health data
  Future<bool> hasHealthDataAccess() async {
    if (_useMockData) return true;

    final types = [
      HealthDataType.STEPS,
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.DISTANCE_DELTA,
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];

    try {
      final hasPermissions = await _health.hasPermissions(types);
      _isAuthorized = hasPermissions ?? false;
      return _isAuthorized;
    } catch (e) {
      debugPrint('Error checking health data access: $e');
      return false;
    }
  }

  /// Request permissions for health data
  Future<bool> requestPermissions() async {
    if (_useMockData) {
      _isAuthorized = true;
      return true;
    }

    final types = [
      HealthDataType.STEPS,
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.DISTANCE_DELTA,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.HEART_RATE,
    ];

    try {
      _isAuthorized = await _health.requestAuthorization(types);
      return _isAuthorized;
    } catch (e) {
      debugPrint('Error requesting health permissions: $e');
      return false;
    }
  }

  /// Get step count for a specific date
  Future<int> getStepCount(DateTime date) async {
    if (_useMockData) return 8542; // Mock steps

    if (!_isAuthorized) {
      await requestPermissions();
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      int totalSteps = 0;
      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          totalSteps += (data.value as NumericHealthValue).numericValue.toInt();
        }
      }

      return totalSteps;
    } catch (e) {
      debugPrint('Error fetching step count: $e');
      return 0;
    }
  }

  /// Get sleep hours for a specific date
  Future<double> getSleepHours(DateTime date) async {
    if (_useMockData) return 7.5; // Mock sleep hours

    if (!_isAuthorized) {
      await requestPermissions();
    }

    try {
      // For sleep, we need to look at the previous night's data
      // Sleep from date-1 evening to date morning
      final sleepStart = DateTime(date.year, date.month, date.day - 1, 18, 0);
      final sleepEnd = DateTime(date.year, date.month, date.day, 12, 0);

      // Try multiple sleep data types for better compatibility
      final sleepTypes = [
        HealthDataType.SLEEP_SESSION,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
      ];

      double totalMinutes = 0;
      Set<String> processedIntervals = {};

      for (final sleepType in sleepTypes) {
        try {
          final healthData = await _health.getHealthDataFromTypes(
            types: [sleepType],
            startTime: sleepStart,
            endTime: sleepEnd,
          );

          for (var data in healthData) {
            // Create a unique key for this time interval to avoid double counting
            final intervalKey =
                '${data.dateFrom.millisecondsSinceEpoch}-${data.dateTo.millisecondsSinceEpoch}';

            if (!processedIntervals.contains(intervalKey)) {
              if (data.value is NumericHealthValue) {
                totalMinutes += (data.value as NumericHealthValue).numericValue;
                processedIntervals.add(intervalKey);
              }
            }
          }
        } catch (e) {
          // Some sleep types might not be available on all devices
          debugPrint('Sleep type $sleepType not available: $e');
        }
      }

      final hours = totalMinutes / 60.0;
      debugPrint(
          'Sleep hours calculated: $hours from ${processedIntervals.length} intervals');
      return hours;
    } catch (e) {
      debugPrint('Error fetching sleep data: $e');
      return 0.0;
    }
  }

  /// Get distance in kilometers for a specific date
  Future<double> getDistance(DateTime date) async {
    if (_useMockData) return 5.2; // Mock distance km

    if (!_isAuthorized) {
      await requestPermissions();
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_DELTA],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      double totalMeters = 0;
      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          totalMeters += (data.value as NumericHealthValue).numericValue;
        }
      }

      return totalMeters / 1000.0; // Convert to kilometers
    } catch (e) {
      debugPrint('Error fetching distance: $e');
      return 0.0;
    }
  }

  /// Get calories burned for a specific date
  Future<double> getCalories(DateTime date) async {
    if (_useMockData) return 450.0; // Mock calories

    if (!_isAuthorized) {
      await requestPermissions();
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      double totalCalories = 0;
      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          totalCalories += (data.value as NumericHealthValue).numericValue;
        }
      }

      return totalCalories;
    } catch (e) {
      debugPrint('Error fetching calories: $e');
      return 0.0;
    }
  }

  /// Get current value for a health metric
  Future<double> getCurrentValue(HealthMetricType metric) async {
    final today = DateTime.now();

    switch (metric) {
      case HealthMetricType.steps:
        return (await getStepCount(today)).toDouble();
      case HealthMetricType.sleep:
        return await getSleepHours(today);
      case HealthMetricType.distance:
        return await getDistance(today);
      case HealthMetricType.calories:
        return await getCalories(today);
      case HealthMetricType.heartRate:
        // Heart rate needs different handling (average)
        return 0.0;
    }
  }

  /// Check if goal is met for a specific metric
  Future<bool> isGoalMet(HealthMetricType metric, double targetValue) async {
    final currentValue = await getCurrentValue(metric);
    return currentValue >= targetValue;
  }

  // ========== DATA VALIDATION METHODS ==========

  /// Validate sleep hours are within reasonable range (0-24 hours)
  bool isValidSleepHours(double? hours) {
    if (hours == null) return false;
    return hours >= 0 && hours <= 24;
  }

  /// Validate step count is within reasonable range (0-100,000)
  bool isValidStepCount(int? steps) {
    if (steps == null) return false;
    return steps >= 0 && steps <= 100000;
  }

  /// Validate distance is within reasonable range (0-100 km per day)
  bool isValidDistance(double? km) {
    if (km == null) return false;
    return km >= 0 && km <= 100;
  }

  /// Validate calories are within reasonable range (0-10,000 per day)
  bool isValidCalories(double? calories) {
    if (calories == null) return false;
    return calories >= 0 && calories <= 10000;
  }

  /// Validate heart rate is within reasonable range (30-220 bpm)
  bool isValidHeartRate(int? bpm) {
    if (bpm == null) return false;
    return bpm >= 30 && bpm <= 220;
  }

  // ========== QUICK ACCESS METHODS FOR AI COACH ==========

  /// Get today's step count
  Future<int?> getTodaySteps() async {
    try {
      final steps = await getStepCount(DateTime.now());
      return steps > 0 ? steps : null;
    } catch (e) {
      debugPrint('Error getting today\'s steps: $e');
      return null;
    }
  }

  /// Get today's distance in km
  Future<double?> getTodayDistance() async {
    try {
      final distance = await getDistance(DateTime.now());
      return distance > 0 ? distance : null;
    } catch (e) {
      debugPrint('Error getting today\'s distance: $e');
      return null;
    }
  }

  /// Get today's sleep hours
  Future<double?> getTodaySleep() async {
    try {
      final sleep = await getSleepHours(DateTime.now());
      return sleep > 0 ? sleep : null;
    } catch (e) {
      debugPrint('Error getting today\'s sleep: $e');
      return null;
    }
  }

  /// Get today's average heart rate
  Future<int?> getTodayHeartRate() async {
    if (_useMockData) return 72; // Mock heart rate

    if (!_isAuthorized) {
      await requestPermissions();
    }

    try {
      final startOfDay = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      if (healthData.isEmpty) return null;

      double totalHeartRate = 0;
      int count = 0;

      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          totalHeartRate += (data.value as NumericHealthValue).numericValue;
          count++;
        }
      }

      return count > 0 ? (totalHeartRate / count).round() : null;
    } catch (e) {
      debugPrint('Error fetching heart rate: $e');
      return null;
    }
  }
  // ========== HEALTH CONNECT HELPERS ==========

  /// Check Health Connect SDK status (Android only)
  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() async {
    if (!Platform.isAndroid) return null;
    return await _health.getHealthConnectSdkStatus();
  }

  /// Install Health Connect (Android only)
  Future<void> installHealthConnect() async {
    if (!Platform.isAndroid) return;
    await _health.installHealthConnect();
  }
}
