import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A small, self-owned bottom sheet that provides a focused TextField so the
/// platform keyboard (and emoji keyboard) can be used. It owns and disposes
/// its controllers and focus nodes to avoid lifecycle races.
class SystemEmojiSheet extends StatefulWidget {
  final String? initial;
  const SystemEmojiSheet({super.key, this.initial});

  @override
  State<SystemEmojiSheet> createState() => _SystemEmojiSheetState();
}

class _SystemEmojiSheetState extends State<SystemEmojiSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
    _focusNode = FocusNode();
    // Request focus after the first frame so keyboard appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Use system emoji keyboard',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
                hintText: 'Tap emoji keyboard and choose',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : Theme.of(context).colorScheme.surface),
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(_controller.text.trim()),
                child: const Text('OK'))
          ])
        ]),
      ),
    );
  }
}

/// A self-contained bottom sheet used to edit a habit (name + emoji). It
/// owns its controllers so they are disposed correctly.
class EditHabitSheet extends StatefulWidget {
  final String initialName;
  final String initialEmoji;

  const EditHabitSheet(
      {super.key, required this.initialName, required this.initialEmoji});

  @override
  State<EditHabitSheet> createState() => _EditHabitSheetState();
}

class _EditHabitSheetState extends State<EditHabitSheet> {
  late final TextEditingController _controller;
  late String _emoji;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _emoji = widget.initialEmoji;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Habit')),
          const SizedBox(height: 12),
          Row(children: [
            Text(_emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              onPressed: () async {
                final picked = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const SystemEmojiSheet(),
                );
                if (picked != null && picked.isNotEmpty) {
                  setState(() => _emoji = picked);
                }
              },
            )
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pop({'name': _controller.text.trim(), 'emoji': _emoji}),
                child: const Text('Save')),
          ])
        ]),
      ),
    );
  }
}
