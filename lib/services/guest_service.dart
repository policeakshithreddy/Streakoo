import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service to manage guest user accounts
class GuestService {
  static final GuestService _instance = GuestService._internal();
  factory GuestService() => _instance;
  GuestService._internal();

  static GuestService get instance => _instance;

  // Storage keys
  static const String _isGuestKey = 'is_guest_user';
  static const String _guestIdKey = 'guest_id';
  static const String _guestStartedAtKey = 'guest_started_at';
  static const String _guestNameKey = 'guest_name';
  static const String _guestDataKey = 'guest_data_pending_sync';

  // Cache
  bool? _isGuest;
  String? _guestId;

  /// Check if current user is a guest
  Future<bool> isGuestUser() async {
    if (_isGuest != null) return _isGuest!;

    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool(_isGuestKey) ?? false;
    return _isGuest!;
  }

  /// Get the guest ID (for local identification)
  Future<String?> getGuestId() async {
    if (_guestId != null) return _guestId;

    final prefs = await SharedPreferences.getInstance();
    _guestId = prefs.getString(_guestIdKey);
    return _guestId;
  }

  /// Start a new guest session
  Future<String> startGuestSession({String name = 'Guest'}) async {
    final prefs = await SharedPreferences.getInstance();
    final guestId = const Uuid().v4();

    await prefs.setBool(_isGuestKey, true);
    await prefs.setString(_guestIdKey, guestId);
    await prefs.setString(_guestStartedAtKey, DateTime.now().toIso8601String());
    await prefs.setString(_guestNameKey, name);

    _isGuest = true;
    _guestId = guestId;

    debugPrint('👤 Guest session started: $guestId');
    return guestId;
  }

  /// Get guest session start date
  Future<DateTime?> getGuestStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final startedAt = prefs.getString(_guestStartedAtKey);
    if (startedAt == null) return null;
    return DateTime.tryParse(startedAt);
  }

  /// Get days since guest session started
  Future<int> getDaysSinceStart() async {
    final startDate = await getGuestStartDate();
    if (startDate == null) return 0;
    return DateTime.now().difference(startDate).inDays;
  }

  /// Get guest display name
  Future<String> getGuestName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guestNameKey) ?? 'Guest';
  }

  /// Mark data as pending sync (for when guest upgrades)
  Future<void> markDataForSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestDataKey, true);
  }

  /// Check if there's pending data to sync after registration
  Future<bool> hasPendingDataToSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestDataKey) ?? false;
  }

  /// Clear pending sync flag after successful sync
  Future<void> clearPendingSyncFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestDataKey);
  }

  /// Convert guest to registered user (preserves data)
  Future<void> upgradeToRegisteredUser() async {
    final prefs = await SharedPreferences.getInstance();

    // Keep the data, just mark as no longer guest
    await prefs.setBool(_isGuestKey, false);
    // Keep guest ID for potential data migration reference
    // Keep started_at for analytics

    // Mark that data needs to be synced to cloud
    await markDataForSync();

    _isGuest = false;

    debugPrint('✅ Guest upgraded to registered user');
  }

  /// Clear all guest data (for complete logout)
  Future<void> clearGuestSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_isGuestKey);
    await prefs.remove(_guestIdKey);
    await prefs.remove(_guestStartedAtKey);
    await prefs.remove(_guestNameKey);
    await prefs.remove(_guestDataKey);

    _isGuest = null;
    _guestId = null;

    debugPrint('🗑️ Guest session cleared');
  }

  /// Check if guest should be prompted to register
  /// Returns true after 7 days or 10 habits created
  Future<bool> shouldPromptRegistration(int habitCount) async {
    if (!await isGuestUser()) return false;

    final daysSinceStart = await getDaysSinceStart();

    // Prompt after 7 days or 10 habits
    return daysSinceStart >= 7 || habitCount >= 10;
  }

  /// Get guest status for UI display
  Future<GuestStatus> getGuestStatus() async {
    final isGuest = await isGuestUser();
    if (!isGuest) {
      return GuestStatus.registered();
    }

    final daysSinceStart = await getDaysSinceStart();
    final name = await getGuestName();

    return GuestStatus.guest(
      name: name,
      daysSinceStart: daysSinceStart,
    );
  }
}

/// Guest status for UI display
class GuestStatus {
  final bool isGuest;
  final String name;
  final int daysSinceStart;

  GuestStatus._({
    required this.isGuest,
    required this.name,
    required this.daysSinceStart,
  });

  factory GuestStatus.registered() => GuestStatus._(
        isGuest: false,
        name: '',
        daysSinceStart: 0,
      );

  factory GuestStatus.guest({
    required String name,
    required int daysSinceStart,
  }) =>
      GuestStatus._(
        isGuest: true,
        name: name,
        daysSinceStart: daysSinceStart,
      );
}
