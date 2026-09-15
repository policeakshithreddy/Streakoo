/// Team Service for managing teams, members, and team habits
library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/team.dart';

class TeamService extends ChangeNotifier {
  static final TeamService _instance = TeamService._internal();
  static TeamService get instance => _instance;
  TeamService._internal();

  final _supabase = Supabase.instance.client;

  /// Current user's teams
  List<Team> _teams = [];
  List<Team> get teams => List.unmodifiable(_teams);

  /// Active teams only
  List<Team> get activeTeams => _teams.where((t) => t.isActive).toList();

  /// Pending teams (waiting for members)
  List<Team> get pendingTeams =>
      _teams.where((t) => t.status == TeamStatus.pending).toList();

  /// Current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Initialize and load teams
  Future<void> initialize() async {
    await refreshTeams();
    _syncUserProfile();
  }

  /// Sync current user profile to ensure they have a name in the system
  Future<void> _syncUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Ensure user_profiles row exists
      final profile = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      String displayName = user.userMetadata?['full_name'] ??
          user.email?.split('@').first ??
          'User';

      if (profile == null) {
        debugPrint('👤 Creating profile for existing user...');
        await _supabase.from('user_profiles').insert({
          'user_id': user.id,
          'username': displayName,
          'age': 18, // Default
        });
      } else {
        displayName = profile['username'] as String? ?? displayName;
      }

