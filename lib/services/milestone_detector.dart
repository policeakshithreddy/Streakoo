import '../models/milestone.dart';
import '../models/health_challenge.dart';
import '../models/habit.dart';

class MilestoneDetector {
  /// Check for milestones based on challenge progress and health metrics
  static List<Milestone> checkForMilestones({
    required HealthChallenge challenge,
    required Map<String, dynamic>? todayMetrics,
    required Map<String, dynamic>? historicalData,
    required List<Habit> challengeHabits,
  }) {
    final milestones = <Milestone>[];
    final daysInChallenge =
        DateTime.now().difference(challenge.startDate).inDays;

    // Check 1: Daily streak within challenge
    final currentStreak = _calculateChallengeStreak(challengeHabits);

    if (currentStreak > 0 && currentStreak % 3 == 0 && currentStreak <= 21) {
      milestones.add(Milestone(
        type: MilestoneType.streak,
        title: '$currentStreak-Day Streak!',
        description: currentStreak >= 7
            ? 'You\'re unstoppable! Keep this momentum going!'
            : 'You\'re building unstoppable momentum!',
        icon: '🔥',
        celebration: currentStreak >= 7
            ? CelebrationType.confetti
            : CelebrationType.minimal,
        data: {'streak': currentStreak},
      ));
    }

    // Check 2: Week completion
    if (daysInChallenge > 0 && daysInChallenge % 7 == 0) {
      final weekNumber = daysInChallenge ~/ 7;
      final weekStats = _calculateWeekStats(
        challengeHabits,
        weekNumber,
        todayMetrics,
      );

      milestones.add(Milestone(
        type: MilestoneType.weekComplete,
        title: 'Week $weekNumber Complete!',
        description:
            '${weekStats.completionRate.toStringAsFixed(0)}% habit completion',
        icon: weekNumber == 1 ? '🎉' : '⭐',
        celebration: CelebrationType.fullScreen,
        data: weekStats.toJson(),
      ));
    }

    // Check 3: Personal best (steps)
    if (todayMetrics != null && historicalData != null) {
      final todaySteps = todayMetrics['steps'] as int?;
      final allTimeSteps = historicalData['allTimeMaxSteps'] as int? ?? 0;

      if (todaySteps != null &&
          todaySteps > allTimeSteps &&
          todaySteps > 5000) {
        final improvement = allTimeSteps > 0
            ? ((todaySteps - allTimeSteps) / allTimeSteps * 100).round()
            : 0;

        milestones.add(Milestone(
          type: MilestoneType.personalBest,
          title: 'New Personal Best!',
          description:
              '$todaySteps steps - Your best day yet!${improvement > 0 ? " (+$improvement%)" : ""}',
          icon: '⭐',
          celebration: CelebrationType.confetti,
          improvement: improvement,
          data: {'steps': todaySteps, 'previousBest': allTimeSteps},
        ));
      }
    }

    // Check 4: Halfway point
    if (daysInChallenge == 14) {
      milestones.add(Milestone(
        type: MilestoneType.halfwayPoint,
        title: 'Halfway There!',
        description: '14 days down, 14 to go. You\'ve got this!',
        icon: '🎯',
        celebration: CelebrationType.fullScreen,
        data: {'daysCompleted': 14, 'daysRemaining': 14},
      ));
    }

    // Check 5: Challenge complete
    if (daysInChallenge >= 28) {
      milestones.add(Milestone(
        type: MilestoneType.challengeComplete,
        title: '4-Week Challenge Complete!',
        description: 'You completed the entire ${challenge.title} challenge!',
        icon: '🏆',
        celebration: CelebrationType.fullScreen,
        data: {'challengeTitle': challenge.title},
      ));
    }

    return milestones;
  }

  /// Calculate current streak within the challenge
  static int _calculateChallengeStreak(List<Habit> challengeHabits) {
    if (challengeHabits.isEmpty) return 0;

    // Find the minimum streak among all challenge habits
    // (all habits must be completed for a "challenge day" to count)
    int minStreak = challengeHabits.first.streak;
    for (final habit in challengeHabits) {
      if (habit.streak < minStreak) {
        minStreak = habit.streak;
      }
    }

    return minStreak;
  }

  /// Calculate statistics for a completed week
  static WeekStats _calculateWeekStats(
    List<Habit> challengeHabits,
    int weekNumber,
    Map<String, dynamic>? todayMetrics,
  ) {
    // Simple calculation based on current habit completion
    // In a real app, you'd track daily completion history

    int totalDays = 7;
    int completedDays = 0;

    // Estimate completed days from streak
    for (final habit in challengeHabits) {
      if (habit.streak >= weekNumber * 7) {
        completedDays = 7; // This habit was done all 7 days
        break;
      }
    }

    if (completedDays == 0) {
      // Estimate from current streak
      completedDays = challengeHabits.isEmpty
          ? 0
          : challengeHabits.first.streak.clamp(0, 7);
    }

    final completionRate = (completedDays / totalDays) * 100;
    final stepsAverage = todayMetrics?['steps'] as int? ?? 7000;
    final sleepAverage = todayMetrics?['sleep'] as double? ?? 7.0;

    return WeekStats(
      completedDays: completedDays,
      totalDays: totalDays,
      completionRate: completionRate,
      stepsAverage: stepsAverage,
      sleepAverage: sleepAverage,
    );
  }
}
