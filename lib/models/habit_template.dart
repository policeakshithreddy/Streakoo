import '../models/habit.dart';

/// Pre-made habit template packs for easy onboarding
class HabitTemplate {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String description;
  final List<String> defaultReminders;
  final List<int> frequencyDays; // 1=Mon, 7=Sun

  const HabitTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.description,
    this.defaultReminders = const ['09:00'],
    this.frequencyDays = const [1, 2, 3, 4, 5, 6, 7], // daily by default
  });

  Habit toHabit() {
    return Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
      category: category,
      frequencyDays: frequencyDays,
    );
  }
}

/// Template Pack containing multiple related habits
class HabitTemplatePack {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<String> benefits;
  final List<HabitTemplate> habits;
  final int estimatedTimeMinutes;

  const HabitTemplatePack({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.benefits,
    required this.habits,
    this.estimatedTimeMinutes = 30,
  });
}

/// All available template packs
class HabitTemplates {
  static const List<HabitTemplatePack> allPacks = [
    morningRoutinePack,
    fitnessStarterPack,
    mindfulnessPack,
    productivityPack,
    healthyEatingPack,
    sleepOptimizationPack,
  ];

  static const morningRoutinePack = HabitTemplatePack(
    id: 'morning_routine',
    name: 'Morning Routine',
    emoji: '🌅',
    description: 'Start your day with energy and focus',
    estimatedTimeMinutes: 45,
    benefits: [
      'Boost energy levels',
      'Improve mental clarity',
      'Set positive tone for the day',
    ],
    habits: [
      HabitTemplate(
        id: 'wake_early',
        name: 'Wake Up Early',
        emoji: '⏰',
        category: 'Productivity',
        description: 'Wake up by 6:30 AM',
        defaultReminders: ['06:00'],
      ),
      HabitTemplate(
        id: 'drink_water',
        name: 'Drink Water',
        emoji: '💧',
        category: 'Health',
        description: 'Start with a glass of water',
        defaultReminders: ['06:15'],
      ),
      HabitTemplate(
        id: 'morning_stretch',
        name: 'Morning Stretch',
        emoji: '🧘',
        category: 'Health',
        description: '5-10 minute stretch routine',
        defaultReminders: ['06:30'],
      ),
      HabitTemplate(
        id: 'healthy_breakfast',
        name: 'Healthy Breakfast',
        emoji: '🥗',
        category: 'Health',
        description: 'Eat a nutritious breakfast',
        defaultReminders: ['07:00'],
      ),
    ],
  );

  static const fitnessStarterPack = HabitTemplatePack(
    id: 'fitness_starter',
    name: 'Fitness Starter',
    emoji: '💪',
    description: 'Build a consistent workout habit',
    estimatedTimeMinutes: 60,
    benefits: [
      'Increase strength and endurance',
      'Boost metabolism',
      'Improve mental health',
    ],
    habits: [
      HabitTemplate(
        id: 'exercise_30min',
        name: '30 Min Exercise',
        emoji: '🏃',
        category: 'Sports',
        description: 'Any form of exercise for 30 minutes',
        defaultReminders: ['07:00'],
      ),
      HabitTemplate(
        id: 'steps_10k',
        name: '10,000 Steps',
        emoji: '👣',
        category: 'Health',
        description: 'Walk 10,000 steps daily',
      ),
      HabitTemplate(
        id: 'strength_training',
        name: 'Strength Training',
        emoji: '🏋️',
        category: 'Sports',
        description: 'Bodyweight or weight training',
        defaultReminders: ['18:00'],
        frequencyDays: [1, 3, 5], // Mon, Wed, Fri
      ),
      HabitTemplate(
        id: 'stretching',
        name: 'Post-Workout Stretch',
        emoji: '🤸',
        category: 'Health',
        description: 'Cool down with stretching',
        defaultReminders: ['18:45'],
      ),
    ],
  );

