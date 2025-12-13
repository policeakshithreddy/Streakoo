import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'year_in_review_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  // App theme colors
  static const primaryOrange = Color(0xFFFFA94A);
  static const secondaryTeal = Color(0xFF1FD1A5);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Stats'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: StatsScreen.primaryOrange,
          indicatorWeight: 3,
          labelColor: StatsScreen.primaryOrange,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
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
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A2A3A), const Color(0xFF0D1B2A)]
                        : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.blue.withValues(alpha: 0.3)
                        : Colors.blue.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: isDark ? 0.1 : 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('❄️', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Streak Freezes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark
                                  ? Colors.blue[200]
                                  : const Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${appState.streakFreezes} available',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
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
                                    color: StatsScreen.primaryOrange
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: StatsScreen.primaryOrange
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '⭐ Focus Tasks Only',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFFA94A),
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
                                style: TextButton.styleFrom(
                                  foregroundColor: StatsScreen.primaryOrange,
                                ),
                                child: const Text('Got it!'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.blue[200] : Colors.blue[700],
                      ),
                      child: const Text('How to earn?'),
                    ),
                  ],
                ),
              );
            },
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF191919)
                    : null,
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
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final consistencyValue = _calculateWeeklyConsistency(habits);
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191919) : null,
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          colors: [Colors.white, Color(0xFFFFFAF5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? StatsScreen.primaryOrange.withValues(alpha: 0.2)
                        : StatsScreen.primaryOrange.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: StatsScreen.primaryOrange.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📊', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'Weekly Consistency',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '$consistencyValue%',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: consistencyValue / 100,
                                backgroundColor: StatsScreen.primaryOrange
                                    .withValues(alpha: 0.15),
                                color: StatsScreen.primaryOrange,
                                strokeWidth: 8,
                                strokeCap: StrokeCap.round,
                              ),
                              Text(
                                consistencyValue >= 80
                                    ? '🔥'
                                    : consistencyValue >= 50
                                        ? '💪'
                                        : '📈',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Based on your last 7 days of activity',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Year in Review Card
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final currentYear = DateTime.now().year;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          YearInReviewScreen(year: currentYear),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF6366F1).withValues(alpha: 0.8),
                              const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                              const Color(0xFFEC4899).withValues(alpha: 0.8),
                            ]
                          : [
                              const Color(0xFF6366F1),
                              const Color(0xFF8B5CF6),
                              const Color(0xFFEC4899),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('🎉', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$currentYear Wrapped',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'See your year in review',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
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
  final List<double> _weeklyCalories = List.filled(7, 0);

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

      // Calories
      final calories = await _healthService.getCalories(date);
      _weeklyCalories[i] = calories;

      // Sleep - fetch real data from health service
      final sleep = await _healthService.getSleepHours(date);
      _weeklySleep[i] = _healthService.isValidSleepHours(sleep) ? sleep : 0.0;

      // Distance - fetch real data from health service
      final distance = await _healthService.getDistance(date);
      _weeklyDistance[i] =
          _healthService.isValidDistance(distance) ? distance : 0.0;
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
      debugPrint('Error generating weekly health summary: $e');
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
              sleepHours: _weeklySleep[displayIndex],
              distanceKm: _weeklyDistance[displayIndex],
              heartRateBpm: null, // TODO: Fetch heart rate data
              currentStepsAvg: currentStepsAvg,
              previousStepsAvg: prevStepsAvg,
              currentSleepAvg: currentSleepAvg,
              previousSleepAvg: prevSleepAvg,
            ),

            const SizedBox(height: 16),

            // NEW: Quick Health Stats Row
            _buildHealthStatsRow(context, displaySteps, stepsGoal),

            const SizedBox(height: 16),

            // Health Challenge Widget
            if (appState.activeHealthChallenge != null)
              const ChallengeProgressWidget(),

            const SizedBox(height: 24),

            // AI Summary Card
            if (_weeklySummary != null) ...[
              Card(
                color: const Color(0xFF191919),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                      color: Color(0xFFFFA94A), width: 1.5), // Orange border
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: const Color(0xFFFFA94A)), // Orange icon
                          const SizedBox(width: 8),
                          Text(
                            'Wind Insights 🌬️',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFA94A), // Orange text
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

  Widget _buildHealthStatsRow(BuildContext context, int steps, int stepsGoal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate health score (0-100)
    final stepsScore = (steps / stepsGoal * 100).clamp(0, 100);
    final sleepScore =
        (_weeklySleep.isNotEmpty ? _weeklySleep.last / 8 * 100 : 50)
            .clamp(0.0, 100.0);
    final healthScore = ((stepsScore + sleepScore) / 2).round();

    // Get sleep hours and distance
    final sleepHours = _weeklySleep.isNotEmpty ? _weeklySleep.last : 0.0;
    final distance = _weeklyDistance.isNotEmpty ? _weeklyDistance.last : 0.0;

    return Column(
      children: [
        // First Row: Health Score & Sleep
        Row(
          children: [
            Expanded(
              child: _HealthMetricCard(
                icon: Icons.favorite_rounded,
                iconColor: _getHealthScoreColor(healthScore),
                title: 'Health Score',
                value: '$healthScore',
                unit: '/100',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HealthMetricCard(
                icon: Icons.bedtime_rounded,
                iconColor: const Color(0xFFFFC107),
                title: 'Sleep',
                value: sleepHours.toStringAsFixed(1),
                unit: 'hrs',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second Row: Steps & Distance
        Row(
          children: [
            Expanded(
              child: _HealthMetricCard(
                icon: Icons.directions_walk_rounded,
                iconColor: const Color(0xFF2196F3),
                title: 'Steps',
                value: '$steps',
                unit: 'steps',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HealthMetricCard(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFFE91E63),
                title: 'Distance',
                value: distance.toStringAsFixed(1),
                unit: 'km',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFA726);
    if (score >= 40) return const Color(0xFFFF7043);
    return const Color(0xFFE91E63);
  }

  Widget _buildDiscoverCoachingCard(BuildContext context) {
    return const _AdvancedHealthCoachingCard();
  }
}

// Simplified Wind Health Coaching Card
class _AdvancedHealthCoachingCard extends StatelessWidget {
  const _AdvancedHealthCoachingCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthCoachingIntroScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.white, const Color(0xFFF8F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6)
                  .withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Modern AI Avatar with gradient ring
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inner icon container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Wind',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // AI Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Personalized health insights & coaching',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Animated Arrow
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    const Color(0xFFEC4899).withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF8B5CF6),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

// Modern Health Metric Card
class _HealthMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String unit;
  final bool isDark;

  const _HealthMetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          // Value + Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 350.ms,
          curve: Curves.easeOut,
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
    final isDark = theme.brightness == Brightness.dark;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate week-over-week change
    final currentWeekAvg = (data[4] + data[5] + data[6]) / 3;
    final prevWeekAvg = (data[0] + data[1] + data[2]) / 3;
    final percentChange = prevWeekAvg > 0
        ? ((currentWeekAvg - prevWeekAvg) / prevWeekAvg * 100).round()
        : 0;
    final isImproved = percentChange > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with comparison badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Week-over-week comparison badge
              if (percentChange != 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isImproved
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                        : const Color(0xFFE91E63).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isImproved ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: isImproved
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE91E63),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isImproved ? '+' : ''}$percentChange%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isImproved
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE91E63),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
                final isToday = index == 6;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap?.call(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Value label for selected/today
                          if (isSelected || isToday)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: heightPercent),
                            duration:
                                Duration(milliseconds: 500 + (index * 50)),
                            curve: Curves.easeOutCubic,
                            builder: (context, animValue, _) {
                              return Container(
                                height: 70 * animValue,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isSelected || isToday
                                        ? [color, color.withValues(alpha: 0.7)]
                                        : [
                                            color.withValues(alpha: 0.3),
                                            color.withValues(alpha: 0.1)
                                          ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: (isSelected || isToday)
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
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
                              fontWeight: (isSelected || isToday)
                                  ? FontWeight.bold
                                  : null,
                              color: (isSelected || isToday) ? color : null,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate achievement stats
    final totalCompletedDays = _getTotalCompletedDays(habits);
    final longestStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    final totalHabits = habits.length;
    final perfectDays = _getPerfectDays(habits);
    final categories = habits.map((h) => h.category).toSet().length;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Summary - Modern pill cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _ModernStatPill(
                    value: '$totalHabits',
                    label: 'Habits',
                    color: const Color(0xFF6366F1),
                    isDark: isDark),
                const SizedBox(width: 8),
                _ModernStatPill(
                    value: '$longestStreak',
                    label: 'Best',
                    color: const Color(0xFFFFA94A),
                    isDark: isDark),
                const SizedBox(width: 8),
                _ModernStatPill(
                    value: '$perfectDays',
                    label: 'Perfect',
                    color: const Color(0xFF10B981),
                    isDark: isDark),
                const SizedBox(width: 8),
                _ModernStatPill(
                    value: '$totalCompletedDays',
                    label: 'Done',
                    color: const Color(0xFF1FD1A5),
                    isDark: isDark),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

          const SizedBox(height: 28),

          // Daily Completion - Horizontal Scroll
          _buildCategorySection(
            context,
            title: '⭐ Daily Completion',
            achievements: [
              _AchievementData('⭐', 'First Perfect', 'Complete all habits',
                  'Bronze', perfectDays >= 1, perfectDays >= 1 ? 1.0 : 0.0),
              _AchievementData(
                  '🌟',
                  'Week Champion',
                  '7 perfect days',
                  'Silver',
                  perfectDays >= 7,
                  (perfectDays / 7).clamp(0.0, 1.0)),
              _AchievementData(
                  '💫',
                  'Monthly Master',
                  '30 perfect days',
                  'Gold',
                  perfectDays >= 30,
                  (perfectDays / 30).clamp(0.0, 1.0)),
            ],
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Streak Records - Horizontal Scroll
          _buildCategorySection(
            context,
            title: '🔥 Streak Records',
            achievements: [
              _AchievementData(
                  '🔥',
                  'Getting Started',
                  '3-day streak',
                  'Bronze',
                  longestStreak >= 3,
                  (longestStreak / 3).clamp(0.0, 1.0)),
              _AchievementData('💥', 'Week Warrior', '7-day streak', 'Silver',
                  longestStreak >= 7, (longestStreak / 7).clamp(0.0, 1.0)),
              _AchievementData('🚀', 'Unstoppable', '30-day streak', 'Gold',
                  longestStreak >= 30, (longestStreak / 30).clamp(0.0, 1.0)),
              _AchievementData(
                  '👑',
                  'Streak Legend',
                  '100-day streak',
                  'Platinum',
                  longestStreak >= 100,
                  (longestStreak / 100).clamp(0.0, 1.0)),
            ],
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Collection - Horizontal Scroll
          _buildCategorySection(
            context,
            title: '🌱 Habit Collection',
            achievements: [
              _AchievementData('🌱', 'First Step', 'Create 1 habit', 'Bronze',
                  totalHabits >= 1, totalHabits >= 1 ? 1.0 : 0.0),
              _AchievementData('🌿', 'Building', '5 habits', 'Silver',
                  totalHabits >= 5, (totalHabits / 5).clamp(0.0, 1.0)),
              _AchievementData('🌳', 'Architect', '10 habits', 'Gold',
                  totalHabits >= 10, (totalHabits / 10).clamp(0.0, 1.0)),
            ],
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Total Completions - Horizontal Scroll
          _buildCategorySection(
            context,
            title: '💪 Total Completions',
            achievements: [
              _AchievementData(
                  '💪',
                  'Committed',
                  '10 completions',
                  'Bronze',
                  totalCompletedDays >= 10,
                  (totalCompletedDays / 10).clamp(0.0, 1.0)),
              _AchievementData(
                  '🏆',
                  'Dedicated',
                  '50 completions',
                  'Silver',
                  totalCompletedDays >= 50,
                  (totalCompletedDays / 50).clamp(0.0, 1.0)),
              _AchievementData(
                  '👑',
                  'Legendary',
                  '100 completions',
                  'Gold',
                  totalCompletedDays >= 100,
                  (totalCompletedDays / 100).clamp(0.0, 1.0)),
              _AchievementData(
                  '💎',
                  'Diamond',
                  '500 completions',
                  'Platinum',
                  totalCompletedDays >= 500,
                  (totalCompletedDays / 500).clamp(0.0, 1.0)),
            ],
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Variety - Horizontal Scroll
          _buildCategorySection(
            context,
            title: '🎨 Variety',
            achievements: [
              _AchievementData('🎨', 'Multi-Tasker', '3 categories', 'Bronze',
                  categories >= 3, (categories / 3).clamp(0.0, 1.0)),
              _AchievementData('☯️', 'Well Rounded', '5 categories', 'Silver',
                  categories >= 5, (categories / 5).clamp(0.0, 1.0)),
            ],
            isDark: isDark,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String title,
    required List<_AchievementData> achievements,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              return Padding(
                padding: EdgeInsets.only(
                    right: index < achievements.length - 1 ? 12 : 0),
                child: _ModernAchievementCard(
                  icon: a.icon,
                  title: a.title,
                  description: a.description,
                  rarity: a.rarity,
                  unlocked: a.unlocked,
                  progress: a.progress,
                  isDark: isDark,
                )
                    .animate(delay: (index * 80).ms)
                    .fadeIn()
                    .slideX(begin: 0.15, end: 0),
              );
            },
          ),
        ),
      ],
    );
  }

  int _getTotalCompletedDays(List<Habit> habits) {
    int total = 0;
    for (final habit in habits) {
      total += habit.completionDates.length;
    }
    return total;
  }

  int _getPerfectDays(List<Habit> habits) {
    if (habits.isEmpty) return 0;
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

// Data class for achievements
class _AchievementData {
  final String icon;
  final String title;
  final String description;
  final String rarity;
  final bool unlocked;
  final double progress;

  _AchievementData(this.icon, this.title, this.description, this.rarity,
      this.unlocked, this.progress);
}

// Modern stat pill widget
class _ModernStatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _ModernStatPill({
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern achievement card with circular progress
class _ModernAchievementCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String rarity;
  final bool unlocked;
  final double progress;
  final bool isDark;

  const _ModernAchievementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.rarity,
    required this.unlocked,
    required this.progress,
    required this.isDark,
  });

  Color get rarityColor {
    switch (rarity) {
      case 'Bronze':
        return const Color(0xFFCD7F32);
      case 'Silver':
        return const Color(0xFFA8A8A8);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Platinum':
        return const Color(0xFF26C6DA);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: unlocked
            ? Border.all(color: rarityColor.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: unlocked
                ? rarityColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress ring with icon
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      unlocked
                          ? rarityColor
                          : rarityColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                // Icon
                Text(
                  icon,
                  style: TextStyle(
                    fontSize: 24,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
                // Checkmark for unlocked
                if (unlocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: rarityColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: unlocked
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 2),
          // Rarity
          Text(
            rarity,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: unlocked ? rarityColor : Colors.grey,
            ),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191919) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.15 : 0.1),
            color.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
