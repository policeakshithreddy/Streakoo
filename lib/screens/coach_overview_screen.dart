import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/habit.dart';

import '../state/app_state.dart';
import '../models/weekly_report.dart';
import '../models/ai_insight.dart';
import '../services/weekly_report_service.dart';
import '../services/insight_analyzer_service.dart';
import '../services/brief_generation_service.dart';
import '../services/groq_ai_service.dart';
import '../services/team_service.dart';
import '../widgets/daily_brief_card.dart';
import '../widgets/weekly_summary_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/chat_bottom_sheet.dart';
import '../widgets/weekly_archive_card.dart';
import '../services/supabase_service.dart';
import '../services/accountability_service.dart';
import 'auth_screen.dart';
import 'accountability_partners_screen.dart';
import 'team_dashboard_screen.dart';

class CoachOverviewScreen extends StatefulWidget {
  const CoachOverviewScreen({super.key});

  @override
  State<CoachOverviewScreen> createState() => _CoachOverviewScreenState();
}

class _CoachOverviewScreenState extends State<CoachOverviewScreen> {
  WeeklyReport? _currentWeekReport;
  List<WeeklyReport> _pastReports = [];
  List<AIInsight> _insights = [];
  bool _isLoading = true;
  final _briefService = BriefGenerationService();

  // AI Smart Insight state
  String? _aiSmartInsight;
  bool _isLoadingSmartInsight = false;
  static const String _smartInsightCacheKey = 'ai_smart_insight_v3';
  static const String _smartInsightDateKey = 'ai_smart_insight_date_v3';

