import 'dart:math';
import 'package:flutter/material.dart';
import 'health_trends_widget.dart';

class ActivityRingsWidget extends StatefulWidget {
  final double stepsProgress; // 0.0 to 1.0
  final double healthHabitsProgress; // 0.0 to 1.0
  final double allHabitsProgress; // 0.0 to 1.0
  final int stepsCount;
  final int stepsGoal;

  // Data for embedded trends
  final int currentStepsAvg;
  final int previousStepsAvg;
  final double currentSleepAvg;
  final double previousSleepAvg;

  const ActivityRingsWidget({
    super.key,
    required this.stepsProgress,
    required this.healthHabitsProgress,
    required this.allHabitsProgress,
    required this.stepsCount,
    required this.stepsGoal,
    required this.currentStepsAvg,
    required this.previousStepsAvg,
    required this.currentSleepAvg,
    required this.previousSleepAvg,
  });

  @override
  State<ActivityRingsWidget> createState() => _ActivityRingsWidgetState();
}

class _ActivityRingsWidgetState extends State<ActivityRingsWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main Row: Rings (Left) + Metrics (Right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LEFT: Small Rings
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _RingsPainter(
                      stepsProgress: widget.stepsProgress,
                      healthProgress: widget.healthHabitsProgress,
                      habitsProgress: widget.allHabitsProgress,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // RIGHT: Today's Metrics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Activity',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMetricRow(
                        context,
                        emoji: '🚶',
                        label: 'Move',
                        value: '${widget.stepsCount}',
                        unit: 'steps',
                        progress: widget.stepsProgress,
                        color: const Color(0xFFFF6B6B),
                      ),
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        context,
                        emoji: '❤️',
                        label: 'Health',
                        value:
                            '${(widget.healthHabitsProgress * 100).toInt()}%',
                        unit: 'complete',
                        progress: widget.healthHabitsProgress,
                        color: const Color(0xFF4ECDC4),
                      ),
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        context,
                        emoji: '📍',
                        label: 'Distance',
                        value: '0.0',
                        unit: 'km',
                        progress: 0.0,
                        color: const Color(0xFF66BB6A),
                      ),

                      // Additional metrics when expanded
                      if (_isExpanded) ...[
                        const SizedBox(height: 12),
                        _buildMetricRow(
                          context,
                          emoji: '✅',
                          label: 'Habits',
                          value: '${(widget.allHabitsProgress * 100).toInt()}%',
                          unit: 'complete',
                          progress: widget.allHabitsProgress,
                          color: const Color(0xFFA78BFA),
                        ),
                        const SizedBox(height: 12),
                        _buildMetricRow(
                          context,
                          emoji: '💓',
                          label: 'Heart Rate',
                          value: '--',
                          unit: 'bpm',
                          progress: 0.0,
                          color: const Color(0xFFEF5350),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Expanded Content: AI Overview
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              child: _isExpanded
                  ? Column(
                      children: [
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Embedded Trends
                        const SizedBox(height: 16),
                        // Embedded Trends
                        HealthTrendsWidget(
                          currentStepsAvg: widget.currentStepsAvg,
                          previousStepsAvg: widget.previousStepsAvg,
                          currentSleepAvg: widget.currentSleepAvg,
                          previousSleepAvg: widget.previousSleepAvg,
                          embedded: true,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required String emoji,
    required String label,
    required String value,
    required String unit,
    required double progress,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$value $unit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double stepsProgress;
  final double healthProgress;
  final double habitsProgress;
  final bool isDark;

  _RingsPainter({
    required this.stepsProgress,
    required this.healthProgress,
    required this.habitsProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.11;
    const spacing = 3.0;

    // Outer Ring (Steps) - Soft Red
    _drawRing(
      canvas,
      center,
      radius: (size.width / 2) - (strokeWidth / 2),
      progress: stepsProgress,
      color: const Color(0xFFFF6B6B),
      strokeWidth: strokeWidth,
    );

    // Middle Ring (Health) - Teal
    _drawRing(
      canvas,
      center,
      radius: (size.width / 2) - (strokeWidth * 1.5) - spacing,
      progress: healthProgress,
      color: const Color(0xFF4ECDC4),
      strokeWidth: strokeWidth,
    );

    // Inner Ring (Habits) - Soft Purple
    _drawRing(
      canvas,
      center,
      radius: (size.width / 2) - (strokeWidth * 2.5) - (spacing * 2),
      progress: habitsProgress,
      color: const Color(0xFFA78BFA),
      strokeWidth: strokeWidth,
    );
  }

  void _drawRing(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double progress,
    required Color color,
    required double strokeWidth,
  }) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background circle
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress arc
    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);

    if (progress > 0) {
      // Add a subtle glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) {
    return oldDelegate.stepsProgress != stepsProgress ||
        oldDelegate.healthProgress != healthProgress ||
        oldDelegate.habitsProgress != habitsProgress;
  }
}
