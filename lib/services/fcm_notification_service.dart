import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background FCM message: ${message.messageId}');
  // Handle background message if needed
}

/// Service for Firebase Cloud Messaging (Push Notifications)
class FCMNotificationService {
  FCMNotificationService._();
  static final FCMNotificationService instance = FCMNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  bool get isInitialized => _initialized;
  String? get fcmToken => _fcmToken;

  static const String _tokenKey = 'fcm_token';

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('📱 Initializing FCM...');

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: true,
        carPlay: false,
        criticalAlert: false,
      );

      debugPrint('📱 FCM permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        await _getAndSaveToken();

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_handleTokenRefresh);

        // Listen for Auth Changes to sync token when user logs in
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          if (data.session != null && _fcmToken != null) {
            debugPrint('👤 User logged in, syncing FCM token...');
            _syncTokenToSupabase(_fcmToken!);
          }
        });

        // Set up foreground message handler
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification tap when app is in background/terminated
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check if app was opened from a notification
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        // Subscribe to default topics
        await subscribeToTopic('all_users');
        await subscribeToTopic('habit_reminders');

        _initialized = true;
        debugPrint(
            '✅ FCM initialized with token: ${_fcmToken?.substring(0, 20)}...');
      } else {
        debugPrint('⚠️ FCM permission denied');
      }
    } catch (e) {
      debugPrint('❌ FCM initialization failed: $e');
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _fcmToken!);
        debugPrint('💾 FCM token saved locally');

        // Save to Supabase for server-side notifications
        await _syncTokenToSupabase(_fcmToken!);
      }
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  /// Manually sync token (for debugging)
  Future<void> forceSyncToken() async {
    if (_fcmToken != null) {
      await _syncTokenToSupabase(_fcmToken!);
    } else {
      // Try to fetch again
      await _getAndSaveToken();
    }
  }

  /// Sync FCM token to Supabase for server-side push
  Future<void> _syncTokenToSupabase(String token) async {
    try {
      String deviceType = 'unknown';
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          deviceType = 'android';
        } else if (Platform.isIOS) {
          deviceType = 'ios';
        } else if (Platform.isMacOS) {
          deviceType = 'macos';
        }
      }

      await SupabaseService().saveFcmToken(
        token: token,
        deviceType: deviceType,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to sync FCM token to Supabase: $e');
      rethrow; // Rethrow to let UI know it failed
    }
  }

  void _handleTokenRefresh(String newToken) async {
    debugPrint('🔄 FCM token refreshed');
    _fcmToken = newToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);

    // Sync refreshed token to Supabase
    await _syncTokenToSupabase(newToken);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground FCM message: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;

    // Show local notification when app is in foreground
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_channel',
            'Push Notifications',
            channelDescription: 'Notifications from server',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');

    // Handle navigation based on notification data
    final data = message.data;

    if (data.containsKey('habit_id')) {
      // Navigate to specific habit
      debugPrint('Navigate to habit: ${data['habit_id']}');
      // TODO: Use navigation service to open habit detail
    } else if (data.containsKey('screen')) {
      // Navigate to specific screen
      debugPrint('Navigate to screen: ${data['screen']}');
      // TODO: Use navigation service
    }
  }

  // ============ TOPIC SUBSCRIPTIONS ============

  /// Subscribe to a topic for broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  // ============ NOTIFICATION SETTINGS ============

  /// Enable/disable streak alert notifications
  Future<void> setStreakAlertsEnabled(bool enabled) async {
    if (enabled) {
      await subscribeToTopic('streak_alerts');
    } else {
      await unsubscribeFromTopic('streak_alerts');
    }
  }

  /// Enable/disable daily reminder notifications
  Future<void> setDailyRemindersEnabled(bool enabled) async {
    if (enabled) {
      await subscribeToTopic('daily_reminders');
    } else {
      await unsubscribeFromTopic('daily_reminders');
    }
  }

  /// Enable/disable motivational notifications
  Future<void> setMotivationalEnabled(bool enabled) async {
    if (enabled) {
      await subscribeToTopic('motivational');
    } else {
      await unsubscribeFromTopic('motivational');
    }
  }

  // ============ TOKEN MANAGEMENT ============

  /// Get stored FCM token
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      // Remove from Supabase first
      if (_fcmToken != null) {
        await SupabaseService().removeFcmToken(_fcmToken!);
      }

      await _messaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      _fcmToken = null;
      debugPrint('🗑️ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Failed to delete FCM token: $e');
    }
  }

  /// Manually sync token to Supabase (call after login)
  Future<void> syncTokenAfterLogin() async {
    if (_fcmToken != null) {
      await _syncTokenToSupabase(_fcmToken!);
    } else {
      await _getAndSaveToken();
    }
  }
}