  // Teams Promo state
  bool _showTeamsPromo = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadOrGenerateSmartInsight();
    _loadTeamsPromoPreference();
  }

  Future<void> _loadTeamsPromoPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showTeamsPromo = prefs.getBool('show_teams_promo') ?? true;
      });
    }
  }

  Future<void> _dismissTeamsPromo() async {
    setState(() {
      _showTeamsPromo = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_teams_promo', false);
  }

  Future<void> _loadOrGenerateSmartInsight() async {
    final appState = context.read<AppState>();
    // No longer skipping AI insight if health challenge is active,
    // as pattern insights are still valuable.

    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cachedDate = prefs.getString(_smartInsightDateKey);

    // Use cached insight if from today
    if (cachedDate == today) {
      final cached = prefs.getString(_smartInsightCacheKey);
      if (cached != null && mounted) {
        setState(() {
          _aiSmartInsight = cached;
        });
        return;
      }
    }

    // Generate new AI insight
    if (!mounted) return;
    setState(() => _isLoadingSmartInsight = true);

    try {
      final habits = appState.habits;
      if (habits.isEmpty) {
        setState(() => _isLoadingSmartInsight = false);
        return;
      }

      // Collect pattern data
      final now = DateTime.now();
      final dayCounts = <int, List<int>>{}; // weekday -> [completed, total]
      for (int i = 0; i < 28; i++) {
        final date = DateTime(now.year, now.month, now.day - i);
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final weekday = date.weekday;
        dayCounts.putIfAbsent(weekday, () => [0, 0]);
        for (final h in habits) {
          dayCounts[weekday]![1]++;
          if (h.completionDates.contains(dateStr)) {
            dayCounts[weekday]![0]++;
          }
        }
      }

      // Calculate stats for prompt
      int worstDay = 1;
      double worstRate = 1.0;
      int bestDay = 1;
      double bestRate = 0.0;
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];

      dayCounts.forEach((day, stats) {
        if (stats[1] > 0) {
          final rate = stats[0] / stats[1];
          if (rate < worstRate) {
            worstRate = rate;
            worstDay = day;
          }
          if (rate > bestRate) {
            bestRate = rate;
            bestDay = day;
          }
        }
      });

      final avgStreak =
          habits.map((h) => h.streak).reduce((a, b) => a + b) / habits.length;

      final prompt =
          '''You're a cool habit coach. Give ONE solid insight (20-30 words).

Stats:
- Power day: ${dayNames[bestDay - 1]} (${(bestRate * 100).round()}%)
- Weak day: ${dayNames[worstDay - 1]} (${(worstRate * 100).round()}%)
- Avg streak: ${avgStreak.round()} days
- Today: ${dayNames[now.weekday - 1]}

Rules:
- Start with a relevant emoji
- Use Gen-Z friendly language
- Be motivating & fun
- Length: 20-30 words to give real value''';

      final insight = await GroqAIService.instance.generateResponse(
        systemPrompt:
            'You are a trendy habit coach. Give meaningful insights. Length 20-30 words. Sound cool and motivating.',
        userPrompt: prompt,
        maxTokens: 60,
      );

      if (insight != null && insight.isNotEmpty && mounted) {
        setState(() {
          _aiSmartInsight = insight;
          _isLoadingSmartInsight = false;
        });
        // Cache
        await prefs.setString(_smartInsightCacheKey, insight);
        await prefs.setString(_smartInsightDateKey, today);
      }
    } catch (e) {
      debugPrint('Failed to generate AI smart insight: $e');
      if (mounted) setState(() => _isLoadingSmartInsight = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final appState = context.read<AppState>();
    final habits = appState.habits;

    try {
      // 1. Trigger auto-generation (Daily Briefs & Weekly Reports)
      // Add timeout to prevent hanging
      await _briefService.checkAndGenerate(context).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ Brief generation timed out');
          return;
        },
      );

      // 2. Generate current week report (on-the-fly) - WITH CACHING
      if (habits.isNotEmpty) {
        // --- WEEKLY SUMMARY / REPORT CACHING ---
        final shouldRefreshSummary = appState.shouldRefreshWeeklySummary;
        final cachedSummary = appState.cachedCurrentWeekSummary;

        // Pass cached summary if available to skip AI call
        final currentReport = await WeeklyReportService.instance
            .getCurrentWeekReport(habits,
                existingSummary: shouldRefreshSummary ? null : cachedSummary)
            .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw 'Report generation timed out';
          },
        );

        // If we generated a NEW summary (and it's not null), update cache
        if (shouldRefreshSummary && currentReport.aiSummary != null) {
          await appState.updateCachedWeeklySummary(currentReport.aiSummary!);
          debugPrint('📝 Weekly summary generated & cached');
        } else if (!shouldRefreshSummary) {
          debugPrint('♻️ Using cached weekly summary');
        }

        // --- INSIGHTS CACHING ---
        List<AIInsight> insights;
        if (appState.shouldRefreshInsights) {
          debugPrint('🧠 Generating new insights...');
          insights = await InsightAnalyzerService.instance
              .analyzeHabits(habits)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => [],
              );
          // Update cache
          await appState.updateCachedInsights(insights);
        } else {
          debugPrint('♻️ Using cached insights');
          insights = appState.cachedInsights;
        }

        if (mounted) {
          setState(() {
            _currentWeekReport = currentReport;
            _pastReports = appState.weeklyReports; // Load from AppState
            _insights = insights.take(3).toList();
            _isLoading = false;
          });

          // Check if challenge is complete
          _checkChallengeCompletion(appState);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading AI brief data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Optionally show a snackbar or error state
        });
      }
    }
  }

  void _checkChallengeCompletion(AppState appState) {
    final challenge = appState.activeHealthChallenge;
    if (challenge == null) return;

    final endDate =
        challenge.startDate.add(Duration(days: challenge.durationWeeks * 7));

    // If we're past the end date
    if (DateTime.now().isAfter(endDate)) {
      // Show completion dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showChallengeCompleteDialog(challenge);
      });
    }
  }

  void _showChallengeCompleteDialog(dynamic challenge) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Text('🎉', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'Challenge Complete!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Congratulations! You have completed the "${challenge.title}".\n\n'
          'We will now clean up your weekly progress and close this chapter so you can start fresh!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await context.read<AppState>().completeCurrentHealthChallenge();
              if (mounted) {
                _loadData(); // Reload to reflect changes
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Challenge closed. Ready for your next goal!'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Claim Victory & Reset'),
          ),
        ],
      ),
    );
  }

  void _openChat({String? initialMessage}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ChatBottomSheet(
        initialContext: initialMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Brief & Insights'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16)
                        .copyWith(bottom: 80),
                    children: [
                      const SizedBox(height: 8),

                      // Daily Brief (Greeting & Focus List)
                      const DailyBriefCard(),

                      // 🎯 Coach's Keystone Habit
                      _buildDailyFocus(context, isDark),
                      const SizedBox(height: 16),

                      // 🚀 Momentum Meter (Velocity)
                      _buildMomentumMeter(context, isDark),
                      const SizedBox(height: 16),

                      // 🧠 Smart Pattern Insight
                      _buildSmartPatternInsight(context, isDark),
                      const SizedBox(height: 16),

                      // 🔮 Future You Projection
                      _buildFutureYou(context, isDark),
                      const SizedBox(height: 20),

                      // 👨‍👩‍👧‍👦 My Teams Section
                      _buildTeamsSection(context, isDark),
                      const SizedBox(height: 20),

                      _buildLeaderboardTeaser(context, isDark),

                      // Current Week Summary
                      if (_currentWeekReport != null) ...[
                        const SizedBox(height: 8),
                        WeeklySummaryCard(
                          report: _currentWeekReport!,
                          onTapExpand: () {
                            _showWeeklyReportDetails(_currentWeekReport!);
                          },
                        ),
                      ],

                      // GUEST LOCK: Insights & Archive
                      // If guest, we show blurred content or just a prompt
                      if (_isGuest()) ...[
                        const SizedBox(height: 40),
                        _buildGuestLockOverlay(theme),
                      ] else ...[
                        // Insights Section
                        if (_insights.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '💡 Insights & Patterns',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._insights.map((insight) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 12, left: 16, right: 16),
                                child: InsightCard(
                                  insight: insight,
                                  onTap: () {
                                    _openChat(
                                        initialMessage: insight.description);
                                  },
                                ),
                              )),
                        ],

                        // Past Weeks Archive
                        if (_pastReports.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          WeeklyArchiveCard(
                            reports: _pastReports,
                            onReportTap: (report) {
                              _showWeeklyReportDetails(report);
                            },
                          ),
                        ],

                        // Empty state for insights
                        if (_currentWeekReport == null &&
                            _insights.isEmpty &&
                            _pastReports.isEmpty) ...[
                          const SizedBox(height: 60),
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  '🌱',
                                  style: TextStyle(fontSize: 64),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Start tracking habits to see insights!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : Colors.black.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openChat(),
        backgroundColor: const Color(0xFF191919),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text(
          'Chat',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  bool _isGuest() {
    final user = SupabaseService().currentUser;
    // Guest if no user or no email (anonymous)
    return user == null || user.email == null || user.email!.isEmpty;
  }

  Widget _buildGuestLockOverlay(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // Blurred Mock Content
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(16)),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(16)),
                ),
              ],
            ),
          ),

          // Lock Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_outline,
                        size: 32, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unlock AI Insights',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Sign up to get personalized daily briefs and weekly reports.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      // Navigate to Auth Screen (guest can go back to continue browsing)
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                    child: const Text('Sign Up / Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeeklyReportDetails(WeeklyReport report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF191919) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Gradient Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryOrange,
                    _secondaryOrange,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _primaryOrange.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    report.weekDisplayString,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${report.completionPercentage}',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12, left: 4),
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Completion Rate',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle_outline,
                            label: 'Completed',
                            value: '${report.totalCompletions}',
                            subValue: 'of ${report.totalExpected}',
                            color: Colors.green,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star_outline,
                            label: 'Best Day',
                            value: report.bestDay ?? '-',
                            color: Colors.amber,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (report.longestStreakThisWeek > 0)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.local_fire_department_outlined,
                              label: 'Longest Streak',
                              value: '${report.longestStreakThisWeek}',
                              subValue: 'days',
                              color: Colors.orange,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.trending_up,
                              label: 'vs Last Week',
                              value: report.previousWeekRate != null
                                  ? '${((report.completionRate - report.previousWeekRate!) * 100).round().abs()}%'
                                  : '-',
                              subValue: report.previousWeekRate != null
                                  ? (report.completionRate >=
                                          report.previousWeekRate!
                                      ? '↑ Improved'
                                      : '↓ Declined')
                                  : 'First week',
                              color: (report.previousWeekRate != null &&
                                      report.completionRate >=
                                          report.previousWeekRate!)
                                  ? Colors.green
                                  : Colors.red,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                    // Top Habits Section
                    if (report.topHabits.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        '🏆 Top Performers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: report.topHabits
                            .map((habit) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.green
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    habit,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],

                    if (report.strugglingHabits.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        '⚠️ Needs Attention',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...report.strugglingHabits.map((habit) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              habit,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          )),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stat Card Widget for Weekly Report
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 2),
            Text(
              subValue,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // ============== COACH ENHANCEMENT WIDGETS (SPECIAL SAUCE) ==============

  // Theme Colors for AI Features
  static const _aiPurple = Color(0xFF8B5CF6);
  static const _aiPink = Color(0xFFEC4899);
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryOrange = Color(0xFFFF8C42);

  // Minimum tasks required before showing AI insights
  static const int _minTasksForInsights = 1;

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

  Widget _buildDailyFocus(BuildContext context, bool isDark) {
    final appState = context.read<AppState>();
    final habits = appState.habits;

    if (habits.isEmpty) return const SizedBox.shrink();

    // Logic: Find habit with streak > 0 (protect it) OR lowest completion rate
    // Prioritize protecting a streak that is at risk (not done today)
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    Habit? focusHabit;

    // 1. Find habit with streak > 3 not done today
    try {
      focusHabit = habits.firstWhere(
          (h) => h.streak > 3 && !h.completionDates.contains(todayStr));
    } catch (_) {
      // 2. Find any habit not done today
      try {
        focusHabit =
            habits.firstWhere((h) => !h.completionDates.contains(todayStr));
      } catch (_) {
        // All done!
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.green.withValues(alpha: 0.2),
              Colors.teal.withValues(alpha: 0.1)
            ]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('All Systems Go!',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87)),
                    Text('You crushed your daily focus. Rest up!',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn();
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _aiPurple.withValues(alpha: 0.15),
            _aiPink.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _aiPurple.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _aiPurple.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _aiPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🎯 KEYSTONE HABIT',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
              ),
              const Icon(Icons.auto_awesome, color: _aiPurple, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            focusHabit.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            focusHabit.streak > 0
                ? 'Protect your ${focusHabit.streak}-day streak!'
                : 'Start strong – this represents your biggest opportunity.',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              appState.completeHabit(focusHabit!);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'TAP TO COMPLETE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, duration: 500.ms);
  }

  Widget _buildMomentumMeter(BuildContext context, bool isDark) {
    // Calculate Velocity: (Current 3-day rate) vs (Historic 14-day rate)
    final appState = context.read<AppState>();
    final habits = appState.habits;
    if (habits.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();

    double calculateRate(int days) {
      if (days == 0) return 0.0;
      int completed = 0;
      int total = 0;
      for (int i = 0; i < days; i++) {
        final date = DateTime(now.year, now.month, now.day - i);
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        for (final h in habits) {
          total++;
          if (h.completionDates.contains(dateStr)) completed++;
        }
      }
      return total == 0 ? 0.0 : completed / total;
    }

    final currentRate = calculateRate(3);
    final historicRate = calculateRate(14);
    final diff = currentRate - historicRate;

    String status;
    Color color;
    IconData icon;
    String message;

    if (diff > 0.1) {
      status = 'Heating Up! 🔥';
      color = const Color(0xFFFF4E00); // Fire Orange
      icon = Icons.trending_up;
      message = 'You\'re +${(diff * 100).round()}% faster than your average.';
    } else if (diff < -0.1) {
      status = 'Cooling Down ❄️';
      color = Colors.blue;
      icon = Icons.severe_cold;
      message =
          'Momentum is slipping by ${(diff.abs() * 100).round()}%. Reignite it!';
    } else {
      status = 'Steady Pace ➡️';
      color = Colors.green;
      icon = Icons.remove_circle_outline;
      message = 'Consistent performance. Keep building.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MOMENTUM',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(status,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                Text(message,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSmartPatternInsight(BuildContext context, bool isDark) {
    // Check task completion requirement
    final completedTasks = _getTodayCompletedTasks();
    final hasEnoughTasks = completedTasks >= _minTasksForInsights;
    final tasksRemaining = _minTasksForInsights - completedTasks;

    // Find the weekday with lowest completion rate
    final appState = context.read<AppState>();
    if (appState.habits.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final dayCounts = <int, List<int>>{}; // weekday -> [completed, total]

    // Analyze last 28 days
    for (int i = 0; i < 28; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final weekday = date.weekday; // 1 = Mon, 7 = Sun

      dayCounts.putIfAbsent(weekday, () => [0, 0]);

      for (final h in appState.habits) {
        dayCounts[weekday]![1]++; // total possible
        if (h.completionDates.contains(dateStr)) {
          dayCounts[weekday]![0]++; // completed
        }
      }
    }

    // Find worst day
    int worstDay = 1;
    double worstRate = 1.0;

    dayCounts.forEach((day, stats) {
      if (stats[1] > 0) {
        final rate = stats[0] / stats[1];
        if (rate < worstRate) {
          worstRate = rate;
          worstDay = day;
        }
      }
    });

    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final worstDayName = dayNames[worstDay - 1];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191919) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFA94A), // Orange
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              const Text('SMART INSIGHT',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      letterSpacing: 1)),
              const Spacer(),
              // AI Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF9C27B0)
                                .withValues(alpha: 0.2), // Purple
                            const Color(0xFF2196F3)
                                .withValues(alpha: 0.2), // Blue
                          ]
                        : [
                            const Color(0xFFF3E5F5), // Light Purple
                            const Color(0xFFE3F2FD), // Light Blue
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFF9C27B0).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFFE1BEE7), // Lighter Purple
                                const Color(0xFFBBDEFB), // Lighter Blue
                              ]
                            : [
                                const Color(0xFF7B1FA2), // Darker Purple
                                const Color(0xFF1976D2), // Darker Blue
                              ],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.white, // Required for ShaderMask
                      ),
                    ),
                    const SizedBox(width: 4),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFFE1BEE7),
                                const Color(0xFFBBDEFB),
                              ]
                            : [
                                const Color(0xFF7B1FA2),
                                const Color(0xFF1976D2),
                              ],
                      ).createShader(bounds),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white, // Required for ShaderMask
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasEnoughTasks) ...[
            Text(
              '🔒 Complete $tasksRemaining more ${tasksRemaining == 1 ? 'task' : 'tasks'} to unlock',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              'AI will analyze your patterns once you complete daily habits',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  height: 1.4),
            ),
          ] else if (_isLoadingSmartInsight) ...[
            // Loading shimmer
            Container(
              height: 18,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 200,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ] else if (_aiSmartInsight != null) ...[
            // AI-generated insight
            Text(
              _aiSmartInsight!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.black87,
                height: 1.4,
                letterSpacing: 0.3,
              ),
            ),
          ] else ...[
            // Fallback to heuristic insight
            Text(
              worstRate > 0.8
                  ? 'Consistency is your superpower! 💫'
                  : 'Let\'s boost your ${worstDayName}s! 🚀',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.black87,
                height: 1.4,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              worstRate > 0.8
                  ? 'You\'re crushing it across the board. Keep this momentum flowing into next week.'
                  : 'Currently, ${worstDayName}s are a bit tricky. Try setting a reminder or starting small to turn it around.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                letterSpacing: 0.3,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildFutureYou(BuildContext context, bool isDark) {
    final appState = context.read<AppState>();
    if (appState.habits.isEmpty) return const SizedBox.shrink();

    final maxStreak =
        appState.habits.map((h) => h.streak).fold(0, (a, b) => a > b ? a : b);
    final projectedStreak = maxStreak + 30;
    final futureDate = DateTime.now().add(const Duration(days: 30));
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dateStr = '${monthNames[futureDate.month - 1]} ${futureDate.day}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.15),
          const Color(0xFF6366F1).withValues(alpha: 0.1),
        ]),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.calendar_today,
                  size: 50,
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
              const Positioned(
                top: 16,
                child: Text('30',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6))),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FUTURE YOU',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('By $dateStr...',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                Text('You will hit a $projectedStreak-day streak!',
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTeamsSection(BuildContext context, bool isDark) {
    final teams = TeamService.instance.activeTeams;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFA94A).withValues(alpha: 0.15),
            const Color(0xFFFFA94A).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
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
                  color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('🤝', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Teams',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      teams.isEmpty
                          ? 'Connect with your friend'
                          : '${teams.length} active team${teams.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountabilityPartnersScreen(),
                    ),
                  );
                },
                icon: Icon(
                  teams.isEmpty ? Icons.add : Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFFFFA94A),
                ),
                label: Text(
                  teams.isEmpty ? 'Connect' : 'View All',
                  style: const TextStyle(
                    color: Color(0xFFFFA94A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (teams.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Team cards
            ...teams.take(2).map((team) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeamDashboardScreen(team: team),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(team.teamEmoji,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${team.members.length} members · ${team.teamStreak} day streak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFFFFA94A),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),

            if (teams.length > 2)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountabilityPartnersScreen(),
                      ),
                    );
                  },
                  child: Text(
                    '+${teams.length - 2} more teams',
                    style: const TextStyle(color: Color(0xFFFFA94A)),
                  ),
                ),
              ),
          ] else if (_showTeamsPromo) ...[
            const SizedBox(height: 12),
            // Empty state with dismiss
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Habit challenges are better together!',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Connect with friends to track habits together',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _dismissTeamsPromo();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.transparent, // Hit area
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.white54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildLeaderboardTeaser(BuildContext context, bool isDark) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getGlobalRanking(),
      builder: (context, snapshot) {
        final rankData = snapshot.data;
        final hasData = rankData != null;
        final percentile = rankData?['percentile'] as int?;
        final isTopPerformer = hasData && (percentile ?? 100) <= 20;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Just refresh or show simple toast since there's no complex screen anymore?
            // Or maybe open a simple dialog explaining the rank?
            // User just said "remove the element... provide ranking of all other".
            // Since there is no more full leaderboard screen, we might make this non-tappable
            // or just a display card. But for visual consistency with the old one, we keep the look.
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isTopPerformer
                    ? [
                        const Color(0xFFFFD700).withValues(alpha: 0.25),
                        const Color(0xFFFFA500).withValues(alpha: 0.15),
                      ]
                    : [
                        const Color(0xFFFFA94A).withValues(alpha: 0.15),
                        const Color(0xFFFF8A3D).withValues(alpha: 0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isTopPerformer
                    ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                    : const Color(0xFFFFA94A).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isTopPerformer
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFFFA94A))
                      .withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isTopPerformer
                          ? [
                              const Color(0xFFFFD700).withValues(alpha: 0.3),
                              const Color(0xFFFFA500).withValues(alpha: 0.2),
                            ]
                          : [
                              const Color(0xFFFFA94A).withValues(alpha: 0.3),
                              const Color(0xFFFF8A3D).withValues(alpha: 0.2),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    isTopPerformer ? '🏆' : '🌎',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isTopPerformer
                              ? const Color(0xFFFFD700)
                              : const Color(0xFFFFA94A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'GLOBAL RANKING',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hasData && percentile != null) ...[
                        Text(
                          'Top $percentile% by Consistency',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You are more consistent than ${100 - percentile}% of others.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Unlock Your Rank',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Complete habits to see where you stand.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1);
  }

  Future<Map<String, dynamic>?> _getGlobalRanking() async {
    try {
      final user = SupabaseService().currentUser;
      if (user == null) return null;

      final appState = context.read<AppState>();
      final habits = appState.habits;
      if (habits.isEmpty) return null;

      // Calculate user's 7-day completion rate
      final now = DateTime.now();
      int totalPossible = 0;
      int completed = 0;

      for (int i = 0; i < 7; i++) {
        final date = DateTime(now.year, now.month, now.day - i);
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        for (final habit in habits) {
          totalPossible++;
          if (habit.completionDates.contains(dateStr)) {
            completed++;
          }
        }
      }

      final userRate = totalPossible > 0 ? completed / totalPossible : 0.0;

      try {
        // Update user stats
        await SupabaseService().client.from('user_stats').upsert({
          'user_id': user.id,
          'weekly_completion_rate': userRate,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');

        // Get all rates for ranking
        final response = await SupabaseService()
            .client
            .from('user_stats')
            .select('weekly_completion_rate')
            .order('weekly_completion_rate', ascending: false)
            .limit(10000);

        final allRates = (response as List)
            .map((r) => (r['weekly_completion_rate'] as num).toDouble())
            .toList();

        if (allRates.isEmpty) {
          return {
            'rank': 1,
            'total': 1,
            'percentile': 1,
            'friendsRank': null,
          };
        }

        // Find position (rank)
        int rank = 1;
        for (final rate in allRates) {
          if (rate > userRate) rank++;
        }

        final totalUsers = allRates.length;
        final percentile = ((rank / totalUsers) * 100).ceil().clamp(1, 99);

        // Check friends ranking
        String? friendsRankText;
        final partners = AccountabilityService.instance.activePartners;
        if (partners.isNotEmpty) {
          final yourStreak =
              habits.map((h) => h.streak).fold(0, (a, b) => a > b ? a : b);
          int betterFriends = 0;
          for (final partner in partners) {
            if (partner.partnerCurrentStreak > yourStreak) betterFriends++;
          }
          if (betterFriends == 0) {
            friendsRankText =
                'Leading among ${partners.length} friend${partners.length > 1 ? 's' : ''}! 🔥';
          } else {
            friendsRankText =
                '$betterFriends friend${betterFriends > 1 ? 's' : ''} ahead of you';
          }
        }

        return {
          'rank': rank,
          'total': totalUsers,
          'percentile': percentile,
          'friendsRank': friendsRankText,
        };
      } catch (e) {
        // Fallback
        final estimatedPercentile =
            (100 - (userRate * 90)).round().clamp(1, 99);
        return {
          'rank': estimatedPercentile * 10, // Rough estimate
          'total': 1000,
          'percentile': estimatedPercentile,
          'friendsRank': null,
        };
      }
    } catch (e) {
      return null;
    }
  }
}
