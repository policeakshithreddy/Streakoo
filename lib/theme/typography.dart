import 'package:flutter/material.dart';

/// Enhanced typography system for consistent text styling
class AppTypography {
  // ========== Display (Large headlines) ==========

  static TextStyle display1({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 48,
        fontWeight: fontWeight ?? FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
        color: color,
      );

  static TextStyle display2({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 36,
        fontWeight: fontWeight ?? FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: color,
      );

  // ========== Headings ==========

  static TextStyle h1({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 30,
        fontWeight: fontWeight ?? FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
        color: color,
      );

  static TextStyle h2({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 24,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: color,
      );

  static TextStyle h3({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 20,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.3,
        color: color,
      );

  static TextStyle h4({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 18,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 1.4,
        color: color,
      );

  static TextStyle h5({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 16,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 1.4,
        color: color,
      );

  static TextStyle h6({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 1.4,
        color: color,
      );

  // ========== Body Text ==========

  static TextStyle bodyLarge({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 16,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
        color: color,
      );

  static TextStyle body({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
        color: color,
      );

  static TextStyle bodySmall({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 13,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.1,
        color: color,
      );

  // ========== Labels & Captions ==========

  static TextStyle label({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.4,
        color: color,
      );

  static TextStyle caption({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 11,
        fontWeight: fontWeight ?? FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.3,
        color: color,
      );

  static TextStyle overline({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 10,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: 1.5,
        height: 1.6,
        color: color,
      ).apply(fontFeatures: [const FontFeature.enable('smcp')]);

  // ========== Buttons ==========

  static TextStyle buttonLarge({Color? color}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.2,
        color: color,
      );

  static TextStyle button({Color? color}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.2,
        color: color,
      );

  static TextStyle buttonSmall({Color? color}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.2,
        color: color,
      );

  // ========== Special ==========

  /// For numbers and stats
  static TextStyle stat({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: 32,
        fontWeight: fontWeight ?? FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  /// For monospaced numbers
  static TextStyle mono({
    Color? color,
    double? fontSize,
  }) =>
      TextStyle(
        fontSize: fontSize ?? 14,
        fontFamily: 'monospace',
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.5,
        color: color,
      );

  /// For code blocks
  static TextStyle code({
    Color? color,
    double? fontSize,
  }) =>
      TextStyle(
        fontSize: fontSize ?? 13,
        fontFamily: 'monospace',
        height: 1.6,
        letterSpacing: 0,
        color: color,
      );
}

/// Text theme configuration for MaterialApp
class AppTextTheme {
  static TextTheme light = const TextTheme(
    displayLarge: TextStyle(
        fontSize: 48, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
    displayMedium: TextStyle(
        fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
    displaySmall: TextStyle(
        fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
    headlineLarge: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    headlineSmall: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    titleLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    titleMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    titleSmall: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF1A1A1A)),
    bodyMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF1A1A1A)),
    bodySmall: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF616161)),
    labelLarge: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF616161)),
    labelMedium: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF757575)),
    labelSmall: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF757575)),
  );

  static TextTheme dark = const TextTheme(
    displayLarge: TextStyle(
        fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white),
    displayMedium: TextStyle(
        fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
    displaySmall: TextStyle(
        fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
    headlineLarge: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
    headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
    headlineSmall: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
    titleLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
    titleMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
    titleSmall: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
    bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
    bodyMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
    bodySmall: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFB0B0B0)),
    labelLarge: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFB0B0B0)),
    labelMedium: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF909090)),
    labelSmall: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF909090)),
  );
}
