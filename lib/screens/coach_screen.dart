import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/coach_message.dart';
import '../models/habit.dart';
import '../widgets/coach_message_bubble.dart';
import '../services/ai_coach_service.dart';
import '../services/health_service.dart';
import '../state/app_state.dart';

class CoachScreen extends StatefulWidget {
  final Habit habit;
  const CoachScreen({super.key, required this.habit});

  // App theme colors
  static const _primaryOrange = Color(0xFFFFA94A);

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<CoachMessage> _messages = [];
  bool _isTyping = false;

  late AiCoachService _ai;

  // Quick reply options based on context
  List<String> _getQuickReplies(String response) {
    final lower = response.toLowerCase();

    if (lower.contains('streak') || lower.contains('days')) {
      return ['How do I maintain it?', 'What if I miss a day?', 'Thanks! 🙏'];
    }
    if (lower.contains('tip') || lower.contains('try')) {
      return ['Tell me more', 'I\'ll try that!', 'Any alternatives?'];
    }
    if (lower.contains('congratulations') || lower.contains('amazing')) {
      return ['Thanks! 😊', 'What\'s next?', 'How can I improve?'];
    }

    return ['Tell me more', 'How do I start?', 'Thanks! 🙏'];
  }

  // Detect message type from response
  CoachMessageType _detectMessageType(String response) {
    final lower = response.toLowerCase();

    if (lower.contains('congratulations') ||
        lower.contains('amazing') ||
        lower.contains('🎉') ||
        lower.contains('🏆')) {
      return CoachMessageType.celebration;
    }

    if (lower.contains('tip:') ||
        lower.contains('pro tip') ||
        lower.contains('💡')) {
      return CoachMessageType.tip;
    }

    return CoachMessageType.normal;
  }

  @override
  void initState() {
    super.initState();

    _ai = AiCoachService.instance;

    _messages.add(
      CoachMessage(
        from: 'coach',
        text:
            "Hey! I'm Wind 🌬️\nLet's talk about \"${widget.habit.name}\" – what's on your mind?",
        quickReplies: const [
          'Tips to improve',
          'Why is this hard?',
          'Motivation please!'
        ],
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
      if (!mounted) return;
      final appState = context.read<AppState>();

      // Fetch today's health metrics
      final healthService = HealthService.instance;
      final todaySteps = await healthService.getTodaySteps();
      final todayDistance = await healthService.getTodayDistance();
      final todaySleep = await healthService.getTodaySleep();
      final todayHeartRate = await healthService.getTodayHeartRate();

      final reply = await _ai
          .getReply(
            habit: widget.habit,
            userMessage: text,
            streak: widget.habit.streak,
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
    } catch (e) {
      setState(() {
        _messages.add(
          const CoachMessage(
            from: 'coach',
            text: "Hmm… something went wrong 😅\nTry again in a bit.",
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
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if user has made ANY progress
    final hasProgress =
        appState.habits.any((h) => h.streak > 0 || h.completedToday);

    if (!hasProgress) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text('Wind – ${widget.habit.name}'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Locked icon with gradient glow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        CoachScreen._primaryOrange.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 64,
                    color: CoachScreen._primaryOrange,
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                    ),
                const SizedBox(height: 24),
                Text(
                  'Coach Locked',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 16),
                Text(
                  'Complete at least one habit to unlock Wind! 🌬️\n\nOnce you make some progress, I\'ll be here to help you level up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [CoachScreen._primaryOrange, Color(0xFFFFBB6E)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color:
                              CoachScreen._primaryOrange.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Go Back & Complete a Habit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA94A), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🌬️', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
            Text('Wind – ${widget.habit.name}'),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.grey[50],
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask Wind…',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: CoachScreen._primaryOrange,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [CoachScreen._primaryOrange, Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color:
                              CoachScreen._primaryOrange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
