import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Global animation configuration for device-adaptive animations.
/// Automatically detects device capability and adjusts animation complexity.
class AnimationConfig {
  static AnimationConfig? _instance;
  static AnimationConfig get instance => _instance ??= AnimationConfig._();

  AnimationConfig._();

  bool _initialized = false;
  bool _isLowEndDevice = false;
  bool _animationsEnabled = true;
  double _refreshRate = 60.0;

  bool get isLowEndDevice => _isLowEndDevice;
  bool get animationsEnabled => _animationsEnabled;
  bool get isHighRefreshRate => _refreshRate > 60;

  /// Duration multiplier: 1.0 = normal, 0.6 = faster for low-end devices
  double get durationMultiplier {
    if (!_animationsEnabled) return 0.0;
    if (_isLowEndDevice) return 0.6;
    return 1.0;
  }

  // ========== STANDARD DURATIONS ==========
  /// Ultra fast (100ms) - for micro-interactions like button press
  Duration get ultraFast =>
      Duration(milliseconds: (100 * durationMultiplier).round());

  /// Fast (200ms) - for quick transitions
  Duration get fast =>
      Duration(milliseconds: (200 * durationMultiplier).round());

  /// Medium (350ms) - for standard animations
  Duration get medium =>
      Duration(milliseconds: (350 * durationMultiplier).round());

  /// Slow (500ms) - for emphasis animations
  Duration get slow =>
      Duration(milliseconds: (500 * durationMultiplier).round());

  /// Stagger delay between list items (40ms on normal, 25ms on low-end)
  Duration get staggerDelay =>
      Duration(milliseconds: (40 * durationMultiplier).round());

  // ========== ANIMATION COMPLEXITY ==========
  /// Whether to use complex effects like blur, shadows, etc.
  bool get useComplexEffects => !_isLowEndDevice;

  /// Whether to use particle effects (confetti, etc.)
  bool get useParticleEffects => !_isLowEndDevice;

  /// Max number of simultaneous animations (fewer on low-end)
  int get maxSimultaneousAnimations => _isLowEndDevice ? 3 : 8;

  // ========== INITIALIZATION ==========
  Future<void> init() async {
    if (_initialized) return;

    _isLowEndDevice = await _detectLowEndDevice();
    _refreshRate = await _detectRefreshRate();
    _initialized = true;

    debugPrint('🎬 AnimationConfig initialized:');
    debugPrint('   - Low-end device: $_isLowEndDevice');
    debugPrint('   - Refresh rate: ${_refreshRate.round()}Hz');
    debugPrint('   - Duration multiplier: $durationMultiplier');
  }

  /// Toggle animations on/off (for accessibility)
  void setAnimationsEnabled(bool enabled) {
    _animationsEnabled = enabled;
  }

  Future<bool> _detectLowEndDevice() async {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        // Read RAM from /proc/meminfo
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final content = await file.readAsString();
          final match = RegExp(r'MemTotal:\s+(\d+)').firstMatch(content);
          if (match != null) {
            final ramMB = int.parse(match.group(1)!) ~/ 1024;
            // Devices with less than 3GB RAM are considered low-end
            return ramMB < 3000;
          }
        }
      }
      // iOS devices are generally capable, default to false
      return false;
    } catch (e) {
      debugPrint('Could not detect device capability: $e');
      return false;
    }
  }

  Future<double> _detectRefreshRate() async {
    try {
      // Use SchedulerBinding to get display refresh rate
      final window = SchedulerBinding.instance.platformDispatcher.views.first;
      final refreshRate = window.display.refreshRate;
      return refreshRate > 0 ? refreshRate : 60.0;
    } catch (e) {
      return 60.0;
    }
  }
}
