enum PetDiaryEntryType {
  challengeCompleted,
  focusTaskCompleted,
  milestoneReached,
  moodUpdate,
  levelUp,
  general,
}

class PetDiaryEntry {
  final String id;
  final DateTime date;
  final String message;
  final String moodEmoji;
  final PetDiaryEntryType type;

  PetDiaryEntry({
    required this.id,
    required this.date,
    required this.message,
    required this.moodEmoji,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'message': message,
      'moodEmoji': moodEmoji,
      'type': type.name,
    };
  }

  factory PetDiaryEntry.fromJson(Map<String, dynamic> json) {
    return PetDiaryEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      message: json['message'],
      moodEmoji: json['moodEmoji'],
      type: PetDiaryEntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PetDiaryEntryType.general,
      ),
    );
  }
}
