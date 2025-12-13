import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/health_service.dart';
import '../services/health_score_service.dart';
import '../services/ai_health_coach_service.dart';
import '../widgets/weekly_trend_chart.dart';
import '../widgets/milestone_celebration.dart';
import '../widgets/interactive_insight_cards.dart';

class HealthCoachingDashboard extends StatefulWidget {
  const HealthCoachingDashboard({super.key});

  @override
  State<HealthCoachingDashboard> createState() =>
      _HealthCoachingDashboardState();
}

class _HealthCoachingDashboardState extends State<HealthCoachingDashboard> {
  final _healthService = HealthService.instance;
  final _scoreService = HealthScoreService.instance;
  final _aiService = AIHealthCoachService.instance;

  bool _isLoading = true;
  double _healthScore = 0.0;
  double _previousScore = 0.0;
  String _smartInsight = '';
  List<String> _recommendations = [];
  List<double> _weeklyScores = [];
  bool _showMilestoneCelebration = false;

  // AI-generated nutrition advice
  Map<String, String>? _aiNutritionAdvice;

  // Predictions
  Map<String, dynamic>? _predictions;

  // Health data
  int _todaySteps = 0;
  double _todaySleep = 0.0;
  double _todayDistance = 0.0;

  // Card theme colors matching health dashboard
  // Wind AI - Indigo/Violet premium gradient
  static const _aiInsightPrimary = Color(0xFF6366F1); // Indigo
  static const _aiInsightSecondary = Color(0xFF8B5CF6); // Violet

  // Nutrition Tips - Emerald/Green gradient
  static const _nutritionPrimary = Color(0xFF10B981); // Emerald
  static const _nutritionSecondary = Color(0xFF059669); // Darker emerald

  // Main theme colors
  static const _primaryPurple = Color(0xFF8B5CF6);
  static const _secondaryPink = Color(0xFFEC4899);

