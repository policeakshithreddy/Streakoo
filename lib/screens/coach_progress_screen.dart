import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  // Purple theme colors (matching Wind AI)
  static const _primaryPurple = Color(0xFF8B5CF6);
  static const _secondaryPink = Color(0xFFEC4899);

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

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final challenge = appState.activeHealthChallenge;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (challenge == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Progress'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insights_outlined,
                size: 64,
                color: _primaryPurple.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No active health challenge',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final baseline = challenge.baselineMetrics ?? {};
    final weeksSinceStart =
        DateTime.now().difference(challenge.startDate).inDays ~/ 7;
    final progressPercent =
        (weeksSinceStart / challenge.durationWeeks * 100).clamp(0, 100).toInt();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          _primaryPurple.withValues(alpha: 0.15),
                          const Color(0xFF0D0D0D),
                        ]
                      : [
                          _primaryPurple.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                ),
              ),
            ),
          ),

          // Decorative orb
          Positioned(
            top: -60,
            right: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Your Progress',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryPurple, _secondaryPink],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Challenge Header
                              _buildChallengeHeader(
                                  challenge, progressPercent, isDark),

                              const SizedBox(height: 28),

                              // Milestones Section
                              _buildSectionHeader(
                                  'Milestones', Icons.emoji_events, isDark),
                              const SizedBox(height: 12),
                              _buildMilestonesGrid(weeksSinceStart,
                                  challenge.durationWeeks, isDark),

                              const SizedBox(height: 28),

                              // Metrics Comparison
                              _buildSectionHeader('Your Journey',
                                  Icons.trending_up_rounded, isDark),
                              const SizedBox(height: 16),

                              if (baseline['weight'] != null)
                                _buildMetricComparison(
                                  'Weight',
                                  Icons.monitor_weight,
                                  baseline['weight'],
                                  baseline['weight'] - 2.5,
                                  'kg',
                                  isDark,
                                  isLowerBetter: true,
                                )
                                    .animate()
                                    .fadeIn(delay: 100.ms)
                                    .slideX(begin: 0.1),

                              const SizedBox(height: 12),

                              _buildMetricComparison(
                                'Avg Steps',
                                Icons.directions_walk,
                                baseline['avgSteps'] ?? 5000,
                                _currentSteps,
                                'steps',
                                isDark,
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideX(begin: 0.1),

                              const SizedBox(height: 12),

                              if (baseline['avgSleep'] != null)
                                _buildMetricComparison(
                                  'Avg Sleep',
                                  Icons.bedtime,
                                  baseline['avgSleep'],
                                  7.2,
                                  'hrs',
                                  isDark,
                                )
                                    .animate()
                                    .fadeIn(delay: 300.ms)
                                    .slideX(begin: 0.1),

                              const SizedBox(height: 28),

                              // Weekly Snapshots
                              if (challenge.progressSnapshots != null &&
                                  challenge.progressSnapshots!.isNotEmpty) ...[
                                _buildSectionHeader('Weekly Check-Ins',
                                    Icons.calendar_today, isDark),
                                const SizedBox(height: 12),
                                ...challenge.progressSnapshots!
                                    .asMap()
                                    .entries
                                    .map((entry) => _buildSnapshotCard(
                                          entry.value,
                                          isDark,
                                        ).animate().fadeIn(
                                            delay: (400 + entry.key * 100).ms)),
                              ],

                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primaryPurple.withValues(alpha: 0.15),
                _secondaryPink.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _primaryPurple),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeHeader(
      HealthChallenge challenge, int progressPercent, bool isDark) {
    final currentWeek =
        DateTime.now().difference(challenge.startDate).inDays ~/ 7 + 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  _primaryPurple.withValues(alpha: 0.2),
                  _secondaryPink.withValues(alpha: 0.1),
                ]
              : [
                  _primaryPurple.withValues(alpha: 0.12),
                  _secondaryPink.withValues(alpha: 0.08),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryPurple, _secondaryPink],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Week $currentWeek of ${challenge.durationWeeks}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: constraints.maxWidth * (progressPercent / 100),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryPurple, _secondaryPink],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progressPercent% Complete',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _primaryPurple,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${challenge.durationWeeks - currentWeek + 1} weeks left',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _primaryPurple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildMilestonesGrid(int currentWeek, int totalWeeks, bool isDark) {
    final milestones = [
      {'week': 1, 'title': 'Started!', 'icon': Icons.play_arrow},
      {'week': 2, 'title': '2 Weeks', 'icon': Icons.favorite},
      {'week': totalWeeks ~/ 2, 'title': 'Halfway', 'icon': Icons.trending_up},
      {'week': totalWeeks, 'title': 'Complete!', 'icon': Icons.celebration},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: milestones.asMap().entries.map((entry) {
        final index = entry.key;
        final milestone = entry.value;
        final isReached = currentWeek >= (milestone['week'] as int);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isReached
                ? const LinearGradient(
                    colors: [_primaryPurple, _secondaryPink],
                  )
                : null,
            color: isReached
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[100]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isReached
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[300]!),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                milestone['icon'] as IconData,
                color: isReached
                    ? Colors.white
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                milestone['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isReached
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 100).ms).scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
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
    bool isDark, {
    bool isLowerBetter = false,
  }) {
    final change = currentValue - baselineValue;
    final percentChange = (change / baselineValue * 100).abs();
    final isImprovement = isLowerBetter ? change < 0 : change > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryPurple.withValues(alpha: 0.15),
                  _secondaryPink.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryPurple, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${baselineValue.toStringAsFixed(0)} $unit',
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward,
                        size: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${currentValue.toStringAsFixed(currentValue is double ? 1 : 0)} $unit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isImprovement
                    ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                    : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isImprovement ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${percentChange.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotCard(Map<String, dynamic> snapshot, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryPurple, _secondaryPink],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week ${snapshot['week']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  snapshot['summary'] ?? 'Check-in completed',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            snapshot['date'] ?? '',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
