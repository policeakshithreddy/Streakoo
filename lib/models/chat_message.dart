class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? suggestedActions;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.suggestedActions,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'suggestedActions': suggestedActions,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
        suggestedActions: json['suggestedActions'] != null
            ? List<String>.from(json['suggestedActions'])
            : null,
      );
}
