import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit.dart';
import '../models/user_level.dart';
import '../config/env.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Check if running on desktop (macOS, Windows, Linux)
  bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  // ============ AUTHENTICATION ============

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AuthResponse> signInWithGoogleNative() async {
    // For desktop (macOS/Windows/Linux), use Supabase OAuth browser flow
    if (isDesktop) {
      return await _signInWithGoogleDesktop();
    }

    // For mobile (iOS/Android), use native Google Sign-In
    return await _signInWithGoogleMobile();
  }

  /// Desktop Google Sign-In using Supabase OAuth (opens browser)
  Future<AuthResponse> _signInWithGoogleDesktop() async {
    // For desktop, we'll open the browser and listen for auth state change
    // Supabase will redirect to the project's configured site URL
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!response) {
      throw 'Failed to initiate Google Sign-In';
    }

    // Wait for the auth state to change (user completes sign-in in browser)
    final completer = Completer<AuthResponse>();
    bool completed = false;

    late final StreamSubscription<AuthState> subscription;
    subscription = _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && !completed) {
        completed = true;
        subscription.cancel();
        completer.complete(
            AuthResponse(session: data.session, user: data.session?.user));
      }
    });

    // Timeout after 3 minutes
    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        subscription.cancel();
        throw 'Sign-in timed out. Please try again.';
      },
    );
  }

  /// Mobile Google Sign-In using native SDK
  Future<AuthResponse> _signInWithGoogleMobile() async {
    const webClientId = Env.googleWebClientId;
    const iosClientId = Env.googleIosClientId;

    debugPrint('🔐 Starting Google Sign-In...');
    debugPrint(
        '   iOS Client ID: ${iosClientId.isNotEmpty ? "configured" : "MISSING"}');
    debugPrint(
        '   Web Client ID: ${webClientId.isNotEmpty ? "configured" : "MISSING"}');

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    try {
      final googleUser = await googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) {
        debugPrint('⚠️ Google Sign-In cancelled by user');
        throw 'Sign-in cancelled';
      }

      debugPrint('✅ Google user obtained: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        debugPrint('❌ No Access Token found');
        throw 'Google Sign-In failed: No access token received. Please check your Google Cloud Console configuration.';
      }
      if (googleAuth.idToken == null) {
        debugPrint('❌ No ID Token found');
        throw 'Google Sign-In failed: No ID token received. Please ensure serverClientId is correctly configured.';
      }

      debugPrint('✅ Tokens obtained, signing into Supabase...');

      return await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );
    } on Exception catch (e) {
      final errorStr = e.toString().toLowerCase();
      debugPrint('❌ Google Sign-In error: $e');

      if (errorStr.contains('network') || errorStr.contains('connection')) {
        throw 'Network error. Please check your internet connection and try again.';
      } else if (errorStr.contains('canceled') ||
          errorStr.contains('cancelled')) {
        throw 'Sign-in cancelled';
      } else if (errorStr.contains('popup_closed') ||
          errorStr.contains('popup closed')) {
        throw 'Sign-in cancelled';
      } else if (errorStr.contains('invalid_client') ||
          errorStr.contains('client_id')) {
        throw 'Google Sign-In configuration error. Please verify your OAuth client IDs.';
      } else if (errorStr.contains('sign_in_required')) {
        throw 'Please sign in to your Google account first.';
      }

      rethrow;
    }
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    return await _client.auth.verifyOTP(
      type: type,
      token: token,
      email: email,
    );
  }

  Future<void> resendOtp(String email, OtpType type) async {
    await _client.auth.resend(
      type: type,
      email: email,
    );
  }

  Future<void> signInWithOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  }

  // ============ USER PROFILE ============

  Future<void> updateUserProfile({
    required String username,
    required int age,
  }) async {
    if (!isAuthenticated) return;

    final userId = currentUser!.id;

    try {
      await _client.from('user_profiles').upsert({
        'user_id': userId,
        'username': username,
        'age': age,
      });
      debugPrint('✅ User profile updated');
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' || e.code == '404') {
        debugPrint(
            '⚠️ user_profiles table not found. Skipping profile update.');
        // Don't throw - just log and continue
        return;
      }
      debugPrint('❌ Error updating user profile: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) return null;

    final userId = currentUser!.id;

    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' || e.code == '404') {
        debugPrint(
            '⚠️ user_profiles table not found. Creating default profile.');
        // Return a default profile instead of null
        return {
          'user_id': userId,
          'username': currentUser!.email?.split('@').first ?? 'User',
          'age': 18,
        };
      }
      debugPrint('❌ Error fetching user profile: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
      return null;
    }
  }

  // ============ REAL-TIME SYNC ============

  Future<void> upsertHabit(Habit habit) async {
    if (!isAuthenticated) return;

    final userId = currentUser!.id;

    try {
      await _client.from('habits').upsert({
        'id': habit.id,
        'user_id': userId,
        'name': habit.name,
        'emoji': habit.emoji,
        'category': habit.category,
        'streak': habit.streak,
        'completion_dates': habit.completionDates, // JSONB

        // Focus Task
        'is_focus_task': habit.isFocusTask,
        'focus_task_priority': habit.focusTaskPriority,

        // Gamification
        'xp_value': habit.xpValue,
        'difficulty': habit.difficulty,

        // Health
        'is_health_tracked': habit.isHealthTracked,
        'health_metric': habit.healthMetric?.index,
        'health_goal_value': habit.healthGoalValue,

        // Customization
        'custom_color': habit.customColor,
        'custom_icon': habit.customIcon,
        'reminder_time': habit.reminderTime,
        'reminder_enabled': habit.reminderEnabled,
        'frequency_days': habit.frequencyDays, // JSONB

        // Challenge
        'challenge_target_days': habit.challengeTargetDays,
        'challenge_progress': habit.challengeProgress,
        'challenge_completed': habit.challengeCompleted,

        // Goal and Focus Mode
        'habit_goal': habit.habitGoal,
        'focus_mode_duration': habit.focusModeDuration,
      }).timeout(const Duration(seconds: 10));
      // debugPrint('✅ Synced habit "${habit.name}"');
    } catch (e) {
      debugPrint('❌ Failed to sync habit "${habit.name}": $e');
      // Don't rethrow to avoid blocking UI, but log it.
    }
  }

  Future<void> upsertUserLevel(UserLevel level, int totalXP) async {
    if (!isAuthenticated) return;
    try {
      await _client.from('user_levels').upsert({
        'user_id': currentUser!.id,
        'level': level.level,
        'current_xp': level.currentXP,
        'xp_to_next_level': level.xpToNextLevel,
        'total_xp': totalXP,
      }).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('⚠️ Failed to sync user level: $e');
    }
  }

  Future<void> upsertAchievements(
      List<Map<String, dynamic>> achievements) async {
    if (!isAuthenticated || achievements.isEmpty) return;
    try {
      final userId = currentUser!.id;
      final data = achievements.map((a) => {...a, 'user_id': userId}).toList();

      await _client
          .from('user_achievements')
          .upsert(data)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('⚠️ Failed to sync achievements: $e');
    }
  }

  Future<void> upsertHealthChallenge(dynamic challenge) async {
    // Note: challenge type is dynamic to avoid import loops if model is not available here
    // But ideally should be strongly typed. Assuming it matches map structure.
    if (!isAuthenticated) return;
    // Implementation depends on HealthChallenge model structure
    // Skipping for now to avoid errors, but placeholder is here.
  }

  // ============ HABITS SYNC ============

  Future<void> deleteHabit(String habitId) async {
    if (!isAuthenticated) return;

    try {
      await _client
          .from('habits')
          .delete()
          .eq('id', habitId)
          .eq('user_id', currentUser!.id); // Ensure user owns the habit
    } catch (e) {
      debugPrint('❌ Error deleting habit from cloud: $e');
      rethrow;
    }
  }

  Future<void> syncHabitsToCloud(List<Habit> habits) async {
    if (!isAuthenticated) return;

    final userId = currentUser!.id;

    try {
      // 1. Fetch existing habit IDs from cloud to determine deletions
      final response = await _client
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 10));

      final cloudIds = (response as List).map((e) => e['id'] as String).toSet();
      final localIds = habits.map((h) => h.id).toSet();

      // 2. Identify habits to delete (in cloud but not in local)
      final idsToDelete = cloudIds.difference(localIds).toList();

      if (idsToDelete.isNotEmpty) {
        debugPrint(
            '🗑️ Deleting ${idsToDelete.length} removed habits from cloud');
        try {
          await _client
              .from('habits')
              .delete()
              .filter('id', 'in', idsToDelete)
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          // If delete fails (e.g. FK constraint), log it but continue with upsert
          debugPrint('⚠️ Iterate delete failed (likely FK constraint): $e');
        }
      }

      // 3. Upsert all local habits (Create or Update)
      if (habits.isNotEmpty) {
        final fullData = habits.map((h) {
          return {
            'id': h.id,
            'user_id': userId,
            'name': h.name,
            'emoji': h.emoji,
            'category': h.category,
            'streak': h.streak,
            'completion_dates': h.completionDates, // JSONB

            // Focus Task
            'is_focus_task': h.isFocusTask,
            'focus_task_priority': h.focusTaskPriority,

            // Gamification
            'xp_value': h.xpValue,
            'difficulty': h.difficulty,

            // Health
            'is_health_tracked': h.isHealthTracked,
            'health_metric': h.healthMetric?.index,
            'health_goal_value': h.healthGoalValue,

            // Customization
            'custom_color': h.customColor,
            'custom_icon': h.customIcon,
            'reminder_time': h.reminderTime,
            'reminder_enabled': h.reminderEnabled,
            'frequency_days': h.frequencyDays, // JSONB

            // Challenge
            'challenge_target_days': h.challengeTargetDays,
            'challenge_progress': h.challengeProgress,
            'challenge_completed': h.challengeCompleted,

            // Goal and Focus Mode
            'habit_goal': h.habitGoal,
            'focus_mode_duration': h.focusModeDuration,
          };
        }).toList();

        await _client
            .from('habits')
            .upsert(fullData)
            .timeout(const Duration(seconds: 30));

        debugPrint('✅ Synced ${habits.length} habits to cloud');
      }
    } catch (e) {
      debugPrint('❌ Backup sync failed: $e');
      // Don't rethrow to avoid crashing UI for background sync
    }
  }

  Future<List<Habit>> fetchHabitsFromCloud() async {
    if (!isAuthenticated) return [];

    final userId = currentUser!.id;

    try {
      final response =
          await _client.from('habits').select().eq('user_id', userId);

      return (response as List).map((json) => Habit.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' || e.code == '404') {
        debugPrint(
            '⚠️ habits table not found in database. Skipping habits restoration.');
        return [];
      }
      debugPrint('❌ Error fetching habits: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching habits: $e');
      return [];
    }
  }

  /// Fetch habits from cloud WITHOUT streak/completion data (for selective sync)
  Future<List<Habit>> fetchHabitsWithoutStreaks() async {
    if (!isAuthenticated) return [];

    final userId = currentUser!.id;

    try {
      final response = await _client
          .from('habits')
          .select('*')
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 10));

      final List<Habit> habits = [];
      for (final row in response as List) {
        final habit = Habit.fromJson(row);
        // Override streak and completion data with empty values
        habits.add(habit.copyWith(
          streak: 0,
          completionDates: [],
        ));
      }

      debugPrint(
          '✅ Fetched ${habits.length} habits (without streaks) from cloud');
      return habits;
    } catch (e) {
      debugPrint('❌ Failed to fetch habits without streaks: $e');
      return [];
    }
  }

  /// Sync ONLY streak and completion dates for specified habits
  Future<void> syncStreaksOnly(List<Habit> habits) async {
    if (!isAuthenticated) return;

    final userId = currentUser!.id;

    try {
      if (habits.isEmpty) return;

      // Update only streak and completion_dates fields
      for (final habit in habits) {
        await _client
            .from('habits')
            .update({
              'streak': habit.streak,
              'completion_dates': habit.completionDates,
            })
            .eq('id', habit.id)
            .eq('user_id', userId)
            .timeout(const Duration(seconds: 10));
      }

      debugPrint('✅ Synced streaks for ${habits.length} habits');
    } catch (e) {
      debugPrint('❌ Failed to sync streaks: $e');
      rethrow;
    }
  }

  // ============ USER LEVEL SYNC ============

  Future<void> syncUserLevelToCloud(UserLevel userLevel) async {
    if (!isAuthenticated) return;

    final userId = currentUser!.id;
    final data = userLevel.toJson();
    data['user_id'] = userId;

    // Upsert user level
    try {
      await _client.from('user_levels').upsert(data);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        debugPrint(
            '⚠️ Backup warning: user_levels table missing. Skipping level backup.');
      } else {
        debugPrint('❌ Failed to sync user level: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Failed to sync user level: $e');
    }
  }

  Future<UserLevel?> fetchUserLevelFromCloud() async {
    if (!isAuthenticated) return null;

    final userId = currentUser!.id;

    try {
      final response = await _client
          .from('user_levels')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return UserLevel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' || e.code == '404') {
        debugPrint(
            '⚠️ user_levels table not found in database. Skipping level restoration.');
        return null;
      }
      debugPrint('❌ Error fetching user level: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user level: $e');
      return null;
    }
  }

  // ============ SOCIAL CHALLENGES ============

  Future<void> createChallenge({
    required String name,
    required String habitId,
    required int targetDays,
    required List<String> participantEmails,
  }) async {
    if (!isAuthenticated) return;

    final userId = currentUser!.id;

    final data = {
      'name': name,
      'habit_id': habitId,
      'target_days': targetDays,
      'creator_id': userId,
      'participant_emails': participantEmails,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _client.from('challenges').insert(data);
  }

  Future<List<Map<String, dynamic>>> fetchMyChallenges() async {
    if (!isAuthenticated) return [];

    final userId = currentUser!.id;

    try {
      final response = await _client.from('challenges').select().or(
          'creator_id.eq.$userId,participant_emails.cs.{${currentUser!.email}}');

      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' || e.code == '404') {
        debugPrint('⚠️ challenges table not found in database.');
        return [];
      }
      debugPrint('❌ Error fetching challenges: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching challenges: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard(
      String challengeId) async {
    if (!isAuthenticated) return [];

    try {
      final response = await _client
          .from('challenge_progress')
          .select('*, user:user_id(email)')
          .eq('challenge_id', challengeId)
          .order('progress', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' || e.code == '404') {
        debugPrint('⚠️ challenge_progress table not found in database.');
        return [];
      }
      debugPrint('❌ Error fetching leaderboard: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching leaderboard: $e');
      return [];
    }
  }

  // ============ REAL-TIME SYNC ============

  Stream<List<Habit>> watchHabits() {
    if (!isAuthenticated) return Stream.value([]);

    final userId = currentUser!.id;

    return _client
        .from('habits')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) => Habit.fromJson(json)).toList());
  }
  // ============ ACCOUNT MANAGEMENT ============

  Future<void> deleteAccount(String password) async {
    if (!isAuthenticated) return;

    final user = currentUser!;
    final email = user.email;

    if (email == null) throw 'User email not found';

    // 1. Re-authenticate to confirm ownership
    try {
      await signIn(email: email, password: password);
    } catch (e) {
      throw 'Incorrect password. Please try again.';
    }

    // 2. Delete all user data
    final userId = user.id;

    try {
      // Delete habits
      await _client.from('habits').delete().eq('user_id', userId);
      // Delete user level
      await _client.from('user_levels').delete().eq('user_id', userId);
      // Delete user profile
      await _client.from('user_profiles').delete().eq('user_id', userId);
      // Delete challenges (created by user)
      await _client.from('challenges').delete().eq('creator_id', userId);
      // Delete challenge progress
      await _client.from('challenge_progress').delete().eq('user_id', userId);

      debugPrint('✅ User data deleted successfully');
    } catch (e) {
      debugPrint('⚠️ Partial data deletion error: $e');
    }

    // 3. Sign out
    await signOut();
  }

  // ============ HEALTH CHALLENGE SYNC ============

  Future<void> syncHealthChallenge(Map<String, dynamic> challengeData) async {
    if (!isAuthenticated) return;

    final userId = currentUser!.id;
    final challengeId = challengeData['id'];

    try {
      // Upsert challenge data
      await _client.from('health_challenges').upsert({
        'id': challengeId,
        'user_id': userId,
        'type': challengeData['type'],
        'title': challengeData['title'],
        'description': challengeData['description'],
        'start_date': challengeData['startDate'],
        'duration_weeks': challengeData['durationWeeks'],
        'goals': challengeData['goals'],
        'ai_plan': challengeData['aiPlan'],
        'recommended_habits': challengeData['recommendedHabits'],
        'baseline_metrics': challengeData['baselineMetrics'],
        'progress_snapshots': challengeData['progressSnapshots'],
        'survey_responses': challengeData['surveyResponses'],
      });

      debugPrint('✅ Health challenge synced to cloud');
    } catch (e) {
      // Ignore if table doesn't exist (PGRST205) or other sync errors
      // This prevents the red banner from showing up for users who don't have this table yet
      final msg = e.toString();
      if (msg.contains('PGRST205') || msg.contains('404')) {
        debugPrint(
            '⚠️ Health challenges table missing, skipping sync (non-critical)');
      } else {
        debugPrint('⚠️ Error syncing health challenges: $e');
        // Don't rethrow, just log it
      }
    }
  }

  Future<Map<String, dynamic>?> fetchHealthChallenge() async {
    if (!isAuthenticated) return null;

    final userId = currentUser!.id;

    try {
      final response = await _client
          .from('health_challenges')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      // Convert snake_case to camelCase for app compatibility
      return {
        'id': response['id'],
        'type': response['type'],
        'title': response['title'],
        'description': response['description'],
        'startDate': response['start_date'],
        'durationWeeks': response['duration_weeks'],
        'goals': response['goals'],
        'aiPlan': response['ai_plan'],
        'recommendedHabits': response['recommended_habits'],
        'baselineMetrics': response['baseline_metrics'],
        'progressSnapshots': response['progress_snapshots'],
        'surveyResponses': response['survey_responses'],
      };
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' || e.code == '404') {
        debugPrint(
            '⚠️ health_challenges table not found in database. Skipping health challenge restoration.');
        return null;
      }
      debugPrint('❌ Error fetching health challenge: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching health challenge: $e');
      return null;
    }
  }

  Future<void> deleteHealthChallenge(String challengeId) async {
    if (!isAuthenticated) return;

    final userId = currentUser!.id;

    try {
      await _client
          .from('health_challenges')
          .delete()
          .eq('id', challengeId)
          .eq('user_id', userId);

      debugPrint('✅ Health challenge deleted from cloud');
    } catch (e) {
      debugPrint('❌ Error deleting health challenge: $e');
      rethrow;
    }
  }

  // ============ DATA RESTORATION CHECK ============

  Future<bool> hasExistingData() async {
    if (!isAuthenticated) {
      debugPrint('🔍 hasExistingData: Not authenticated');
      return false;
    }

    final userId = currentUser!.id;
    debugPrint('🔍 Checking existing data for user: $userId');

    try {
      // 1. Check for habits
      final habitsResponse = await _client
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 15));

      debugPrint('🔍 Habits count: ${habitsResponse.count}');
      if (habitsResponse.count > 0) {
        debugPrint('✅ Found existing habits - returning user detected');
        return true;
      }

      // 2. Check for user level (XP/Progress)
      final levelResponse = await _client
          .from('user_levels')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 15));

      debugPrint('🔍 User level count: ${levelResponse.count}');
      if (levelResponse.count > 0) {
        debugPrint('✅ Found user level data - returning user detected');
        return true;
      }

      // 3. Check for health challenges
      final challengeResponse = await _client
          .from('health_challenges')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 15));

      debugPrint('🔍 Health challenges count: ${challengeResponse.count}');
      if (challengeResponse.count > 0) {
        debugPrint('✅ Found health challenge - returning user detected');
        return true;
      }

      debugPrint('🔍 No existing data found - treating as new user');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking existing data: $e');
      return false;
    }
  }

  // ============ FCM TOKEN MANAGEMENT ============

  /// Save FCM token to database for server-side push notifications
  Future<void> saveFcmToken({
    required String token,
    required String deviceType,
  }) async {
    if (!isAuthenticated) {
      debugPrint('⚠️ Cannot save FCM token: User not authenticated');
      return;
    }

    final userId = currentUser!.id;

    try {
      await _client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': deviceType,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');

      debugPrint('✅ FCM token saved to Supabase');
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '42P01') {
        debugPrint(
            '⚠️ fcm_tokens table not found. Run the SQL migration first.');
      } else {
        debugPrint('❌ Failed to save FCM token: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  /// Remove FCM token from database (on logout)
  Future<void> removeFcmToken(String token) async {
    if (!isAuthenticated) return;

    try {
      await _client.from('fcm_tokens').delete().eq('token', token);
      debugPrint('✅ FCM token removed from Supabase');
    } catch (e) {
      debugPrint('⚠️ Failed to remove FCM token: $e');
    }
  }

  /// Remove all FCM tokens for current user (on account delete)
  Future<void> removeAllFcmTokens() async {
    if (!isAuthenticated) return;

    final userId = currentUser!.id;

    try {
      await _client.from('fcm_tokens').delete().eq('user_id', userId);
      debugPrint('✅ All FCM tokens removed for user');
    } catch (e) {
      debugPrint('⚠️ Failed to remove FCM tokens: $e');
    }
  }
}
