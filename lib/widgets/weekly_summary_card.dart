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
              ? const Color(0xFFFFA94A).withOpacity(0.4)
              : (isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08)),
          width: isCurrentWeek ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
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
                // Header
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
                          color: const Color(0xFFFFA94A).withOpacity(0.2),
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
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.4),
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
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
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

                // Percentage
                Text(
                  '${report.completionPercentage}% Complete',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

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
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
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
                ? Colors.white.withOpacity(0.6)
                : Colors.black.withOpacity(0.5),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
