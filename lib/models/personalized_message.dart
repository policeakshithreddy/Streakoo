import '../utils/time_utils.dart';

/// Personalized celebration message generator
class PersonalizedMessage {
  /// Generate a personalized message based on context
  static String generate({
    required int completedToday,
    required int totalHabits,
    required bool isAllComplete,
    required int longestStreak,
    int consecutivePerfectDays = 0,
  }) {
    final timeEmoji = TimeUtils.getTimeEmoji();
    final isEarly = TimeUtils.isEarlyDay();
    final isLate = TimeUtils.isLateDay();
    final isWeekend = TimeUtils.isWeekend();

    // All habits complete
    if (isAllComplete) {
      if (consecutivePerfectDays >= 7) {
        return '🔥 $consecutivePerfectDays perfect days in a row! Legendary! 👑';
      } else if (consecutivePerfectDays >= 3) {
        return '$consecutivePerfectDays perfect days in a row! On fire! 🔥';
      } else if (isEarly) {
        return 'Speedrunner! All done early! $timeEmoji';
      } else if (isLate) {
        return 'Night owl! Better late than never! 🦉';
      } else if (isWeekend) {
        return 'Weekend warrior! 💪 No days off!';
      } else {
        return 'Perfect day! All habits crushed! 🎯';
      }
    }

    // Progress messages
    if (completedToday == 0) {
      if (isEarly) {
        return '$timeEmoji Good morning! Ready to start strong?';
      } else if (isLate) {
        return '$timeEmoji Still time to make progress!';
      } else {
        return '$timeEmoji Let\'s make today count!';
      }
    } else if (completedToday == 1) {
      return 'Great start! 🌟 Momentum building!';
    } else if (completedToday >= totalHabits * 0.8) {
      final remaining = totalHabits - completedToday;
      return 'Almost there! Just $remaining more! 🎯';
    } else if (completedToday >= totalHabits / 2) {
      return 'Halfway there! Keep the momentum! 🔥';
    } else {
      return 'Making progress! Keep it up! 💪';
    }
  }

  /// Generate celebration message for all habits complete
  static String allHabitsMessage({
    required int consecutivePerfectDays,
    required int totalStreak,
  }) {
    if (consecutivePerfectDays >= 30) {
      return '🏆 Monthly Master!\n$consecutivePerfectDays perfect days!';
    } else if (consecutivePerfectDays >= 7) {
      return '👑 Weekly Champion!\n$consecutivePerfectDays perfect days in a row!';
    } else if (consecutivePerfectDays >= 3) {
      return '🔥 Hot Streak!\n$consecutivePerfectDays perfect days!';
    } else if (TimeUtils.isEarlyDay()) {
      return '⚡ Early Bird Champion!\nAll habits done before noon!';
    } else if (TimeUtils.isLateDay()) {
      return '🌙 Night Owl Victory!\nBetter late than never!';
    } else if (TimeUtils.isWeekend()) {
      return '💪 Weekend Warrior!\nNo days off for champions!';
    } else {
      return '🎯 Daily Goal Achieved!\nYou completed all habits today!';
    }
  }

  /// Generate toast message for habit completion
  static String habitCompletionToast({
    required String habitName,
    required int xp,
    required int streak,
    required bool isEarly,
    required bool isLate,
  }) {
    if (streak > 0 && streak % 10 == 0) {
      return '$habitName - $streak day streak! 🔥 +$xp XP';
    } else if (isEarly) {
      return '⚡ Early start! "$habitName" +$xp XP';
    } else if (isLate) {
      return '🌙 Late night grind! "$habitName" +$xp XP';
    } else {
      return '✓ "$habitName" +$xp XP 🎯';
    }
  }

  /// Generate motivational quote for time of day
  static String timeBasedMotivation() {
    final greeting = TimeUtils.getGreeting();
    final emoji = TimeUtils.getTimeEmoji();
    final isEarly = TimeUtils.isEarlyDay();
    final isLate = TimeUtils.isLateDay();

    if (isEarly) {
      return '$greeting! $emoji The early bird gets the worm!';
    } else if (isLate) {
      return '$greeting! $emoji Still time to make today count!';
    } else {
      return '$greeting! $emoji Let\'s crush those habits!';
    }
  }

  /// Generate comeback message after missing days
  static String comebackMessage(int daysMissed) {
    if (daysMissed == 1) {
      return '👋 Welcome back! Yesterday is history, today is your canvas!';
    } else if (daysMissed <= 3) {
      return '💪 Back in action! Let\'s rebuild that streak!';
    } else {
      return '🌟 Fresh start! Every expert was once a beginner!';
    }
  }

  /// Generate streak milestone tease
  static String? nextMilestoneTease(int currentStreak) {
    final nextMilestone = [7, 14, 30, 50, 100, 365]
        .firstWhere((m) => m > currentStreak, orElse: () => 0);

    if (nextMilestone == 0) return null;

    final daysUntil = nextMilestone - currentStreak;

    if (daysUntil == 1) {
      return '🏆 One more day until $nextMilestone-day milestone!';
    } else if (daysUntil <= 3) {
      return '🎯 $daysUntil days until $nextMilestone-day milestone!';
    }

    return null;
  }
}
