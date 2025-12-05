import 'package:flutter/material.dart';
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

    // Check if user has made ANY progress (completed any habit at least once)
    final hasProgress =
        appState.habits.any((h) => h.streak > 0 || h.completedToday);

    if (!hasProgress) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Coach – ${widget.habit.name}'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                const Text(
                  'Coach Locked',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Complete at least one habit to unlock your AI Coach! 🤖\n\nOnce you make some progress, I\'ll be here to help you level up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back & Complete a Habit'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Coach – ${widget.habit.name}'),
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
