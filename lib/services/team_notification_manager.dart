import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart';

/// Manages real-time notifications for team activities
class TeamNotificationManager {
  TeamNotificationManager._();
  static final TeamNotificationManager instance = TeamNotificationManager._();

  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _subscription;

  // Cache for team info to avoid spamming DB
  final Map<String, String> _teamNameCache = {};
  final Map<String, String> _habitNameCache = {};
  final Map<String, String> _userNameCache = {};

  bool _isInitialized = false;

  /// Initialize real-time listener
  Future<void> initialize() async {
    if (_isInitialized) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    debugPrint('🔔 Initializing Team Notification Listener...');

    // Subscribe to INSERT events on team_habit_progress
    _subscription = _supabase
        .channel('public:team_habit_progress')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'team_habit_progress',
          callback: (payload) => _handleProgressInsert(payload, userId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'team_reactions',
          callback: (payload) => _handleReactionInsert(payload, userId),
        )
        .subscribe();

    _isInitialized = true;
  }

  // Notification Buffer
  final List<Map<String, String>> _pendingNotifications = [];
  Timer? _bufferTimer;
  static const Duration _bufferDuration = Duration(seconds: 2);

  /// Handle a new progress entry
  Future<void> _handleProgressInsert(
      PostgresChangePayload payload, String currentUserId) async {
    try {
      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) return;

      final recordUserId = newRecord['user_id'] as String;
      final teamHabitId = newRecord['team_habit_id'] as String;

      // 1. Ignore own actions
      if (recordUserId == currentUserId) return;

      // 2. Fetch details (with minimal caching)
      final habitInfo = await _getHabitInfo(teamHabitId);
      if (habitInfo == null) {
        return; // Might be a habit from a team we're not in ?
      }

      final teamId = habitInfo['team_id'] as String;
      final habitName = habitInfo['name'] as String;

      // 3. Check if notifications are enabled for this team AND specifically for habits
      if (!await _isNotificationEnabled(teamId, 'habits')) return;

      final userName = await _getUserName(recordUserId);
      final teamName = await _getTeamName(teamId);

      // 4. Add to Buffer
      _addToBuffer(
        teamId: teamId,
        teamName: teamName,
        userName: userName,
        habitName: habitName,
      );
    } catch (e) {
      debugPrint('❌ Error handling team notification: $e');
    }
  }

  /// Handle a new reaction entry
  Future<void> _handleReactionInsert(
      PostgresChangePayload payload, String currentUserId) async {
    try {
      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) return;

      final fromUserId = newRecord['user_id'] as String;
      final teamId = newRecord['team_id'] as String;
      final emoji = newRecord['emoji'] as String; // Assuming 'emoji' column?

      // 1. Ignore own reactions
      if (fromUserId == currentUserId) return;

      // 2. Check if notifications are enabled for this team AND specifically for reactions
      if (!await _isNotificationEnabled(teamId, 'reactions')) return;

      final userName = await _getUserName(fromUserId);
      final teamName = await _getTeamName(teamId);

      // Show immediate notification for reaction (no buffering needed usually, or reuse buffer?)
      // Reactions are personal. Let's show immediately.

      await LocalNotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'New Reaction in $teamName',
        body: '$userName reacted $emoji',
        payload: 'team_dashboard',
      );
    } catch (e) {
      debugPrint('❌ Error handling reaction notification: $e');
    }
  }

  void _addToBuffer({
    required String teamId,
    required String teamName,
    required String userName,
    required String habitName,
  }) {
    _pendingNotifications.add({
      'teamName': teamName,
      'userName': userName,
      'habitName': habitName,
    });

    if (_bufferTimer?.isActive ?? false) return;

    _bufferTimer = Timer(_bufferDuration, _flushBuffer);
  }

  Future<void> _flushBuffer() async {
    if (_pendingNotifications.isEmpty) return;

    // Separate buffer by team or just show summary?
    // For simplicity, let's process the batch.

    // De-duplicate if needed? multiple habits by same user?

    try {
      if (_pendingNotifications.length == 1) {
        // Single Nofication
        final item = _pendingNotifications.first;
        await LocalNotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: 'Team Update: ${item['teamName']} 🔥',
          body: '${item['userName']} just completed ${item['habitName']}!',
          payload: 'team_dashboard',
        );
      } else {
        // Batch Notification
        // "Alex and 2 others completed tasks!"
        // Group by user count
        final userCount =
            _pendingNotifications.map((e) => e['userName']).toSet();
        final firstUser = userCount.first;
        final count = userCount.length;

        // If 1 user completed 3 tasks: "Alex completed 3 tasks!"
        // If 3 users completed tasks: "Alex and 2 others completed tasks!"

        String body;
        if (count == 1) {
          body = '$firstUser completed ${_pendingNotifications.length} tasks!';
        } else {
          body =
              '$firstUser and ${count - 1} other${count > 2 ? 's' : ''} completed tasks!';
        }

        await LocalNotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: 'Team Updates 🔥',
          body: body,
          payload: 'team_dashboard',
        );
      }
    } catch (e) {
      debugPrint('Error flushing notifications: $e');
    } finally {
      _pendingNotifications.clear();
      _bufferTimer = null;
    }
  }

  /// Check if notifications are enabled for a specific team and type
  Future<bool> _isNotificationEnabled(String teamId, String type) async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true if not set.
    // Key format: 'team_notifications_{teamId}_{type}'
    // For general 'team_notifications_{teamId}' backward compatibility?
    // The UI now sets specific keys. If specific key is null, fallback to true.

    return prefs.getBool('team_notifications_${teamId}_$type') ?? true;
  }

  Future<Map<String, dynamic>?> _getHabitInfo(String habitId) async {
    // Check cache first (Habit names don't change often)
    if (_habitNameCache.containsKey(habitId)) {
      // We need team_id too, so maybe cache the whole object or just refetch for simplicity on MVP
    }

    try {
      final data = await _supabase
          .from('team_habits')
          .select('name, team_id')
          .eq('id', habitId)
          .maybeSingle();

      return data;
    } catch (e) {
      return null;
    }
  }

  Future<String> _getUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) return _userNameCache[userId]!;

    try {
      final data = await _supabase
          .from('user_profiles')
          .select('username')
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        final name = (data['username'] ?? 'Teammate') as String;
        _userNameCache[userId] = name;
        return name;
      }
    } catch (e) {
      // ignore
    }
    return 'Teammate';
  }

  Future<String> _getTeamName(String teamId) async {
    if (_teamNameCache.containsKey(teamId)) return _teamNameCache[teamId]!;

    try {
      final data = await _supabase
          .from('teams')
          .select('name')
          .eq('id', teamId)
          .maybeSingle();

      if (data != null) {
        final name = data['name'] as String;
        _teamNameCache[teamId] = name;
        return name;
      }
    } catch (e) {
      // ignore
    }
    return 'Team';
  }

  void dispose() {
    _subscription?.unsubscribe();
    _bufferTimer?.cancel();
    _isInitialized = false;
  }
}
