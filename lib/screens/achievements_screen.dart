import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../state/app_state.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? existing;

  const AddHabitScreen({
    super.key,
    this.existing,
  });

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emojiCtrl = TextEditingController(text: '🔥');

  String _category = 'General';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _emojiCtrl.text = widget.existing!.emoji;
      _category = widget.existing!.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();

    if (widget.existing == null) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final habit = Habit(
        id: id,
        name: _nameCtrl.text.trim(),
        emoji: _emojiCtrl.text.trim().isEmpty ? '🔥' : _emojiCtrl.text.trim(),
        category: _category,
      );
      appState.addHabit(habit);
    } else {
      final updated = widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        emoji: _emojiCtrl.text.trim().isEmpty ? '🔥' : _emojiCtrl.text.trim(),
        category: _category,
      );
      appState.updateHabit(updated);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit habit' : 'Add habit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter a habit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emojiCtrl,
                maxLength: 2,
                decoration: const InputDecoration(
                  labelText: 'Emoji',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Health', child: Text('Health')),
                  DropdownMenuItem(value: 'Study', child: Text('Study')),
                  DropdownMenuItem(value: 'Work', child: Text('Work')),
                  DropdownMenuItem(value: 'Mind', child: Text('Mind')),
                  DropdownMenuItem(value: 'General', child: Text('General')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _category = v);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Save changes' : 'Create habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
