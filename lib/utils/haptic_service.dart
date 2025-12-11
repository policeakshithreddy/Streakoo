import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Centralized haptic feedback service for consistent tactile responses
class HapticService {
  static final HapticService instance = HapticService._();
  HapticService._();

  bool _isEnabled = true;
  bool _hasVibrator = true;

  /// Initialize and check device capabilities
  Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator();
    } catch (e) {
      _hasVibrator = false;
    }
  }

  /// Enable/disable haptic feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  // ========== Feedback Types ==========

  /// Light tap (button press, checkbox)
  Future<void> light() async {
    if (!_isEnabled) return;

    try {
      if (_hasVibrator) {
        await Vibration.vibrate(duration: 10, amplitude: 50);
      } else {
        await HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Fallback to system haptic
      await HapticFeedback.lightImpact();
    }
  }

  /// Medium impact (swipe action, toggle)
  Future<void> medium() async {
    if (!_isEnabled) return;

    try {
      if (_hasVibrator) {
        await Vibration.vibrate(duration: 20, amplitude: 100);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Heavy impact (major action, completion)
  Future<void> heavy() async {
    if (!_isEnabled) return;

    try {
      if (_hasVibrator) {
        await Vibration.vibrate(duration: 30, amplitude: 150);
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Selection changed (picker, dropdown)
  Future<void> selection() async {
    if (!_isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Success feedback (habit completed, milestone)
  Future<void> success() async {
    if (!_isEnabled) return;

    try {
      if (_hasVibrator) {
        // Double tap pattern
        await Vibration.vibrate(duration: 50, amplitude: 120);
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 50, amplitude: 150);
      } else {
        await heavy();
      }
    } catch (e) {
      await heavy();
    }
  }

  /// Error feedback (form validation, action failed)
  Future<void> error() async {
    if (!_isEnabled) return;

    try {
      if (_hasVibrator) {
        // Triple short tap pattern
        for (int i = 0; i < 3; i++) {
          await Vibration.vibrate(duration: 30, amplitude: 100);
          if (i < 2) await Future.delayed(const Duration(milliseconds: 80));
        }
      } else {
        await medium();
      }
    } catch (e) {
      await medium();
    }
  }

  /// Warning feedback (streak at risk)
  Future<void> warning() async {
    if (!_isEnabled) return;

    try {
      if (_hasVibrator) {
        // Long-short pattern
        await Vibration.vibrate(duration: 100, amplitude: 130);
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 50, amplitude: 100);
      } else {
        await medium();
      }
    } catch (e) {
      await medium();
    }
  }

  /// Celebration feedback (level up, milestone)
  Future<void> celebration() async {
    if (!_isEnabled) return;

    try {
      if (_hasVibrator) {
        // Rising intensity pattern
        await Vibration.vibrate(duration: 50, amplitude: 80);
        await Future.delayed(const Duration(milliseconds: 80));
        await Vibration.vibrate(duration: 50, amplitude: 120);
        await Future.delayed(const Duration(milliseconds: 80));
        await Vibration.vibrate(duration: 100, amplitude: 180);
      } else {
        await heavy();
      }
    } catch (e) {
      await heavy();
    }
  }

  /// Notification received
  Future<void> notification() async {
    if (!_isEnabled) return;

    try {
      if (_hasVibrator) {
        await Vibration.vibrate(duration: 40, amplitude: 100);
      } else {
        await medium();
      }
    } catch (e) {
      await medium();
    }
  }

  /// Custom pattern
  Future<void> custom({
    required int duration,
    int amplitude = 128,
  }) async {
    if (!_isEnabled) return;

    try {
      if (_hasVibrator) {
        await Vibration.vibrate(
          duration: duration,
          amplitude: amplitude,
        );
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      await HapticFeedback.mediumImpact();
    }
  }
}
