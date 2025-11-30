import 'package:flutter/material.dart';

/// Celebration theme types
enum CelebrationType {
  party, // Default - confetti, balloons, vibrant colors
  cosmic, // Stars, galaxies, purple/blue
  zen, // Cherry blossoms, calm, peaceful
  fire, // Flames, sparks, orange/red
}

/// Celebration theme configuration
class CelebrationTheme {
  final CelebrationType type;
  final String name;
  final String description;
  final String emoji;
  final List<Color> confettiColors;
  final List<Color> backgroundGradient;
  final Color primaryColor;
  final bool unlocked;
  final int unlockLevel;

  const CelebrationTheme({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    required this.confettiColors,
    required this.backgroundGradient,
    required this.primaryColor,
    this.unlocked = false,
    this.unlockLevel = 1,
  });

  /// Party theme (default - always unlocked)
  static const CelebrationTheme party = CelebrationTheme(
    type: CelebrationType.party,
    name: 'Party',
    description: 'Vibrant confetti and balloons',
    emoji: '🎉',
    confettiColors: [
      Color(0xFFFF6B6B), // Red
      Color(0xFF4ECDC4), // Turquoise
      Color(0xFFFFE66D), // Yellow
      Color(0xFF95E1D3), // Mint
      Color(0xFFF38181), // Pink
      Color(0xFFA8E6CF), // Light green
    ],
    backgroundGradient: [
      Color(0xFFFF9966),
      Color(0xFFFF5E62),
    ],
    primaryColor: Color(0xFFFF6B6B),
    unlocked: true,
    unlockLevel: 1,
  );

  /// Cosmic theme (unlock at level 5)
  static const CelebrationTheme cosmic = CelebrationTheme(
    type: CelebrationType.cosmic,
    name: 'Cosmic',
    description: 'Stars and galaxies from outer space',
    emoji: '🌟',
    confettiColors: [
      Color(0xFF9D4EDD), // Purple
      Color(0xFF5A189A), // Dark purple
      Color(0xFF4361EE), // Blue
      Color(0xFF4CC9F0), // Cyan
      Color(0xFFFFD60A), // Gold stars
      Color(0xFFFFFFFF), // White sparkles
    ],
    backgroundGradient: [
      Color(0xFF5A189A),
      Color(0xFF240046),
    ],
    primaryColor: Color(0xFF9D4EDD),
    unlocked: false,
    unlockLevel: 5,
  );

  /// Zen theme (unlock at level 15)
  static const CelebrationTheme zen = CelebrationTheme(
    type: CelebrationType.zen,
    name: 'Zen',
    description: 'Peaceful cherry blossoms and calm vibes',
    emoji: '🌸',
    confettiColors: [
      Color(0xFFFFB7C5), // Light pink
      Color(0xFFFFDAE9), // Very light pink
      Color(0xFFF8BBD0), // Pink
      Color(0xFFE1BEE7), // Lavender
      Color(0xFFBBDEFB), // Light blue
      Color(0xFFC8E6C9), // Light green
    ],
    backgroundGradient: [
      Color(0xFFFFE5EC),
      Color(0xFFE1BEE7),
    ],
    primaryColor: Color(0xFFFFB7C5),
    unlocked: false,
    unlockLevel: 15,
  );

  /// Fire theme (unlock at level 25)
  static const CelebrationTheme fire = CelebrationTheme(
    type: CelebrationType.fire,
    name: 'Fire',
    description: 'Blazing flames and explosive sparks',
    emoji: '🔥',
    confettiColors: [
      Color(0xFFFF4500), // Orange red
      Color(0xFFFF6347), // Tomato
      Color(0xFFFF8C00), // Dark orange
      Color(0xFFFFD700), // Gold
      Color(0xFFFFA500), // Orange
      Color(0xFFDC143C), // Crimson
    ],
    backgroundGradient: [
      Color(0xFFFF4500),
      Color(0xFFDC143C),
    ],
    primaryColor: Color(0xFFFF4500),
    unlocked: false,
    unlockLevel: 25,
  );

  /// Get all available themes
  static List<CelebrationTheme> get allThemes => [
        party,
        cosmic,
        zen,
        fire,
      ];

  /// Get theme by type
  static CelebrationTheme getByType(CelebrationType type) {
    switch (type) {
      case CelebrationType.party:
        return party;
      case CelebrationType.cosmic:
        return cosmic;
      case CelebrationType.zen:
        return zen;
      case CelebrationType.fire:
        return fire;
    }
  }

  /// Check if theme is unlocked at a given level
  static CelebrationTheme withUnlockStatus(
    CelebrationTheme theme,
    int currentLevel,
  ) {
    return CelebrationTheme(
      type: theme.type,
      name: theme.name,
      description: theme.description,
      emoji: theme.emoji,
      confettiColors: theme.confettiColors,
      backgroundGradient: theme.backgroundGradient,
      primaryColor: theme.primaryColor,
      unlocked: currentLevel >= theme.unlockLevel,
      unlockLevel: theme.unlockLevel,
    );
  }

  /// Get unlocked themes for current level
  static List<CelebrationTheme> getUnlockedThemes(int currentLevel) {
    return allThemes
        .where((theme) => currentLevel >= theme.unlockLevel)
        .toList();
  }
}
