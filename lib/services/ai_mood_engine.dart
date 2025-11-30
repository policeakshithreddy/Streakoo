import '../models/mood_tracker.dart';
import '../models/habit_idea.dart';

class AIMoodEngine {
  AIMoodEngine._();
  static final AIMoodEngine instance = AIMoodEngine._();

  // Analyze recent moods and provide insights
  MoodAnalysis analyzeMoods(List<MoodEntry> entries) {
    return MoodAnalysis.fromEntries(entries);
  }

  // Get AI coaching tone based on current mood
  String getCoachingTone(MoodType? currentMood) {
    if (currentMood == null) return 'encouraging';

    switch (currentMood) {
      case MoodType.happy:
      case MoodType.energetic:
        return 'enthusiastic';
      case MoodType.neutral:
        return 'encouraging';
      case MoodType.sad:
      case MoodType.stressed:
        return 'gentle';
    }
  }

  // Get motivational message based on mood
  String getMotivationalMessage(MoodType mood, String userName) {
    switch (mood) {
      case MoodType.happy:
        return "You're radiating positive energy, $userName! Let's channel that into crushing your goals today! 🌟";
      case MoodType.energetic:
        return "Wow, $userName! That energy is contagious! Perfect time to tackle those challenging habits! ⚡";
      case MoodType.neutral:
        return "Hey $userName, every journey starts with a single step. Let's make today count! 💪";
      case MoodType.sad:
        return "I know things feel heavy right now, $userName. But small wins matter. Let's take it one step at a time. 🌸";
      case MoodType.stressed:
        return "$userName, take a deep breath. You've got this. Start with just one small habit today. 🧘‍♀️";
    }
  }

  // Suggest habits based on mood
  List<HabitIdea> getMoodBasedSuggestions(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return [
          HabitIdea(
            name: 'Share gratitude',
            emoji: '🙏',
            category: 'Mindfulness',
          ),
          HabitIdea(
            name: 'Call a friend',
            emoji: '📞',
            category: 'Social',
          ),
          HabitIdea(
            name: 'Learn something new',
            emoji: '📚',
            category: 'Study',
          ),
        ];

      case MoodType.energetic:
        return [
          HabitIdea(
            name: '30-minute workout',
            emoji: '🏃',
            category: 'Health',
          ),
          HabitIdea(
            name: 'Work on a passion project',
            emoji: '🎨',
            category: 'Personal',
          ),
          HabitIdea(
            name: 'Dance for 10 minutes',
            emoji: '💃',
            category: 'Health',
          ),
        ];

      case MoodType.neutral:
        return [
          HabitIdea(
            name: 'Morning walk',
            emoji: '🚶',
            category: 'Health',
          ),
          HabitIdea(
            name: 'Read 10 pages',
            emoji: '📖',
            category: 'Study',
          ),
          HabitIdea(
            name: 'Tidy workspace',
            emoji: '🧹',
            category: 'Personal',
          ),
        ];

      case MoodType.sad:
        return [
          HabitIdea(
            name: '5-minute meditation',
            emoji: '🧘',
            category: 'Mindfulness',
          ),
          HabitIdea(
            name: 'Journal your feelings',
            emoji: '📝',
            category: 'Mindfulness',
          ),
          HabitIdea(
            name: 'Listen to uplifting music',
            emoji: '🎵',
            category: 'Personal',
          ),
          HabitIdea(
            name: 'Take a warm shower',
            emoji: '🚿',
            category: 'Self-care',
          ),
        ];

      case MoodType.stressed:
        return [
          HabitIdea(
            name: 'Deep breathing (3 min)',
            emoji: '🌬️',
            category: 'Mindfulness',
          ),
          HabitIdea(
            name: 'Gentle stretching',
            emoji: '🤸',
            category: 'Health',
          ),
          HabitIdea(
            name: 'Drink herbal tea',
            emoji: '🍵',
            category: 'Self-care',
          ),
          HabitIdea(
            name: 'Step outside for fresh air',
            emoji: '🌳',
            category: 'Health',
          ),
        ];
    }
  }

  // Adjust notification frequency based on mood patterns
  int getRecommendedNotificationFrequency(MoodAnalysis analysis) {
    // Higher average mood score = fewer interruptions
    if (analysis.averageMoodScore > 0.7) {
      return 2; // Fewer notifications when feeling good
    } else if (analysis.averageMoodScore < 0.3) {
      return 4; // More gentle reminders when struggling
    } else {
      return 3; // Normal frequency
    }
  }

  // Determine if user should take a break
  bool shouldSuggestBreak(List<MoodEntry> recentEntries) {
    if (recentEntries.length < 3) return false;

    // If last 3 moods are stressed or sad, suggest a break
    final lastThree = recentEntries.take(3);
    final stressCount = lastThree
        .where((e) => e.mood == MoodType.stressed || e.mood == MoodType.sad)
        .length;

    return stressCount >= 2;
  }
}
