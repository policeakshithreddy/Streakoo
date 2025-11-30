import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/behavior_mood_detector.dart';

class MoodStateCard extends StatelessWidget {
  final UserMoodState moodState;
  final MoodDisplayInfo displayInfo;

  const MoodStateCard({
    super.key,
    required this.moodState,
    required this.displayInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Color(displayInfo.color).withValues(alpha: 0.15),
              Color(displayInfo.color).withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with emoji and title
            Row(
              children: [
                Text(
                  displayInfo.emoji,
                  style: const TextStyle(fontSize: 40),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                      duration: 2000.ms,
                      delay: 1000.ms,
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayInfo.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(displayInfo.color),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auto-detected from your behavior',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Energy level indicator
            Row(
              children: [
                const Icon(Icons.battery_charging_full, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: displayInfo.energyLevel / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(displayInfo.color),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${displayInfo.energyLevel}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Message
            Text(
              displayInfo.message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}

// Compact version for smaller spaces
class MoodStateChip extends StatelessWidget {
  final UserMoodState moodState;
  final MoodDisplayInfo displayInfo;

  const MoodStateChip({
    super.key,
    required this.moodState,
    required this.displayInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(displayInfo.color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(displayInfo.color).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayInfo.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            displayInfo.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(displayInfo.color),
            ),
          ),
        ],
      ),
    );
  }
}
