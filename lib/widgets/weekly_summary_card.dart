import 'package:flutter/material.dart';

import '../models/weekly_report.dart';

class WeeklySummaryCard extends StatelessWidget {
  final WeeklyReport report;
  final VoidCallback? onTapExpand;

  const WeeklySummaryCard({
    super.key,
    required this.report,
    this.onTapExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCurrentWeek = report.isCurrentWeek;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentWeek
              ? const Color(0xFFFFA94A).withValues(alpha: 0.4)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08)),
          width: isCurrentWeek ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with comparison badge
                Row(
                  children: [
                    Text(
                      isCurrentWeek
                          ? '📊 This Week'
                          : '📅 ${report.weekDisplayString}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (isCurrentWeek)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFA94A),
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Week-over-week comparison badge
                    if (report.percentageChange != null)
                      _ComparisonBadge(
                        change: report.percentageChange!,
                        isDark: isDark,
                      ),
                  ],
                ),
                if (!isCurrentWeek)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      report.weekDisplayString,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: report.completionRate,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: report.completionRate >= 0.8
                                ? [
                                    const Color(0xFF27AE60),
                                    const Color(0xFF2ECC71)
                                  ]
                                : report.completionRate >= 0.6
                                    ? [
                                        const Color(0xFFFFA94A),
                                        const Color(0xFFFFCB74)
                                      ]
                                    : [
                                        const Color(0xFFE74C3C),
                                        const Color(0xFFFF6B6B)
                                      ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Percentage with achievement indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${report.completionPercentage}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black54,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Perfect week badge
                    if (report.isPerfectWeek)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA94A)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🏆', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              'Perfect!',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Health Stats Section
                if (report.healthStats != null) ...[
                  _HealthStatsSection(
                    healthStats: report.healthStats!,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],

                // Stats
                _StatRow(
                  icon: '🔥',
                  label: 'Best Day',
                  value: report.bestDay ?? 'N/A',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                if (report.topHabits.isNotEmpty)
                  _StatRow(
                    icon: '💪',
                    label: 'Top Habit',
                    value: report.topHabits.first,
                    isDark: isDark,
                  ),
                if (report.topHabits.isNotEmpty) const SizedBox(height: 8),
                if (report.strugglingHabits.isNotEmpty)
                  _StatRow(
                    icon: '⚠️',
                    label: 'Needs Focus',
                    value: report.strugglingHabits.first,
                    isDark: isDark,
                  ),

                // Weekly Consistency Map
                if (report.dailyCompletions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ConsistencyMap(
                    dailyCompletions: _getDailyRates(report),
                    isDark: isDark,
                  ),
                ],

                // XP & Level Progress
                if (report.xpEarned > 0 || report.levelsGained > 0) ...[
                  const SizedBox(height: 16),
                  _XPProgressSection(
                    xpEarned: report.xpEarned,
                    levelsGained: report.levelsGained,
                    isDark: isDark,
                  ),
                ],

                // Achievements
                if (report.achievements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _AchievementsSection(
                    achievements: report.achievements,
                    isDark: isDark,
                  ),
                ],

                // AI Summary
                if (report.aiSummary != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF191919)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            report.aiSummary!,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // View Full Report button
          if (onTapExpand != null)
            InkWell(
              onTap: onTapExpand,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Full Report',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFA94A),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Color(0xFFFFA94A),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<int, double> _getDailyRates(WeeklyReport report) {
    final rates = <int, double>{};
    final avgExpected = report.totalExpected / 7; // Approx daily expected

    report.dailyCompletions.forEach((day, count) {
      int weekday;
      switch (day) {
        case 'Monday':
          weekday = 1;
          break;
        case 'Tuesday':
          weekday = 2;
          break;
        case 'Wednesday':
          weekday = 3;
          break;
        case 'Thursday':
          weekday = 4;
          break;
        case 'Friday':
          weekday = 5;
          break;
        case 'Saturday':
          weekday = 6;
          break;
        case 'Sunday':
          weekday = 7;
          break;
        default:
          weekday = 1;
      }

      // Calculate rate (0.0 to 1.0)
      // Use avgExpected if > 0, otherwise count as 100% just to show activity
      rates[weekday] = avgExpected > 0
          ? (count / avgExpected).clamp(0.0, 1.0)
          : (count > 0 ? 1.0 : 0.0);
    });

    return rates;
  }
}

/// Week-over-week comparison badge
class _ComparisonBadge extends StatelessWidget {
  final int change;
  final bool isDark;

  const _ComparisonBadge({required this.change, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPositive = change > 0;
    final color =
        isPositive ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${change.abs()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Health stats section
class _HealthStatsSection extends StatelessWidget {
  final WeeklyHealthStats healthStats;
  final bool isDark;

  const _HealthStatsSection({
    required this.healthStats,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A90E2).withValues(alpha: isDark ? 0.15 : 0.1),
            const Color(0xFF50C9FF).withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💙 Health This Week',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (healthStats.averageSteps != null)
                Expanded(
                  child: _HealthStatItem(
                    icon: '👣',
                    value: _formatSteps(healthStats.averageSteps!),
                    label: 'avg/day',
                    isDark: isDark,
                  ),
                ),
              if (healthStats.averageSleep != null)
                Expanded(
                  child: _HealthStatItem(
                    icon: '😴',
                    value: '${healthStats.averageSleep!.toStringAsFixed(1)}h',
                    label: 'avg sleep',
                    isDark: isDark,
                  ),
                ),
              if (healthStats.averageHeartRate != null)
                Expanded(
                  child: _HealthStatItem(
                    icon: '❤️',
                    value: '${healthStats.averageHeartRate}',
                    label: 'bpm',
                    isDark: isDark,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }
}

class _HealthStatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final bool isDark;

  const _HealthStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

/// XP Progress section - Refined UI
class _XPProgressSection extends StatelessWidget {
  final int xpEarned;
  final int levelsGained;
  final bool isDark;

  const _XPProgressSection({
    required this.xpEarned,
    required this.levelsGained,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
            : const Color(0xFF6C63FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (xpEarned > 0)
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 16, color: Color(0xFFFFA94A)),
                const SizedBox(width: 4),
                Text(
                  '+$xpEarned XP',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFA94A),
                  ),
                ),
              ],
            ),
          if (xpEarned > 0 && levelsGained > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 1,
              height: 16,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          if (levelsGained > 0)
            Row(
              children: [
                const Icon(Icons.rocket_launch_rounded,
                    size: 14, color: Color(0xFF9B59B6)),
                const SizedBox(width: 6),
                Text(
                  '+$levelsGained Level Up',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9B59B6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Achievements section - Refined UI
class _AchievementsSection extends StatelessWidget {
  final List<StreakAchievement> achievements;
  final bool isDark;

  const _AchievementsSection({
    required this.achievements,
    required this.isDark,
  });

  String _getAchievementLabel(StreakAchievement achievement) {
    switch (achievement) {
      case StreakAchievement.perfectWeek:
        return 'Perfect Week';
      case StreakAchievement.milestone7:
        return '7 Day Streak';
      case StreakAchievement.milestone14:
        return '14 Day Streak';
      case StreakAchievement.milestone30:
        return '30 Day Streak';
      case StreakAchievement.milestone100:
        return '100 Streak';
      case StreakAchievement.newRecord:
        return 'New Record';
      case StreakAchievement.comeback:
        return 'Comeback';
    }
  }

  IconData _getAchievementIcon(StreakAchievement achievement) {
    switch (achievement) {
      case StreakAchievement.perfectWeek:
        return Icons.emoji_events_rounded;
      case StreakAchievement.milestone7:
      case StreakAchievement.milestone14:
      case StreakAchievement.milestone30:
      case StreakAchievement.milestone100:
        return Icons.local_fire_department_rounded;
      case StreakAchievement.newRecord:
        return Icons.flag_rounded;
      case StreakAchievement.comeback:
        return Icons.refresh_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Awards',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievements.map((achievement) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                // Unified "Premium" look - dark purple/blue tint
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2D2D44), const Color(0xFF232336)]
                      : [Colors.white, const Color(0xFFF5F5FA)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAchievementIcon(achievement),
                    size: 14,
                    color: const Color(0xFFFFD700), // Gold for all awards
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getAchievementLabel(achievement),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Weekly Consistency Map
class _ConsistencyMap extends StatelessWidget {
  final Map<int, double> dailyCompletions;
  final bool isDark;

  const _ConsistencyMap({
    required this.dailyCompletions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 = Mon, 7 = Sun

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // White layout for dark theme as requested
        color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Weekly Consistency',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  // Dark text on white background for dark theme
                  color: isDark ? Colors.black87 : Colors.black54,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.grid_view_rounded,
                size: 14,
                color: isDark ? Colors.black26 : Colors.black26,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final rate = dailyCompletions[weekday] ?? 0.0;
              final isToday = weekday == todayWeekday;

              // Color based on completion rate
              Color color;
              if (rate >= 1.0) {
                color = const Color(0xFF27AE60); // Green
              } else if (rate >= 0.5) {
                color = const Color(0xFFFFA94A); // Orange
              } else if (rate > 0) {
                color = const Color(0xFFE74C3C); // Red
              } else {
                // Empty cells - light gray on white background
                color = Colors.grey.withValues(alpha: 0.2);
              }

              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isToday ? 1.0 : 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: Colors.black, width: 1.5)
                          : null,
                    ),
                    child: rate > 0
                        ? Center(
                            child: rate >= 1.0
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : Text(
                                    '${(rate * 100).round()}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      // Dark text on white background for dark theme
                      color: isToday ? Colors.black : Colors.black54,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
