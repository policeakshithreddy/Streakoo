import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/coach_message.dart';
import '../services/ai_coach_service.dart';
import '../services/health_service.dart';
import '../widgets/coach_message_bubble.dart';
import '../state/app_state.dart';

class ChatBottomSheet extends StatefulWidget {
  final Habit? contextHabit; // Optional: for context-aware chat
  final String? initialContext; // Optional: initial message context

  const ChatBottomSheet({
    super.key,
    this.contextHabit,
    this.initialContext,
  });

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<CoachMessage> _messages = [];
  bool _isTyping = false;
  late AiCoachService _ai;

  // Quick reply options based on context
  List<String> _getQuickReplies(String response) {
    final lower = response.toLowerCase();

    // Context-aware quick replies
    if (lower.contains('streak') || lower.contains('days')) {
      return ['How do I maintain it?', 'What if I miss a day?', 'Thanks! 🙏'];
    }
    if (lower.contains('tip') || lower.contains('try')) {
      return ['Tell me more', 'I\'ll try that!', 'Any alternatives?'];
    }
    if (lower.contains('congratulations') ||
        lower.contains('amazing') ||
        lower.contains('awesome')) {
      return ['Thanks! 😊', 'What\'s next?', 'How can I improve?'];
    }
    if (lower.contains('habit')) {
      return ['How do I start?', 'Best time to do it?', 'Make it easier'];
    }

    // Default quick replies
    return ['Tell me more', 'How do I start?', 'Thanks! 🙏'];
  }

  // Detect message type from response
  CoachMessageType _detectMessageType(String response) {
    final lower = response.toLowerCase();

    if (lower.contains('congratulations') ||
        lower.contains('amazing') ||
        lower.contains('incredible') ||
        lower.contains('fantastic') ||
        lower.contains('🎉') ||
        lower.contains('🏆')) {
      return CoachMessageType.celebration;
    }

    if (lower.contains('tip:') ||
        lower.contains('pro tip') ||
        lower.contains('try this') ||
        lower.contains('here\'s a tip') ||
        lower.contains('💡')) {
      return CoachMessageType.tip;
    }

    return CoachMessageType.normal;
  }

  @override
  void initState() {
    super.initState();
    _ai = AiCoachService.instance;

    // Add initial greeting with quick replies
    _messages.add(
      CoachMessage(
        from: 'coach',
        text: widget.initialContext ??
            (widget.contextHabit != null
                ? 'Hey! Let\'s talk about "${widget.contextHabit!.name}" ${widget.contextHabit!.emoji}\nWhat do you want to know?'
                : 'Hey! I\'m Koo, your Streakoo coach! ✨\nAsk me anything about your habits!'),
        quickReplies: widget.contextHabit != null
            ? ['Tips to improve', 'Why is this hard?', 'Motivation please!']
            : ['Show my progress', 'Need motivation', 'Habit tips'],
      ),
    );
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

  void _handleQuickReply(String reply) {
    _controller.text = reply;
    _send();
  }

  void _handleReaction(int messageIndex, String emoji) {
    HapticFeedback.lightImpact();
    setState(() {
      _messages[messageIndex] =
          _messages[messageIndex].copyWith(reaction: emoji);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(CoachMessage(from: 'user', text: text));
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final appState = context.read<AppState>();

      // Use context habit if available, otherwise use a random habit
      final habit = widget.contextHabit ??
          (appState.habits.isNotEmpty ? appState.habits.first : null);

      if (habit != null) {
        // Fetch today's health metrics
        final healthService = HealthService.instance;
        final todaySteps = await healthService.getTodaySteps();
        final todayDistance = await healthService.getTodayDistance();
        final todaySleep = await healthService.getTodaySleep();
        final todayHeartRate = await healthService.getTodayHeartRate();

        final reply = await _ai
            .getReply(
              habit: habit,
              userMessage: text,
              streak: habit.streak,
              allHabits: appState.habits,
              userLevel: appState.userLevel.level,
              totalXP: appState.totalXP,
              todaySteps: todaySteps,
              todayDistance: todayDistance,
              todaySleep: todaySleep,
              todayHeartRate: todayHeartRate,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  "I'm having trouble connecting right now. Please try again later! 🔌",
            );

        setState(() {
          _messages.add(CoachMessage(
            from: 'coach',
            text: reply,
            messageType: _detectMessageType(reply),
            quickReplies: _getQuickReplies(reply),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages.add(
            const CoachMessage(
              from: 'coach',
              text:
                  'It looks like you don\'t have any habits yet! Create your first habit to get started. 🚀',
              quickReplies: ['How do I create one?', 'What habits are best?'],
            ),
          );
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(
          const CoachMessage(
            from: 'coach',
            text: 'Hmm… something went wrong 😅\nTry again in a bit.',
            quickReplies: ['Try again'],
          ),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with Koo branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA94A), Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Your habit coach',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Online indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const CoachMessageBubble(
                    message: CoachMessage(from: 'coach', text: 'Typing…'),
                    isThinking: true,
                  );
                }

                final message = _messages[index];
                return CoachMessageBubble(
                  message: message,
                  onQuickReplyTap: _handleQuickReply,
                  onReactionTap: (emoji) => _handleReaction(index, emoji),
                );
              },
            ),
          ),

          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),

          // Input field
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              bottom: MediaQuery.of(context).viewInsets.bottom == 0,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask Koo anything...',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA94A), Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _send,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