      // 2. Update my name in all my team memberships
      // This "Backfills" the name for existing older records
      await _supabase
          .from('team_members')
          .update({'display_name': displayName}).eq('user_id', user.id);
    } catch (e) {
      debugPrint('⚠️ Error syncing user profile: $e');
    }
  }

  /// Refresh user's teams from database
  Future<void> refreshTeams() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // Get teams where user is a member
      final membershipResponse = await _supabase
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId);

      final teamIds = (membershipResponse as List)
          .map((m) => m['team_id'] as String)
          .toList();

      if (teamIds.isEmpty) {
        _teams = [];
        notifyListeners();
        return;
      }

      // Get team details
      final teamsResponse =
          await _supabase.from('teams').select().inFilter('id', teamIds);

      _teams = (teamsResponse as List)
          .map((t) => Team.fromJson(t as Map<String, dynamic>))
          .toList();

      // Load members for each team
      for (var i = 0; i < _teams.length; i++) {
        final members = await getTeamMembers(_teams[i].id);
        _teams[i] = _teams[i].copyWith(members: members);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing teams: $e');
    }
  }

  /// Create a new team
  Future<Team?> createTeam({
    required String name,
    required int maxMembers,
    String teamEmoji = '🔥',
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Must be signed in');

    try {
      final teamId = _generateUUID();
      final now = DateTime.now();

      // Create team
      await _supabase.from('teams').insert({
        'id': teamId,
        'name': name,
        'creator_id': userId,
        'max_members': maxMembers,
        'status': 'pending',
        'team_emoji': teamEmoji,
        'team_streak': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Add creator as first member
      await _supabase.from('team_members').insert({
        'team_id': teamId,
        'user_id': userId,
        'role': 'creator',
        'joined_at': now.toIso8601String(),
      });

      // Construct team object directly (don't rely on refreshTeams + firstWhere)
      // This avoids issues if RLS policies block reads
      final team = Team(
        id: teamId,
        name: name,
        creatorId: userId,
        maxMembers: maxMembers,
        status: TeamStatus.pending,
        teamEmoji: teamEmoji,
        teamStreak: 0,
        createdAt: now,
        updatedAt: now,
        members: [
          TeamMember(
            id: '${teamId}_$userId',
            teamId: teamId,
            userId: userId,
            displayName: null,
            role: TeamRole.creator,
            joinedAt: now,
          ),
        ],
      );

      // Add to local cache
      _teams.add(team);
      notifyListeners();

      return team;
    } catch (e) {
      debugPrint('❌ Error creating team: $e');
      // Rethrow with detailed message so UI can show it
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || errorStr.contains('policy')) {
        throw Exception('Database permission error. Check RLS policies.');
      } else if (errorStr.contains('duplicate')) {
        throw Exception('Team name already exists.');
      } else if (errorStr.contains('undefined_table') ||
          errorStr.contains('does not exist') ||
          errorStr.contains('relation') &&
              errorStr.contains('does not exist')) {
        throw Exception(
            'Teams feature not set up. Please set up the teams tables in Supabase.');
      }
      throw Exception('Failed to create team: $e');
    }
  }

  /// Generate team invite code
  Future<TeamInviteCode?> generateInviteCode(String teamId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Must be signed in');

    try {
      final team = _teams.firstWhere((t) => t.id == teamId);
      final code = _generateCode(6);
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      await _supabase.from('team_invite_codes').insert({
        'code': code,
        'team_id': teamId,
        'created_by': userId,
        'expires_at': expiresAt.toIso8601String(),
        'max_uses': team.maxMembers - 1, // Minus creator
        'use_count': team.members.length - 1, // Current non-creator members
        'created_at': now.toIso8601String(),
      });

      return TeamInviteCode(
        code: code,
        teamId: teamId,
        createdBy: userId,
        expiresAt: expiresAt,
        maxUses: team.maxMembers - 1,
        useCount: team.members.length - 1,
        createdAt: now,
      );
    } catch (e) {
      debugPrint('❌ Error generating invite code: $e');
      return null;
    }
  }

  /// Join a team via invite code
  Future<Team?> joinTeamWithCode(String code, {String? displayName}) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Must be signed in');

    try {
      // Find the invite code
      final codeResponse = await _supabase
          .from('team_invite_codes')
          .select()
          .eq('code', code.toUpperCase())
          .maybeSingle();

      if (codeResponse == null) {
        throw Exception('Invalid invite code. Please check and try again.');
      }

      final inviteCode = TeamInviteCode.fromJson(codeResponse);

      if (!inviteCode.isValid) {
        throw Exception('Invite code is expired or fully used');
      }

      // Check if already a member
      final existingMember = await _supabase
          .from('team_members')
          .select()
          .eq('team_id', inviteCode.teamId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('You are already a member of this team');
      }

      // Join the team
      await _supabase.from('team_members').insert({
        'team_id': inviteCode.teamId,
        'user_id': userId,
        'role': 'member',
        'display_name': displayName,
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Increment use count
      await _supabase
          .from('team_invite_codes')
          .update({'use_count': inviteCode.useCount + 1}).eq(
              'code', code.toUpperCase());

      await refreshTeams();
      return _teams.firstWhere((t) => t.id == inviteCode.teamId);
    } catch (e) {
      debugPrint('❌ Error joining team: $e');
      rethrow;
    }
  }

  /// Get team members with profile data
  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    try {
      final response =
          await _supabase.from('team_members').select().eq('team_id', teamId);

      final members = (response as List)
          .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
          .toList();

      // Enrich with profile data
      if (members.isNotEmpty) {
        final userIds = members.map((m) => m.userId).toList();
        try {
          final profilesResponse = await _supabase
              .from('user_profiles')
              .select('user_id, username')
              .inFilter('user_id', userIds);

          final profiles = {
            for (var p in (profilesResponse as List)) p['user_id'] as String: p
          };

          return members.map((m) {
            final profile = profiles[m.userId];
            if (profile != null) {
              return TeamMember(
                id: m.id,
                teamId: m.teamId,
                userId: m.userId,
                role: m.role,
                displayName: profile['username'] as String? ?? m.displayName,
                joinedAt: m.joinedAt,
              );
            }
            return m;
          }).toList();
        } catch (e) {
          debugPrint('⚠️ Error fetching profiles for team members: $e');
          // Return members with whatever data they have
          return members;
        }
      }
      return members;
    } catch (e) {
      debugPrint('❌ Error getting team members: $e');
      return [];
    }
  }

  /// Leave a team
  Future<bool> leaveTeam(String teamId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      await _supabase
          .from('team_members')
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', userId);

      await refreshTeams();
      return true;
    } catch (e) {
      debugPrint('❌ Error leaving team: $e');
      return false;
    }
  }

  /// Remove a member from the team (Creator only)
  Future<bool> removeMember(String teamId, String memberUserId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    // Verify creator status
    final team = _teams.any((t) => t.id == teamId)
        ? _teams.firstWhere((t) => t.id == teamId)
        : null;
    if (team == null || team.creatorId != userId) {
      debugPrint('❌ Permission denied: Only creator can remove members');
      return false;
    }

    try {
      await _supabase
          .from('team_members')
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', memberUserId);

      // Force refresh to update the UI immediately
      await refreshTeams();
      return true;
    } catch (e) {
      debugPrint('❌ Error removing member: $e');
      return false;
    }
  }

  /// Delete a team (Creator only)
  Future<bool> deleteTeam(String teamId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    // Verify creator status
    final team = _teams.any((t) => t.id == teamId)
        ? _teams.firstWhere((t) => t.id == teamId)
        : null;
    if (team == null || team.creatorId != userId) {
      debugPrint('❌ Permission denied: Only creator can delete team');
      return false;
    }

    try {
      // Cascading deletes should handle members/habits if configured in DB.
      // If not, we might need manual cleanup, but usually RLS/FK handles it.
      await _supabase.from('teams').delete().eq('id', teamId);

      await refreshTeams();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting team: $e');
      return false;
    }
  }

  /// Update team name (creator only)
  Future<bool> updateTeamName(String teamId, String newName) async {
    try {
      await _supabase.from('teams').update({
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', teamId);

      await refreshTeams();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating team name: $e');
      return false;
    }
  }

  // ==========================================
  // TEAM HABITS
  // ==========================================

  /// Create a team habit
  Future<TeamHabit?> createTeamHabit({
    required String teamId,
    required String name,
    String emoji = '✅',
    String? description,
    int targetDays = 7,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final habitId = _generateUUID();
      final now = DateTime.now();

      await _supabase.from('team_habits').insert({
        'id': habitId,
        'team_id': teamId,
        'name': name,
        'emoji': emoji,
        'description': description,
        'created_by': userId,
        'status': 'active',
        'target_days': targetDays,
        'created_at': now.toIso8601String(),
      });

      return TeamHabit(
        id: habitId,
        teamId: teamId,
        name: name,
        emoji: emoji,
        description: description,
        createdBy: userId,
        status: TeamHabitStatus.active,
        targetDays: targetDays,
        createdAt: now,
      );
    } catch (e) {
      debugPrint('❌ Error creating team habit: $e');
      return null;
    }
  }

  /// Get team habits
  Future<List<TeamHabit>> getTeamHabits(String teamId) async {
    try {
      final response = await _supabase
          .from('team_habits')
          .select()
          .eq('team_id', teamId)
          .eq('status', 'active');

      return (response as List)
          .map((h) => TeamHabit.fromJson(h as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting team habits: $e');
      return [];
    }
  }

  /// Complete a team habit for today
  Future<bool> completeTeamHabit(String teamHabitId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _supabase.from('team_habit_progress').upsert({
        'team_habit_id': teamHabitId,
        'user_id': userId,
        'completed_date': dateStr,
        'completed_at': today.toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error completing team habit: $e');
      return false;
    }
  }

  /// Undo a team habit completion for today
  Future<bool> undoTeamHabit(String teamHabitId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _supabase.from('team_habit_progress').delete().match({
        'team_habit_id': teamHabitId,
        'user_id': userId,
        'completed_date': dateStr,
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error undoing team habit: $e');
      return false;
    }
  }

  /// Get progress for a team habit
  Future<List<TeamHabitProgress>> getHabitProgress(String teamHabitId,
      {int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final startStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('team_habit_progress')
          .select()
          .eq('team_habit_id', teamHabitId)
          .gte('completed_date', startStr);

      return (response as List)
          .map((p) => TeamHabitProgress.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting habit progress: $e');
      return [];
    }
  }

  // ==========================================
  // REACTIONS
  // ==========================================

  /// Send a reaction to a team member
  Future<bool> sendReaction({
    required String teamId,
    String? toUserId,
    required String emoji,
    String? message,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      await _supabase.from('team_reactions').insert({
        'team_id': teamId,
        'from_user_id': userId,
        'to_user_id': toUserId,
        'emoji': emoji,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error sending reaction: $e');
      return false;
    }
  }

  /// Get recent reactions for a team
  Future<List<TeamReaction>> getRecentReactions(String teamId,
      {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('team_reactions')
          .select()
          .eq('team_id', teamId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((r) => TeamReaction.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting reactions: $e');
      return [];
    }
  }

  // ==========================================
  // TEAM INVITATIONS
  // ==========================================

  /// Send a team invitation to a specific user (existing partner)
  Future<bool> sendTeamInvite({
    required String teamId,
    required String toUserId,
    required String teamName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final inviteId = _generateUUID();

      // Store invite in database
      await _supabase.from('team_invites').insert({
        'id': inviteId,
        'team_id': teamId,
        'from_user_id': userId,
        'to_user_id': toUserId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'expires_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      });

      // Send push notification to invited user
      try {
        await _supabase.functions.invoke('send-partner-nudge', body: {
          'to_user_id': toUserId,
          'from_user_name': 'Your Partner',
          'message':
              '🎯 You\'ve been invited to join "$teamName"! Open the app to accept.',
        });
      } catch (e) {
        debugPrint('⚠️ Failed to send invite notification: $e');
      }

      debugPrint('✅ Team invite sent to $toUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to send team invite: $e');
      return false;
    }
  }

  /// Get pending team invites for current user
  Future<List<Map<String, dynamic>>> getPendingInvites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️ getPendingInvites: User not logged in');
      return [];
    }

    try {
      debugPrint('🔍 Fetching pending invites for user: $userId');

      // Simple query without joins first
      final response = await _supabase
          .from('team_invites')
          .select('*')
          .eq('to_user_id', userId)
          .eq('status', 'pending');

      debugPrint('📬 Found ${(response as List).length} pending invites');

      // Enrich with team names
      final enriched = <Map<String, dynamic>>[];
      for (final invite in response) {
        final teamId = invite['team_id'];
        String teamName = 'A Team';
        String teamEmoji = '🔥';

        try {
          final teamData = await _supabase
              .from('teams')
              .select('name, team_emoji')
              .eq('id', teamId)
              .maybeSingle();

          if (teamData != null) {
            teamName = teamData['name'] ?? 'A Team';
            teamEmoji = teamData['team_emoji'] ?? '🔥';
          }
        } catch (e) {
          debugPrint('⚠️ Could not fetch team name: $e');
        }

        enriched.add({
          ...invite,
          'teams': {'name': teamName, 'emoji': teamEmoji},
        });
      }

      return enriched;
    } catch (e) {
      debugPrint('❌ Failed to get pending invites: $e');
      return [];
    }
  }

  /// Accept or decline a team invite
  Future<bool> respondToInvite(String inviteId, bool accept) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Update invite status
      await _supabase.from('team_invites').update({
        'status': accept ? 'accepted' : 'declined',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', inviteId);

      if (accept) {
        // Get the team ID from invite
        final invite = await _supabase
            .from('team_invites')
            .select('team_id')
            .eq('id', inviteId)
            .maybeSingle();

        if (invite != null) {
          // Add user as team member
          await _supabase.from('team_members').insert({
            'team_id': invite['team_id'],
            'user_id': userId,
            'role': 'member',
            'joined_at': DateTime.now().toIso8601String(),
          });

          await refreshTeams();
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Failed to respond to invite: $e');
      return false;
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================

  String _generateCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _generateUUID() {
    final random = Random();
    const hexDigits = '0123456789abcdef';
    final uuid = List<String>.generate(36, (i) {
      if (i == 8 || i == 13 || i == 18 || i == 23) return '-';
      if (i == 14) return '4';
      if (i == 19) return hexDigits[(random.nextInt(4) + 8)];
      return hexDigits[random.nextInt(16)];
    });
    return uuid.join();
  }

  /// Calculate team streak (days where ALL members completed ALL habits)
  Future<int> calculateTeamStreak(String teamId) async {
    try {
      final team = _teams.firstWhere((t) => t.id == teamId);
      final habits = await getTeamHabits(teamId);

      if (habits.isEmpty || team.members.isEmpty) return 0;

      int streak = 0;
      DateTime checkDate = DateTime.now().subtract(const Duration(days: 1));

      while (true) {
        final dateStr =
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

        bool allCompleted = true;
        for (final habit in habits) {
          final progress = await _supabase
              .from('team_habit_progress')
              .select()
              .eq('team_habit_id', habit.id)
              .eq('completed_date', dateStr);

          final completedUsers =
              (progress as List).map((p) => p['user_id']).toSet();
          final allMemberIds = team.members.map((m) => m.userId).toSet();

          if (!allMemberIds.every((id) => completedUsers.contains(id))) {
            allCompleted = false;
            break;
          }
        }

        if (allCompleted) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      // Update team streak in database
      await _supabase
          .from('teams')
          .update({'team_streak': streak}).eq('id', teamId);

      return streak;
    } catch (e) {
      debugPrint('❌ Error calculating team streak: $e');
      return 0;
    }
  }
}
