/// Represents a streak milestone achievement
class StreakMilestone {
  final int days;
  final String title;
  final String emoji;
  final String badge;
  final List<int> confettiColors;
  final String message;

  const StreakMilestone({
    required this.days,
    required this.title,
    required this.emoji,
    required this.badge,
    required this.confettiColors,
    required this.message,
  });

  /// Predefined milestones
  static const List<int> milestoneValues = [7, 14, 30, 50, 100, 365];

  /// Get milestone for a specific day count
  static StreakMilestone? forDays(int days) {
    if (days == 7) return _week;
    if (days == 14) return _twoWeeks;
    if (days == 30) return _month;
    if (days == 50) return _fiftyDays;
    if (days == 100) return _hundred;
    if (days == 365) return _year;
    return null;
  }

  /// Check if a day count is a milestone
  static bool isMilestone(int days) {
    return milestoneValues.contains(days);
  }

  /// 7 Day Milestone - Bronze Trophy
  static const StreakMilestone _week = StreakMilestone(
    days: 7,
    title: 'One Week Streak!',
    emoji: '🥉',
    badge: 'Bronze',
    confettiColors: [
      0xFFCD7F32, // Bronze
      0xFFD4AF37, // Gold
      0xFFFFA500, // Orange
      0xFFFFD700, // Golden
    ],
    message: 'Amazing! You\'ve completed your habits for 7 days straight!',
  );

  /// 14 Day Milestone - Silver Trophy
  static const StreakMilestone _twoWeeks = StreakMilestone(
    days: 14,
    title: 'Two Week Warrior!',
    emoji: '🥈',
    badge: 'Silver',
    confettiColors: [
      0xFFC0C0C0, // Silver
      0xFF87CEEB, // Sky blue
      0xFFADD8E6, // Light blue
      0xFFE6E6FA, // Lavender
    ],
    message: 'Incredible! Two weeks of consistent habits!',
  );

  /// 30 Day Milestone - Gold Trophy
  static const StreakMilestone _month = StreakMilestone(
    days: 30,
    title: 'Monthly Champion!',
    emoji: '🥇',
    badge: 'Gold',
    confettiColors: [
      0xFFFFD700, // Gold
      0xFFFFA500, // Orange
      0xFFFF8C00, // Dark orange
      0xFFFFDF00, // Golden yellow
    ],
    message: 'Outstanding! A full month of dedication!',
  );

  /// 50 Day Milestone - Fire Badge
  static const StreakMilestone _fiftyDays = StreakMilestone(
    days: 50,
    title: 'Fire Keeper!',
    emoji: '🔥',
    badge: 'Flame',
    confettiColors: [
      0xFFFF4500, // Orange red
      0xFFFF6347, // Tomato
      0xFFFF8C00, // Dark orange
      0xFFFFD700, // Gold
    ],
    message: 'You\'re on fire! 50 days of unstoppable progress!',
  );

  /// 100 Day Milestone - Diamond Badge
  static const StreakMilestone _hundred = StreakMilestone(
    days: 100,
    title: 'Diamond Legend!',
    emoji: '💎',
    badge: 'Diamond',
    confettiColors: [
      0xFF00CED1, // Dark turquoise
      0xFF4169E1, // Royal blue
      0xFF9370DB, // Medium purple
      0xFFFF69B4, // Hot pink
      0xFFFFD700, // Gold
      0xFFFFFFFF, // White (sparkle)
    ],
    message: 'Legendary! 100 days of pure dedication! You\'re a habit master!',
  );

  /// 365 Day Milestone - Year Badge
  static const StreakMilestone _year = StreakMilestone(
    days: 365,
    title: 'Annual Achievement!',
    emoji: '👑',
    badge: 'Crown',
    confettiColors: [
      0xFFFFD700, // Gold
      0xFFFF1493, // Deep pink
      0xFF9400D3, // Dark violet
      0xFF00CED1, // Dark turquoise
      0xFFFF4500, // Orange red
      0xFFFFFFFF, // White
    ],
    message:
        'LEGENDARY! A full year of perfect habits! You are unstoppable! 👑',
  );

  /// Get next milestone from current day count
  static StreakMilestone? getNext(int currentDays) {
    for (final milestone in milestoneValues) {
      if (milestone > currentDays) {
        return forDays(milestone);
      }
    }
    return null; // Already at max
  }

  /// Get days until next milestone
  static int daysUntilNext(int currentDays) {
    final next = getNext(currentDays);
    return next != null ? next.days - currentDays : 0;
  }
}
