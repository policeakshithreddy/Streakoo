import 'package:flutter/material.dart';
import '../models/habit.dart';

class JournalScreen extends StatefulWidget {
  final Habit habit;

  const JournalScreen({super.key, required this.habit});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _lastSaved;

  void _saveEntry() {
    setState(() {
      _lastSaved = _controller.text.trim();
    });

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journal saved (mock only, no backend yet) 📝'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Journal – ${habit.name}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 8,
              style: TextStyle(color: color.onSurface),
              decoration: InputDecoration(
                hintText: 'How did today go? What helped or blocked you?',
                hintStyle: TextStyle(
                  color: color.onSurface.withValues(alpha: 0.6),
                ),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: color.primary,
                  foregroundColor: color.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_lastSaved != null && _lastSaved!.isNotEmpty) ...[
              const Divider(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Last saved entry (local only):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _lastSaved!,
                  style: TextStyle(color: color.onSurface),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
