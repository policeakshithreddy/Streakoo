import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';

/// Service for managing Siri Shortcuts (iOS) and Google Assistant actions (Android)
class VoiceShortcutService {
  static final VoiceShortcutService instance = VoiceShortcutService._();
  VoiceShortcutService._();

  static const _channel = MethodChannel('com.streakoo/shortcuts');

  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up method call handler for incoming shortcut invocations
      _channel.setMethodCallHandler(_handleMethodCall);
      _isInitialized = true;
      debugPrint('🎙️ VoiceShortcutService initialized');
    } catch (e) {
      debugPrint('Failed to initialize VoiceShortcutService: $e');
    }
  }

  /// Handle incoming method calls from native code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'completeHabit':
        final habitId = call.arguments['habitId'] as String?;
        if (habitId != null) {
          await _onShortcutCompleteHabit(habitId);
        }
        return true;

      case 'openApp':
        // Just opens the app, nothing special to do
        return true;

      default:
        throw MissingPluginException('Unknown method: ${call.method}');
    }
  }

  /// Called when a Siri shortcut completes a habit
  Future<void> _onShortcutCompleteHabit(String habitId) async {
    // This will be handled by the app when it opens
    // We store the pending action and the main.dart will read it
    debugPrint('🎙️ Shortcut requested to complete habit: $habitId');

    // You would typically store this in shared preferences and have
    // the app check for pending shortcut actions on startup
  }

  /// Register shortcuts for all habits
  Future<void> registerShortcuts(List<Habit> habits) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      final shortcutData = habits
          .map((habit) => {
                'id': habit.id,
                'name': habit.name,
                'emoji': habit.emoji,
                'suggestedPhrase': 'Complete ${habit.name}',
              })
          .toList();

      await _channel.invokeMethod('registerShortcuts', {
        'shortcuts': shortcutData,
      });

      debugPrint('🎙️ Registered ${habits.length} shortcuts');
    } catch (e) {
      debugPrint('Failed to register shortcuts: $e');
    }
  }

  /// Donate a Siri Suggestion (iOS only)
  /// This makes the shortcut appear in Siri Suggestions
  Future<void> donateSiriSuggestion(Habit habit) async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('donateInteraction', {
        'habitId': habit.id,
        'habitName': habit.name,
        'habitEmoji': habit.emoji,
      });

      debugPrint('🎙️ Donated Siri suggestion for: ${habit.name}');
    } catch (e) {
      debugPrint('Failed to donate Siri suggestion: $e');
    }
  }

  /// Delete a shortcut when habit is deleted
  Future<void> deleteShortcut(String habitId) async {
    try {
      await _channel.invokeMethod('deleteShortcut', {
        'habitId': habitId,
      });
    } catch (e) {
      debugPrint('Failed to delete shortcut: $e');
    }
  }

  /// Check if shortcuts are available on this platform
  Future<bool> get isAvailable async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get the suggested Siri phrase for a habit
  String getSuggestedPhrase(Habit habit) {
    // Clean the habit name for voice
    final cleanName = habit.name
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special chars
        .trim();

    return 'Complete $cleanName';
  }

  /// Open Siri shortcuts settings (iOS only)
  Future<void> openShortcutsSettings() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('openShortcutsSettings');
    } catch (e) {
      debugPrint('Failed to open shortcuts settings: $e');
    }
  }
}

/// Extension to add shortcut support to Habit model
extension HabitShortcutExtension on Habit {
  /// Get the voice command phrase for this habit
  String get voiceCommandPhrase => 'Complete $name';

  /// Get Siri shortcut activity type
  String get siriActivityType => 'com.streakoo.habit.$id';
}
