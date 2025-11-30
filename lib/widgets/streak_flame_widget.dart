import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Duolingo-style streak flame widget
/// Shows streak count with animated flame icon
class StreakFlameWidget extends StatefulWidget {
  final int streakDays;
  final bool showLabel;
  final double size;
  final bool animate;

  const StreakFlameWidget({
    super.key,
    required this.streakDays,
    this.showLabel = true,
    this.size = 40,
    this.animate = true,
  });

  @override
  State<StreakFlameWidget> createState() => _StreakFlameWidgetState();
}

class _StreakFlameWidgetState extends State<StreakFlameWidget> {
  /// Get flame color based on streak length
  Color get _flameColor {
    if (widget.streakDays >= 100) {
      return const Color(0xFFFFD700); // Gold/diamond
    } else if (widget.streakDays >= 30) {
      return const Color(0xFFFF4500); // Red-orange
    } else if (widget.streakDays >= 7) {
      return const Color(0xFFFFA500); // Bright orange
    } else {
      return const Color(0xFFFF6B00); // Orange
    }
  }

  /// Get flame gradient colors
  List<Color> get _flameGradient {
    if (widget.streakDays >= 100) {
      return [
        const Color(0xFFFFD700), // Gold
        const Color(0xFFFFE97F), // Light gold
        const Color(0xFFFFFFFF), // White sparkle
      ];
    } else if (widget.streakDays >= 30) {
      return [
        const Color(0xFFFF4500), // Orange red
        const Color(0xFFFF6347), // Tomato
        const Color(0xFFFFA500), // Orange
      ];
    } else {
      return [
        const Color(0xFFFF6B00), // Orange
        const Color(0xFFFFA500), // Bright orange
        const Color(0xFFFFD700), // Gold tips
      ];
    }
  }

  /// Get flame emoji based on streak
  String get _flameEmoji {
    if (widget.streakDays >= 100) {
      return '💎'; // Diamond for 100+ days
    } else {
      return '🔥'; // Regular flame
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _flameGradient.map((c) => c.withOpacity(0.15)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _flameColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated flame icon
          Text(
            _flameEmoji,
            style: TextStyle(fontSize: widget.size),
          )
              .animate(
                onPlay: (controller) => widget.animate
                    ? controller.repeat(reverse: true)
                    : controller.stop(),
              )
              .scale(
                duration: 800.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              ),

          const SizedBox(width: 6),

          // Streak count
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.streakDays.toString(),
                style: TextStyle(
                  fontSize: widget.size * 0.6,
                  fontWeight: FontWeight.bold,
                  color: _flameColor,
                  height: 1.0,
                ),
              ),
              if (widget.showLabel)
                Text(
                  'day${widget.streakDays == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: widget.size * 0.25,
                    color: _flameColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact streak flame (just icon + number)
class CompactStreakFlame extends StatelessWidget {
  final int streakDays;
  final double size;

  const CompactStreakFlame({
    super.key,
    required this.streakDays,
    this.size = 24,
  });

  Color get _flameColor {
    if (streakDays >= 100) {
      return const Color(0xFFFFD700);
    } else if (streakDays >= 30) {
      return const Color(0xFFFF4500);
    } else if (streakDays >= 7) {
      return const Color(0xFFFFA500);
    } else {
      return const Color(0xFFFF6B00);
    }
  }

  String get _emoji {
    return streakDays >= 100 ? '💎' : '🔥';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _emoji,
          style: TextStyle(fontSize: size),
        ),
        const SizedBox(width: 4),
        Text(
          streakDays.toString(),
          style: TextStyle(
            fontSize: size * 0.7,
            fontWeight: FontWeight.bold,
            color: _flameColor,
          ),
        ),
      ],
    );
  }
}
