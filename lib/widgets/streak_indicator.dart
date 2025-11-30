import 'package:flutter/material.dart';

class StreakIndicator extends StatelessWidget {
  final int streak;

  const StreakIndicator({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.local_fire_department,
            color: Colors.orangeAccent.withValues(alpha: 0.9)),
        const SizedBox(width: 4),
        Text(
          '$streak',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        )
      ],
    );
  }
}
