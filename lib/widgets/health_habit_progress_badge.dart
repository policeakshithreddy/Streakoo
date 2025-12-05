import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/health_checker_service.dart';

/// Widget showing real-time progress for health-tracked habits
class HealthHabitProgressBadge extends StatefulWidget {
  final Habit habit;

  const HealthHabitProgressBadge({
    super.key,
    required this.habit,
  });

  @override
  State<HealthHabitProgressBadge> createState() =>
      _HealthHabitProgressBadgeState();
}

class _HealthHabitProgressBadgeState extends State<HealthHabitProgressBadge> {
  Map<String, dynamic>? _progress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.habit.isHealthTracked && !widget.habit.completedToday) {
      _loadProgress();
    }
  }

  @override
  void didUpdateWidget(HealthHabitProgressBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.habit.id != oldWidget.habit.id ||
        widget.habit.completedToday != oldWidget.habit.completedToday) {
      if (widget.habit.isHealthTracked && !widget.habit.completedToday) {
        _loadProgress();
      }
    }
  }

  Future<void> _loadProgress() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final progress =
          await HealthCheckerService.instance.getHabitProgress(widget.habit);
      if (mounted) {
        setState(() {
          _progress = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.habit.isHealthTracked || widget.habit.completedToday) {
      return const SizedBox.shrink();
    }

    if (_isLoading || _progress == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final current = _progress!['current'] as double;
    final target = _progress!['target'] as double;
    final percentage = _progress!['percentage'] as double;
    final unit = _progress!['unit'] as String;

    final isNearlyComplete = percentage >= 80;
    final isComplete = percentage >= 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isComplete
            ? const Color(0xFF58CC02).withValues(alpha: 0.1)
            : isNearlyComplete
                ? Colors.orange.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete
              ? const Color(0xFF58CC02).withValues(alpha: 0.3)
              : isNearlyComplete
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.favorite,
            size: 14,
            color: isComplete
                ? const Color(0xFF58CC02)
                : isNearlyComplete
                    ? Colors.orange
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            '${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)} $unit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isComplete
                  ? const Color(0xFF58CC02)
                  : isNearlyComplete
                      ? Colors.orange
                      : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (isNearlyComplete && !isComplete) ...[
            const SizedBox(width: 4),
            const Text(
              '🔥',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small sync indicator for health-tracked habits
class HealthSyncIndicator extends StatelessWidget {
  const HealthSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF58CC02).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync,
            size: 10,
            color: Color(0xFF58CC02),
          ),
          SizedBox(width: 4),
          Text(
            'Auto',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF58CC02),
            ),
          ),
        ],
      ),
    );
  }
}
