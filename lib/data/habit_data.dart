class HabitSuggestion {
  final String name;
  final String subtitle;
  final String emoji;
  final String? targetCategory; // Optional: Override category for Popular items

  const HabitSuggestion({
    required this.name,
    required this.subtitle,
    required this.emoji,
    this.targetCategory,
  });
}

class HabitCategoryData {
  final String id;
  final String name;
  final String description;
  final String iconEmoji;
  final List<HabitSuggestion> suggestions;

  const HabitCategoryData({
    required this.id,
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.suggestions,
  });
}

final List<HabitCategoryData> habitCategories = [
  const HabitCategoryData(
    id: 'popular',
    name: 'Popular',
    description: 'Start with proven habits that have helped thousands succeed',
    iconEmoji: '⭐',
    suggestions: [
      HabitSuggestion(
        name: 'Gym Workout',
        subtitle: 'Crush a gym session',
        emoji: '🏋️‍♂️',
        targetCategory: 'Sports',
      ),
      HabitSuggestion(
        name: '7h Sleep',
        subtitle: 'Rest and recharge fully',
        emoji: '😴',
        targetCategory: 'Health',
      ),
      HabitSuggestion(
        name: '10k Steps',
        subtitle: 'Walk your way to wellness',
        emoji: '👣',
        targetCategory: 'Health',
      ),
      HabitSuggestion(
        name: 'Make Bed',
        subtitle: 'Start your day with order',
        emoji: '🛏️',
        targetCategory: 'Lifestyle',
      ),
      HabitSuggestion(
        name: 'Read a Book',
        subtitle: 'Read a few pages',
        emoji: '📖',
        targetCategory: 'Learning',
      ),
      HabitSuggestion(
        name: 'Gratitude Journal',
        subtitle: 'Reflect on what matters',
        emoji: '📔',
        targetCategory: 'Mindfulness',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'health',
    name: 'Health',
    description: 'Nourish your body and mind for a healthier you',
    iconEmoji: '🌿',
    suggestions: [
      HabitSuggestion(
        name: 'Drink Water',
        subtitle: 'Stay hydrated all day',
        emoji: '💧',
      ),
      HabitSuggestion(
        name: 'Eat Fruit',
        subtitle: 'Get your daily vitamins',
        emoji: '🍎',
      ),
      HabitSuggestion(
        name: 'No Sugar',
        subtitle: 'Avoid added sugars',
        emoji: '🚫',
      ),
      HabitSuggestion(
        name: 'Take Vitamins',
        subtitle: 'Daily supplements',
        emoji: '💊',
      ),
      HabitSuggestion(
        name: 'Meditate',
        subtitle: 'Clear your mind',
        emoji: '🧘',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'sports',
    name: 'Sports',
    description: 'Get moving and stay active with these sports habits',
    iconEmoji: '🏃',
    suggestions: [
      HabitSuggestion(
        name: 'Running',
        subtitle: 'Go for a run',
        emoji: '🏃‍♂️',
      ),
      HabitSuggestion(
        name: 'Cycling',
        subtitle: 'Ride your bike',
        emoji: '🚴',
      ),
      HabitSuggestion(
        name: 'Swimming',
        subtitle: 'Laps in the pool',
        emoji: '🏊',
      ),
      HabitSuggestion(
        name: 'Yoga',
        subtitle: 'Stretch and strengthen',
        emoji: '🧘‍♀️',
      ),
      HabitSuggestion(
        name: 'Plank',
        subtitle: 'Core strength',
        emoji: '💪',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'social',
    name: 'Social Media',
    description: 'Manage your digital life and stay connected mindfully',
    iconEmoji: '📱',
    suggestions: [
      HabitSuggestion(
        name: 'Limit Screen Time',
        subtitle: 'Reduce digital strain',
        emoji: '📵',
      ),
      HabitSuggestion(
        name: 'No Phone Before Bed',
        subtitle: 'Better sleep hygiene',
        emoji: '🛌',
      ),
      HabitSuggestion(
        name: 'Call a Friend',
        subtitle: 'Stay in touch',
        emoji: '📞',
      ),
      HabitSuggestion(
        name: 'Unfollow Toxic',
        subtitle: 'Clean up your feed',
        emoji: '🧹',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'lifestyle',
    name: 'Lifestyle',
    description: 'Build a balanced and productive lifestyle',
    iconEmoji: '🌱',
    suggestions: [
      HabitSuggestion(
        name: 'Wake up Early',
        subtitle: 'Seize the day',
        emoji: '🌅',
      ),
      HabitSuggestion(
        name: 'Plan the Day',
        subtitle: 'Organize your tasks',
        emoji: '📝',
      ),
      HabitSuggestion(
        name: 'Clean Room',
        subtitle: 'Tidy space, tidy mind',
        emoji: '🧹',
      ),
      HabitSuggestion(
        name: 'Make Breakfast',
        subtitle: 'Start with nutrition',
        emoji: '🍳',
      ),
      HabitSuggestion(
        name: 'Evening Walk',
        subtitle: 'Unwind and reflect',
        emoji: '🚶‍♂️',
      ),
      HabitSuggestion(
        name: 'Limit Coffee',
        subtitle: 'One cup a day',
        emoji: '☕',
      ),
      HabitSuggestion(
        name: 'Skincare Routine',
        subtitle: 'Take care of yourself',
        emoji: '✨',
      ),
      HabitSuggestion(
        name: 'Declutter 10 mins',
        subtitle: 'Organize daily',
        emoji: '📦',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'productivity',
    name: 'Productivity',
    description: 'Boost your efficiency and get more done',
    iconEmoji: '⚡',
    suggestions: [
      HabitSuggestion(
        name: 'Deep Work Session',
        subtitle: '90 min focused work',
        emoji: '🎯',
      ),
      HabitSuggestion(
        name: 'Plan Tomorrow',
        subtitle: 'Evening planning',
        emoji: '📋',
      ),
      HabitSuggestion(
        name: 'Inbox Zero',
        subtitle: 'Clear your emails',
        emoji: '📧',
      ),
      HabitSuggestion(
        name: 'Review Goals',
        subtitle: 'Check weekly progress',
        emoji: '🎯',
      ),
      HabitSuggestion(
        name: 'Time Blocking',
        subtitle: 'Schedule your day',
        emoji: '⏰',
      ),
      HabitSuggestion(
        name: 'Pomodoro Session',
        subtitle: '25 min focused work',
        emoji: '🍅',
      ),
      HabitSuggestion(
        name: 'Prioritize Tasks',
        subtitle: 'Top 3 for today',
        emoji: '📌',
      ),
      HabitSuggestion(
        name: 'No Multitasking',
        subtitle: 'One task at a time',
        emoji: '🚫',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'mindfulness',
    name: 'Mindfulness',
    description: 'Cultivate peace and mental clarity',
    iconEmoji: '🧘',
    suggestions: [
      HabitSuggestion(
        name: 'Morning Meditation',
        subtitle: '10 minutes of calm',
        emoji: '🧘‍♀️',
      ),
      HabitSuggestion(
        name: 'Breathing Exercise',
        subtitle: 'Deep breathing',
        emoji: '🌬️',
      ),
      HabitSuggestion(
        name: 'Mindful Walk',
        subtitle: 'Walk with awareness',
        emoji: '🚶',
      ),
      HabitSuggestion(
        name: 'No Social Media',
        subtitle: 'Digital detox hour',
        emoji: '📵',
      ),
      HabitSuggestion(
        name: 'Evening Reflection',
        subtitle: 'Review your day',
        emoji: '🌙',
      ),
      HabitSuggestion(
        name: 'Body Scan',
        subtitle: 'Connect with yourself',
        emoji: '💆',
      ),
      HabitSuggestion(
        name: 'Affirmations',
        subtitle: 'Positive self-talk',
        emoji: '💭',
      ),
      HabitSuggestion(
        name: 'Nature Time',
        subtitle: 'Be outdoors',
        emoji: '🌳',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'finance',
    name: 'Finance',
    description: 'Build wealth and financial security',
    iconEmoji: '💰',
    suggestions: [
      HabitSuggestion(
        name: 'Track Expenses',
        subtitle: 'Log daily spending',
        emoji: '💳',
      ),
      HabitSuggestion(
        name: 'Review Budget',
        subtitle: 'Check your finances',
        emoji: '📊',
      ),
      HabitSuggestion(
        name: 'Save 10%',
        subtitle: 'Auto-save income',
        emoji: '🏦',
      ),
      HabitSuggestion(
        name: 'Learn Investing',
        subtitle: 'Read finance news',
        emoji: '📈',
      ),
      HabitSuggestion(
        name: 'No Impulse Buy',
        subtitle: 'Avoid unnecessary spending',
        emoji: '🚫',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'learning',
    name: 'Learning',
    description: 'Expand your knowledge and skills',
    iconEmoji: '📚',
    suggestions: [
      HabitSuggestion(
        name: 'Read 30 Pages',
        subtitle: 'Daily reading habit',
        emoji: '📖',
      ),
      HabitSuggestion(
        name: 'Watch Tutorial',
        subtitle: 'Learn something new',
        emoji: '🎥',
      ),
      HabitSuggestion(
        name: 'Practice Coding',
        subtitle: 'Code for 1 hour',
        emoji: '💻',
      ),
      HabitSuggestion(
        name: 'Language Practice',
        subtitle: 'Duolingo or study',
        emoji: '🗣️',
      ),
      HabitSuggestion(
        name: 'Listen Podcast',
        subtitle: 'Educational content',
        emoji: '🎧',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'social_relationships',
    name: 'Social',
    description: 'Strengthen relationships and connections',
    iconEmoji: '👥',
    suggestions: [
      HabitSuggestion(
        name: 'Call Family',
        subtitle: 'Stay connected',
        emoji: '📞',
      ),
      HabitSuggestion(
        name: 'Quality Time',
        subtitle: 'Spend time together',
        emoji: '❤️',
      ),
      HabitSuggestion(
        name: 'Message Friend',
        subtitle: 'Check in on someone',
        emoji: '💬',
      ),
      HabitSuggestion(
        name: 'Give Compliment',
        subtitle: 'Brighten someone\'s day',
        emoji: '🌟',
      ),
      HabitSuggestion(
        name: 'Active Listening',
        subtitle: 'Be present',
        emoji: '👂',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'creativity',
    name: 'Creativity',
    description: 'Express yourself and create',
    iconEmoji: '🎨',
    suggestions: [
      HabitSuggestion(
        name: 'Draw or Sketch',
        subtitle: 'Visual expression',
        emoji: '✏️',
      ),
      HabitSuggestion(
        name: 'Write Journal',
        subtitle: 'Free writing',
        emoji: '✍️',
      ),
      HabitSuggestion(
        name: 'Play Music',
        subtitle: 'Practice instrument',
        emoji: '🎸',
      ),
      HabitSuggestion(
        name: 'Take Photo',
        subtitle: 'Capture moments',
        emoji: '📷',
      ),
      HabitSuggestion(
        name: 'Creative Project',
        subtitle: 'Work on passion',
        emoji: '🎭',
      ),
    ],
  ),
  const HabitCategoryData(
    id: 'general',
    name: 'General',
    description: 'Simple habits for everyday life',
    iconEmoji: '✨',
    suggestions: [
      HabitSuggestion(
        name: 'Custom Habit',
        subtitle: 'Create your own',
        emoji: '✨',
      ),
    ],
  ),
];
