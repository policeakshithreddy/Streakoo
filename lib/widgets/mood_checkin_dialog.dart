import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/mood_tracker.dart';

class MoodCheckinDialog extends StatefulWidget {
  final Function(MoodEntry) onMoodSelected;

  const MoodCheckinDialog({
    super.key,
    required this.onMoodSelected,
  });

  @override
  State<MoodCheckinDialog> createState() => _MoodCheckinDialogState();
}

class _MoodCheckinDialogState extends State<MoodCheckinDialog> {
  MoodType? _selectedMood;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitMood() {
    if (_selectedMood == null) return;

    final entry = MoodEntry(
      id: const Uuid().v4(),
      mood: _selectedMood!,
      timestamp: DateTime.now(),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    widget.onMoodSelected(entry);
    Navigator.of(context).pop();
  }

  Widget _buildMoodOption(MoodType mood) {
    final isSelected = _selectedMood == mood;
    final entry = MoodEntry(
      id: '',
      mood: mood,
      timestamp: DateTime.now(),
    );

    return GestureDetector(
      onTap: () => setState(() => _selectedMood = mood),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected
              ? _hexToColor(entry.colorHex).withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isSelected ? _hexToColor(entry.colorHex) : Colors.transparent,
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            entry.emoji,
            style: TextStyle(
              fontSize: isSelected ? 36 : 32,
            ),
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Mood options
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: MoodType.values
                  .map((mood) => _buildMoodOption(mood))
                  .toList(),
            ),

            const SizedBox(height: 20),

            // Mood label
            if (_selectedMood != null)
              Text(
                MoodEntry(
                  id: '',
                  mood: _selectedMood!,
                  timestamp: DateTime.now(),
                ).displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _hexToColor(
                    MoodEntry(
                      id: '',
                      mood: _selectedMood!,
                      timestamp: DateTime.now(),
                    ).colorHex,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Optional notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
              maxLength: 100,
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Skip'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _selectedMood == null ? null : _submitMood,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
