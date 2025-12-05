import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive emoji-based sleep quality selector
class EmojiSleepSlider extends StatefulWidget {
  final double initialValue; // 1-5
  final ValueChanged<double> onChanged;

  const EmojiSleepSlider({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<EmojiSleepSlider> createState() => _EmojiSleepSliderState();
}

class _EmojiSleepSliderState extends State<EmojiSleepSlider>
    with SingleTickerProviderStateMixin {
  late double _value;
  late AnimationController _scaleController;

  final List<SleepEmoji> _emojis = [
    SleepEmoji(emoji: '😴', label: 'Poor', sublabel: '<5hrs', value: 1),
    SleepEmoji(emoji: '😪', label: 'Fair', sublabel: '5-6hrs', value: 2),
    SleepEmoji(emoji: '😐', label: 'Good', sublabel: '6-7hrs', value: 3),
    SleepEmoji(emoji: '🙂', label: 'Great', sublabel: '7-8hrs', value: 4),
    SleepEmoji(emoji: '😊', label: 'Excellent', sublabel: '8+hrs', value: 5),
  ];

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap(double value) {
    HapticFeedback.selectionClick();
    setState(() => _value = value);
    widget.onChanged(value);

    // Trigger scale animation
    _scaleController.forward().then((_) => _scaleController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emoji row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _emojis.map((sleepEmoji) {
            final isSelected = _value.round() == sleepEmoji.value;

            return GestureDetector(
              onTap: () => _handleTap(sleepEmoji.value.toDouble()),
              child: AnimatedScale(
                scale: isSelected ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      sleepEmoji.emoji,
                      style: TextStyle(
                        fontSize: isSelected ? 32 : 28,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Selected label
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey(_value.round()),
              children: [
                Text(
                  _emojis[_value.round() - 1].label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _emojis[_value.round() - 1].sublabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SleepEmoji {
  final String emoji;
  final String label;
  final String sublabel;
  final int value;

  SleepEmoji({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.value,
  });
}
