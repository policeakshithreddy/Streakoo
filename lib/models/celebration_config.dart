enum CelebrationTrigger {
  singleHabitCompleted,
  allHabitsCompleted,
  achievementUnlocked,
  levelUp,
  streakMilestone,
}

class CelebrationConfig {
  final CelebrationTrigger trigger;
  final bool showConfetti;
  final bool showFireworks;
  final bool enableHaptics;
  final bool showBanner;
  final String? bannerMessage;
  final Duration duration;

  CelebrationConfig({
    required this.trigger,
    this.showConfetti = false,
    this.showFireworks = false,
    this.enableHaptics = true,
    this.showBanner = false,
    this.bannerMessage,
    this.duration = const Duration(seconds: 2),
  });

  // Predefined configurations
  static CelebrationConfig singleHabit() {
    return CelebrationConfig(
      trigger: CelebrationTrigger.singleHabitCompleted,
      showConfetti: true,
      showFireworks: false,
      enableHaptics: true,
      showBanner: false,
      duration: const Duration(milliseconds: 800),
    );
  }

  static CelebrationConfig allHabits() {
    return CelebrationConfig(
      trigger: CelebrationTrigger.allHabitsCompleted,
      showConfetti: true,
      showFireworks: false, // Only confetti, no fireworks
      enableHaptics: true,
      showBanner: false, // Only visual celebration, no text
      duration: const Duration(seconds: 3),
    );
  }

  static CelebrationConfig achievement(String achievementName) {
    return CelebrationConfig(
      trigger: CelebrationTrigger.achievementUnlocked,
      showConfetti: true,
      showFireworks: false,
      enableHaptics: true,
      showBanner: false, // Only visual celebration, no text
      duration: const Duration(milliseconds: 2500),
    );
  }

  static CelebrationConfig levelUp(int newLevel, String title) {
    return CelebrationConfig(
      trigger: CelebrationTrigger.levelUp,
      showConfetti: true,
      showFireworks: false, // Only confetti, no fireworks
      enableHaptics: true,
      showBanner: false, // Only visual celebration, no text
      duration: const Duration(seconds: 3),
    );
  }

  static CelebrationConfig streakMilestone(int days) {
    return CelebrationConfig(
      trigger: CelebrationTrigger.streakMilestone,
      showConfetti: true,
      showFireworks: false, // Only confetti, no fireworks
      enableHaptics: true,
      showBanner: false, // Only visual celebration, no text
      duration: const Duration(milliseconds: 2500),
    );
  }
}