  static const mindfulnessPack = HabitTemplatePack(
    id: 'mindfulness',
    name: 'Mindfulness',
    emoji: '🧘‍♀️',
    description: 'Cultivate inner peace and presence',
    estimatedTimeMinutes: 25,
    benefits: [
      'Reduce stress and anxiety',
      'Improve focus and clarity',
      'Better emotional regulation',
    ],
    habits: [
      HabitTemplate(
        id: 'meditation',
        name: 'Meditate',
        emoji: '🧘',
        category: 'Mindfulness',
        description: '10 minutes of meditation',
        defaultReminders: ['07:00', '21:00'],
      ),
      HabitTemplate(
        id: 'gratitude_journal',
        name: 'Gratitude Journal',
        emoji: '📝',
        category: 'Mindfulness',
        description: 'Write 3 things you\'re grateful for',
        defaultReminders: ['21:30'],
      ),
      HabitTemplate(
        id: 'deep_breathing',
        name: 'Deep Breathing',
        emoji: '🌬️',
        category: 'Mindfulness',
        description: '5 minutes of deep breathing',
        defaultReminders: ['12:00'],
      ),
      HabitTemplate(
        id: 'no_phone_morning',
        name: 'Phone-Free Morning',
        emoji: '📵',
        category: 'Mindfulness',
        description: 'No phone for first 30 minutes',
        defaultReminders: ['06:30'],
      ),
    ],
  );

  static const productivityPack = HabitTemplatePack(
    id: 'productivity',
    name: 'Productivity Pro',
    emoji: '🚀',
    description: 'Maximize your daily output',
    estimatedTimeMinutes: 40,
    benefits: [
      'Get more done in less time',
      'Reduce procrastination',
      'Achieve your goals faster',
    ],
    habits: [
      HabitTemplate(
        id: 'plan_day',
        name: 'Plan Your Day',
        emoji: '📋',
        category: 'Productivity',
        description: 'Write top 3 priorities',
        defaultReminders: ['07:30'],
      ),
      HabitTemplate(
        id: 'deep_work',
        name: 'Deep Work Session',
        emoji: '🎯',
        category: 'Productivity',
        description: '90 minutes of focused work',
        defaultReminders: ['09:00'],
      ),
      HabitTemplate(
        id: 'review_day',
        name: 'Daily Review',
        emoji: '📊',
        category: 'Productivity',
        description: 'Review what you accomplished',
        defaultReminders: ['18:00'],
      ),
      HabitTemplate(
        id: 'learn_something',
        name: 'Learn Something New',
        emoji: '📚',
        category: 'Learning',
        description: '20 minutes of learning',
        defaultReminders: ['19:00'],
      ),
    ],
  );

  static const healthyEatingPack = HabitTemplatePack(
    id: 'healthy_eating',
    name: 'Healthy Eating',
    emoji: '🥗',
    description: 'Build better eating habits',
    estimatedTimeMinutes: 20,
    benefits: [
      'More energy throughout the day',
      'Better digestion',
      'Maintain healthy weight',
    ],
    habits: [
      HabitTemplate(
        id: 'no_sugar',
        name: 'No Added Sugar',
        emoji: '🍬',
        category: 'Health',
        description: 'Avoid foods with added sugar',
      ),
      HabitTemplate(
        id: 'eat_veggies',
        name: 'Eat Vegetables',
        emoji: '🥦',
        category: 'Health',
        description: 'Eat at least 3 servings of veggies',
      ),
      HabitTemplate(
        id: 'drink_water_8',
        name: '8 Glasses of Water',
        emoji: '💧',
        category: 'Health',
        description: 'Stay hydrated throughout the day',
      ),
      HabitTemplate(
        id: 'no_late_snacking',
        name: 'No Late Snacking',
        emoji: '🌙',
        category: 'Health',
        description: 'No eating after 8 PM',
      ),
    ],
  );

  static const sleepOptimizationPack = HabitTemplatePack(
    id: 'sleep_optimization',
    name: 'Sleep Better',
    emoji: '😴',
    description: 'Optimize your sleep quality',
    estimatedTimeMinutes: 30,
    benefits: [
      'Wake up refreshed',
      'Better cognitive function',
      'Improved mood',
    ],
    habits: [
      HabitTemplate(
        id: 'no_screens',
        name: 'No Screens Before Bed',
        emoji: '📵',
        category: 'Health',
        description: 'No screens 1 hour before sleep',
        defaultReminders: ['21:00'],
      ),
      HabitTemplate(
        id: 'sleep_routine',
        name: 'Bedtime Routine',
        emoji: '🛁',
        category: 'Health',
        description: 'Wind down with a calming routine',
        defaultReminders: ['21:30'],
      ),
      HabitTemplate(
        id: 'sleep_time',
        name: 'Sleep by 10:30 PM',
        emoji: '🛏️',
        category: 'Health',
        description: 'Get to bed on time',
        defaultReminders: ['22:00'],
      ),
      HabitTemplate(
        id: 'room_cool',
        name: 'Cool Room Setup',
        emoji: '❄️',
        category: 'Health',
        description: 'Set room to optimal temperature',
        defaultReminders: ['21:00'],
      ),
    ],
  );
}
