import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/user_level.dart';
import 'supabase_service.dart';
import 'guest_service.dart';

/// Sync operation types
enum SyncOperation {
  upsertHabit,
  deleteHabit,
  upsertUserLevel,
  syncHealthChallenge,
}

/// A queued sync operation for offline support
class PendingSyncItem {
  final String id;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  PendingSyncItem({
    required this.id,
    required this.operation,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'operation': operation.name,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingSyncItem.fromJson(Map<String, dynamic> json) {
    return PendingSyncItem(
      id: json['id'],
      operation: SyncOperation.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => SyncOperation.upsertHabit,
      ),
      data: json['data'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Service to handle automatic sync and offline queue
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static SyncService get instance => _instance;

  final SupabaseService _supabase = SupabaseService();
  final GuestService _guest = GuestService();

  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _pendingQueueKey = 'pending_sync_queue';
  static const String _syncEnabledKey = 'auto_sync_enabled';

  bool _isSyncing = false;

  /// Initialize the sync service
  Future<void> initialize() async {
    debugPrint('🔄 Sync service initialized');

    // Try to process any pending items on startup
    await _processPendingQueue();
  }

  /// Check if auto-sync is enabled
  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? true;
  }

  /// Set auto-sync enabled/disabled
  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, enabled);
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Check if sync is needed (e.g., hasn't synced recently)
  Future<bool> needsSync() async {
    // Guest users don't sync to cloud
    if (await _guest.isGuestUser()) return false;

    // Check if authenticated
    if (!_supabase.isAuthenticated) return false;

    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;

    // Sync if last sync was more than 1 hour ago
    final hoursSinceSync = DateTime.now().difference(lastSync).inHours;
    return hoursSinceSync >= 1;
  }

  /// Perform a full sync on app open
  Future<SyncResult> syncOnAppOpen(
      List<Habit> localHabits, UserLevel localLevel) async {
    // Skip for guests
    if (await _guest.isGuestUser()) {
      return SyncResult(success: true, message: 'Guest mode - no sync needed');
    }

    // Skip if not authenticated
    if (!_supabase.isAuthenticated) {
      return SyncResult(success: false, message: 'Not authenticated');
    }

    // Skip if sync not needed
    if (!(await needsSync())) {
      return SyncResult(success: true, message: 'Already synced recently');
    }

    // Skip if already syncing
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    _isSyncing = true;
    debugPrint('🔄 Starting app open sync...');

    try {
      // First, process any pending offline operations
      await _processPendingQueue();

      // Sync habits to cloud
      await _supabase.syncHabitsToCloud(localHabits);

      // Sync user level
      await _supabase.syncUserLevelToCloud(localLevel);

      await _updateLastSyncTime();

      debugPrint('✅ App open sync completed');
      return SyncResult(success: true, message: 'Sync completed');
    } catch (e) {
      debugPrint('❌ App open sync failed: $e');
      return SyncResult(success: false, message: 'Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Add an operation to the offline queue
  Future<void> addToQueue(
      SyncOperation operation, Map<String, dynamic> data) async {
    // Guest users store everything locally
    if (await _guest.isGuestUser()) {
      await _guest.markDataForSync();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final queue = await _getPendingQueue();

    final item = PendingSyncItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
    );

    queue.add(item);
    await prefs.setString(
        _pendingQueueKey, jsonEncode(queue.map((e) => e.toJson()).toList()));

    debugPrint('📥 Added to offline queue: ${operation.name}');

    // Try to process immediately
    _processPendingQueue();
  }

  /// Get pending sync queue
  Future<List<PendingSyncItem>> _getPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_pendingQueueKey);
    if (queueJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(queueJson);
      return decoded.map((e) => PendingSyncItem.fromJson(e)).toList();
    } catch (e) {
      debugPrint('⚠️ Failed to parse pending queue: $e');
      return [];
    }
  }

  /// Clear the pending queue
  Future<void> _clearPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingQueueKey);
  }

  /// Get count of pending operations
  Future<int> getPendingCount() async {
    final queue = await _getPendingQueue();
    return queue.length;
  }

  /// Process pending sync operations
  Future<void> _processPendingQueue() async {
    if (!_supabase.isAuthenticated) return;
    if (_isSyncing) return;

    final queue = await _getPendingQueue();
    if (queue.isEmpty) return;

    debugPrint('🔄 Processing ${queue.length} pending sync operations...');

    final failedItems = <PendingSyncItem>[];

    for (final item in queue) {
      try {
        await _processQueueItem(item);
        debugPrint('✅ Processed: ${item.operation.name}');
      } catch (e) {
        debugPrint('❌ Failed to process ${item.operation.name}: $e');
        // Network errors or other failures - keep for retry
        failedItems.add(item);
      }
    }

    // Keep failed items for retry
    if (failedItems.isEmpty) {
      await _clearPendingQueue();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _pendingQueueKey,
        jsonEncode(failedItems.map((e) => e.toJson()).toList()),
      );
    }
  }

  /// Process a single queue item
  Future<void> _processQueueItem(PendingSyncItem item) async {
    switch (item.operation) {
      case SyncOperation.upsertHabit:
        final habit = Habit.fromJson(item.data);
        await _supabase.upsertHabit(habit);
        break;

      case SyncOperation.deleteHabit:
        await _supabase.deleteHabit(item.data['habitId']);
        break;

      case SyncOperation.upsertUserLevel:
        final level = UserLevel.fromJson(item.data['level']);
        final totalXP = item.data['totalXP'] ?? 0;
        await _supabase.upsertUserLevel(level, totalXP);
        break;

      case SyncOperation.syncHealthChallenge:
        await _supabase.syncHealthChallenge(item.data);
        break;
    }
  }

  /// Handle guest upgrade - sync all local data to cloud
  Future<SyncResult> syncGuestDataOnUpgrade(
      List<Habit> habits, UserLevel level) async {
    if (!_supabase.isAuthenticated) {
      return SyncResult(success: false, message: 'Not authenticated');
    }

    debugPrint('🔄 Syncing guest data after upgrade...');

    try {
      // Sync all habits
      await _supabase.syncHabitsToCloud(habits);

      // Sync user level
      await _supabase.syncUserLevelToCloud(level);

      // Clear the pending data flag
      await _guest.clearPendingSyncFlag();

      await _updateLastSyncTime();

      debugPrint('✅ Guest data synced successfully');
      return SyncResult(success: true, message: 'Data synced to cloud');
    } catch (e) {
      debugPrint('❌ Guest data sync failed: $e');
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  /// Manually trigger a sync retry (call this when app comes to foreground)
  Future<void> retryPendingSync() async {
    await _processPendingQueue();
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;

  SyncResult({required this.success, required this.message});
}
