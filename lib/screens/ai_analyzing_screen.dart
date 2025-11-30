import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ai_habit_engine.dart';
import 'suggestion_screen.dart';

class AiAnalyzingScreen extends StatefulWidget {
  final String displayName;
  final List<String> goals;
  final List<String> struggles;
  final String timeOfDay;
  final int age;
  final int challengeTargetDays;

  const AiAnalyzingScreen({
    super.key,
    required this.displayName,
    required this.goals,
    required this.struggles,
    required this.timeOfDay,
    required this.age,
    required this.challengeTargetDays,
  });

  @override
  State<AiAnalyzingScreen> createState() => _AiAnalyzingScreenState();
}

class _AiAnalyzingScreenState extends State<AiAnalyzingScreen> {
  @override
  void initState() {
    super.initState();

    // Fake AI work
    Timer(const Duration(seconds: 2), () {
      final suggestions = const AiHabitEngine().buildFromAnswers(
        mainGoal: widget.goals.isNotEmpty ? widget.goals.first : 'General',
        struggles: widget.struggles,
        timeOfDay: [widget.timeOfDay],
        age: widget.age,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuggestionScreen(
            displayName: widget.displayName,
            suggestions: suggestions,
            challengeTargetDays: widget.challengeTargetDays,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(strokeWidth: 6),
            ),
            const SizedBox(height: 20),
            Text(
              'Scanning your answers…',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Cooking up starter habits just for you ✨',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
