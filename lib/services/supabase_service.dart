import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode;
import '../models/habit.dart';
import '../models/user_level.dart';
import '../config/env.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

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

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;

    if (googleAuth == null) {
      throw 'Google Sign In failed';
    }

    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
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
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('✅ User profile updated');
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' || e.code == '404') {
        print('⚠️ user_profiles table not found. Skipping profile update.');
        // Don't throw - just log and continue
        return;
      }
      print('❌ Error updating user profile: ${e.message}');
    } catch (e) {
      print('❌ Error updating user profile: $e');
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
        print('⚠️ user_profiles table not found. Creating default profile.');
        // Return a default profile instead of null
        return {
          'user_id': userId,
          'username': currentUser!.email?.split('@').first ?? 'User',
          'age': 18,
        };
      }
      print('❌ Error fetching user profile: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Error fetching user profile: $e');
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

        'updated_at': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 10));
      // print('✅ Synced habit "${habit.name}"');
    } catch (e) {
      print('❌ Failed to sync habit "${habit.name}": $e');
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
        'updated_at': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silent fail (or log if needed)
      // print('⚠️ Failed to sync user level: $e');
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
      print('❌ Error deleting habit from cloud: $e');
      rethrow;
    }
  }

  Future<void> syncHabitsToCloud(List<Habit> habits) async {
    if (!isAuthenticated) return;

    final userId = currentUser!.id;

    try {
      // Delete existing habits for this user with timeout protection
      await _client
          .from('habits')
          .delete()
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 30));
      print('✅ Deleted old habits from cloud');
    } catch (e) {
      print('⚠️ Failed to delete old habits during backup: $e');
      // Continue to insert even if delete fails (best effort)
    }

    // Prepare full data payload
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

        'updated_at': DateTime.now().toIso8601String(),
      };
    }).toList();

    if (fullData.isNotEmpty) {
      try {
        await _client
            .from('habits')
            .insert(fullData)
            .timeout(const Duration(seconds: 30));
        print('✅ Backed up ${fullData.length} habits with FULL data');
      } catch (e) {
        print('❌ Backup failed: $e');
        rethrow;
      }
    } else {
      print('ℹ️ No habits to backup (empty list)');
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
        print(
            '⚠️ habits table not found in database. Skipping habits restoration.');
        return [];
      }
      print('❌ Error fetching habits: ${e.message}');
      return [];
    } catch (e) {
      print('❌ Error fetching habits: $e');
      return [];
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
        print(
            '⚠️ Backup warning: user_levels table missing. Skipping level backup.');
      } else {
        print('❌ Failed to sync user level: ${e.message}');
      }
    } catch (e) {
      print('❌ Failed to sync user level: $e');
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
        print(
            '⚠️ user_levels table not found in database. Skipping level restoration.');
        return null;
      }
      print('❌ Error fetching user level: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Error fetching user level: $e');
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

    final response = await _client.from('challenges').select().or(
        'creator_id.eq.$userId,participant_emails.cs.{${currentUser!.email}}');

    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard(
      String challengeId) async {
    if (!isAuthenticated) return [];

    final response = await _client
        .from('challenge_progress')
        .select('*, user:user_id(email)')
        .eq('challenge_id', challengeId)
        .order('progress', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
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

      print('✅ User data deleted successfully');
    } catch (e) {
      print('⚠️ Partial data deletion error: $e');
    }

    // 3. Sign out
    await signOut();
  }

  // ============ HEALTH CHALLENGE SYNC ============

  Future<void> syncHealthChallenge(Map<String, dynamic> challengeData) async {
    if (!isAuthenticated) throw 'User not authenticated';

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
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Health challenge synced to cloud');
    } catch (e) {
      print('❌ Error syncing health challenge: $e');
      rethrow;
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
        print(
            '⚠️ health_challenges table not found in database. Skipping health challenge restoration.');
        return null;
      }
      print('❌ Error fetching health challenge: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Error fetching health challenge: $e');
      return null;
    }
  }

  Future<void> deleteHealthChallenge(String challengeId) async {
    if (!isAuthenticated) throw 'User not authenticated';

    final userId = currentUser!.id;

    try {
      await _client
          .from('health_challenges')
          .delete()
          .eq('id', challengeId)
          .eq('user_id', userId);

      print('✅ Health challenge deleted from cloud');
    } catch (e) {
      print('❌ Error deleting health challenge: $e');
      rethrow;
    }
  }

  // ============ DATA RESTORATION CHECK ============

  Future<bool> hasExistingData() async {
    if (!isAuthenticated) {
      print('🔍 hasExistingData: Not authenticated');
      return false;
    }

    final userId = currentUser!.id;
    print('🔍 Checking existing data for user: $userId');

    try {
      // 1. Check for habits
      final habitsResponse = await _client
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 15));

      print('🔍 Habits count: ${habitsResponse.count}');
      if (habitsResponse.count > 0) {
        print('✅ Found existing habits - returning user detected');
        return true;
      }

      // 2. Check for user level (XP/Progress)
      final levelResponse = await _client
          .from('user_levels')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 15));

      print('🔍 User level count: ${levelResponse.count}');
      if (levelResponse.count > 0) {
        print('✅ Found user level data - returning user detected');
        return true;
      }

      // 3. Check for health challenges
      final challengeResponse = await _client
          .from('health_challenges')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 15));

      print('🔍 Health challenges count: ${challengeResponse.count}');
      if (challengeResponse.count > 0) {
        print('✅ Found health challenge - returning user detected');
        return true;
      }

      print('🔍 No existing data found - treating as new user');
      return false;
    } catch (e) {
      print('❌ Error checking existing data: $e');
      return false;
    }
  }
}
