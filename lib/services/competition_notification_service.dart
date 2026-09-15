import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accountability_service.dart';
import '../state/app_state.dart';

/// Service for competition notifications when friends pass your streak
class CompetitionNotificationService {
  static final CompetitionNotificationService instance =
      CompetitionNotificationService._();
  CompetitionNotificationService._();

  static const _prefsKeyLastCheck = 'competition_last_check';
  static const _prefsKeyFriendStreaks = 'friend_streaks_cache';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      const macos = DarwinInitializationSettings();
      const settings =
          InitializationSettings(android: android, iOS: ios, macOS: macos);
      await _notifications.initialize(settings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ CompetitionNotificationService init failed: $e');
    }
  }

  /// Check if any friend has passed your streak and notify
  Future<void> checkAndNotify(AppState appState) async {
    try {
      if (!_isInitialized) await initialize();

      final partners = AccountabilityService.instance.activePartners;
      if (partners.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();

      // Get your max streak
      final yourMaxStreak = appState.habits.isEmpty
          ? 0
          : appState.habits
              .map((h) => h.streak)
              .reduce((a, b) => a > b ? a : b);

      // Load cached friend streaks
      final cachedStreaksJson = prefs.getString(_prefsKeyFriendStreaks) ?? '{}';
      final Map<String, int> previousStreaks = {};
      try {
        final decoded = cachedStreaksJson.split(';');
        for (final entry in decoded) {
          if (entry.contains(':')) {
            final parts = entry.split(':');
            previousStreaks[parts[0]] = int.tryParse(parts[1]) ?? 0;
          }
        }
      } catch (_) {}

      // Check each friend
      for (final partner in partners) {
        final friendStreak = partner.partnerCurrentStreak;
        final previousStreak = previousStreaks[partner.partnerUserId] ?? 0;

        // Friend just passed your streak!
        if (friendStreak > yourMaxStreak && previousStreak <= yourMaxStreak) {
          await _sendPassedNotification(
            friendName: partner.partnerName,
            friendStreak: friendStreak,
            yourStreak: yourMaxStreak,
          );
        }

        // Update cache
        previousStreaks[partner.partnerUserId] = friendStreak;
      }

      // Save updated cache
      final cacheString =
          previousStreaks.entries.map((e) => '${e.key}:${e.value}').join(';');
      await prefs.setString(_prefsKeyFriendStreaks, cacheString);
      await prefs.setString(
          _prefsKeyLastCheck, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('⚠️ CompetitionNotificationService checkAndNotify failed: $e');
    }
  }

  /// Send notification when friend passes your streak
  Future<void> _sendPassedNotification({
    required String friendName,
    required int friendStreak,
    required int yourStreak,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'competition_channel',
      'Friend Competition',
      channelDescription: 'Notifications when friends pass your streak',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
        android: androidDetails, iOS: iosDetails, macOS: iosDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '🔥 $friendName just passed you!',
      '$friendName is on a $friendStreak-day streak! You\'re at $yourStreak. Time to catch up!',
      details,
    );
  }

  /// Send encouraging notification when you pass a friend
  Future<void> notifyYouPassedFriend({
    required String friendName,
    required int yourStreak,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'competition_channel',
      'Friend Competition',
      channelDescription: 'Notifications when you pass friends',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
        android: androidDetails, iOS: iosDetails, macOS: iosDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000 + 1,
      '🏆 You passed $friendName!',
      'Your $yourStreak-day streak puts you ahead! Keep going!',
      details,
    );
  }

  /// Clear cached data
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyLastCheck);
    await prefs.remove(_prefsKeyFriendStreaks);
  }
}
