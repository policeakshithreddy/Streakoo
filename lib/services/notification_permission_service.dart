import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPermissionStatus {
  notRequested,
  granted,
  denied,
  notDetermined,
}

class NotificationPermissionService {
  NotificationPermissionService._();
  static final NotificationPermissionService instance =
      NotificationPermissionService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _permissionKey = 'notification_permission_requested';

  /// Check if we've requested permissions before
  Future<bool> hasRequestedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionKey) ?? false;
  }

  /// Mark that we've requested permissions
  Future<void> setPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, true);
  }

  /// Get current permission status
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    try {
      // Check Android permission
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        if (granted == null) {
          return NotificationPermissionStatus.notDetermined;
        }
        return granted
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      }

      // For iOS, we can't easily check status without newer API,
      // so we'll check if we've requested before
      final hasRequested = await hasRequestedPermissions();
      if (!hasRequested) {
        return NotificationPermissionStatus.notRequested;
      }

      // Assume granted if we've requested (iOS doesn't provide easy status check)
      return NotificationPermissionStatus.granted;
    } catch (e) {
      print('Error checking notification permission status: $e');
      return NotificationPermissionStatus.notDetermined;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      await setPermissionRequested();

      // Request Android permissions
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      // Request iOS permissions
      final iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return false;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await getPermissionStatus();
    return status == NotificationPermissionStatus.granted;
  }

  /// Get user-friendly status text
  String getStatusText(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return 'Enabled';
      case NotificationPermissionStatus.denied:
        return 'Denied';
      case NotificationPermissionStatus.notRequested:
        return 'Not Requested';
      case NotificationPermissionStatus.notDetermined:
        return 'Not Determined';
    }
  }
}
