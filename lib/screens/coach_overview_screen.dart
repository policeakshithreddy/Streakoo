import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/weekly_report.dart';
import '../models/ai_insight.dart';
import '../services/weekly_report_service.dart';
import '../services/insight_analyzer_service.dart';
import '../services/brief_generation_service.dart';
import '../widgets/daily_brief_card.dart';
import '../widgets/weekly_summary_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/chat_bottom_sheet.dart';
import '../widgets/weekly_archive_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
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

      // 2. Generate current week report (on-the-fly)
      if (habits.isNotEmpty) {
        final currentReport = await WeeklyReportService.instance
            .getCurrentWeekReport(habits)
            .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Return a dummy/empty report or handle gracefully
            // For now, we'll just return null or rethrow to be caught
            throw 'Report generation timed out';
          },
        );

        // 3. Generate insights
        final insights =
            await InsightAnalyzerService.instance.analyzeHabits(habits).timeout(
                  const Duration(seconds: 5),
                  onTimeout: () => [],
                );

        if (mounted) {
          setState(() {
            _currentWeekReport = currentReport;
            _pastReports = appState.weeklyReports; // Load from AppState
            _insights = insights.take(3).toList();
            _isLoading = false;
          });
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
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  const SizedBox(height: 8),

                  // Daily Brief Card
                  const DailyBriefCard(),

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
                    ..._insights.map((insight) => InsightCard(
                          insight: insight,
                          onTap: () {
                            _openChat(initialMessage: insight.description);
                          },
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

                  // Empty state
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

  void _showWeeklyReportDetails(WeeklyReport report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Report',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          report.weekDisplayString,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Completion Rate
                    Center(
                      child: Text(
                        '${report.completionPercentage}%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Completion Rate',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Stats
                    _DetailRow(
                      label: 'Total Completions',
                      value:
                          '${report.totalCompletions} / ${report.totalExpected}',
                      isDark: isDark,
                    ),
                    if (report.bestDay != null)
                      _DetailRow(
                        label: 'Best Day',
                        value: report.bestDay!,
                        isDark: isDark,
                      ),
                    if (report.topHabits.isNotEmpty)
                      _DetailRow(
                        label: 'Top Habits',
                        value: report.topHabits.join(', '),
                        isDark: isDark,
                      ),

                    // AI Summary
                    if (report.aiSummary != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA94A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                const Color(0xFFFFA94A).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFFFFA94A),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Summary',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              report.aiSummary!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.black.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
