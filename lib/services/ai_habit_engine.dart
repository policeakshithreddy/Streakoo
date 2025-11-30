import '../models/habit_idea.dart';

/// Very simple "AI-like" habit generator.
/// You can later replace this with a real API call.
class AiHabitEngine {
  const AiHabitEngine();

  List<HabitIdea> buildFromAnswers({
    required String mainGoal,
    required List<String> struggles,
    required List<String> timeOfDay,
    required int age,
  }) {
    final List<HabitIdea> result = [];

    void add(String name, String emoji, String category) {
      result.add(
        HabitIdea(
          name: name,
          emoji: emoji,
          category: category,
        ),
      );
    }

    final goal = mainGoal.toLowerCase();
    final hasHealthGoal = goal.contains('health') || goal.contains('fit');
    final hasStudyGoal = goal.contains('study') ||
        goal.contains('school') ||
        goal.contains('grades');
    final hasSleepGoal = goal.contains('sleep') || goal.contains('energy');
    final hasFocusGoal = goal.contains('focus') || goal.contains('deep work');
    final hasDisciplineGoal = goal.contains('discipline');

    final strugglesList = struggles.map((s) => s.toLowerCase()).toList();
    final strugglesConsistency =
        strugglesList.any((s) => s.contains('consistent'));
    final strugglesGettingStarted =
        strugglesList.any((s) => s.contains('getting started'));
    final strugglesDistraction = strugglesList
        .any((s) => s.contains('distraction') || s.contains('phone'));
    final strugglesMotivation =
        strugglesList.any((s) => s.contains('motivation'));
    final strugglesSleep =
        strugglesList.any((s) => s.contains('sleep') || s.contains('tired'));

    // Health-related habits
    if (hasHealthGoal) {
      add('Drink 3 glasses of water', '💧', 'Health');
      add('10 minute walk or stretch', '🚶‍♂️', 'Health');
      add('Eat a healthy breakfast', '🥗', 'Health');
    }

    // Study-related habits
    if (hasStudyGoal) {
      add('25 min focused study session', '📚', 'Study');
      add('Review notes before bed', '📝', 'Study');
    }

    // Sleep-related habits
    if (hasSleepGoal || strugglesSleep) {
      add('No screens 30 min before bed', '📵', 'Sleep');
      add('Set consistent bedtime', '🌙', 'Sleep');
    }

    // Focus-related habits
    if (hasFocusGoal || strugglesDistraction) {
      add('5 min breathing exercise', '🧘', 'Mind');
      add('Silence phone during work', '🔕', 'Focus');
    }

    // Motivation & consistency habits
    if (strugglesMotivation || strugglesConsistency) {
      add('Write 3 things you\'re grateful for', '✍️', 'Mindset');
      add('Set 1 daily intention', '🎯', 'Mindset');
    }

    // Getting started habit
    if (strugglesGettingStarted) {
      add('2-minute morning routine', '⏰', 'Morning');
    }

    // Discipline habit
    if (hasDisciplineGoal) {
      add('Make your bed', '🛏️', 'Discipline');
    }

    // Ensure at least 5-7 habits, add general ones if needed
    if (result.length < 5) {
      if (!result.any((h) => h.name.contains('water'))) {
        add('Drink 3 glasses of water', '💧', 'Health');
      }
      if (!result.any((h) => h.name.contains('walk'))) {
        add('10 minute walk', '🚶‍♂️', 'Health');
      }
      if (!result.any((h) => h.name.contains('grateful'))) {
        add('Write 3 things you\'re grateful for', '✍️', 'Mindset');
      }
      if (!result.any((h) => h.name.contains('bed'))) {
        add('Make your bed', '🛏️', 'Discipline');
      }
      if (!result.any((h) => h.name.contains('breathing'))) {
        add('5 min breathing exercise', '🧘', 'Mind');
      }
    }

    // Limit to max 7 suggestions to avoid overwhelming
    return result.take(7).toList();
  }
}
