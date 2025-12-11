import 'dart:math';
import '../models/daily_challenge.dart';
import '../models/habit.dart';

/// Service to generate random daily challenges
class ChallengeGeneratorService {
  static final ChallengeGeneratorService instance =
      ChallengeGeneratorService._();
  ChallengeGeneratorService._();

  final _random = Random();

  /// Generate daily challenges based on user's habits and progress
  List<DailyChallenge> generateDailyChallenges({
    required List<Habit> habits,
    required int currentStreak,
    required int completedToday,
    int count = 3,
  }) {
    final challenges = <DailyChallenge>[];
    final availableTypes = <ChallengeType>[...ChallengeType.values];

    // Always include a perfect day challenge if user has habits
    if (habits.isNotEmpty && completedToday < habits.length) {
      challenges
          .add(_generatePerfectDayChallenge(habits.length, completedToday));
      availableTypes.remove(ChallengeType.perfectDay);
    }

    // Add focus task challenge if user has focus tasks
    final focusTasks = habits.where((h) => h.isFocusTask).toList();
    if (focusTasks.isNotEmpty) {
      challenges.add(_generateFocusTaskChallenge(focusTasks));
      availableTypes.remove(ChallengeType.focusTaskMaster);
    }

    // Fill remaining slots with random challenges
    while (challenges.length < count && availableTypes.isNotEmpty) {
      final type = availableTypes[_random.nextInt(availableTypes.length)];
      final challenge = _generateChallengeByType(type, habits, currentStreak);
      if (challenge != null) {
        challenges.add(challenge);
      }
      availableTypes.remove(type);
    }

    return challenges;
  }

  DailyChallenge _generatePerfectDayChallenge(int totalHabits, int completed) {
    return DailyChallenge(
      type: ChallengeType.perfectDay,
      title: 'Perfect Day',
      description: 'Complete all your habits today',
      emoji: '💯',
      xpReward: ChallengeDifficulty.hard.baseXP,
      targetValue: totalHabits,
      currentProgress: completed,
    );
  }

  DailyChallenge _generateFocusTaskChallenge(List<Habit> focusTasks) {
    final completed = focusTasks.where((h) => h.completedToday).length;
    return DailyChallenge(
      type: ChallengeType.focusTaskMaster,
      title: 'Focus Task Master',
      description: 'Complete all your focus tasks',
      emoji: '🎯',
      xpReward: ChallengeDifficulty.medium.baseXP,
      targetValue: focusTasks.length,
      currentProgress: completed,
    );
  }

  DailyChallenge? _generateChallengeByType(
    ChallengeType type,
    List<Habit> habits,
    int currentStreak,
  ) {
    switch (type) {
      case ChallengeType.streakBoost:
        return DailyChallenge(
          type: ChallengeType.streakBoost,
          title: 'Streak Booster',
          description: 'Maintain a ${currentStreak + 1} day streak',
          emoji: '🔥',
          xpReward: ChallengeDifficulty.medium.baseXP,
          targetValue: currentStreak + 1,
          currentProgress: currentStreak,
        );

      case ChallengeType.earlyBird:
        final now = DateTime.now();
        final isMorning = now.hour < 10;
        return DailyChallenge(
          type: ChallengeType.earlyBird,
          title: 'Early Bird',
          description: 'Complete 3 habits before 10 AM',
          emoji: '🌅',
          xpReward: ChallengeDifficulty.medium.baseXP,
          targetValue: 3,
          currentProgress:
              isMorning ? habits.where((h) => h.completedToday).length : 0,
        );

      case ChallengeType.completionCount:
        final target = min(5, habits.length);
        final completed = habits.where((h) => h.completedToday).length;
        return DailyChallenge(
          type: ChallengeType.completionCount,
          title: 'Productivity Pro',
          description: 'Complete $target habits today',
          emoji: '✅',
          xpReward: ChallengeDifficulty.easy.baseXP,
          targetValue: target,
          currentProgress: completed,
        );

      case ChallengeType.weekendWarrior:
        final isWeekend = DateTime.now().weekday >= 6;
        if (!isWeekend) return null;

        return DailyChallenge(
          type: ChallengeType.weekendWarrior,
          title: 'Weekend Warrior',
          description: 'Keep your streak alive on the weekend',
          emoji: '🏖️',
          xpReward: ChallengeDifficulty.medium.baseXP,
          targetValue: 1,
          currentProgress: habits.any((h) => h.completedToday) ? 1 : 0,
        );

      case ChallengeType.consistency:
        // Find a habit with a good streak
        final habitsWithStreak = habits.where((h) => h.streak >= 3).toList();
        if (habitsWithStreak.isEmpty) return null;

        final habit =
            habitsWithStreak[_random.nextInt(habitsWithStreak.length)];
        return DailyChallenge(
          type: ChallengeType.consistency,
          title: 'Consistency King',
          description: 'Keep "${habit.name}" streak going',
          emoji: '👑',
          xpReward: ChallengeDifficulty.easy.baseXP,
          targetValue: 1,
          currentProgress: habit.completedToday ? 1 : 0,
        );

      default:
        return null;
    }
  }

  /// Update challenge progress based on app state
  DailyChallenge updateChallengeProgress(
    DailyChallenge challenge,
    List<Habit> habits,
  ) {
    int newProgress = challenge.currentProgress;

    switch (challenge.type) {
      case ChallengeType.perfectDay:
        newProgress = habits.where((h) => h.completedToday).length;
        break;

      case ChallengeType.focusTaskMaster:
        newProgress =
            habits.where((h) => h.isFocusTask && h.completedToday).length;
        break;

      case ChallengeType.completionCount:
        newProgress = habits.where((h) => h.completedToday).length;
        break;

      case ChallengeType.earlyBird:
        final now = DateTime.now();
        if (now.hour < 10) {
          newProgress = habits.where((h) => h.completedToday).length;
        }
        break;

      case ChallengeType.weekendWarrior:
        newProgress = habits.any((h) => h.completedToday) ? 1 : 0;
        break;

      default:
        break;
    }

    final isCompleted = newProgress >= challenge.targetValue;

    return challenge.copyWith(
      currentProgress: newProgress,
      isCompleted: isCompleted,
    );
  }
}
