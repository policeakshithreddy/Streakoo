import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/gradients.dart';

/// Animated circular progress ring with gradient support
class AnimatedProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Widget? child;
  final Duration animationDuration;
  final bool showPercentage;
  final TextStyle? percentageStyle;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.gradient,
    this.backgroundColor,
    this.child,
    this.animationDuration = const Duration(milliseconds: 800),
    this.showPercentage = false,
    this.percentageStyle,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
      _animation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ProgressRingPainter(
              progress: _animation.value,
              strokeWidth: widget.strokeWidth,
              gradient: widget.gradient ?? AppGradients.primary,
              backgroundColor: widget.backgroundColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: widget.child ??
                  (widget.showPercentage
                      ? Text(
                          '${(_animation.value * 100).round()}%',
                          style: widget.percentageStyle ??
                              TextStyle(
                                fontSize: widget.size * 0.2,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                        )
                      : null),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Gradient gradient;
  final Color backgroundColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2; // Start from top
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Multiple stacked progress rings
class StackedProgressRings extends StatelessWidget {
  final List<ProgressRingData> rings;
  final double size;
  final Widget? centerChild;

  const StackedProgressRings({
    super.key,
    required this.rings,
    this.size = 150,
    this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rings from largest to smallest
          ...rings.asMap().entries.map((entry) {
            final index = entry.key;
            final ring = entry.value;
            final ringSize = size - (index * (ring.strokeWidth + 4));

            return AnimatedProgressRing(
              progress: ring.progress,
              size: ringSize,
              strokeWidth: ring.strokeWidth,
              gradient: ring.gradient,
              backgroundColor: ring.backgroundColor,
            );
          }),

          // Center content
          if (centerChild != null) centerChild!,
        ],
      ),
    );
  }
}

class ProgressRingData {
  final double progress;
  final double strokeWidth;
  final Gradient gradient;
  final Color? backgroundColor;

  const ProgressRingData({
    required this.progress,
    this.strokeWidth = 8,
    required this.gradient,
    this.backgroundColor,
  });
}

/// Mini progress ring (for compact displays)
class MiniProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;

  const MiniProgressRing({
    super.key,
    required this.progress,
    this.size = 24,
    this.color = const Color(0xFFFFA94A),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: 3,
        backgroundColor: color.withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
