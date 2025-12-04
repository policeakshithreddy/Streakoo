import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../services/ai_health_coach_service.dart';
import '../services/health_service.dart';
import '../state/app_state.dart';

class AICoachChatScreen extends StatefulWidget {
  const AICoachChatScreen({super.key});

  @override
  State<AICoachChatScreen> createState() => _AICoachChatScreenState();
}

class _AICoachChatScreenState extends State<AICoachChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // Suggested questions for new users
  final List<String> _suggestedQuestions = [
    "Why am I not losing weight?",
    "How can I improve my sleep?",
    "What should I eat before a workout?",
    "How do I stay motivated?",
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final appState = context.read<AppState>();
    final challenge = appState.activeHealthChallenge;

    final welcomeText = challenge != null
        ? 'Hi! I\'m your AI coach for the ${challenge.title} challenge. How can I help you today?'
        : 'Hi! I\'m your AI health coach. Ask me anything about fitness, nutrition, or habits!';

    _messages.add(ChatMessage(
      text: welcomeText,
      isUser: false,
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isTyping = true;
    });

    _inputController.clear();
    _scrollToBottom();

    // Build context for AI
    final context = await _buildChatContext();

    // Call AI
    try {
      final response = await AIHealthCoachService.instance.chatWithCoach(
        userMessage: text,
        challenge: context['challenge'],
        recentMetrics: context['recentMetrics'],
        habits: context['habits'],
      );

      // Add AI response
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
          ));
          _isTyping = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _buildChatContext() async {
    final appState = context.read<AppState>();
    final challenge = appState.activeHealthChallenge;

    // Get recent health metrics
    final healthService = HealthService.instance;
    int recentSteps = 0;
    double recentSleep = 0;

    try {
      recentSteps = await healthService.getStepCount(DateTime.now());
      recentSleep = await healthService.getSleepHours(DateTime.now());
    } catch (e) {
      // Health data might not be available
    }

    return {
      'challenge': challenge,
      'recentMetrics': {
        'steps': recentSteps,
        'sleep': recentSleep,
      },
      'habits': appState.habits,
    };
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Coach'),
            Text(
              'Powered by Groq AI',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return _buildTypingIndicator(theme);
                      }

                      final message = _messages[index];
                      return _buildMessageBubble(message, theme);
                    },
                  ),
          ),

          // Suggested questions (show when conversation is new)
          if (_messages.length <= 1 && !_isTyping)
            _buildSuggestedQuestions(theme),

          // Input bar
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask me anything!',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested questions:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedQuestions.map((question) {
              return ActionChip(
                label: Text(question),
                onPressed: () => _sendMessage(question),
                avatar: Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              child: Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ).animate().scale(
                delay: 100.ms, duration: 300.ms, curve: Curves.elasticOut),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(
                  begin: isUser ? 0.3 : -0.3,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
            ).animate().scale(
                delay: 100.ms, duration: 300.ms, curve: Curves.elasticOut),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(theme, 0),
                const SizedBox(width: 4),
                _buildTypingDot(theme, 200),
                const SizedBox(width: 4),
                _buildTypingDot(theme, 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(ThemeData theme, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: _sendMessage,
              enabled: !_isTyping,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed:
                _isTyping ? null : () => _sendMessage(_inputController.text),
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
