import 'package:flutter/material.dart';

/// Predefined gradient presets for consistent branding
class AppGradients {
  // ========== Brand Gradients ==========

  /// Primary orange gradient (warm, energetic)
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFFFFA94A), Color(0xFFFFBB6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary teal gradient (fresh, calming)
  static const LinearGradient secondary = LinearGradient(
    colors: [Color(0xFF1FD1A5), Color(0xFF4ADBC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success gradient (green)
  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Error gradient (red)
  static const LinearGradient error = LinearGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warning gradient (orange-yellow)
  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFFFA94A), Color(0xFFFFCB74)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Info gradient (blue)
  static const LinearGradient info = LinearGradient(
    colors: [Color(0xFF4A90E2), Color(0xFF50C9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== Streak & Fire Gradients ==========

  /// Fire streak gradient (red-orange-yellow)
  static const LinearGradient fire = LinearGradient(
    colors: [
      Color(0xFFFF4500), // Orange red
      Color(0xFFFF6347), // Tomato
      Color(0xFFFFD700), // Gold
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Ice/Freeze gradient (cyan-blue)
  static const LinearGradient freeze = LinearGradient(
    colors: [
      Color(0xFF00CED1), // Dark turquoise
      Color(0xFF4FC3F7), // Light blue
      Color(0xFFE0F7FA), // Very light cyan
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== Milestone Gradients ==========

  /// Bronze milestone (7 days)
  static const LinearGradient bronze = LinearGradient(
    colors: [
      Color(0xFFCD7F32), // Bronze
      Color(0xFFD4AF37), // Gold accent
      Color(0xFFFFA500), // Orange
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Silver milestone (14 days)
  static const LinearGradient silver = LinearGradient(
    colors: [
      Color(0xFFC0C0C0), // Silver
      Color(0xFFE6E6FA), // Lavender
      Color(0xFF87CEEB), // Sky blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold milestone (30 days)
  static const LinearGradient gold = LinearGradient(
    colors: [
      Color(0xFFFFD700), // Gold
      Color(0xFFFFA500), // Orange
      Color(0xFFFFDF00), // Golden yellow
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Diamond milestone (100 days)
  static const LinearGradient diamond = LinearGradient(
    colors: [
      Color(0xFF00CED1), // Dark turquoise
      Color(0xFF4169E1), // Royal blue
      Color(0xFF9370DB), // Medium purple
      Color(0xFFFF69B4), // Hot pink
      Color(0xFFFFD700), // Gold
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== Premium Theme Gradients ==========

  /// Ocean theme (blue-teal)
  static const LinearGradient ocean = LinearGradient(
    colors: [
      Color(0xFF006994), // Deep sea
      Color(0xFF1E88E5), // Ocean blue
      Color(0xFF4FC3F7), // Light blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Forest theme (green)
  static const LinearGradient forest = LinearGradient(
    colors: [
      Color(0xFF1B5E20), // Dark green
      Color(0xFF43A047), // Green
      Color(0xFF81C784), // Light green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Sunset theme (orange-purple)
  static const LinearGradient sunset = LinearGradient(
    colors: [
      Color(0xFFFF6B6B), // Coral
      Color(0xFFFFD93D), // Yellow
      Color(0xFFFF9F1C), // Orange
      Color(0xFFE05297), // Pink
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Midnight theme (dark blue-purple)
  static const LinearGradient midnight = LinearGradient(
    colors: [
      Color(0xFF1A237E), // Indigo
      Color(0xFF311B92), // Deep purple
      Color(0xFF4A148C), // Purple
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Aurora theme (multi-color)
  static const LinearGradient aurora = LinearGradient(
    colors: [
      Color(0xFF00F260), // Green
      Color(0xFF0575E6), // Blue
      Color(0xFF9B59B6), // Purple
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Cherry Blossom theme (pink-purple)
  static const LinearGradient cherryBlossom = LinearGradient(
    colors: [
      Color(0xFFEF5350), // Light red
      Color(0xFFEC407A), // Pink
      Color(0xFFAB47BC), // Purple
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== Background Gradients ==========

  /// Subtle background gradient for dark mode
  static const LinearGradient darkBackground = LinearGradient(
    colors: [
      Color(0xFF0A0A0A), // Almost black
      Color(0xFF1A1A1A), // Dark gray
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Subtle background gradient for light mode
  static const LinearGradient lightBackground = LinearGradient(
    colors: [
      Color(0xFFFAFAFA), // Off white
      Color(0xFFF5F5F5), // Light gray
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ========== Card Gradients ==========

  /// Elevated card gradient (light)
  static LinearGradient cardLight = LinearGradient(
    colors: [
      Colors.white,
      Colors.white.withValues(alpha: 0.95),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Elevated card gradient (dark)
  static LinearGradient cardDark = LinearGradient(
    colors: [
      const Color(0xFF1E1E1E),
      const Color(0xFF1E1E1E).withValues(alpha: 0.95),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== Utility Methods ==========

  /// Create a gradient with custom opacity
  static LinearGradient withOpacity(LinearGradient gradient, double opacity) {
    return LinearGradient(
      colors: gradient.colors
          .map((color) => color.withValues(alpha: opacity))
          .toList(),
      begin: gradient.begin,
      end: gradient.end,
      stops: gradient.stops,
      tileMode: gradient.tileMode,
    );
  }

  /// Create a radial gradient version
  static RadialGradient toRadial(LinearGradient gradient) {
    return RadialGradient(
      colors: gradient.colors,
      center: Alignment.center,
      radius: 1.0,
    );
  }

  /// Shimmer loading gradient
  static LinearGradient shimmer(bool isDark) {
    final baseColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return LinearGradient(
      colors: [
        baseColor,
        highlightColor,
        baseColor,
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: const Alignment(-1.0, 0.0),
      end: const Alignment(1.0, 0.0),
      tileMode: TileMode.clamp,
    );
  }
}
