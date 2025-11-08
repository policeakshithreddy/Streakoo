// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

// A reusable task title input with smart emoji suggestions and an in-app emoji picker.
// Usage: TaskEditingInput(controller: ..., onChanged: ...)
class TaskEditingInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  const TaskEditingInput({
    Key? key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
    this.validator,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<TaskEditingInput> createState() => _TaskEditingInputState();
}

class _TaskEditingInputState extends State<TaskEditingInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _showPicker = false;

  // Simple lookup map for smart suggestions. Keys are keywords to match in the input,
  // values are lists of emoji strings to suggest.
  static const Map<String, List<String>> _emojiLookup = {
    'drink': ['💧', '🚰', '☕'],
    'water': ['💧', '🚰'],
    'run': ['🏃', '🏃‍♂️', '🏃‍♀️'],
    'exercise': ['🏃', '🏋️', '🤸'],
    'read': ['📚', '📖', '🧠'],
    'study': ['📚', '📝'],
    'sleep': ['😴', '🛌', '🌙'],
    'meditate': ['🧘', '🕊️'],
    'work': ['💼', '🧑‍💻'],
    'code': ['💻', '👨‍💻', '👩‍💻'],
    'yoga': ['🧘', '🕉️'],
    'walk': ['🚶', '🚶‍♀️', '🚶‍♂️'],
    'weight': ['🏋️', '🏋️‍♀️', '🏋️‍♂️'],
    'clean': ['🧹', '🧼'],
    'cook': ['🍳', '🍲', '👩‍🍳'],
    'tea': ['🍵', '☕'],
    'coffee': ['☕', '🥤'],
    'music': ['🎵', '🎧'],
    'habit': ['🔥', '✅'],
    'streak': ['🔥', '📈'],
    'smile': ['😊', '🙂', '😁'],
    'sugar': ['🍭', '🍬'],
  };

  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.initialValue != null && (widget.controller == null)) {
      _controller.text = widget.initialValue!;
    }
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.toLowerCase();
    final found = <String>{};
    if (text.trim().isNotEmpty) {
      for (final entry in _emojiLookup.entries) {
        if (text.contains(entry.key)) {
          found.addAll(entry.value);
        }
      }
    }
    setState(() {
      _suggestions = found.toList();
    });
    if (widget.onChanged != null) widget.onChanged!(_controller.text);
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final int start = selection.start >= 0 ? selection.start : text.length;
    final int end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _controller.text = newText;
    final newOffset = start + emoji.length;
    _controller.selection = TextSelection.collapsed(offset: newOffset);
    // keep focus on the input
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    // Update suggestions after insertion
    _onTextChanged();
  }

  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    // Limit suggestions to 8
    final list = _suggestions.take(8).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final e = list[index];
          return GestureDetector(
            onTap: () => _insertEmoji(e),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(e, style: const TextStyle(fontSize: 20)),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: list.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // suggestions row above field
        _buildSuggestions(),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                textInputAction: TextInputAction.done,
                validator: widget.validator,
                onFieldSubmitted: widget.onSubmitted,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'What will you do?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Emoji toggle button
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                onPressed: () {
                  // toggle picker visibility
                  setState(() {
                    _showPicker = !_showPicker;
                    if (_showPicker) {
                      // unfocus keyboard to show picker if desired
                      _focusNode.unfocus();
                    } else {
                      // bring back focus to text field
                      _focusNode.requestFocus();
                    }
                  });
                },
              ),
            ),
          ],
        ),
        // emoji picker panel
        if (_showPicker)
          SizedBox(
            height: 260,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                // emoji.emoji returns the string
                _insertEmoji(emoji.emoji);
              },
              config: Config(
                columns: 8,
                emojiSizeMax: 24,
                verticalSpacing: 0,
                horizontalSpacing: 0,
                gridPadding: EdgeInsets.zero,
                initCategory: Category.RECENT,
                bgColor: theme.scaffoldBackgroundColor,
                indicatorColor: theme.colorScheme.primary,
                iconColor: theme.iconTheme.color ?? Colors.grey,
                iconColorSelected: theme.colorScheme.primary,
                backspaceColor: theme.colorScheme.secondary,
                recentsLimit: 28,
                tabIndicatorAnimDuration: kTabScrollDuration,
                buttonMode: ButtonMode.MATERIAL,
              ),
            ),
          ),
      ],
    );
  }
}
