import 'package:flutter/material.dart';

/// Theme preset model for customization
class ThemePreset {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final LinearGradient primaryGradient;
  final LinearGradient secondaryGradient;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardColor;
  final bool isPremium;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardColor,
    this.isPremium = false,
  });

  // Predefined themes
  static const ThemePreset defaultTheme = ThemePreset(
    id: 'default',
    name: 'Default',
    description: 'Energetic orange and teal',
    emoji: '🎨',
    primaryGradient: LinearGradient(
      colors: [Color(0xFFFFA94A), Color(0xFFFFBB6E)],
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF1FD1A5), Color(0xFF4ADBC4)],
    ),
    accentColor: Color(0xFFFFA94A),
    backgroundColor: Color(0xFF121212),
    cardColor: Color(0xFF1E1E1E),
  );

  static const ThemePreset ocean = ThemePreset(
    id: 'ocean',
    name: 'Ocean',
    description: 'Calming blue and teal',
    emoji: '🌊',
    primaryGradient: LinearGradient(
      colors: [Color(0xFF006994), Color(0xFF1E88E5), Color(0xFF4FC3F7)],
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF00838F), Color(0xFF26C6DA)],
    ),
    accentColor: Color(0xFF4FC3F7),
    backgroundColor: Color(0xFF0A1929),
    cardColor: Color(0xFF132F4C),
    isPremium: true,
  );

  static const ThemePreset forest = ThemePreset(
    id: 'forest',
    name: 'Forest',
    description: 'Fresh green and natural',
    emoji: '🌲',
    primaryGradient: LinearGradient(
      colors: [Color(0xFF1B5E20), Color(0xFF43A047), Color(0xFF81C784)],
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    ),
    accentColor: Color(0xFF66BB6A),
    backgroundColor: Color(0xFF1B1B1B),
    cardColor: Color(0xFF1E3A1E),
    isPremium: true,
  );

  static const ThemePreset sunset = ThemePreset(
    id: 'sunset',
    name: 'Sunset',
    description: 'Warm orange and pink',
    emoji: '🌅',
    primaryGradient: LinearGradient(
      colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFFFF9F1C)],
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFFE05297), Color(0xFFFF6B6B)],
    ),
    accentColor: Color(0xFFFF9F1C),
    backgroundColor: Color(0xFF1A0F0F),
    cardColor: Color(0xFF2A1515),
    isPremium: true,
  );

  static const ThemePreset midnight = ThemePreset(
    id: 'midnight',
    name: 'Midnight',
    description: 'Deep purple and indigo',
    emoji: '🌙',
    primaryGradient: LinearGradient(
      colors: [Color(0xFF1A237E), Color(0xFF311B92), Color(0xFF4A148C)],
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    ),
    accentColor: Color(0xFF9C27B0),
    backgroundColor: Color(0xFF0D0D1A),
    cardColor: Color(0xFF1A1A2E),
    isPremium: true,
  );

  static const ThemePreset aurora = ThemePreset(
    id: 'aurora',
    name: 'Aurora',
    description: 'Magical green and blue',
    emoji: '✨',
    primaryGradient: LinearGradient(
      colors: [Color(0xFF00F260), Color(0xFF0575E6), Color(0xFF9B59B6)],
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    ),
    accentColor: Color(0xFF0575E6),
    backgroundColor: Color(0xFF0A0A1A),
    cardColor: Color(0xFF1A1A2E),
    isPremium: true,
  );

  static const ThemePreset cherry = ThemePreset(
    id: 'cherry',
    name: 'Cherry Blossom',
    description: 'Soft pink and purple',
    emoji: '🌸',
    primaryGradient: LinearGradient(
      colors: [Color(0xFFEF5350), Color(0xFFEC407A), Color(0xFFAB47BC)],
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFFBA68C8), Color(0xFFE91E63)],
    ),
    accentColor: Color(0xFFEC407A),
    backgroundColor: Color(0xFF1A0F14),
    cardColor: Color(0xFF2A1520),
    isPremium: true,
  );

  /// Get all available themes
  static List<ThemePreset> all() => [
        defaultTheme,
        ocean,
        forest,
        sunset,
        midnight,
        aurora,
        cherry,
      ];

  /// Get free themes only
  static List<ThemePreset> free() =>
      all().where((theme) => !theme.isPremium).toList();

  /// Get premium themes
  static List<ThemePreset> premium() =>
      all().where((theme) => theme.isPremium).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory ThemePreset.fromJson(Map<String, dynamic> json) {
    return all().firstWhere(
      (theme) => theme.id == json['id'],
      orElse: () => defaultTheme,
    );
  }
}
