import 'package:flutter/material.dart';
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
  final List<CoachMessage> _messages = [];
  bool _isTyping = false;
  late AiCoachService _ai;

  @override
  void initState() {
    super.initState();
    _ai = AiCoachService.instance;

    // Add initial greeting
    _messages.add(
      CoachMessage(
        from: 'coach',
        text: widget.initialContext ??
            (widget.contextHabit != null
                ? 'Hey! Let\'s talk about "${widget.contextHabit!.name}" ${widget.contextHabit!.emoji}\\nWhat do you want to know?'
                : 'Hey! I\'m your Streakoo AI Coach 🤖🔥\\nAsk me anything about your habits!'),
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(CoachMessage(from: 'user', text: text));
      _controller.clear();
      _isTyping = true;
    });

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
              allHabits: appState.habits, // Pass all habits for context
              userLevel: appState.userLevel.level, // Pass user level
              totalXP: appState.totalXP, // Pass total XP
              todaySteps: todaySteps, // Health data
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
          _messages.add(CoachMessage(from: 'coach', text: reply));
          _isTyping = false;
        });
      } else {
        setState(() {
          _messages.add(
            const CoachMessage(
              from: 'coach',
              text:
                  'It looks like you don\'t have any habits yet! Create your first habit to get started. 🚀',
            ),
          );
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          const CoachMessage(
            from: 'coach',
            text: 'Hmm… something went wrong 😅\\nTry again in a bit.',
          ),
        );
        _isTyping = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF50C9FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your AI Coach',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Always here to help',
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

          const Divider(height: 1),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const CoachMessageBubble(
                    message: CoachMessage(from: 'coach', text: 'Typing…'),
                    isThinking: true,
                  );
                }

                return CoachMessageBubble(
                  message: _messages[index],
                );
              },
            ),
          ),

          const Divider(height: 1),

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
                        hintText: 'Ask me anything...',
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
                        colors: [Color(0xFF4A90E2), Color(0xFF50C9FF)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
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
