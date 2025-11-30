import 'package:shared_preferences/shared_preferences.dart';

import '../models/celebration_theme.dart';

/// Service to manage celebration theme selection and persistence
class CelebrationThemeService {
  static final CelebrationThemeService instance = CelebrationThemeService._();
  CelebrationThemeService._();

  static const String _prefsKey = 'celebration_theme';

  CelebrationType _currentTheme = CelebrationType.party;
  int _userLevel = 1;

  /// Get current theme
  CelebrationType get currentTheme => _currentTheme;

  /// Get current theme object
  CelebrationTheme get currentThemeObject {
    return CelebrationTheme.getByType(_currentTheme);
  }

  /// Initialize theme from preferences
  Future<void> initialize(int userLevel) async {
    _userLevel = userLevel;
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_prefsKey);

    if (themeIndex != null && themeIndex < CelebrationType.values.length) {
      final theme = CelebrationType.values[themeIndex];
      final themeObj = CelebrationTheme.getByType(theme);

      // Only set theme if user has unlocked it
      if (userLevel >= themeObj.unlockLevel) {
        _currentTheme = theme;
      }
    }
  }

  /// Set theme (only if unlocked)
  Future<bool> setTheme(CelebrationType theme) async {
    final themeObj = CelebrationTheme.getByType(theme);

    // Check if unlocked
    if (_userLevel < themeObj.unlockLevel) {
      return false;
    }

    _currentTheme = theme;

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, theme.index);

    return true;
  }

  /// Update user level (may unlock new themes)
  void updateUserLevel(int level) {
    _userLevel = level;
  }

  /// Get all themes with unlock status
  List<CelebrationTheme> getAllThemesWithStatus() {
    return CelebrationTheme.allThemes
        .map((theme) => CelebrationTheme.withUnlockStatus(theme, _userLevel))
        .toList();
  }

  /// Get unlocked themes
  List<CelebrationTheme> getUnlockedThemes() {
    return CelebrationTheme.getUnlockedThemes(_userLevel);
  }

  /// Check if theme is unlocked
  bool isThemeUnlocked(CelebrationType theme) {
    final themeObj = CelebrationTheme.getByType(theme);
    return _userLevel >= themeObj.unlockLevel;
  }
}
