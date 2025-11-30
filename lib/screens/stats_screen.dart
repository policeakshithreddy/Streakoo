import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/habit.dart';
import '../services/health_service.dart';
import '../services/behavior_mood_detector.dart';
import '../services/ai_health_coach_service.dart';
import '../services/insight_service.dart';
import '../widgets/habit_heatmap.dart';
import '../widgets/streak_flame_graph.dart';
import '../widgets/category_radar_chart.dart';
import '../widgets/level_badge.dart';
import '../widgets/mood_state_card.dart';
import '../widgets/health_connection_dialog.dart';
import '../widgets/challenge_progress_widget.dart';
import '../widgets/activity_rings_widget.dart';
import 'health_coaching_intro_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false, // Make tabs fill width
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
            Tab(text: 'Health', icon: Icon(Icons.favorite_outline)),
            Tab(text: 'Awards', icon: Icon(Icons.emoji_events_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverviewTab(),
          _TrendsTab(),
          _HealthDashboardTab(),
          _AchievementsTab(),
        ],
      ),
    );
  }
}

// ============ OVERVIEW TAB ============
class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final habits = appState.habits;
    final userLevel = appState.userLevel;

    final totalHabits = habits.length;
    final completedToday = habits.where((h) => h.completedToday).length;
    final totalStreaks = habits.fold<int>(0, (sum, h) => sum + h.streak);
    final perfectDay = totalHabits > 0 && completedToday == totalHabits;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Badge
          Center(
            child: LevelBadge(
              userLevel: userLevel,
              showProgress: true,
              size: 120,
            ),
          ),

          const SizedBox(height: 24),

          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total XP: ${appState.totalXP}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Streak Freeze Card
          Card(
            color: const Color(0xFFE3F2FD), // Light blue for freeze
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('❄️', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Streak Freezes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      Text(
                        '${appState.streakFreezes} available',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Text('❄️ How to Earn Freezes'),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Earn streak freezes by completing challenges!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildEarnInfo(
                                  '🥉', '7-Day Challenge', '2 Freezes'),
                              const SizedBox(height: 8),
                              _buildEarnInfo(
                                  '🥈', '15-Day Challenge', '3 Freezes'),
                              const SizedBox(height: 8),
                              _buildEarnInfo(
                                  '🥇', '30-Day Challenge', '6 Freezes'),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⭐ Focus Tasks Only',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Freezes only protect your Focus Tasks! Regular tasks don\'t use freezes.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it!'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('How to earn?'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Auto-detected mood state
          Builder(
            builder: (context) {
              final detector = BehaviorBasedMoodDetector.instance;
              final moodState = detector.detectMood(habits);
              final displayInfo = detector.getMoodDisplay(moodState);

              return MoodStateCard(
                moodState: moodState,
                displayInfo: displayInfo,
              );
            },
          ),
          const SizedBox(height: 24),

          // AI Insights
          FutureBuilder<List<String>>(
            future: InsightService().generateInsights(habits),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final insights = snapshot.data!;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'AI Insights',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...insights.take(3).map((insight) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(fontSize: 16)),
                                Expanded(
                                  child: Text(
                                    insight,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Today's metrics
          Row(
            children: [
              const Icon(Icons.today_outlined, size: 28),
              const SizedBox(width: 8),
              Text(
                'Today',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Habits',
                  value: '$totalHabits',
                  icon: Icons.track_changes,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Completed',
                  value: '$completedToday',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Streaks',
                  value: '$totalStreaks',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'XP Today',
                  value:
                      '${habits.where((h) => h.completedToday).fold<int>(0, (sum, h) => sum + h.actualXP)}',
                  icon: Icons.stars,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // Weekly Consistency Card
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Consistency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${_calculateWeeklyConsistency(habits)}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: _calculateWeeklyConsistency(habits) / 100,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on your last 7 days of activity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Perfect day status
          if (perfectDay)
            const _AchievementTile(
              title: 'Perfect Day 🎉',
              description:
                  'You completed every habit today. You\'re on fire! 🔥',
              color: Colors.green,
            )
          else
            const _AchievementTile(
              title: 'Keep going',
              description:
                  'Complete all habits today to unlock the Perfect Day badge.',
              color: Colors.grey,
            ),
        ],
      ),
    );
  }

  int _calculateWeeklyConsistency(List<Habit> habits) {
    if (habits.isEmpty) return 0;

    final now = DateTime.now();
    final startOfWeek = now.subtract(const Duration(days: 6));
    int completedCount = 0;
    int expectedCount = 0;

    for (final habit in habits) {
      // Calculate expected days based on frequency
      final frequencyDays = habit.frequencyDays; // [1..7]

      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final weekday = day.weekday;

        if (frequencyDays.contains(weekday)) {
          expectedCount++;

          // Check if completed on this day
          final dateKey =
              '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
          if (habit.completionDates.contains(dateKey)) {
            completedCount++;
          }
        }
      }
    }

    if (expectedCount == 0) return 0;
    return ((completedCount / expectedCount) * 100).round();
  }

  Widget _buildEarnInfo(String emoji, String challenge, String reward) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            challenge,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            reward,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

// ============ TRENDS TAB ============
class _TrendsTab extends StatelessWidget {
  const _TrendsTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final habits = appState.habits;

    // Prepare heatmap data
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 90)); // Last 3 months
    final datasets = <DateTime, int>{};

    for (final habit in habits) {
      for (final dateStr in habit.completionDates) {
        final date = DateTime.parse(dateStr);
        final key = DateTime(date.year, date.month, date.day);
        if (key.isAfter(startDate.subtract(const Duration(days: 1)))) {
          datasets[key] = (datasets[key] ?? 0) + 1;
        }
      }
    }

    // Prepare frozen dates
    final frozenDates =
        appState.frozenDates.map((d) => DateTime.parse(d)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heatmap
          HabitHeatmap(
            datasets: datasets,
            frozenDates: frozenDates,
            startDate: startDate,
            endDate: now,
          ),

          const SizedBox(height: 24),

          // Streak flame graph
          if (habits.isNotEmpty) ...[
            StreakFlameGraph(habits: habits),
            const SizedBox(height: 20),
          ],

          // Category radar chart
          if (habits.length >= 3) ...[
            CategoryRadarChart(habits: habits),
            const SizedBox(height: 20),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.insights_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Not enough data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add at least 3 habits to see category trends',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Mood analysis if available
          if (appState.moodHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '😊 Mood Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MoodInsights(appState: appState),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============ DAILY TRACK TAB ============
// ============ HEALTH DASHBOARD TAB ============
// ============ DAILY TRACK TAB ============
// ============ HEALTH DASHBOARD TAB ============

class _HealthDashboardTab extends StatefulWidget {
  const _HealthDashboardTab();

  @override
  State<_HealthDashboardTab> createState() => _HealthDashboardTabState();
}

class _HealthDashboardTabState extends State<_HealthDashboardTab> {
  final _healthService = HealthService.instance;
  bool _isLoading = false;

  // Weekly data for charts
  final List<int> _weeklySteps = List.filled(7, 0);
  final List<double> _weeklySleep = List.filled(7, 0);
  final List<double> _weeklyDistance = List.filled(7, 0);

  String? _weeklySummary;
  int? _selectedDayIndex;
  String _selectedDayLabel = '';

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    // Load last 7 days
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));

      // Steps
      final steps = await _healthService.getStepCount(date);
      _weeklySteps[i] = steps;

      // Sleep (mock logic or real if available)
      // For now, we'll use a placeholder or previous logic if available
      // Assuming getSleep is not yet implemented per-day in HealthService for this specific loop
      // We will keep existing logic or default to 0 if not available
    }

    // Simulate sleep data for demo (since we don't have full history API connected in this snippet)
    // In a real app, you'd fetch this from HealthService
    for (int i = 0; i < 7; i++) {
      _weeklySleep[i] = 6.5 + (i % 3) * 0.5; // Mock variation
      _weeklyDistance[i] = _weeklySteps[i] * 0.0007; // Approx km
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
    try {
      final summary =
          await AIHealthCoachService.instance.generateWeeklyHealthSummary(
        steps: _weeklySteps,
        sleep: _weeklySleep,
        distance: _weeklyDistance,
      );
      if (mounted) {
        setState(() => _weeklySummary = summary);
      }
    } catch (e) {
      // Error generating summary
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    // Check if health data is connected
    final hasAccess = await _healthService.hasHealthDataAccess();

    if (!hasAccess) {
      // Show connection dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => HealthConnectionDialog(
          onConnected: () {
            // Reload data after connection
            _loadHealthData();
          },
        ),
      );
    } else {
      // Already connected, just refresh the data
      await _loadHealthData();
    }
  }

  void _onDaySelected(int index) {
    setState(() {
      if (_selectedDayIndex == index) {
        _selectedDayIndex = null; // Deselect
        _selectedDayLabel = '';
      } else {
        _selectedDayIndex = index;
        final now = DateTime.now();
        final day = now.subtract(Duration(days: 6 - index));
        _selectedDayLabel =
            '${_getDayName(day.weekday)}, ${day.day}/${day.month}';
      }
    });
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final healthHabits = appState.habits
        .where((h) =>
            h.isHealthTracked ||
            h.category == 'Health' ||
            h.category == 'Sports')
        .toList();

    // Determine values to show (Today or Selected Day)
    // Note: _weekly arrays are ordered [6 days ago, ..., Today]
    // So index 6 is Today.
    final displayIndex = _selectedDayIndex ?? 6;

    final displaySteps = _weeklySteps[displayIndex];

    // Calculate Progress for Rings
    // 1. Steps (Goal: 10,000)
    const stepsGoal = 10000;
    final stepsProgress = (displaySteps / stepsGoal).clamp(0.0, 1.0);

    // 2. Health Habits (Goal: All health habits for the day)
    final todayHealthHabits = healthHabits; // In real app, filter by frequency
    final completedHealthHabits =
        todayHealthHabits.where((h) => h.completedToday).length;
    final healthHabitsProgress = todayHealthHabits.isEmpty
        ? 0.0
        : (completedHealthHabits / todayHealthHabits.length).clamp(0.0, 1.0);

    // 3. All Habits
    final allHabits = appState.habits;
    final completedAll = allHabits.where((h) => h.completedToday).length;
    final allHabitsProgress = allHabits.isEmpty
        ? 0.0
        : (completedAll / allHabits.length).clamp(0.0, 1.0);

    // Calculate Averages for Trends
    // Current week (last 3 days) vs Previous (days 0-2) - Simplified logic
    final currentStepsAvg =
        (_weeklySteps[4] + _weeklySteps[5] + _weeklySteps[6]) ~/ 3;
    final prevStepsAvg =
        (_weeklySteps[0] + _weeklySteps[1] + _weeklySteps[2]) ~/ 3;

    final currentSleepAvg =
        (_weeklySleep[4] + _weeklySleep[5] + _weeklySleep[6]) / 3;
    final prevSleepAvg =
        (_weeklySleep[0] + _weeklySleep[1] + _weeklySleep[2]) / 3;

    return RefreshIndicator(
      onRefresh: _loadHealthData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Health Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedDayLabel.isNotEmpty)
                      Text(
                        _selectedDayLabel,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _handleRefresh,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Health Coaching Discovery (moved to top)
            if (appState.activeHealthChallenge == null)
              _buildDiscoverCoachingCard(context),

            const SizedBox(height: 16),

            // NEW: Activity Rings
            ActivityRingsWidget(
              stepsProgress: stepsProgress,
              healthHabitsProgress: healthHabitsProgress,
              allHabitsProgress: allHabitsProgress,
              stepsCount: displaySteps,
              stepsGoal: stepsGoal,
              currentStepsAvg: currentStepsAvg,
              previousStepsAvg: prevStepsAvg,
              currentSleepAvg: currentSleepAvg,
              previousSleepAvg: prevSleepAvg,
            ),

            const SizedBox(height: 16),

            // Health Challenge Widget
            if (appState.activeHealthChallenge != null)
              const ChallengeProgressWidget(),

            const SizedBox(height: 24),

            // AI Summary Card
            if (_weeklySummary != null) ...[
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'AI Coach Insights',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _weeklySummary!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 24),

            // Weekly Steps Chart
            _WeeklyChart(
              title: 'Weekly Steps',
              data: _weeklySteps.map((e) => e.toDouble()).toList(),
              color: Colors.blue,
              maxValue: 12000,
              selectedIndex: _selectedDayIndex,
              onTap: _onDaySelected,
            ),

            const SizedBox(height: 16),

            // Weekly Sleep Chart
            _WeeklyChart(
              title: 'Weekly Sleep (hours)',
              data: _weeklySleep,
              color: Colors.purple,
              maxValue: 10,
              selectedIndex: _selectedDayIndex,
              onTap: _onDaySelected,
            ),

            const SizedBox(height: 16),

            // Weekly Overall Progress (Activity Score)
            _WeeklyPerformanceChart(
              steps: _weeklySteps,
              sleep: _weeklySleep,
              distance: _weeklyDistance,
              selectedIndex: _selectedDayIndex,
              onTap: _onDaySelected,
            ),

            const SizedBox(height: 24),

            // Health Habits List
            if (healthHabits.isNotEmpty) ...[
              Text(
                'Your Health Habits',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...healthHabits.asMap().entries.map(
                    (entry) => _AnimatedListItem(
                      index: entry.key,
                      child: _HealthHabitCard(habit: entry.value),
                    ),
                  ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.favorite_border,
                          size: 64, color: Theme.of(context).disabledColor),
                      const SizedBox(height: 16),
                      Text(
                        'No health habits yet',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).disabledColor,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add habits in Health or Sports category',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverCoachingCard(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const HealthCoachingIntroScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Health Coaching',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get personalized plans for weight, heart health, and more.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final String title;
  final List<double> data;
  final Color color;
  final double maxValue;
  final int? selectedIndex;
  final Function(int)? onTap;

  const _WeeklyChart({
    required this.title,
    required this.data,
    required this.color,
    required this.maxValue,
    this.selectedIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final value = data[index];
                  final heightPercent = (value / maxValue).clamp(0.0, 1.0);
                  final isSelected = selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap?.call(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: heightPercent),
                              duration:
                                  Duration(milliseconds: 500 + (index * 50)),
                              curve: Curves.easeOutCubic,
                              builder: (context, animValue, _) {
                                return Container(
                                  height: 80 * animValue,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : color.withValues(alpha: 0.1),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.black12, width: 2)
                                        : null,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              days[index],
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : null,
                                color: isSelected ? color : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyPerformanceChart extends StatelessWidget {
  final List<int> steps;
  final List<double> sleep;
  final List<double> distance;
  final int? selectedIndex;
  final Function(int)? onTap;

  const _WeeklyPerformanceChart({
    required this.steps,
    required this.sleep,
    required this.distance,
    this.selectedIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate activity scores (0-100)
    final scores = List.generate(7, (i) {
      final stepScore = (steps[i] / 10000).clamp(0.0, 1.0) * 50;
      final sleepScore = (sleep[i] / 8).clamp(0.0, 1.0) * 30;
      final distScore = (distance[i] / 5).clamp(0.0, 1.0) * 20;
      return stepScore + sleepScore + distScore;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Weekly Overall Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final score = scores[index];
                  final heightPercent = (score / 100).clamp(0.0, 1.0);
                  final isSelected = selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap?.call(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                score.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: heightPercent),
                            duration:
                                Duration(milliseconds: 600 + (index * 50)),
                            curve: Curves.easeOutBack,
                            builder: (context, animValue, _) {
                              return Container(
                                height: 100 * animValue,
                                width: 12,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.orange
                                      : Colors.orange.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            days[index],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : null,
                              color: isSelected ? Colors.orange : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep existing _HealthHabitCard implementation below

class _HealthHabitCard extends StatefulWidget {
  final Habit habit;

  const _HealthHabitCard({required this.habit});

  @override
  State<_HealthHabitCard> createState() => _HealthHabitCardState();
}

class _HealthHabitCardState extends State<_HealthHabitCard> {
  double _currentValue = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    if (!widget.habit.isHealthTracked || widget.habit.healthMetric == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final value = await HealthService.instance
          .getCurrentValue(widget.habit.healthMetric!);
      if (mounted) {
        setState(() {
          _currentValue = value;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error loading health data
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = widget.habit.healthGoalValue ?? 1;
    final progress = (_currentValue / goal).clamp(0.0, 1.0);
    final isCompleted = _currentValue >= goal;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.habit.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.habit.healthMetric?.name.toUpperCase() ??
                            'MANUAL',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const LinearProgressIndicator()
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_currentValue.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 12,
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ============ ACHIEVEMENTS TAB ============
class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final habits = appState.habits;

    // Calculate achievement stats
    final totalCompletedDays = getTotalCompletedDays(habits);
    final longestStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    final totalHabits = habits.length;
    final perfectDays = getPerfectDays(habits);

    // Build achievement list - simpler approach
    final List<Widget> achievementWidgets = [];
    bool hasDailyHeader = false;

    // Daily Completion achievements
    if (perfectDays >= 1) {
      if (!hasDailyHeader) {
        achievementWidgets
            .add(_buildCategoryHeader(context, '🎯 Daily Completion'));
        achievementWidgets.add(const SizedBox(height: 12));
        hasDailyHeader = true;
      }
      achievementWidgets.add(const _AchievementCard(
          icon: '⭐',
          title: 'First Perfect Day',
          description: 'Completed all habits in one day',
          color: Colors.amber,
          unlocked: true));
    }
    if (perfectDays >= 7) {
      if (!hasDailyHeader) {
        achievementWidgets
            .add(_buildCategoryHeader(context, '🎯 Daily Completion'));
        achievementWidgets.add(const SizedBox(height: 12));
        hasDailyHeader = true;
      }
      achievementWidgets.add(const _AchievementCard(
          icon: '🌟',
          title: 'Week Warrior',
          description: '7 perfect days achieved',
          color: Colors.orange,
          unlocked: true));
    }
    if (perfectDays >= 30) {
      if (!hasDailyHeader) {
        achievementWidgets
            .add(_buildCategoryHeader(context, '🎯 Daily Completion'));
        achievementWidgets.add(const SizedBox(height: 12));
        hasDailyHeader = true;
      }
      achievementWidgets.add(const _AchievementCard(
          icon: '💫',
          title: 'Month Master',
          description: '30 perfect days achieved',
          color: Colors.purple,
          unlocked: true));
    }

    // Streak achievements
    if (longestStreak >= 3 || longestStreak >= 7 || longestStreak >= 30) {
      if (achievementWidgets.isNotEmpty) {
        achievementWidgets.add(const SizedBox(height: 24));
      }
      achievementWidgets
          .add(_buildCategoryHeader(context, '🔥 Streak Achievements'));
      achievementWidgets.add(const SizedBox(height: 12));

      if (longestStreak >= 3) {
        achievementWidgets.add(const _AchievementCard(
            icon: '🔥',
            title: 'Streak Starter',
            description: 'Maintained a 3-day streak',
            color: Colors.red,
            unlocked: true));
      }
      if (longestStreak >= 7) {
        achievementWidgets.add(const _AchievementCard(
            icon: '💥',
            title: 'Week Streak',
            description: 'Maintained a 7-day streak',
            color: Colors.deepOrange,
            unlocked: true));
      }
      if (longestStreak >= 30) {
        achievementWidgets.add(const _AchievementCard(
            icon: '🚀',
            title: 'Unstoppable',
            description: 'Maintained a 30-day streak!',
            color: Colors.indigo,
            unlocked: true));
      }
    }

    // Habit Collection achievements
    if (totalHabits >= 1 || totalHabits >= 5 || totalHabits >= 10) {
      if (achievementWidgets.isNotEmpty) {
        achievementWidgets.add(const SizedBox(height: 24));
      }
      achievementWidgets.add(_buildCategoryHeader(context, '📚 Collection'));
      achievementWidgets.add(const SizedBox(height: 12));

      if (totalHabits >= 1) {
        achievementWidgets.add(const _AchievementCard(
            icon: '🌱',
            title: 'First Habit',
            description: 'Created your first habit',
            color: Colors.green,
            unlocked: true));
      }
      if (totalHabits >= 5) {
        achievementWidgets.add(const _AchievementCard(
            icon: '🌿',
            title: 'Habit Apprentice',
            description: '5 habits created',
            color: Colors.teal,
            unlocked: true));
      }
      if (totalHabits >= 10) {
        achievementWidgets.add(const _AchievementCard(
            icon: '🌳',
            title: 'Habit Master',
            description: '10 habits created',
            color: Colors.cyan,
            unlocked: true));
      }
    }

    // Total Completions achievements
    if (totalCompletedDays >= 10 ||
        totalCompletedDays >= 50 ||
        totalCompletedDays >= 100) {
      if (achievementWidgets.isNotEmpty) {
        achievementWidgets.add(const SizedBox(height: 24));
      }
      achievementWidgets
          .add(_buildCategoryHeader(context, '💪 Total Completions'));
      achievementWidgets.add(const SizedBox(height: 12));

      if (totalCompletedDays >= 10) {
        achievementWidgets.add(const _AchievementCard(
            icon: '💪',
            title: 'Committed',
            description: '10 total completions',
            color: Colors.blue,
            unlocked: true));
      }
      if (totalCompletedDays >= 50) {
        achievementWidgets.add(_AchievementCard(
            icon: '🏆',
            title: 'Dedicated',
            description: '50 total completions',
            color: Colors.yellow.shade700,
            unlocked: true));
      }
      if (totalCompletedDays >= 100) {
        achievementWidgets.add(const _AchievementCard(
            icon: '👑',
            title: 'Legendary',
            description: '100 total completions!',
            color: Colors.deepPurple,
            unlocked: true));
      }
    }

    // Show empty state if no achievements
    if (achievementWidgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined,
                size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No achievements yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Complete habits to unlock achievements!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Achievements',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your earned milestones',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 24),

          // Animate list items
          ...List.generate(achievementWidgets.length, (index) {
            return _AnimatedListItem(
              index: index,
              child: achievementWidgets[index],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          height: 2,
          width: 4,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  int getTotalCompletedDays(List<Habit> habits) {
    int total = 0;
    for (final habit in habits) {
      total += habit.completionDates.length;
    }
    return total;
  }

  int getPerfectDays(List<Habit> habits) {
    if (habits.isEmpty) return 0;

    // Get all unique dates where all habits were completed
    final allDates = <String>{};
    for (final habit in habits) {
      allDates.addAll(habit.completionDates);
    }

    int perfectDays = 0;
    for (final date in allDates) {
      bool allCompleted = true;
      for (final habit in habits) {
        if (!habit.completionDates.contains(date)) {
          allCompleted = false;
          break;
        }
      }
      if (allCompleted) perfectDays++;
    }

    return perfectDays;
  }
}

class _AchievementCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final Color color;
  final bool unlocked;

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: unlocked
            ? color.withValues(alpha: 0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? color : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: unlocked ? color : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: unlocked
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: unlocked
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (!unlocked)
              const Icon(
                Icons.lock_outline,
                color: Colors.grey,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// ============ HELPER WIDGETS ============

class _AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        // Stagger delay based on index
        final delay = index * 0.1;
        final delayedValue = (value - delay).clamp(0.0, 1.0);

        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - delayedValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final String description;
  final Color color;

  const _AchievementTile({
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodInsights extends StatelessWidget {
  final AppState appState;

  const _MoodInsights({required this.appState});

  @override
  Widget build(BuildContext context) {
    final analysis = appState.getMoodAnalysis(days: 7);

    if (analysis.dominantMood == null) {
      return const Text('Not enough mood data yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This week you\'ve been mostly feeling:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              appState.moodHistory.last.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Text(
              appState.moodHistory.last.displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Mood score: ${(analysis.averageMoodScore * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
