import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final String label;
  final String value;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 8,
                backgroundColor: color.outline.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color.primary),
              ),
              Center(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
