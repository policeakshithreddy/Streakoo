import 'package:flutter/material.dart';
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
  final List<CoachMessage> _messages = [];
  bool _isTyping = false;

  late AiCoachService _ai;

  @override
  void initState() {
    super.initState();

    _ai = AiCoachService.instance;

    _messages.add(
      CoachMessage(
        from: 'coach',
        text:
            "Hey! I'm your Streakoo Coach 🤖🔥\nWhat do you want help with regarding \"${widget.habit.name}\"?",
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
    } catch (e) {
      setState(() {
        _messages.add(
          const CoachMessage(
            from: 'coach',
            text: "Hmm… something went wrong 😅\nTry again in a bit.",
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
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if user has made ANY progress (completed any habit at least once)
    final hasProgress =
        appState.habits.any((h) => h.streak > 0 || h.completedToday);

    if (!hasProgress) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text('Coach – ${widget.habit.name}'),
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
                  'Complete at least one habit to unlock your AI Coach! 🤖\n\nOnce you make some progress, I\'ll be here to help you level up.',
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
        title: Text('Coach – ${widget.habit.name}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
                      hintText: 'Ask your coach…',
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
                        colors: [CoachScreen._primaryOrange, Color(0xFFFFBB6E)],
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
