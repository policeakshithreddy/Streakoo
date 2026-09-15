import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../services/groq_ai_service.dart';

/// Pet Chat screen where user talks WITH the pet (not AI)
class PetChatScreen extends StatefulWidget {
  const PetChatScreen({super.key});

  @override
  State<PetChatScreen> createState() => _PetChatScreenState();
}

class _PetChatScreenState extends State<PetChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  final Random _random = Random();

  // Pet expressions during chat
  final String _currentPetMood = '🐥';
  String _currentExpression = '';

  // Pet personality phrases
  static const List<String> _greetings = [
    "Chirp chirp! 🐥 What's on your mind?",
    "Hiya friend! I missed you! 💕",
    "Yay, you're here! Let's chat! ✨",
    "Peep peep! How can I help today? 🌟",
  ];

  static const List<String> _thinkingPhrases = [
    "Hmm, let me think...",
    "*pecks around thoughtfully* 🤔",
    "Ooh, interesting question!",
    "*fluffs feathers* Let me see...",
  ];

  static const List<String> _encouragements = [
    "You're doing amazing! I'm so proud! 🎉",
    "Keep going! I believe in you! 💪",
    "Every small step counts! ⭐",
    "You've got this, friend! 🌟",
  ];

  @override
  void initState() {
    super.initState();
    _addPetGreeting();
  }

  void _addPetGreeting() {
    final greeting = _greetings[_random.nextInt(_greetings.length)];
    _messages.add(_ChatMessage(
      text: greeting,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _currentExpression = '👀'; // Pet looks at message
    });
    _messageController.clear();
    _scrollToBottom();
    HapticFeedback.lightImpact();

    // Simulate pet "thinking"
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _currentExpression = '🤔');

    // Generate pet response via AI with pet personality
    final response = await _generatePetResponse(text);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _currentExpression = _getExpressionForResponse(response);
    });
    _scrollToBottom();
    HapticFeedback.mediumImpact();

    // Clear expression after a moment
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _currentExpression = '');
    });
  }

  Future<String> _generatePetResponse(String userMessage) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final habits = appState.habits;
      final streaks =
          habits.map((h) => '${h.name}: ${h.streak} days').join(', ');

      final petName = appState.petName;

      final systemPrompt =
          '''You are $petName, a cute, friendly baby chick pet 🐥 in a habit tracking app. 
You have a playful, encouraging personality. You speak in short, fun sentences with emojis.
You care deeply about helping your owner build good habits.

User's habits and streaks: $streaks

The user said: "$userMessage"

Respond AS THE PET (not as an AI). Be cute, supportive, and fun!
You can use occasional bird sounds (like *chirp* or *peep*) when excited or happy, but don't overuse them.
Avoid making up strange sounds like "preep" or "chreep".
Keep response under 3 sentences. Include 1-2 emojis.''';

      final groqService = GroqAIService.instance;
      final response = await groqService.generateResponse(
        systemPrompt: systemPrompt,
        userPrompt: userMessage,
      );
      return response ?? _getFallbackResponse(userMessage);
    } catch (e) {
      return _getFallbackResponse(userMessage);
    }
  }

  String _getFallbackResponse(String userMessage) {
    final lower = userMessage.toLowerCase();

    if (lower.contains('habit') || lower.contains('streak')) {
      return "Peep! Your habits are looking great! Keep it up! 🌟";
    } else if (lower.contains('sad') || lower.contains('tired')) {
      return "Aww, *nuzzles you* 🐥💕 Tomorrow is a new day, friend! You've got this!";
    } else if (lower.contains('help') || lower.contains('?')) {
      return "Chirp! I'm here to cheer you on! What do you need help with? ✨";
    } else if (lower.contains('love') || lower.contains('cute')) {
      return "*happy chirps* 🥰 I love you too, friend! You make me so happy!";
    } else {
      return _encouragements[_random.nextInt(_encouragements.length)];
    }
  }

  String _getExpressionForResponse(String response) {
    if (response.contains('love') || response.contains('💕')) return '😍';
    if (response.contains('proud') || response.contains('🎉')) return '🤩';
    if (response.contains('sad') || response.contains('tired')) return '🥺';
    if (response.contains('great') || response.contains('amazing')) return '😊';
    return '';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Consumer<AppState>(
          builder: (context, appState, _) {
            final petName = appState.petName;
            return Row(
              children: [
                Text(_currentPetMood, style: const TextStyle(fontSize: 28)),
                if (_currentExpression.isNotEmpty)
                  Text(_currentExpression, style: const TextStyle(fontSize: 20))
                      .animate()
                      .fadeIn()
                      .scale(begin: const Offset(0.5, 0.5)),
                const SizedBox(width: 8),
                Text('Chat with $petName'),
              ],
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(isDark);
                }
                return _buildMessageBubble(_messages[index], isDark);
              },
            ),
          ),

          // Quick action buttons
          _buildQuickActions(isDark),

          // Message input
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, bool isDark) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const Text('🐥', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFFFFA94A), Color(0xFFFFD54F)],
                      )
                    : LinearGradient(
                        colors: isDark
                            ? [Colors.grey[800]!, Colors.grey[700]!]
                            : [Colors.white, Colors.grey[100]!],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: 15,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms).slideX(
                begin: isUser ? 0.2 : -0.2,
                end: 0,
                duration: 200.ms,
              ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Text('🐥', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _thinkingPhrases[_random.nextInt(_thinkingPhrases.length)],
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(
                  3,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA94A),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 200))
                      .fadeIn()
                      .then()
                      .fadeOut()
                      .then()
                      .fadeIn(),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildQuickActions(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildQuickButton('How am I doing? 📊', isDark),
          _buildQuickButton('Motivate me! 💪', isDark),
          _buildQuickButton('Tell me a tip 💡', isDark),
          _buildQuickButton('I need help 🆘', isDark),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () => _sendMessage(text),
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        side: const BorderSide(color: Color(0xFFFFA94A)),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Talk to Streaky...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFA94A), Color(0xFFFFD54F)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
