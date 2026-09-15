import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pet accessory item
class PetAccessory {
  final String id;
  final String name;
  final String emoji;
  final String category; // hat, glasses, badge, etc.
  final int requiredLevel;
  final bool isPremium;

  const PetAccessory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.requiredLevel = 0,
    this.isPremium = false,
  });
}

/// Pet theme (different animal types)
class PetTheme {
  final String id;
  final String name;
  final Map<int, String> stageEmojis; // level -> emoji
  final bool isPremium;
  final int requiredLevel;

  const PetTheme({
    required this.id,
    required this.name,
    required this.stageEmojis,
    required this.requiredLevel,
    this.isPremium = false,
  });

  String getEmoji(int level) {
    // Find highest matching stage
    int bestLevel = 0;
    for (final l in stageEmojis.keys) {
      if (l <= level && l > bestLevel) {
        bestLevel = l;
      }
    }
    return stageEmojis[bestLevel] ?? '🐣';
  }
}

/// Pet customization service
class PetCustomizationService {
  static final instance = PetCustomizationService._();
  PetCustomizationService._();

  static const String _accessoryKey = 'pet_equipped_accessory';
  static const String _themeKey = 'pet_theme';

  String? _equippedAccessoryId;
  String _currentThemeId = 'chicken';

  // Available accessories (unlocked by level)
  static const List<PetAccessory> accessories = [
    PetAccessory(
        id: 'crown',
        name: 'Crown',
        emoji: '👑',
        category: 'hat',
        requiredLevel: 10),
    PetAccessory(
        id: 'sunglasses',
        name: 'Sunglasses',
        emoji: '🕶️',
        category: 'glasses',
        requiredLevel: 5),
    PetAccessory(
        id: 'party_hat',
        name: 'Party Hat',
        emoji: '🎉',
        category: 'hat',
        requiredLevel: 7),
    PetAccessory(
        id: 'halo',
        name: 'Halo',
        emoji: '😇',
        category: 'hat',
        requiredLevel: 15),
    PetAccessory(
        id: 'headphones',
        name: 'Headphones',
        emoji: '🎧',
        category: 'accessory',
        requiredLevel: 12),
    PetAccessory(
        id: 'bow',
        name: 'Bow',
        emoji: '🎀',
        category: 'accessory',
        requiredLevel: 3),
    PetAccessory(
        id: 'star',
        name: 'Star',
        emoji: '⭐',
        category: 'badge',
        requiredLevel: 20),
    PetAccessory(
        id: 'fire',
        name: 'On Fire',
        emoji: '🔥',
        category: 'badge',
        requiredLevel: 25),
    PetAccessory(
        id: 'rainbow',
        name: 'Rainbow',
        emoji: '🌈',
        category: 'badge',
        requiredLevel: 30),
    PetAccessory(
        id: 'rocket',
        name: 'Rocket',
        emoji: '🚀',
        category: 'badge',
        requiredLevel: 35),
  ];

  // Available pet themes
  static final List<PetTheme> themes = [
    const PetTheme(
      id: 'chicken',
      name: 'Chicken',
      stageEmojis: {
        0: '🥚',
        2: '🐣',
        5: '🐥',
        10: '🐤',
        20: '🐔',
        35: '🐓',
        50: '🦅'
      },
      requiredLevel: 1,
    ),
  ];

  String? get equippedAccessoryId => _equippedAccessoryId;
  String get currentThemeId => _currentThemeId;

  PetAccessory? get equippedAccessory => _equippedAccessoryId != null
      ? accessories.firstWhere((a) => a.id == _equippedAccessoryId,
          orElse: () => accessories.first)
      : null;

  PetTheme get currentTheme => themes.firstWhere((t) => t.id == _currentThemeId,
      orElse: () => themes.first);

  List<PetAccessory> getUnlockedAccessories(int userLevel) {
    return accessories
        .where((a) => !a.isPremium && a.requiredLevel <= userLevel)
        .toList();
  }

  List<PetTheme> getUnlockedThemes(int userLevel) {
    return themes.where((t) => !t.isPremium).toList();
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _equippedAccessoryId = prefs.getString(_accessoryKey);
    _currentThemeId = prefs.getString(_themeKey) ?? 'chicken';
    debugPrint(
        '🎨 Pet customization loaded: accessory=$_equippedAccessoryId, theme=$_currentThemeId');
  }

  Future<void> equipAccessory(String? accessoryId) async {
    _equippedAccessoryId = accessoryId;
    final prefs = await SharedPreferences.getInstance();
    if (accessoryId != null) {
      await prefs.setString(_accessoryKey, accessoryId);
    } else {
      await prefs.remove(_accessoryKey);
    }
    debugPrint('👑 Equipped accessory: $accessoryId');
  }

  Future<void> setTheme(String themeId) async {
    _currentThemeId = themeId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeId);
    debugPrint('🐱 Set pet theme: $themeId');
  }
}
