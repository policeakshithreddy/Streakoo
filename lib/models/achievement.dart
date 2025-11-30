class Achievement {
  final String id; // e.g. "streak_7" or "challenge_30"
  final String title;
  final String description;
  final String iconEmoji;
  final DateTime earnedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconEmoji: json['iconEmoji']?.toString() ?? '🏆',
      earnedAt: DateTime.tryParse(json['earnedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconEmoji': iconEmoji,
        'earnedAt': earnedAt.toIso8601String(),
      };
}
