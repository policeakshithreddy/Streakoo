import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _accentOrange = Color(0xFFFFA94A); // soft orange
  static const _accentTeal = Color(0xFF1FD1A5); // mint/teal

  // Dark theme colors
  static const _bgDark = Color(0xFF121212); // Modern dark background
  static const _cardDark = Color(0xFF1E1E1E); // Slightly lighter cards

  // Light theme colors
  static const _bgLight = Color(0xFFF8F9FA); // Soft off-white background
  static const _cardLight = Color(0xFFFFFFFF); // White cards

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _bgLight,
      // iOS-style page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: _accentOrange,
        secondary: _accentTeal,
        surface: _cardLight,
        onSurface: Color(0xFF1A1A1A),
      ),
    );

    return base.copyWith(
      // iOS-style app bar (minimal, blur effect)
      appBarTheme: AppBarTheme(
        backgroundColor: _bgLight.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: true, // Center alignment
        foregroundColor: const Color(0xFF1A1A1A),
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFF1A1A1A),
          fontSize: 18, // Normal size
          fontWeight: FontWeight.w600, // Semi-bold, not too heavy
          letterSpacing: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _bgLight.withValues(alpha: 0.95),
        indicatorColor: _accentOrange.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 65,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentOrange,
        foregroundColor: Colors.white,
        elevation: 4, // Subtle iOS elevation
        // Don't force shape - let extended FABs be pill-shaped
      ),
      // iOS-style cards with minimal shadows
      cardTheme: CardThemeData(
        color: _cardLight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // iOS corner radius
        ),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
      // iOS interaction feedback
      splashFactory: NoSplash.splashFactory, // Remove Material ripples
      highlightColor: Colors.transparent,
      // iOS-style buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323232), // Dark gray for light theme
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme()
          .apply(
            bodyColor: const Color(0xFF1A1A1A),
            displayColor: const Color(0xFF1A1A1A),
          )
          .copyWith(
            // iOS-style text with explicit colors for light theme
            headlineLarge: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: const Color(0xFF1A1A1A),
            ),
            headlineMedium: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              color: const Color(0xFF1A1A1A),
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            titleMedium: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            titleSmall: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 17,
              letterSpacing: -0.4,
              color: const Color(0xFF1A1A1A),
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 15,
              letterSpacing: -0.2,
              color: const Color(0xFF1A1A1A),
            ),
            bodySmall: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF666666),
            ),
            labelLarge: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            labelMedium: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            labelSmall: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF666666),
            ),
          ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bgDark,
      // iOS-style page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.dark(
        primary: _accentOrange,
        secondary: _accentTeal,
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: _bgDark.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: true, // Center alignment
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18, // Normal size
          fontWeight: FontWeight.w600, // Semi-bold, not too heavy
          letterSpacing: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _bgDark.withValues(alpha: 0.95),
        indicatorColor: _accentOrange.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 65,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentOrange,
        foregroundColor: Colors.black,
        elevation: 4,
        // Don't force shape - let extended FABs be pill-shaped
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFF4A4A4A), // Lighter soft gray for dark theme
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme()
          .apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          )
          .copyWith(
            headlineLarge: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
            headlineMedium: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 17,
              letterSpacing: -0.4,
              color: Colors.white,
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 15,
              letterSpacing: -0.2,
              color: Colors.white,
            ),
          ),
    );
  }
}