  // Minimum tasks required before showing AI insights
  static const int _minTasksForInsights = 2;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Get count of tasks completed today
  int _getTodayCompletedTasks() {
    final appState = context.read<AppState>();
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    int completedToday = 0;
    for (final habit in appState.habits) {
      if (habit.completionDates.contains(todayStr)) {
        completedToday++;
      }
    }
    return completedToday;
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final appState = context.read<AppState>();

      // Fetch today's health data
      final steps = await _healthService.getTodaySteps();
      final sleep = await _healthService.getTodaySleep();
      final distance = await _healthService.getTodayDistance();

      // Get habit data
      final habits = appState.habits;
      final completedToday = habits.where((h) => h.completedToday).length;
      final currentStreak = habits.isEmpty
          ? 0
          : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

      // Calculate health score
      final score = _scoreService.calculateHealthScore(
        sleepHours: sleep ?? 0.0,
        steps: steps ?? 0,
        habitsCompleted: completedToday,
        totalHabits: habits.length,
        currentStreak: currentStreak,
        distance: distance,
      );

      // Get recommendations
      final recs = _scoreService.getRecommendations(
        sleepHours: sleep ?? 0.0,
        steps: steps ?? 0,
        habitsCompleted: completedToday,
        totalHabits: habits.length,
        currentStreak: currentStreak,
      );

      // Generate motivational message
      final motivation = _aiService.generateMotivationalMessage(
        healthScore: score,
        currentStreak: currentStreak,
      );

      if (mounted) {
        setState(() {
          _healthScore = score;
          _todaySteps = steps ?? 0;
          _todaySleep = sleep ?? 0.0;
          _todayDistance = distance ?? 0.0;
          _recommendations = recs;
          _smartInsight = motivation;
          _isLoading = false;
        });
      }

      // Load AI insights (async, don't block UI)
      _loadAIInsights();
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAIInsights() async {
    try {
      // Get weekly data for pattern analysis
      final now = DateTime.now();
      final weeklySteps = <int>[];
      final weeklySleep = <double>[];
      final weeklyScoresList = <double>[];

      // Get habit data once
      final appState = context.read<AppState>();
      final habits = appState.habits;
      final totalHabits = habits.length;

      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final steps = await _healthService.getStepCount(date);
        final sleep = await _healthService.getSleepHours(date);
        weeklySteps.add(steps);
        weeklySleep.add(sleep);

        // Calculate score for each day
        final dayScore = _scoreService.calculateHealthScore(
          sleepHours: sleep,
          steps: steps,
          habitsCompleted: habits.where((h) => h.completedToday).length,
          totalHabits: totalHabits,
          currentStreak: habits.isEmpty
              ? 0
              : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b),
        );
        weeklyScoresList.add(dayScore);
      }

      final habitsCompleted =
          appState.habits.where((h) => h.completedToday).length;
      final currentStreak = appState.habits.isEmpty
          ? 0
          : appState.habits
              .map((h) => h.streak)
              .reduce((a, b) => a > b ? a : b);

      final insight = await _aiService.generateSmartInsight(
        weeklySteps: weeklySteps,
        weeklySleep: weeklySleep,
        habitsCompleted: habitsCompleted,
        currentStreak: currentStreak,
      );

      if (mounted) {
        setState(() {
          _smartInsight = insight;
          _weeklyScores = weeklyScoresList;

          // Generate predictions
          if (weeklyScoresList.length >= 3) {
            final recentScores = weeklyScoresList.sublist(
              weeklyScoresList.length - 3,
            );
            final avgRecent =
                recentScores.reduce((a, b) => a + b) / recentScores.length;
            final previousScores = weeklyScoresList.sublist(
              0,
              weeklyScoresList.length - 3,
            );
            final avgPrevious =
                previousScores.reduce((a, b) => a + b) / previousScores.length;

            final trend = avgRecent - avgPrevious;
            final predicted = (avgRecent + trend).clamp(0.0, 100.0);

            String message;
            String confidence;
            String trendName;

            if (trend > 5) {
              message = 'You\'re on an upward trajectory! Keep it up! 🚀';
              confidence = 'High';
              trendName = 'improving';
            } else if (trend < -5) {
              message = 'Let\'s work on reversing this trend together';
              confidence = 'Medium';
              trendName = 'declining';
            } else {
              message = 'Maintaining your current level - aim higher!';
              confidence = 'Medium';
              trendName = 'stable';
            }

            _predictions = {
              'nextWeekScore': predicted,
              'trend': trendName,
              'confidence': confidence,
              'message': message,
            };
          }

          // Check if we should show milestone celebration
          if (weeklyScoresList.length >= 2) {
            _previousScore = weeklyScoresList[weeklyScoresList.length - 2];
            // Only show celebration on significant improvement
            if (_healthScore > _previousScore + 5) {
              _showMilestoneCelebration = true;
            }
          }
        });

        // Load AI-generated nutrition advice
        try {
          final nutritionAdvice = await _aiService.generateNutritionAdvice(
            sleep: _todaySleep,
            steps: _todaySteps,
            healthScore: _healthScore,
          );
          if (mounted) {
            setState(() {
              _aiNutritionAdvice = nutritionAdvice;
            });
          }
        } catch (e) {
          debugPrint('Error loading AI nutrition advice: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading AI insights: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = _scoreService.getScoreCategory(_healthScore);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.grey[50],
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
                          _primaryPurple.withValues(alpha: 0.05),
                          Colors.grey[50]!,
                        ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Health Dashboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Powered by Wind AI',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryPurple, _secondaryPink],
                          ),
                          borderRadius: BorderRadius.circular(20),
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
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: _primaryPurple,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Analyzing your health data...',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDashboardData,
                          color: _primaryPurple,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Health Score Card
                                _buildHealthScoreCard(category, isDark),

                                const SizedBox(height: 20),

                                // Today's Stats
                                _buildTodayStats(isDark),

                                const SizedBox(height: 20),

                                // Weekly Trend Chart
                                if (_weeklyScores.isNotEmpty)
                                  WeeklyTrendChart(
                                    weeklyScores: _weeklyScores,
                                    isDark: isDark,
                                  ),

                                if (_weeklyScores.isNotEmpty)
                                  const SizedBox(height: 20),

                                // Wind AI Insight Card with nutrition tips
                                if (_smartInsight.isNotEmpty)
                                  Column(
                                    children: [
                                      _buildInsightCard(
                                        title: 'Wind AI',
                                        icon: Icons.auto_awesome,
                                        content: _smartInsight,
                                        isDark: isDark,
                                      ),

                                      // Nutrition Recommendations
                                      if (_healthScore < 75)
                                        const SizedBox(height: 16),
                                      if (_healthScore < 75)
                                        _buildNutritionCard(isDark),
                                    ],
                                  ),

                                const SizedBox(height: 16),

                                // Predictive Insight Card
                                if (_predictions != null)
                                  PredictiveInsightCard(
                                    predictedScore:
                                        (_predictions!['nextWeekScore'] as num)
                                            .toDouble(),
                                    trend: _predictions!['trend'] as String,
                                    confidence:
                                        _predictions!['confidence'] as String,
                                    message: _predictions!['message'] as String,
                                    isDark: isDark,
                                  ),

                                if (_predictions != null)
                                  const SizedBox(height: 16),

                                // Recommendations
                                if (_recommendations.isNotEmpty)
                                  _buildRecommendationsCard(isDark),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Milestone Celebration Overlay
          if (_showMilestoneCelebration)
            MilestoneCelebration(
              score: _healthScore,
              previousScore: _previousScore,
              onComplete: () {
                setState(() => _showMilestoneCelebration = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(HealthScoreCategory category, bool isDark) {
    final color = Color(
      int.parse('0xFF${category.color}'),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Score circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: _healthScore / 100,
                  strokeWidth: 12,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ).animate().scale(
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _healthScore.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  Text(
                    category.level,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Message
          Text(
            category.message,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTodayStats(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.directions_walk_rounded,
                label: 'Steps',
                value: _todaySteps.toString(),
                color: const Color(0xFF4CAF50),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.bedtime_outlined,
                label: 'Sleep',
                value: '${_todaySleep.toStringAsFixed(1)}h',
                color: const Color(0xFF9C27B0),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.map_outlined,
                label: 'Distance',
                value: '${_todayDistance.toStringAsFixed(1)}km',
                color: const Color(0xFF2196F3),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
    ).animate().fadeIn(delay: 200.ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
        );
  }

  Widget _buildInsightCard({
    required String title,
    required IconData icon,
    required String content,
    required bool isDark,
  }) {
    final completedTasks = _getTodayCompletedTasks();
    final hasEnoughTasks = completedTasks >= _minTasksForInsights;
    final tasksRemaining = _minTasksForInsights - completedTasks;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _aiInsightPrimary.withValues(alpha: isDark ? 0.2 : 0.1),
            _aiInsightSecondary.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _aiInsightPrimary.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _aiInsightPrimary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_aiInsightPrimary, _aiInsightSecondary],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _aiInsightPrimary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // AI Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_aiInsightPrimary, _aiInsightSecondary],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Show content only if user has completed enough tasks
                if (hasEnoughTasks)
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.5,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔒 Complete $tasksRemaining more ${tasksRemaining == 1 ? 'task' : 'tasks'} to unlock AI insights',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI will analyze your patterns once you complete daily habits',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildRecommendationsCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ..._recommendations.asMap().entries.map((entry) {
          final index = entry.key;
          final rec = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryPurple, _secondaryPink],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (400 + index * 100).ms).slideX(
                  begin: 0.1,
                  end: 0,
                ),
          );
        }),
      ],
    );
  }

  Widget _buildNutritionCard(bool isDark) {
    final completedTasks = _getTodayCompletedTasks();
    final hasEnoughTasks = completedTasks >= _minTasksForInsights;

    // Use AI-generated nutrition advice if available and user has completed enough tasks
    final List<Map<String, String>> nutritionTips = [];

    if (hasEnoughTasks &&
        _aiNutritionAdvice != null &&
        _aiNutritionAdvice!.isNotEmpty) {
      // Use AI-generated advice
      nutritionTips.add({
        'icon': '🤖',
        'title': _aiNutritionAdvice!['title'] ?? 'AI Recommendation',
        'food': _aiNutritionAdvice!['food'] ?? 'Balanced nutrition',
        'why': _aiNutritionAdvice!['why'] ?? 'Personalized for you'
      });
    } else {
      // Fallback: Generate nutrition advice based on health data
      if (_todaySleep < 7) {
        nutritionTips.add({
          'icon': '🥛',
          'title': 'Improve Sleep Quality',
          'food': 'Almonds, cherries, chamomile tea',
          'why': 'Rich in melatonin & magnesium'
        });
      }

      if (_todaySteps < 8000) {
        nutritionTips.add({
          'icon': '🍌',
          'title': 'Boost Energy Levels',
          'food': 'Bananas, oats, sweet potatoes',
          'why': 'Complex carbs for sustained energy'
        });
      }

      if (_todaySteps > 10000) {
        nutritionTips.add({
          'icon': '🥗',
          'title': 'Post-Activity Recovery',
          'food': 'Greek yogurt, berries, spinach',
          'why': 'Protein & antioxidants for recovery'
        });
      }

      if (nutritionTips.isEmpty) {
        nutritionTips.add({
          'icon': '🥑',
          'title': 'Maintain Your Progress',
          'food': 'Avocado, salmon, quinoa, broccoli',
          'why': 'Balanced nutrition for optimal health'
        });
      }
    }

    // Achievement-based message
    String achievementMessage = '';
    if (_healthScore >= 90) {
      achievementMessage = '🏆 Amazing! You\'re in the top 10% of users!';
    } else if (_healthScore >= 75) {
      achievementMessage = '⭐ Great job! You\'re performing above average!';
    } else if (_healthScore >= 60) {
      achievementMessage =
          '💪 Good progress! Small improvements will boost your score.';
    } else {
      achievementMessage =
          '🌱 Every journey starts somewhere. Focus on one habit at a time!';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _nutritionPrimary.withValues(alpha: isDark ? 0.2 : 0.1),
            _nutritionSecondary.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _nutritionPrimary.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _nutritionPrimary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_nutritionPrimary, _nutritionSecondary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _nutritionPrimary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Nutrition Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_nutritionPrimary, _nutritionSecondary],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasEnoughTasks && _aiNutritionAdvice != null
                          ? 'AI-powered recommendations'
                          : hasEnoughTasks
                              ? 'Personalized for your goals'
                              : 'Complete ${_minTasksForInsights - completedTasks} more ${_minTasksForInsights - completedTasks == 1 ? 'task' : 'tasks'} to unlock',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Achievement message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : _nutritionSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _nutritionSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              achievementMessage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nutrition recommendations
          ...nutritionTips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : _nutritionPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _nutritionPrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tip['icon']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip['title']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🍽️ ${tip['food']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Why: ${tip['why']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
