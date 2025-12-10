import 'package:flutter/foundation.dart';

/// Types of coach messages for different visual styling
enum CoachMessageType {
  normal, // Regular chat message
  tip, // Actionable tip with gradient card
  celebration, // Achievement/milestone with confetti
}

@immutable
class CoachMessage {
  final String from; // "coach" or "user"
  final String text;
  final CoachMessageType messageType;
  final List<String> quickReplies;
  final String? reaction; // User's reaction emoji

  const CoachMessage({
    required this.from,
    required this.text,
    this.messageType = CoachMessageType.normal,
    this.quickReplies = const [],
    this.reaction,
  });

  bool get isFromCoach => from.toLowerCase() == 'coach';
  bool get isFromUser => !isFromCoach;

  /// Create a copy with updated reaction
  CoachMessage copyWith({
    String? from,
    String? text,
    CoachMessageType? messageType,
    List<String>? quickReplies,
    String? reaction,
  }) {
    return CoachMessage(
      from: from ?? this.from,
      text: text ?? this.text,
      messageType: messageType ?? this.messageType,
      quickReplies: quickReplies ?? this.quickReplies,
      reaction: reaction ?? this.reaction,
    );
  }
}
