import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/habit_idea.dart';
import '../state/app_state.dart';
import 'nav_wrapper.dart';

class SuggestionScreen extends StatefulWidget {
  final String displayName;
  final List<HabitIdea> suggestions;
  final int challengeTargetDays;

  const SuggestionScreen({
    super.key,
    required this.displayName,
    required this.suggestions,
    required this.challengeTargetDays,
  });

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  late List<_SelectableIdea> _items;

  @override
  void initState() {
    super.initState();

    _items = widget.suggestions
        .map((idea) => _SelectableIdea(idea: idea, selected: true))
        .toList();
  }

  void _toggle(int index, bool? value) {
    setState(() {
      _items[index].selected = value ?? false;
    });
  }

  Future<void> _editIdea(int index) async {
    final idea = _items[index].idea;

    final nameCtrl = TextEditingController(text: idea.name);
    final emojiCtrl = TextEditingController(text: idea.emoji);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit habit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Habit name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiCtrl,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: "Emoji",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() {
        _items[index] = _SelectableIdea(
          idea: idea.copyWith(
            name:
                nameCtrl.text.trim().isEmpty ? idea.name : nameCtrl.text.trim(),
            emoji: emojiCtrl.text.trim().isEmpty
                ? idea.emoji
                : emojiCtrl.text.trim(),
          ),
          selected: _items[index].selected,
        );
      });
    }
  }

  Future<void> _createHabits() async {
    final appState = context.read<AppState>();

    final selected = _items.where((i) => i.selected).toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one habit to continue.")),
      );
      return;
    }

    for (final item in selected) {
      final idea = item.idea;

      final habit = Habit(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: idea.name,
        emoji: idea.emoji,
        category: idea.category,
        streak: 0,
        completedToday: false,
        completionDates: [],
        challengeTargetDays: widget.challengeTargetDays,
        challengeProgress: 0,
        challengeCompleted: false,
      );

      appState.addHabit(habit);
    }

    if (!mounted) return;

    await appState.setFirstRunComplete();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const NavWrapper()),
      (route) => false,
    );
  }

  Future<void> _addCustomHabit() async {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Custom Habit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Habit name",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiCtrl,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: "Emoji (optional)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Add"),
          ),
        ],
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _items.add(_SelectableIdea(
          idea: HabitIdea(
            name: nameCtrl.text.trim(),
            emoji: emojiCtrl.text.trim().isEmpty ? '✨' : emojiCtrl.text.trim(),
            category: 'Custom',
          ),
          selected: true,
        ));
      });
    }
  }

  void _removeHabit(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Habit Plan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addCustomHabit,
            tooltip: 'Add custom habit',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Here is your AI-generated plan, ${widget.displayName}. Customize it as you like!",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount:
                    _items.length + 1, // +1 for the "Add" button at bottom
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: OutlinedButton.icon(
                        onPressed: _addCustomHabit,
                        icon: const Icon(Icons.add),
                        label: const Text('Add another habit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.5),
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    );
                  }

                  final item = _items[index];
                  final idea = item.idea;

                  // Staggered animation
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: item.selected ? 2 : 0,
                      color: item.selected
                          ? theme.cardColor
                          : theme.disabledColor.withValues(alpha: 0.1),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            idea.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        title: Text(
                          idea.name,
                          style: TextStyle(
                            decoration: item.selected
                                ? null
                                : TextDecoration.lineThrough,
                            color: item.selected ? null : theme.disabledColor,
                          ),
                        ),
                        subtitle: Text(idea.category),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editIdea(index),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () => _removeHabit(index),
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                        onTap: () => _toggle(index, !item.selected),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _createHabits,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Start My Journey 🚀"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableIdea {
  HabitIdea idea;
  bool selected;

  _SelectableIdea({
    required this.idea,
    this.selected = true,
  });
}
