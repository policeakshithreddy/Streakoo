enum MoodType {
  happy,
  neutral,
  sad,
  stressed,
  energetic,
}

class MoodEntry {
  final String id;
  final MoodType mood;
  final DateTime timestamp;
  final String? notes;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.timestamp,
    this.notes,
  });

  // Get emoji for mood
  String get emoji {
    switch (mood) {
      case MoodType.happy:
        return '😊';
      case MoodType.neutral:
        return '😐';
      case MoodType.sad:
        return '😞';
      case MoodType.stressed:
        return '😰';
      case MoodType.energetic:
        return '⚡';
    }
  }

  // Get display name for mood
  String get displayName {
    switch (mood) {
      case MoodType.happy:
        return 'Happy';
      case MoodType.neutral:
        return 'Neutral';
      case MoodType.sad:
        return 'Sad';
      case MoodType.stressed:
        return 'Stressed';
      case MoodType.energetic:
        return 'Energetic';
    }
  }

  // Get color for mood
  String get colorHex {
    switch (mood) {
      case MoodType.happy:
        return '#FFD700'; // Gold
      case MoodType.neutral:
        return '#A0AEC0'; // Gray
      case MoodType.sad:
        return '#4299E1'; // Blue
      case MoodType.stressed:
        return '#F56565'; // Red
      case MoodType.energetic:
        return '#48BB78'; // Green
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood': mood.toString(),
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    final moodStr = json['mood'] as String;
    final mood = MoodType.values.firstWhere(
      (e) => e.toString() == moodStr,
      orElse: () => MoodType.neutral,
    );

    return MoodEntry(
      id: json['id'] as String,
      mood: mood,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
    );
  }
}

class MoodAnalysis {
  final Map<MoodType, int> moodCounts;
  final MoodType? dominantMood;
  final double averageMoodScore;

  MoodAnalysis({
    required this.moodCounts,
    this.dominantMood,
    required this.averageMoodScore,
  });

  // Analyze moods from entries
  factory MoodAnalysis.fromEntries(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return MoodAnalysis(
        moodCounts: {},
        dominantMood: null,
        averageMoodScore: 0.5,
      );
    }

    final counts = <MoodType, int>{};
    double totalScore = 0;

    for (final entry in entries) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
      totalScore += _moodScore(entry.mood);
    }

    MoodType? dominant;
    int maxCount = 0;
    counts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = mood;
      }
    });

    return MoodAnalysis(
      moodCounts: counts,
      dominantMood: dominant,
      averageMoodScore: totalScore / entries.length,
    );
  }

  // Mood score from 0 (sad) to 1 (energetic)
  static double _moodScore(MoodType mood) {
    switch (mood) {
      case MoodType.sad:
        return 0.2;
      case MoodType.stressed:
        return 0.3;
      case MoodType.neutral:
        return 0.5;
      case MoodType.happy:
        return 0.8;
      case MoodType.energetic:
        return 1.0;
    }
  }
}
