/// Smart Suggestion Engine - Context-aware coaching tips
class SmartSuggestionEngine {
  /// Generate daily insight based on user context
  static DailyInsight generateInsight({
    required int healthScore,
    required int currentStreak,
    required bool completedYesterday,
    required bool completedToday,
    required int dayOfWeek, // 1=Mon, 7=Sun
    required double sleepQuality,
    required double stressLevel,
    required int missedHabitsCount,
  }) {
    // Priority 1: Recovery from missed day
    if (!completedYesterday && completedToday) {
      return DailyInsight(
        type: InsightType.encouragement,
        emoji: '💪',
        title: 'Welcome Back!',
        message: 'Great to see you back on track! Yesterday is behind you.',
        actionTip: 'Complete one more habit to solidify your comeback',
        priority: 10,
      );
    }

    // Priority 2: Streak milestone
    if (currentStreak > 0 && currentStreak % 7 == 0) {
      return DailyInsight(
        type: InsightType.celebration,
        emoji: '🔥',
        title: '$currentStreak-Day Streak!',
        message:
            'You\'ve been consistent for ${(currentStreak / 7).floor()} week(s)!',
        actionTip: 'Keep the momentum - don\'t break it now!',
        priority: 9,
      );
    }

    // Priority 3: Weekend upcoming
    if (dayOfWeek >= 5 && currentStreak >= 5) {
      return DailyInsight(
        type: InsightType.challenge,
        emoji: '🎯',
        title: 'Weekend Challenge',
        message: 'You\'ve crushed the weekdays! Can you keep it going?',
        actionTip: 'Plan your weekend workouts now',
        priority: 7,
      );
    }

    // Priority 4: Low sleep + high stress
    if (sleepQuality <= 2 && stressLevel >= 4) {
      return DailyInsight(
        type: InsightType.wellness,
        emoji: '🧘',
        title: 'Rest & Recovery',
        message: 'Your body needs rest. Low sleep + high stress detected.',
        actionTip: 'Try a 5-minute meditation or gentle stretching today',
        priority: 8,
      );
    }

    // Priority 5: Perfect day
    if (missedHabitsCount == 0 && completedToday) {
      return DailyInsight(
        type: InsightType.celebration,
        emoji: '⭐',
        title: 'Perfect Day!',
        message: 'You completed ALL habits today! Outstanding!',
        actionTip: 'Celebrate your win - you earned it!',
        priority: 9,
      );
    }

    // Priority 6: Struggling
    if (healthScore < 50 && missedHabitsCount > 2) {
      return DailyInsight(
        type: InsightType.coaching,
        emoji: '🎯',
        title: 'Let\'s Simplify',
        message: 'Focus on just ONE habit today. Small wins build big results.',
        actionTip: 'Pick your easiest habit and complete it',
        priority: 8,
      );
    }

    // Default: Positive encouragement
    return DailyInsight(
      type: InsightType.encouragement,
      emoji: '💡',
      title: 'Daily Tip',
      message: 'Consistency beats intensity. Show up, even if it\'s small.',
      actionTip: 'Complete at least 50% of your habits today',
      priority: 5,
    );
  }

  /// Get personalized morning message
  static String getMorningMessage(
      String userName, int healthScore, int currentStreak) {
    if (currentStreak >= 30) {
      return 'Good morning, Champion! 30+ day streak is incredible! 🏆';
    } else if (currentStreak >= 7) {
      return 'Morning! Your $currentStreak-day streak is impressive 🔥';
    } else if (healthScore >= 80) {
      return 'Good morning! You\'re doing amazing! ⭐';
    } else if (healthScore >= 60) {
      return 'Morning! Let\'s make today even better! 💪';
    } else {
      return 'Good morning! Today is a fresh start! 🌅';
    }
  }

  /// Suggest optimal rest day
  static String? suggestRestDay({
    required int consecutiveDays,
    required double averageStress,
    required double averageSleep,
  }) {
    if (consecutiveDays >= 14 && averageStress >= 3.5) {
      return '💡 You\'ve been going hard for $consecutiveDays days straight. Consider a rest day to prevent burnout.';
    }

    if (averageSleep <= 2.5 && consecutiveDays >= 7) {
      return '😴 Low sleep detected. A rest day might help you recover and perform better.';
    }

    return null;
  }

  /// Get goal-specific advice
  static String getGoalAdvice(String challengeType, int weeksCompleted) {
    final adviceMap = {
      'weightManagement': [
        'Week 1-2: Focus on consistency, not perfection',
        'Week 3-4: Your metabolism is adapting - progress may slow but keep going!',
        'Week 5+: You\'ve built solid habits. Time to optimize nutrition',
      ],
      'heartHealth': [
        'Week 1-2: Start slow, listen to your body',
        'Week 3-4: Your cardiovascular fitness is improving!',
        'Week 5+: Consider adding interval training',
      ],
      'activityStrength': [
        'Week 1-2: Proper form > heavy weights',
        'Week 3-4: Progressive overload - increase gradually',
        'Week 5+: You\'re ready for advanced techniques!',
      ],
    };

    final advice = adviceMap[challengeType];
    if (advice == null) return 'Keep up the great work!';

    if (weeksCompleted <= 2) return advice[0];
    if (weeksCompleted <= 4) return advice[1];
    return advice[2];
  }
}

enum InsightType {
  encouragement,
  celebration,
  challenge,
  wellness,
  coaching,
}

class DailyInsight {
  final InsightType type;
  final String emoji;
  final String title;
  final String message;
  final String actionTip;
  final int priority; // 1-10, higher = more important

  DailyInsight({
    required this.type,
    required this.emoji,
    required this.title,
    required this.message,
    required this.actionTip,
    required this.priority,
  });
}
