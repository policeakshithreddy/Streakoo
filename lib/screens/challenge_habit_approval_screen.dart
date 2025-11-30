import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/health_challenge.dart';
import '../state/app_state.dart';
import '../services/health_service.dart';

class ChallengeHabitApprovalScreen extends StatefulWidget {
  final HealthChallenge challenge;

  const ChallengeHabitApprovalScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeHabitApprovalScreen> createState() =>
      _ChallengeHabitApprovalScreenState();
}

class _ChallengeHabitApprovalScreenState
    extends State<ChallengeHabitApprovalScreen> {
  late List<_HabitApprovalItem> _habits;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _initializeHabits();
  }

  void _initializeHabits() {
    final appState = context.read<AppState>();
    _habits = widget.challenge.recommendedHabits.map((challengeHabit) {
      // Check if a similar habit exists
      final existingHabit = _findSimilarHabit(appState, challengeHabit);

      return _HabitApprovalItem(
        challengeHabit: challengeHabit,
        isSelected: true,
        existingHabit: existingHabit,
        action: existingHabit != null ? HabitAction.update : HabitAction.create,
      );
    }).toList();
  }

  Habit? _findSimilarHabit(AppState appState, ChallengeHabit challengeHabit) {
    // Check if user has a habit with the same health metric
    if (challengeHabit.healthMetric != null) {
      final metricType = _parseHealthMetric(challengeHabit.healthMetric!);
      if (metricType != null) {
        try {
          return appState.habits.firstWhere(
            (h) => h.isHealthTracked && h.healthMetric == metricType,
          );
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  HealthMetricType? _parseHealthMetric(String metric) {
    switch (metric.toLowerCase()) {
      case 'steps':
        return HealthMetricType.steps;
      case 'sleep':
        return HealthMetricType.sleep;
      case 'distance':
        return HealthMetricType.distance;
      case 'calories':
      case 'active_energy':
      case 'activeenergy':
        return HealthMetricType.calories;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Recommended Habits'),
        centerTitle: true,
      ),
      body: _isCreating
          ? _buildCreatingState(theme)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Based on your ${widget.challenge.title} challenge, we recommend these habits:',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select the ones you want to add, or modify existing habits.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._habits.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildHabitCard(theme, item, index);
                      }),
                    ],
                  ),
                ),
                _buildBottomBar(theme),
              ],
            ),
    );
  }

  Widget _buildHabitCard(ThemeData theme, _HabitApprovalItem item, int index) {
    final isUpdate = item.action == HabitAction.update;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: item.isSelected,
                  onChanged: (val) {
                    setState(() => _habits[index].isSelected = val ?? false);
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  item.challengeHabit.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.challengeHabit.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.challengeHabit.targetValue != null)
                        Text(
                          'Goal: ${item.challengeHabit.targetValue!.toInt()} ${item.challengeHabit.healthMetric ?? ""}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      Text(
                        'Frequency: ${item.challengeHabit.frequency}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isUpdate && item.existingHabit != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.update,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Will update existing habit',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current: ${item.existingHabit!.name} (${item.existingHabit!.healthGoalValue?.toInt() ?? 0})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[800],
                      ),
                    ),
                    Text(
                      'New: ${item.challengeHabit.name} (${item.challengeHabit.targetValue?.toInt() ?? 0})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final selectedCount = _habits.where((h) => h.isSelected).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$selectedCount habit${selectedCount != 1 ? 's' : ''} selected',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Skip for Now'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: selectedCount > 0 ? _createHabits : null,
                  child: const Text('Create Habits'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreatingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Creating your habits...',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _createHabits() async {
    setState(() => _isCreating = true);

    try {
      final appState = context.read<AppState>();
      final selectedHabits = _habits.where((h) => h.isSelected).toList();

      for (final item in selectedHabits) {
        if (item.action == HabitAction.update && item.existingHabit != null) {
          // Update existing habit
          final updatedHabit = item.existingHabit!.copyWith(
            name: item.challengeHabit.name,
            healthGoalValue: item.challengeHabit.targetValue,
          );
          appState.updateHabit(updatedHabit);
        } else {
          // Create new habit
          final metricType =
              _parseHealthMetric(item.challengeHabit.healthMetric ?? '');

          final newHabit = Habit(
            id: const Uuid().v4(),
            name: item.challengeHabit.name,
            emoji: item.challengeHabit.emoji,
            category: _getCategoryForChallenge(widget.challenge.type),
            isHealthTracked: metricType != null,
            healthMetric: metricType,
            healthGoalValue: item.challengeHabit.targetValue,
            frequencyDays: item.challengeHabit.frequency == 'daily'
                ? [1, 2, 3, 4, 5, 6, 7]
                : [1, 2, 3, 4, 5],
          );

          appState.addHabit(newHabit);
        }
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ ${selectedHabits.length} habit${selectedHabits.length != 1 ? 's' : ''} created!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating habits: $e')),
        );
      }
    }
  }

  String _getCategoryForChallenge(ChallengeType type) {
    switch (type) {
      case ChallengeType.weightManagement:
        return 'Health';
      case ChallengeType.heartHealth:
        return 'Sports';
      case ChallengeType.nutritionWellness:
        return 'Health';
      case ChallengeType.activityStrength:
        return 'Sports';
    }
  }
}

enum HabitAction { create, update }

class _HabitApprovalItem {
  final ChallengeHabit challengeHabit;
  bool isSelected;
  final Habit? existingHabit;
  final HabitAction action;

  _HabitApprovalItem({
    required this.challengeHabit,
    required this.isSelected,
    this.existingHabit,
    required this.action,
  });
}
