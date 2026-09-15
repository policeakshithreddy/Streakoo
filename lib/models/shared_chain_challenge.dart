import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

/// Model for a shared chain challenge between accountability partners
class SharedChainChallenge {
  final String id;
  final String chainName;
  final String? description;
  final List<String> habitNames; // List of habit names in the chain
  final String createdBy;
  final String partnerId;
  final DateTime createdAt;
  final bool isActive;

  // Progress tracking (local for display)
  int myProgress;
  int partnerProgress;
  int myStreak;
  int partnerStreak;

  SharedChainChallenge({
    required this.id,
    required this.chainName,
    this.description,
    required this.habitNames,
    required this.createdBy,
    required this.partnerId,
    required this.createdAt,
    this.isActive = true,
    this.myProgress = 0,
    this.partnerProgress = 0,
    this.myStreak = 0,
    this.partnerStreak = 0,
  });

  int get totalHabits => habitNames.length;

  double get myProgressPercent =>
      totalHabits > 0 ? myProgress / totalHabits : 0;
  double get partnerProgressPercent =>
      totalHabits > 0 ? partnerProgress / totalHabits : 0;

  SharedChainChallenge copyWith({
    String? chainName,
    String? description,
    List<String>? habitNames,
    bool? isActive,
    int? myProgress,
    int? partnerProgress,
    int? myStreak,
    int? partnerStreak,
  }) {
    return SharedChainChallenge(
      id: id,
      chainName: chainName ?? this.chainName,
      description: description ?? this.description,
      habitNames: habitNames ?? this.habitNames,
      createdBy: createdBy,
      partnerId: partnerId,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      myProgress: myProgress ?? this.myProgress,
      partnerProgress: partnerProgress ?? this.partnerProgress,
      myStreak: myStreak ?? this.myStreak,
      partnerStreak: partnerStreak ?? this.partnerStreak,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chain_name': chainName,
        'chain_description': description,
        'habit_ids': habitNames,
        'created_by': createdBy,
        'partner_id': partnerId,
        'created_at': createdAt.toIso8601String(),
        'is_active': isActive,
      };

  factory SharedChainChallenge.fromJson(Map<String, dynamic> json) {
    return SharedChainChallenge(
      id: json['id'] as String,
      chainName: json['chain_name'] as String,
      description: json['chain_description'] as String?,
      habitNames: (json['habit_ids'] as List<dynamic>).cast<String>(),
      createdBy: json['created_by'] as String,
      partnerId: json['partner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Service to manage shared chain challenges
class SharedChainChallengeService extends ChangeNotifier {
  static final SharedChainChallengeService _instance =
      SharedChainChallengeService._();
  static SharedChainChallengeService get instance => _instance;
  SharedChainChallengeService._();

  SupabaseClient? _supabase;
  String? _currentUserId;
  List<SharedChainChallenge> _challenges = [];

  List<SharedChainChallenge> get challenges => _challenges;
  List<SharedChainChallenge> get activeChallenges =>
      _challenges.where((c) => c.isActive).toList();

  static const String _localStorageKey = 'shared_chain_challenges';

  /// Initialize the service
  Future<void> initialize() async {
    try {
      _supabase = Supabase.instance.client;
      _currentUserId = _supabase?.auth.currentUser?.id;
      await _loadLocalData();
      await refreshChallenges();
    } catch (e) {
      debugPrint('Error initializing SharedChainChallengeService: $e');
    }
  }

  /// Load challenges from local storage
  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_localStorageKey);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _challenges =
            decoded.map((e) => SharedChainChallenge.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading local challenges: $e');
    }
  }

  /// Save challenges to local storage
  Future<void> _saveLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _localStorageKey,
        jsonEncode(_challenges.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving local challenges: $e');
    }
  }

  /// Refresh challenges from server
  Future<void> refreshChallenges() async {
    if (_supabase == null || _currentUserId == null) return;

    try {
      final response = await _supabase!
          .from('shared_chain_challenges')
          .select()
          .or('created_by.eq.$_currentUserId,partner_id.eq.$_currentUserId');

      _challenges = (response as List).map((data) {
        return SharedChainChallenge.fromJson(data);
      }).toList();

      // Load progress for each challenge
      for (int i = 0; i < _challenges.length; i++) {
        final challenge = _challenges[i];
        try {
          final progressResponse = await _supabase!
              .from('shared_chain_progress')
              .select()
              .eq('challenge_id', challenge.id);

          for (final progress in progressResponse as List) {
            final userId = progress['user_id'] as String;
            final completedIndices =
                (progress['completed_habit_indices'] as List<dynamic>?)
                        ?.cast<int>() ??
                    [];
            final streak = progress['streak_count'] as int? ?? 0;

            if (userId == _currentUserId) {
              _challenges[i] = challenge.copyWith(
                myProgress: completedIndices.length,
                myStreak: streak,
              );
            } else {
              _challenges[i] = _challenges[i].copyWith(
                partnerProgress: completedIndices.length,
                partnerStreak: streak,
              );
            }
          }
        } catch (e) {
          debugPrint(
              'Error loading progress for challenge ${challenge.id}: $e');
        }
      }

      await _saveLocalData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing challenges: $e');
    }
  }

  /// Create a new shared chain challenge
  Future<SharedChainChallenge?> createChallenge({
    required String chainName,
    String? description,
    required List<String> habitNames,
    required String partnerId,
  }) async {
    if (_supabase == null || _currentUserId == null) return null;

    if (habitNames.length < 2) {
      throw ArgumentError('A chain must have at least 2 habits');
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final challenge = SharedChainChallenge(
      id: id,
      chainName: chainName,
      description: description,
      habitNames: habitNames,
      createdBy: _currentUserId!,
      partnerId: partnerId,
      createdAt: DateTime.now(),
    );

    try {
      await _supabase!
          .from('shared_chain_challenges')
          .insert(challenge.toJson());

      // Initialize progress for both users
      await _supabase!.from('shared_chain_progress').insert({
        'id': '${id}_$_currentUserId',
        'challenge_id': id,
        'user_id': _currentUserId,
      });
      await _supabase!.from('shared_chain_progress').insert({
        'id': '${id}_$partnerId',
        'challenge_id': id,
        'user_id': partnerId,
      });

      _challenges.add(challenge);
      await _saveLocalData();
      notifyListeners();
      return challenge;
    } catch (e) {
      debugPrint('Error creating challenge: $e');
      rethrow;
    }
  }

  /// Complete a habit in a challenge
  Future<void> completeHabit(String challengeId, int habitIndex) async {
    if (_supabase == null || _currentUserId == null) return;

    try {
      // Get current progress
      final progressResponse = await _supabase!
          .from('shared_chain_progress')
          .select()
          .eq('challenge_id', challengeId)
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      if (progressResponse == null) {
        debugPrint('No progress record found for challenge $challengeId');
        return;
      }

      final currentIndices =
          (progressResponse['completed_habit_indices'] as List<dynamic>?)
                  ?.cast<int>() ??
              [];

      if (!currentIndices.contains(habitIndex)) {
        currentIndices.add(habitIndex);

        await _supabase!
            .from('shared_chain_progress')
            .update({
              'completed_habit_indices': currentIndices,
              'last_completed_at': DateTime.now().toIso8601String(),
            })
            .eq('challenge_id', challengeId)
            .eq('user_id', _currentUserId!);
      }

      await refreshChallenges();
    } catch (e) {
      debugPrint('Error completing habit: $e');
    }
  }

  /// Delete a challenge (only creator can delete)
  Future<void> deleteChallenge(String challengeId) async {
    if (_supabase == null) return;

    try {
      await _supabase!
          .from('shared_chain_challenges')
          .delete()
          .eq('id', challengeId);
      _challenges.removeWhere((c) => c.id == challengeId);
      await _saveLocalData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting challenge: $e');
    }
  }

  /// Get challenges with a specific partner
  List<SharedChainChallenge> getChallengesWithPartner(String partnerId) {
    return _challenges
        .where((c) => c.partnerId == partnerId || c.createdBy == partnerId)
        .toList();
  }

  /// Clear all data (for logout)
  Future<void> clear() async {
    _challenges.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localStorageKey);
    notifyListeners();
  }
}
