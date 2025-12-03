import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Stress level slider with color gradient and emoji feedback
class StressLevelSlider extends StatefulWidget {
  final double initialValue; // 1-5
  final ValueChanged<double> onChanged;

  const StressLevelSlider({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<StressLevelSlider> createState() => _StressLevelSliderState();
}

class _StressLevelSliderState extends State<StressLevelSlider> {
  late double _value;

  final List<StressLevel> _levels = [
    StressLevel(emoji: '😌', label: 'Very Low', color: const Color(0xFF4CAF50)),
    StressLevel(emoji: '🙂', label: 'Low', color: const Color(0xFF8BC34A)),
    StressLevel(emoji: '😐', label: 'Moderate', color: const Color(0xFFFFC107)),
    StressLevel(emoji: '😟', label: 'High', color: const Color(0xFFFF9800)),
    StressLevel(emoji: '😰', label: 'Very High', color: const Color(0xFFF44336)),
  ];

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  Color _getColorForValue(double value) {
    // Interpolate between colors based on value
    final index = (value - 1).clamp(0.0, 4.0);
    final lowerIndex = index.floor();
    final upperIndex = (lowerIndex + 1).clamp(0, 4);
    final t = index - lowerIndex;

    return Color.lerp(
      _levels[lowerIndex].color,
      _levels[upperIndex].color,
      t,
    )!;
  }

  void _handleChange(double value) {
    HapticFeedback.selectionClick();
    setState(() => _value = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLevel = _levels[_value.round() - 1];
    final sliderColor = _getColorForValue(_value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emoji indicators at ends
        Row(
          children: [
            Text(_levels.first.emoji, style: const TextStyle(fontSize: 24)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: sliderColor,
                  inactiveTrackColor: sliderColor.withOpacity(0.3),
                  thumbColor: sliderColor,
                  overlayColor: sliderColor.withOpacity(0.2),
                  trackHeight: 8,
                  thumbShape: PulsingThumbShape(
                    color: sliderColor,
                    enabledThumbRadius: 14,
                  ),
                ),
                child: Slider(
                  value: _value,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: _handleChange,
                ),
              ),
            ),
            Text(_levels.last.emoji, style: const TextStyle(fontSize: 24)),
          ],
        ),

        const SizedBox(height: 8),

        // Gradient bar visualization
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: _levels.map((l) => l.color).toList(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Current level indicator
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: sliderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sliderColor, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLevel.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  currentLevel.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: sliderColor,
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

class StressLevel {
  final String emoji;
  final String label;
  final Color color;

  StressLevel({
    required this.emoji,
    required this.label,
    required this.color,
  });
}

/// Custom thumb shape with pulsing effect
class PulsingThumbShape extends SliderComponentShape {
  final Color color;
  final double enabledThumbRadius;

  const PulsingThumbShape({
    required this.color,
    this.enabledThumbRadius = 10,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Outer glow
    canvas.drawCircle(
      center,
      enabledThumbRadius + 4,
      Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    // Main thumb
    canvas.drawCircle(
      center,
      enabledThumbRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Inner highlight
    canvas.drawCircle(
      center,
      enabledThumbRadius / 2,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.fill,
    );
  }
}
