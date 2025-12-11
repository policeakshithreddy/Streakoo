import 'package:flutter/material.dart';

/// Design tokens for consistent spacing, sizing, and layout
class DesignTokens {
  // ========== Spacing (4px grid system) ==========
  static const double space0 = 0;
  static const double space1 = 4.0; // 1 unit
  static const double space2 = 8.0; // 2 units
  static const double space3 = 12.0; // 3 units
  static const double space4 = 16.0; // 4 units
  static const double space5 = 20.0; // 5 units
  static const double space6 = 24.0; // 6 units
  static const double space8 = 32.0; // 8 units
  static const double space10 = 40.0; // 10 units
  static const double space12 = 48.0; // 12 units
  static const double space16 = 64.0; // 16 units
  static const double space20 = 80.0; // 20 units

  // ========== Border Radius ==========
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radius2XL = 24.0;
  static const double radiusFull = 9999.0;

  static BorderRadius get borderRadiusXS => BorderRadius.circular(radiusXS);
  static BorderRadius get borderRadiusSM => BorderRadius.circular(radiusSM);
  static BorderRadius get borderRadiusMD => BorderRadius.circular(radiusMD);
  static BorderRadius get borderRadiusLG => BorderRadius.circular(radiusLG);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadius2XL => BorderRadius.circular(radius2XL);

  // ========== Elevation / Shadows ==========

  /// No shadow
  static List<BoxShadow> get shadowNone => [];

  /// Subtle shadow for hover states
  static List<BoxShadow> shadowXS(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Light shadow for cards
  static List<BoxShadow> shadowSM(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Medium shadow for modals, dropdowns
  static List<BoxShadow> shadowMD(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 3,
          offset: const Offset(0, 2),
        ),
      ];

  /// Large shadow for floating elements
  static List<BoxShadow> shadowLG(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ];

  /// Extra large shadow for popovers
  static List<BoxShadow> shadowXL(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.15),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ];

  /// Maximum shadow for high-priority overlays
  static List<BoxShadow> shadow2XL(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  /// Colored glow effect
  static List<BoxShadow> glowSM(Color color, {double alpha = 0.3}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> glowMD(Color color, {double alpha = 0.4}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 16,
          spreadRadius: 4,
        ),
      ];

  static List<BoxShadow> glowLG(Color color, {double alpha = 0.5}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 24,
          spreadRadius: 6,
        ),
      ];

  // ========== Duration (Animations) ==========
  static const Duration durationInstant = Duration(milliseconds: 100);
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationSlower = Duration(milliseconds: 800);

  // ========== Icon Sizes ==========
  static const double iconXS = 12.0;
  static const double iconSM = 16.0;
  static const double iconMD = 20.0;
  static const double iconLG = 24.0;
  static const double iconXL = 32.0;
  static const double icon2XL = 40.0;
  static const double icon3XL = 48.0;

  // ========== Font Sizes ==========
  static const double fontSize2XS = 10.0;
  static const double fontSizeXS = 12.0;
  static const double fontSizeSM = 13.0;
  static const double fontSizeBase = 14.0;
  static const double fontSizeMD = 16.0;
  static const double fontSizeLG = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSize2XL = 24.0;
  static const double fontSize3XL = 30.0;
  static const double fontSize4XL = 36.0;
  static const double fontSize5XL = 48.0;

  // ========== Font Weights ==========
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // ========== Opacity Levels ==========
  static const double opacityDisabled = 0.4;
  static const double opacityMuted = 0.6;
  static const double opacitySubtle = 0.8;
  static const double opacityFull = 1.0;

  // ========== Z-Index (Stacking) ==========
  static const int zIndexBase = 0;
  static const int zIndexDropdown = 10;
  static const int zIndexSticky = 20;
  static const int zIndexFixed = 30;
  static const int zIndexModal = 40;
  static const int zIndexPopover = 50;
  static const int zIndexTooltip = 60;
  static const int zIndexNotification = 70;

  // ========== Breakpoints (Responsive) ==========
  static const double breakpointSM = 640.0;
  static const double breakpointMD = 768.0;
  static const double breakpointLG = 1024.0;
  static const double breakpointXL = 1280.0;

  // ========== Container Widths ==========
  static const double containerXS = 320.0;
  static const double containerSM = 384.0;
  static const double containerMD = 448.0;
  static const double containerLG = 512.0;
  static const double containerXL = 576.0;
  static const double container2XL = 672.0;
}
