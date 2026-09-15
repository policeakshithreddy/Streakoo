import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../widgets/tour_tooltip.dart';

/// Service to manage app-wide tour state and create tour instances
class TourService {
  TourService._();
  static final TourService instance = TourService._();

  /// Scroll a target widget into view before showing the tour step
  Future<void> scrollToTarget(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;

    try {
      // Find the nearest scrollable ancestor and scroll to make the target visible
      // Using a smooth cubic bezier curve for premium feel
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic, // Smoother acceleration and deceleration
        alignment:
            0.3, // Position at 30% from top for better visibility with tooltip
      );
      // Small delay to let the scroll complete and settle
      await Future.delayed(const Duration(milliseconds: 150));
    } catch (e) {
      debugPrint('⚠️ Could not scroll to target: $e');
    }
  }

  // SharedPreferences keys
  static const _keyHomeTour = 'tour_home_shown';
  static const _keySettingsTour = 'tour_settings_shown';
  static const _keyStatsTour = 'tour_stats_shown';
  static const _keyHealthTour = 'tour_health_shown';

  // Tour state
  bool _isLoaded = false;
  bool _hasShownHomeTour = false;
  bool _hasShownSettingsTour = false;
  bool _hasShownStatsTour = false;
  bool _hasShownHealthTour = false;

  // Getters
  bool get isLoaded => _isLoaded;
  bool get hasShownHomeTour => _hasShownHomeTour;
  bool get hasShownSettingsTour => _hasShownSettingsTour;
  bool get hasShownStatsTour => _hasShownStatsTour;
  bool get hasShownHealthTour => _hasShownHealthTour;

  /// Load tour state from SharedPreferences (only loads once per session)
  Future<void> loadTourState() async {
    // Only load once per session to prevent race conditions
    if (_isLoaded) {
      debugPrint('📚 Tour state already loaded this session');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    _hasShownHomeTour = prefs.getBool(_keyHomeTour) ?? false;
    _hasShownSettingsTour = prefs.getBool(_keySettingsTour) ?? false;
    _hasShownStatsTour = prefs.getBool(_keyStatsTour) ?? false;
    _hasShownHealthTour = prefs.getBool(_keyHealthTour) ?? false;

    _isLoaded = true;

    debugPrint(
        '📚 Tour state loaded - Home: $_hasShownHomeTour, Settings: $_hasShownSettingsTour, Stats: $_hasShownStatsTour, Health: $_hasShownHealthTour');
  }

  /// Mark a specific tour as shown
  Future<void> markTourAsShown(String tourId) async {
    final prefs = await SharedPreferences.getInstance();

    switch (tourId) {
      case 'home':
        _hasShownHomeTour = true;
        await prefs.setBool(_keyHomeTour, true);
        break;
      case 'settings':
        _hasShownSettingsTour = true;
        await prefs.setBool(_keySettingsTour, true);
        break;
      case 'stats':
        _hasShownStatsTour = true;
        await prefs.setBool(_keyStatsTour, true);
        break;
      case 'health':
        _hasShownHealthTour = true;
        await prefs.setBool(_keyHealthTour, true);
        break;
    }

    debugPrint('✅ Tour marked as shown: $tourId');
  }

  /// Reset all tours (for "Show Tour Again" feature)
  Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();

    _hasShownHomeTour = false;
    _hasShownSettingsTour = false;
    _hasShownStatsTour = false;
    _hasShownHealthTour = false;

    await prefs.setBool(_keyHomeTour, false);
    await prefs.setBool(_keySettingsTour, false);
    await prefs.setBool(_keyStatsTour, false);
    await prefs.setBool(_keyHealthTour, false);

    debugPrint('🔄 All tours reset');
  }

  /// Create a TutorialCoachMark instance with the given targets
  TutorialCoachMark createTour({
    required List<TargetFocus> targets,
    required VoidCallback onFinish,
    required VoidCallback onSkip,
    Color overlayColor = const Color(0xCC000000),
  }) {
    return TutorialCoachMark(
      targets: targets,
      colorShadow: overlayColor,
      paddingFocus: 10,
      opacityShadow: 0.85,
      imageFilter: null,
      // Smooth transition settings - spotlight moves directly to next target
      focusAnimationDuration: const Duration(milliseconds: 400),
      unFocusAnimationDuration:
          Duration.zero, // Skip the unfocus animation for smooth transitions
      pulseAnimationDuration: const Duration(milliseconds: 800),
      pulseEnable: true, // Gentle pulse to draw attention
      // Skip animation for seamless target-to-target transitions
      skipWidget: const SizedBox.shrink(), // Hide default skip widget
      onFinish: onFinish,
      onSkip: () {
        onSkip();
        return true; // Return true to allow skip
      },
      hideSkip: true, // We have our own skip button in tooltip
    );
  }

  /// Create a target focus with tooltip
  TargetFocus createTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String description,
    required int currentStep,
    required int totalSteps,
    required VoidCallback onNext,
    required VoidCallback onSkip,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
    double radius = 16,
    ContentAlign align = ContentAlign.bottom,
  }) {
    final isLastStep = currentStep == totalSteps;

    return TargetFocus(
      identify: identify,
      keyTarget: keyTarget,
      shape: shape,
      radius: radius,
      paddingFocus: 12,
      // Smooth animation settings for each target
      focusAnimationDuration: const Duration(milliseconds: 400),
      unFocusAnimationDuration:
          Duration.zero, // No unfocus delay for smooth transitions
      enableOverlayTab: true, // Allow tapping overlay to go to next step
      enableTargetTab: false, // Prevent accidental taps on target
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return TourTooltip(
              title: title,
              description: description,
              currentStep: currentStep,
              totalSteps: totalSteps,
              isLastStep: isLastStep,
              onNext: onNext,
              onSkip: onSkip,
            );
          },
        ),
      ],
    );
  }
}
