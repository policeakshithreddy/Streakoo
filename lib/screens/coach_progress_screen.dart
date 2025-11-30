import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/health_challenge.dart';
import '../services/health_service.dart';

class CoachProgressScreen extends StatefulWidget {
  const CoachProgressScreen({super.key});

  @override
  State<CoachProgressScreen> createState() => _CoachProgressScreenState();
}

class _CoachProgressScreenState extends State<CoachProgressScreen> {
  final _healthService = HealthService.instance;
  bool _isLoading = true;

  // Current metrics
  int _currentSteps = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentMetrics();
  }

  Future<void> _loadCurrentMetrics() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    _currentSteps = await _healthService.getStepCount(now);
    // Note: Weight and sleep would come from Health Connect in a real app
    // For now, we'll use baseline + some mock progress

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final challenge = appState.activeHealthChallenge;

    if (challenge == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progress')),
        body: const Center(
          child: Text('No active health challenge'),
        ),
      );
    }

    final baseline = challenge.baselineMetrics ?? {};
    final weeksSinceStart =
        DateTime.now().difference(challenge.startDate).inDays ~/ 7;
    final progressPercent =
        (weeksSinceStart / challenge.durationWeeks * 100).clamp(0, 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCurrentMetrics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenge Header
                  _buildChallengeHeader(challenge, progressPercent),

                  const SizedBox(height: 24),

                  // Milestones Section
                  const Text(
                    '🏆 Milestones',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildMilestonesGrid(
                      weeksSinceStart, challenge.durationWeeks),

                  const SizedBox(height: 32),

                  // Metrics Comparison
                  const Text(
                    '📊 Your Journey',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (baseline['weight'] != null)
                    _buildMetricComparison(
                      'Weight',
                      Icons.monitor_weight,
                      baseline['weight'],
                      baseline['weight'] - 2.5, // Mock progress
                      'kg',
                      Colors.blue,
                      isLowerBetter: true,
                    ),

                  const SizedBox(height: 16),

                  _buildMetricComparison(
                    'Avg Steps',
                    Icons.directions_walk,
                    baseline['avgSteps'] ?? 5000,
                    _currentSteps,
                    'steps',
                    Colors.orange,
                  ),

                  const SizedBox(height: 16),

                  if (baseline['avgSleep'] != null)
                    _buildMetricComparison(
                      'Avg Sleep',
                      Icons.bedtime,
                      baseline['avgSleep'],
                      7.2, // Mock current
                      'hrs',
                      Colors.purple,
                    ),

                  const SizedBox(height: 32),

                  // Weekly Snapshots
                  if (challenge.progressSnapshots != null &&
                      challenge.progressSnapshots!.isNotEmpty) ...[
                    const Text(
                      '📈 Weekly Check-Ins',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...challenge.progressSnapshots!
                        .map((snapshot) => _buildSnapshotCard(snapshot)),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildChallengeHeader(HealthChallenge challenge, int progressPercent) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Week ${DateTime.now().difference(challenge.startDate).inDays ~/ 7 + 1} of ${challenge.durationWeeks}',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$progressPercent% Complete',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesGrid(int currentWeek, int totalWeeks) {
    final milestones = [
      {'week': 1, 'title': 'Started!', 'icon': Icons.play_arrow},
      {'week': 2, 'title': '2 Weeks Strong', 'icon': Icons.favorite},
      {'week': 4, 'title': 'One Month!', 'icon': Icons.cake},
      {
        'week': totalWeeks ~/ 2,
        'title': 'Halfway There',
        'icon': Icons.trending_up
      },
      {'week': totalWeeks, 'title': 'Completed!', 'icon': Icons.celebration},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: milestones.map((milestone) {
        final isReached = currentWeek >= (milestone['week'] as int);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isReached
                ? const Color(0xFFFFF3E0)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isReached
                  ? const Color(0xFFFFB74D)
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                milestone['icon'] as IconData,
                color: isReached ? const Color(0xFFFFB74D) : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                milestone['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isReached ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricComparison(
    String label,
    IconData icon,
    num baselineValue,
    num currentValue,
    String unit,
    Color color, {
    bool isLowerBetter = false,
  }) {
    final change = currentValue - baselineValue;
    final percentChange = (change / baselineValue * 100).abs();
    final isImprovement = isLowerBetter ? change < 0 : change > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${baselineValue.toStringAsFixed(0)} $unit',
                      style: TextStyle(
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${currentValue.toStringAsFixed(currentValue is double ? 1 : 0)} $unit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isImprovement ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isImprovement ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${percentChange.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotCard(Map<String, dynamic> snapshot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text('Week ${snapshot['week']}'),
        subtitle: Text(snapshot['summary'] ?? 'Check-in completed'),
        trailing: Text(
          snapshot['date'] ?? '',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
