class HabitIdea {
  final String name;
  final String emoji;
  final String category;

  HabitIdea({
    required this.name,
    required this.emoji,
    required this.category,
  });

  HabitIdea copyWith({
    String? name,
    String? emoji,
    String? category,
  }) {
    return HabitIdea(
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
    );
  }
}
