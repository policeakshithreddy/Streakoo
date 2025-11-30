import 'package:vibration/vibration.dart';

import '../models/celebration_config.dart';

class CelebrationEngine {
  CelebrationEngine._();
  static final CelebrationEngine instance = CelebrationEngine._();

  final List<CelebrationConfig> _celebrationQueue = [];
  bool _isPlaying = false;

  // Add celebration to queue
  void celebrate(CelebrationConfig config) {
    _celebrationQueue.add(config);
    if (!_isPlaying) {
      _processQueue();
    }
  }

  // Process celebration queue
  Future<void> _processQueue() async {
    if (_celebrationQueue.isEmpty) {
      _isPlaying = false;
      return;
    }

    _isPlaying = true;
    final config = _celebrationQueue.removeAt(0);

    // Trigger haptics if enabled
    if (config.enableHaptics) {
      await _triggerHaptics(config.trigger);
    }

    // Wait for duration
    await Future.delayed(config.duration);

    // Process next in queue
    _processQueue();
  }

  // Trigger haptic feedback based on celebration type
  Future<void> _triggerHaptics(CelebrationTrigger trigger) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    switch (trigger) {
      case CelebrationTrigger.singleHabitCompleted:
        // Short single vibration
        Vibration.vibrate(duration: 50);
        break;

      case CelebrationTrigger.allHabitsCompleted:
        // Double vibration pattern
        Vibration.vibrate(
          pattern: [0, 100, 50, 150],
          intensities: [0, 128, 0, 255],
        );
        break;

      case CelebrationTrigger.achievementUnlocked:
        // Triple tap pattern
        Vibration.vibrate(
          pattern: [0, 50, 30, 50, 30, 80],
          intensities: [0, 100, 0, 150, 0, 200],
        );
        break;

      case CelebrationTrigger.levelUp:
        // Escalating pattern
        Vibration.vibrate(
          pattern: [0, 80, 40, 100, 40, 150],
          intensities: [0, 100, 0, 180, 0, 255],
        );
        break;

      case CelebrationTrigger.streakMilestone:
        // Long celebration
        Vibration.vibrate(
          pattern: [0, 100, 50, 100, 50, 200],
          intensities: [0, 150, 0, 200, 0, 255],
        );
        break;
    }
  }

  // Celebration for single habit completion
  void celebrateSingleHabit(String habitName) {
    celebrate(CelebrationConfig.singleHabit());
  }

  // Celebration for all habits completed
  void celebrateAllHabits() {
    celebrate(CelebrationConfig.allHabits());
  }

  // Celebration for achievement unlocked
  void celebrateAchievement(String achievementName) {
    celebrate(CelebrationConfig.achievement(achievementName));
  }

  // Celebration for level up
  void celebrateLevelUp(int newLevel, String title) {
    celebrate(CelebrationConfig.levelUp(newLevel, title));
  }

  // Celebration for streak milestone
  void celebrateStreakMilestone(int days) {
    celebrate(CelebrationConfig.streakMilestone(days));
  }

  // Clear celebration queue
  void clearQueue() {
    _celebrationQueue.clear();
    _isPlaying = false;
  }

  // Check if celebration is currently playing
  bool get isPlaying => _isPlaying;
}
