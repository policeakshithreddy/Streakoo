import 'package:flutter/material.dart';

class HealthTrendsWidget extends StatelessWidget {
  final int currentStepsAvg;
  final int previousStepsAvg;
  final double currentSleepAvg;
  final double previousSleepAvg;
  final bool embedded;

  const HealthTrendsWidget({
    super.key,
    required this.currentStepsAvg,
    required this.previousStepsAvg,
    required this.currentSleepAvg,
    required this.previousSleepAvg,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate trends
    final stepsDiff = currentStepsAvg - previousStepsAvg;
    final stepsPercent = previousStepsAvg > 0
        ? ((stepsDiff / previousStepsAvg) * 100).round()
        : 0;

    final sleepDiff = currentSleepAvg - previousSleepAvg;

    // Determine primary insight
    String title = 'Health Trends';
    String message = 'Keep tracking to see your trends.';
    IconData icon = Icons.trending_flat;
    Color color = Colors.grey;

    if (stepsDiff > 500) {
      title = 'Trending Up';
      message =
          'You\'re walking $stepsPercent% more than last week! Great job staying active.';
      icon = Icons.trending_up;
      color = Colors.green;
    } else if (stepsDiff < -1000) {
      title = 'Step Count Down';
      message =
          'Your average steps are down by ${stepsPercent.abs()}%. Try to take a short walk today.';
      icon = Icons.trending_down;
      color = Colors.orange;
    } else if (sleepDiff > 0.5) {
      title = 'Better Sleep';
      message =
          'You\'re averaging ${sleepDiff.toStringAsFixed(1)}h more sleep this week.';
      icon = Icons.bedtime;
      color = const Color(0xFF5E35B1); // Deep purple
    }

    return Container(
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(20),
      decoration: embedded
          ? null
          : BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          // Mini stats row
          Row(
            children: [
              _buildMiniStat(context, 'Avg Steps', currentStepsAvg.toString(),
                  stepsDiff > 0 ? Colors.green : Colors.orange),
              const SizedBox(width: 24),
              _buildMiniStat(
                  context,
                  'Avg Sleep',
                  '${currentSleepAvg.toStringAsFixed(1)}h',
                  sleepDiff >= 0 ? const Color(0xFF5E35B1) : Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}
