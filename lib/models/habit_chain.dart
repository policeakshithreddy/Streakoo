import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Model for a chain of linked habits
/// "After I do X, I will do Y" - habit stacking
class HabitChain {
  final String id;
  final String name;
  final List<String> habitIds; // Ordered list of habit IDs
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const HabitChain({
    required this.id,
    required this.name,
    required this.habitIds,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  HabitChain copyWith({
    String? name,
    List<String>? habitIds,
    String? description,
    bool? isActive,
  }) {
    return HabitChain(
      id: id,
      name: name ?? this.name,
      habitIds: habitIds ?? this.habitIds,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'habitIds': habitIds,
        'description': description,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HabitChain.fromJson(Map<String, dynamic> json) => HabitChain(
        id: json['id'] as String,
        name: json['name'] as String,
        habitIds: (json['habitIds'] as List<dynamic>).cast<String>(),
        description: json['description'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Manager service for Habit Chains
class HabitChainService extends ChangeNotifier {
  static final HabitChainService _instance = HabitChainService._();
  static HabitChainService get instance => _instance;
  HabitChainService._();

  List<HabitChain> _chains = [];
  List<HabitChain> get chains => _chains;
  List<HabitChain> get activeChains =>
      _chains.where((c) => c.isActive).toList();

  static const String _storageKey = 'habit_chains';

  /// Initialize and load chains from storage
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chainsJson = prefs.getString(_storageKey);

      if (chainsJson != null) {
        final List<dynamic> decoded = jsonDecode(chainsJson);
        _chains = decoded.map((e) => HabitChain.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading habit chains: $e');
    }
    notifyListeners();
  }

  /// Save chains to storage
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_chains.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving habit chains: $e');
    }
  }

  /// Create a new chain
  Future<void> createChain({
    required String name,
    required List<String> habitIds,
    String? description,
  }) async {
    if (habitIds.length < 2) {
      throw ArgumentError('A chain must have at least 2 habits');
    }

    final chain = HabitChain(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      habitIds: habitIds,
      description: description,
      createdAt: DateTime.now(),
    );

    _chains.add(chain);
    await _save();
    notifyListeners();
  }

  /// Update an existing chain
  Future<void> updateChain(HabitChain chain) async {
    final index = _chains.indexWhere((c) => c.id == chain.id);
    if (index != -1) {
      _chains[index] = chain;
      await _save();
      notifyListeners();
    }
  }

  /// Delete a chain
  Future<void> deleteChain(String chainId) async {
    _chains.removeWhere((c) => c.id == chainId);
    await _save();
    notifyListeners();
  }

  /// Toggle chain active status
  Future<void> toggleChainActive(String chainId) async {
    final chain = _chains.firstWhere((c) => c.id == chainId);
    await updateChain(chain.copyWith(isActive: !chain.isActive));
  }

  /// Get the next habit in a chain after completing one
  String? getNextHabitInChain(String completedHabitId) {
    for (final chain in activeChains) {
      final index = chain.habitIds.indexOf(completedHabitId);
      if (index != -1 && index < chain.habitIds.length - 1) {
        return chain.habitIds[index + 1];
      }
    }
    return null;
  }

  /// Get chains containing a specific habit
  List<HabitChain> getChainsForHabit(String habitId) {
    return _chains.where((c) => c.habitIds.contains(habitId)).toList();
  }

  /// Check if a habit is part of any chain
  bool isHabitInChain(String habitId) {
    return _chains.any((c) => c.habitIds.contains(habitId));
  }

  /// Get the chain a habit belongs to (if any)
  HabitChain? getChainForHabit(String habitId) {
    try {
      return activeChains.firstWhere((c) => c.habitIds.contains(habitId));
    } catch (e) {
      return null;
    }
  }

  /// Get progress in a chain (how many habits completed in sequence)
  int getChainProgress(HabitChain chain, Set<String> completedToday) {
    int count = 0;
    for (final habitId in chain.habitIds) {
      if (completedToday.contains(habitId)) {
        count++;
      } else {
        break; // Stop at first not-completed habit
      }
    }
    return count;
  }
}
