import 'package:flutter/foundation.dart';

@immutable
class CoachMessage {
  final String from; // "coach" or "user"
  final String text;

  const CoachMessage({
    required this.from,
    required this.text,
  });

  bool get isFromCoach => from.toLowerCase() == 'coach';

  bool get isFromUser => !isFromCoach;
}
