/// Statistics for a user's year in review
class YearInReview {
  final int year;
  final int totalCompletions;
  final int longestStreak;
  final String mostConsistentHabit;
  final String mostConsistentEmoji;
  final int totalXP;
  final String bestMonth;
  final double avgCompletionRate;
  final Map<String, int> habitBreakdown; // habit name -> completions
  final int totalDaysActive;
  final int perfectDays; // days with 100% completion

  const YearInReview({
    required this.year,
    required this.totalCompletions,
    required this.longestStreak,
    required this.mostConsistentHabit,
    required this.mostConsistentEmoji,
    required this.totalXP,
    required this.bestMonth,
    required this.avgCompletionRate,
    required this.habitBreakdown,
    required this.totalDaysActive,
    required this.perfectDays,
  });

  /// Calculate percentage rank (for gamification)
  String get streakRank {
    if (longestStreak >= 365) return 'Legend 🏆';
    if (longestStreak >= 180) return 'Champion 👑';
    if (longestStreak >= 90) return 'Master 🌟';
    if (longestStreak >= 30) return 'Expert ⭐';
    if (longestStreak >= 7) return 'Rising Star 🌠';
    return 'Beginner 🌱';
  }

  /// Get motivational message based on performance
  String get motivationalMessage {
    if (avgCompletionRate >= 0.9) {
      return 'You\'re absolutely crushing it! 💪';
    } else if (avgCompletionRate >= 0.7) {
      return 'Great consistency this year!';
    } else if (avgCompletionRate >= 0.5) {
      return 'You\'re building momentum!';
    } else {
      return 'Every journey starts with a single step!';
    }
  }
}
