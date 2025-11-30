class CoachMessage {
  final String from; // 'coach' or 'user'
  final String text;

  CoachMessage({required this.from, required this.text});
}

final List<CoachMessage> mockConversation = [
  CoachMessage(
    from: 'coach',
    text: 'Hey, proud of you for keeping up with your habits this week 🔥',
  ),
  CoachMessage(
    from: 'user',
    text: 'Thanks, I missed one day though.',
  ),
  CoachMessage(
    from: 'coach',
    text:
        'That\'s completely fine. Let\'s look at what blocked you and make a tiny adjustment for tomorrow. No guilt, only data 📊',
  ),
  CoachMessage(
    from: 'coach',
    text:
        'Remember: consistency beats perfection. Your 11-day streak still tells a strong story.',
  ),
];
