import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/accountability_partner.dart';
import '../models/habit.dart';

/// Service for managing accountability partners
class AccountabilityService {
  static final AccountabilityService instance = AccountabilityService._();
  AccountabilityService._();

  static const _prefsKeyLocalPartners = 'local_partners';
  static const _prefsKeyPendingNudges = 'pending_nudges';

  List<AccountabilityPartner> _partners = [];
  List<PartnerNudge> _pendingNudges = [];
  PartnerInviteCode? _activeInviteCode;

  List<AccountabilityPartner> get partners => _partners;
  List<AccountabilityPartner> get activePartners =>
      _partners.where((p) => p.status == PartnerStatus.active).toList();
  List<PartnerNudge> get pendingNudges => _pendingNudges;
  PartnerInviteCode? get activeInviteCode => _activeInviteCode;
  bool get hasUnreadNudges => _pendingNudges.any((n) => !n.isRead);

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _currentUserId => _supabase?.auth.currentUser?.id;

  bool _isInitialized = false;

  /// Initialize and load partners
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadLocalData();
      await refreshPartners();
      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ AccountabilityService init failed: $e');
    }
  }

  /// Load local data
  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load partners
    final partnersJson = prefs.getString(_prefsKeyLocalPartners);
    if (partnersJson != null) {
      final list = jsonDecode(partnersJson) as List;
      _partners = list
          .map((e) => AccountabilityPartner.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Load pending nudges
    final nudgesJson = prefs.getString(_prefsKeyPendingNudges);
    if (nudgesJson != null) {
      final list = jsonDecode(nudgesJson) as List;
      _pendingNudges = list
          .map((e) => PartnerNudge.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  /// Save local data
  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKeyLocalPartners,
      jsonEncode(_partners.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _prefsKeyPendingNudges,
      jsonEncode(_pendingNudges.map((e) => e.toJson()).toList()),
    );
  }

  /// Generate a new invite code
  Future<String> generateInviteCode() async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Must be signed in to generate invite code');
    }

    _activeInviteCode = PartnerInviteCode.create(userId);

    // Store in Supabase if available
    if (_supabase != null) {
      try {
        await _supabase!.from('partner_invite_codes').upsert({
          'code': _activeInviteCode!.code,
          'creator_user_id': userId,
          'created_at': _activeInviteCode!.createdAt.toIso8601String(),
          'expires_at': _activeInviteCode!.expiresAt.toIso8601String(),
          'is_used': false,
        });
      } catch (e) {
        debugPrint('Failed to save invite code to Supabase: $e');
      }
    }

    return _activeInviteCode!.code;
  }

  /// Connect with a partner using their invite code
  Future<AccountabilityPartner?> connectWithCode(String code) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Must be signed in to connect with partner');
    }

    if (_supabase == null) {
      throw Exception('Supabase not available');
    }

    try {
      // Look up the invite code
      final response = await _supabase!
          .from('partner_invite_codes')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_used', false)
          .maybeSingle();

      if (response == null) {
        throw Exception('Invite code not found or invalid');
      }

      final inviteCode = PartnerInviteCode.fromJson(response);

      if (!inviteCode.isValid) {
        throw Exception('Invite code is expired or already used');
      }

      if (inviteCode.creatorUserId == userId) {
        throw Exception('Cannot connect with yourself');
      }

      // DIRECT DB CHECK: Query if already connected (both directions)
      // This is more robust than relying on the potentially stale local _partners list
      final existingCheck = await _supabase!
          .from('accountability_partners')
          .select('id')
          .or('and(user_id.eq.$userId,partner_id.eq.${inviteCode.creatorUserId}),and(user_id.eq.${inviteCode.creatorUserId},partner_id.eq.$userId)')
          .limit(1);

      if ((existingCheck as List).isNotEmpty) {
        throw Exception('Already connected with this partner');
      }

      // Get partner info
      Map<String, dynamic>? partnerProfile;
      try {
        partnerProfile = await _supabase!
            .from('user_profiles')
            .select('username')
            .eq('user_id', inviteCode.creatorUserId)
            .maybeSingle();
      } catch (e) {
        debugPrint(
            '⚠️ Error fetching partner profile (table might be missing): $e');
        // Continue with null, fallback handles it
      }

      // If profile is missing (e.g. RLS or sync issue), we'll gracefully handle it
      if (partnerProfile == null) {
        debugPrint(
            'Warning: Partner profile not found for ${inviteCode.creatorUserId}');
      }

      // Create partner connections (both directions)
      final partnerId = DateTime.now().millisecondsSinceEpoch.toString();

      // Get current user's name for the partner to see
      String? myName;
      try {
        final myProfile = await _supabase!
            .from('user_profiles')
            .select('username')
            .eq('user_id', userId)
            .maybeSingle();
        myName = myProfile?['username'] as String?;
      } catch (e) {
        debugPrint('⚠️ Could not fetch own profile: $e');
      }

      // Fallback to email if profile is missing
      if (myName == null || myName.isEmpty) {
        final user = _supabase!.auth.currentUser;
        myName = user?.email?.split('@').first ?? 'You';
      }

      final partnerNameToStore =
          partnerProfile?['username'] as String? ?? 'Partner';

      // Your record - we only insert ONE row now.
      // The other user will see this via the updated refreshPartners query.
      // We store BOTH names to avoid profile lookup issues later.
      try {
        await _supabase!.from('accountability_partners').insert({
          'id': partnerId,
          'user_id': userId,
          'partner_id': inviteCode.creatorUserId,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'initiator_name': myName,
          'partner_name': partnerNameToStore,
        });
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          throw Exception('Already connected with this partner');
        }
        rethrow;
      }

      // NOTE: We do NOT insert the reverse record anymore to avoid RLS 42501 errors.
      // The robust query in refreshPartners handles the bidirectionality.

      // Mark code as used
      await _supabase!
          .from('partner_invite_codes')
          .update({'is_used': true}).eq('code', code.toUpperCase());

      // Create local partner record
      final partner = AccountabilityPartner(
        id: partnerId,
        partnerUserId: inviteCode.creatorUserId,
        partnerName: partnerNameToStore,
        status: PartnerStatus.active,
        connectedAt: DateTime.now(),
      );

      _partners.add(partner);
      await _saveLocalData();

      debugPrint('🤝 Connected with partner: ${partner.partnerName}');
      return partner;
    } catch (e) {
      debugPrint('Failed to connect with code: $e');
      rethrow;
    }
  }

  /// Refresh partners from server
  Future<void> refreshPartners() async {
    final userId = _currentUserId;
    if (userId == null || _supabase == null) return;

    try {
      // Query for matches where I am the user OR the partner
      // Include stored names (initiator_name, partner_name) and profile joins as fallback
      dynamic response;
      try {
        response = await _supabase!.from('accountability_partners').select('''
            id,
            user_id,
            partner_id,
            status,
            created_at,
            initiator_name,
            partner_name,
            partner_profile:user_profiles!partner_id(username),
            initiator_profile:user_profiles!user_id(username)
          ''').or('user_id.eq.$userId,partner_id.eq.$userId');
      } catch (e) {
        // Profile joins not available, using fallback with stored names
        debugPrint(
            'ℹ️ Using fallback partner query (profile joins not configured)');
        // Fallback: Try query with stored names only
        try {
          response = await _supabase!
              .from('accountability_partners')
              .select(
                  'id, user_id, partner_id, status, created_at, initiator_name, partner_name')
              .or('user_id.eq.$userId,partner_id.eq.$userId');
        } catch (e2) {
          debugPrint('⚠️ Error with names (trying basic query): $e2');
          try {
            response = await _supabase!
                .from('accountability_partners')
                .select('id, user_id, partner_id, status, created_at')
                .or('user_id.eq.$userId,partner_id.eq.$userId');
          } catch (e3) {
            debugPrint('❌ Fatal error refreshing partners: $e3');
            return;
          }
        }
      }

      _partners = (response as List).map((data) {
        final isMyRecord = data['user_id'] == userId;

        // Determine which field holds the partner's ID
        final partnerUserId = isMyRecord
            ? data['partner_id'] as String
            : data['user_id'] as String;

        // Priority for partner name:
        // 1. Stored name in the record (initiator_name or partner_name)
        // 2. Profile join (username)
        // 3. Fallback to 'Partner'
        String partnerName;
        if (isMyRecord) {
          // I created this record, partner is stored in partner_name
          partnerName = data['partner_name'] as String? ??
              (data['partner_profile'] as Map<String, dynamic>?)?['username']
                  as String? ??
              'Partner';
        } else {
          // Partner created this record, their name is in initiator_name
          partnerName = data['initiator_name'] as String? ??
              (data['initiator_profile'] as Map<String, dynamic>?)?['username']
                  as String? ??
              'Partner';
        }

        return AccountabilityPartner(
          id: data['id'] as String,
          partnerUserId: partnerUserId,
          partnerName: partnerName,
          status: PartnerStatus.values.firstWhere(
            (s) => s.name == (data['status'] as String),
            orElse: () => PartnerStatus.pending,
          ),
          connectedAt: DateTime.parse(data['created_at'] as String),
        );
      }).toList();

      await _saveLocalData();
      debugPrint('🤝 Refreshed ${_partners.length} partners');
    } catch (e) {
      debugPrint('Failed to refresh partners: $e');
    }
  }

  /// Send a nudge to a partner
  Future<void> sendNudge(
    String partnerId,
    String message, {
    String? habitName,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Must be signed in to send nudge');
    }

    final partner = _partners.firstWhere((p) => p.id == partnerId);
    if (!partner.canSendNudge) {
      throw Exception(
          'Daily nudge limit reached ($maxDailyNudges per day). Try again tomorrow!');
    }

    final nudge = PartnerNudge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromUserId: userId,
      toUserId: partner.partnerUserId,
      message: message,
      habitName: habitName,
      sentAt: DateTime.now(),
    );

    // Save to Supabase if available
    if (_supabase != null) {
      try {
        await _supabase!.from('partner_nudges').insert({
          'id': nudge.id,
          'from_user_id': nudge.fromUserId,
          'to_user_id': nudge.toUserId,
          'message': nudge.message,
          'habit_name': nudge.habitName,
          'created_at': nudge.sentAt.toIso8601String(),
        });

        // Determine sender name dynamically
        String senderName = 'Your Partner';
        try {
          final user = _supabase?.auth.currentUser;
          final meta = user?.userMetadata;
          senderName = meta?['full_name'] as String? ??
              meta?['name'] as String? ??
              meta?['username'] as String? ??
              user?.email?.split('@').first ??
              'Your Partner';
        } catch (_) {}

        // Also trigger push notification (Edge Function)
        await _supabase!.functions.invoke('send-partner-nudge', body: {
          'to_user_id': partner.partnerUserId,
          'from_user_name': senderName,
          'message': message,
        });
      } catch (e) {
        debugPrint('Failed to save nudge to Supabase: $e');
      }
    }

    // Update partner with nudge time and increment daily count
    final now = DateTime.now();
    final newCount = partner.nudgesSentToday + 1;
    final updatedPartner = partner.copyWith(
      lastNudgeSent: now,
      nudgesTodayCount: newCount,
      nudgeCountResetDate: now,
    );
    final index = _partners.indexWhere((p) => p.id == partnerId);
    if (index >= 0) {
      _partners[index] = updatedPartner;
    }

    await _saveLocalData();
    debugPrint(
        '📲 Sent nudge to ${partner.partnerName}: $message (${updatedPartner.remainingNudgesToday} remaining today)');
  }

  /// Mark nudges as read
  Future<void> markNudgesAsRead() async {
    _pendingNudges = _pendingNudges.map((n) {
      return PartnerNudge(
        id: n.id,
        fromUserId: n.fromUserId,
        toUserId: n.toUserId,
        message: n.message,
        habitName: n.habitName,
        sentAt: n.sentAt,
        isRead: true,
      );
    }).toList();
    await _saveLocalData();
  }

  /// Notify partners when you miss a habit (called by app at end of day)
  Future<void> notifyPartnersOfMiss(Habit habit) async {
    for (final partner in activePartners) {
      // This creates a record that partner can see
      // They'll get notified via push notification
      if (_supabase != null) {
        try {
          await _supabase!.from('partner_habit_misses').insert({
            'user_id': _currentUserId,
            'partner_id': partner.partnerUserId,
            'habit_name': habit.name,
            'habit_emoji': habit.emoji,
            'missed_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Failed to notify partner of miss: $e');
        }
      }
    }
  }

  /// Remove a partner
  Future<void> removePartner(String partnerId) async {
    if (_supabase != null && _currentUserId != null) {
      try {
        await _supabase!
            .from('accountability_partners')
            .delete()
            .eq('id', partnerId);
      } catch (e) {
        debugPrint('Failed to remove partner from Supabase: $e');
      }
    }

    _partners.removeWhere((p) => p.id == partnerId);
    await _saveLocalData();
  }

  /// Clear all data (for logout)
  Future<void> clear() async {
    _partners.clear();
    _pendingNudges.clear();
    _activeInviteCode = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyLocalPartners);
    await prefs.remove(_prefsKeyPendingNudges);
  }

  /// Update privacy settings for a specific partner connection
  Future<void> updatePrivacySettings(String partnerConnectionId,
      AccountabilityPrivacySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'accountability_privacy_$partnerConnectionId';
    await prefs.setString(key, jsonEncode(settings.toJson()));
    debugPrint('✅ Privacy settings persisted for $partnerConnectionId');
  }

  /// Get privacy settings for a specific partner connection
  Future<AccountabilityPrivacySettings> getPrivacySettings(
      String partnerConnectionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'accountability_privacy_$partnerConnectionId';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return AccountabilityPrivacySettings(); // Default
    try {
      return AccountabilityPrivacySettings.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return AccountabilityPrivacySettings();
    }
  }
}
