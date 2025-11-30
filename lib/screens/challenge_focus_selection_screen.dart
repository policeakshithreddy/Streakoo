import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../utils/slide_route.dart';
import 'ai_analyzing_screen.dart';

class ChallengeFocusSelectionScreen extends StatefulWidget {
  final String displayName;
  final int age;
  final List<String> goals;
  final List<String> struggles;
  final String timeOfDay;
  final int challengeTargetDays;

  const ChallengeFocusSelectionScreen({
    super.key,
    required this.displayName,
    required this.age,
    required this.goals,
    required this.struggles,
    required this.timeOfDay,
    required this.challengeTargetDays,
  });

  @override
  State<ChallengeFocusSelectionScreen> createState() =>
      _ChallengeFocusSelectionScreenState();
}

class _ChallengeFocusSelectionScreenState
    extends State<ChallengeFocusSelectionScreen> {
  final Set<String> _selectedHabitIds = {};

  void _continue() {
    // Set the selected habits as focus tasks
    final appState = context.read<AppState>();

    for (final habit in appState.habits) {
      final shouldBeFocus = _selectedHabitIds.contains(habit.id);
      if (habit.isFocusTask != shouldBeFocus) {
        appState.updateHabit(habit.copyWith(isFocusTask: shouldBeFocus));
      }
    }

    // Navigate to AI analyzing screen
    Navigator.of(context).push(
      slideFromRight(
        AiAnalyzingScreen(
          displayName: widget.displayName,
          goals: widget.goals,
          struggles: widget.struggles,
          timeOfDay: widget.timeOfDay,
          age: widget.age,
          challengeTargetDays: widget.challengeTargetDays,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final habits = appState.habits;
    final theme = Theme.of(context);

    // Calculate freeze reward
    int freezeReward = 2;
    String badge = '🥉';
    if (widget.challengeTargetDays == 15) {
      freezeReward = 3;
      badge = '🥈';
    } else if (widget.challengeTargetDays == 30) {
      freezeReward = 6;
      badge = '🥇';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Focus Tasks'),
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(badge, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${widget.challengeTargetDays}-Day Challenge',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('❄️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Complete this challenge to earn $freezeReward Streak Freezes!',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⭐ Select up to 5 Focus Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only Focus Tasks will be protected by Streak Freezes. Choose wisely!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Habit List
          Expanded(
            child: habits.isEmpty
                ? const Center(
                    child: Text('No habits yet. Create some first!'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      final isSelected = _selectedHabitIds.contains(habit.id);
                      final canSelect =
                          isSelected || _selectedHabitIds.length < 5;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isSelected
                            ? Colors.amber.withOpacity(0.1)
                            : theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                isSelected ? Colors.amber : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: canSelect
                              ? () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedHabitIds.remove(habit.id);
                                    } else {
                                      _selectedHabitIds.add(habit.id);
                                    }
                                  });
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Checkbox
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.amber
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? Colors.amber
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                // Emoji
                                Text(
                                  habit.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: 12),
                                // Name and streak
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        habit.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${habit.streak} day streak',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Star if selected
                                if (isSelected)
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom bar with counter and button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Counter
                  Text(
                    '${_selectedHabitIds.length} / 5 Focus Tasks Selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedHabitIds.isEmpty
                          ? Colors.grey
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _selectedHabitIds.isNotEmpty ? _continue : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedHabitIds.isEmpty
                            ? 'Select at least 1 habit'
                            : 'Continue to AI Analysis',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
