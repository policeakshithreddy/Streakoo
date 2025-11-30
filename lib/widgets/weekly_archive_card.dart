import 'package:flutter/material.dart';
import '../models/weekly_report.dart';

class WeeklyArchiveCard extends StatefulWidget {
  final List<WeeklyReport> reports;
  final Function(WeeklyReport) onReportTap;

  const WeeklyArchiveCard({
    super.key,
    required this.reports,
    required this.onReportTap,
  });

  @override
  State<WeeklyArchiveCard> createState() => _WeeklyArchiveCardState();
}

class _WeeklyArchiveCardState extends State<WeeklyArchiveCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // If no reports, don't show anything (or show empty state if desired)
    if (widget.reports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.grey[800] : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Archive',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.reports.length} past reports',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),

          // Expanded List
          if (_isExpanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: widget.reports.length,
              separatorBuilder: (context, index) => Divider(
                height: 24,
                color: theme.dividerColor.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final report = widget.reports[index];
                return InkWell(
                  onTap: () => widget.onReportTap(report),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Date Range
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateRange(
                                    report.weekStart, report.weekEnd),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildStatBadge(
                                    context,
                                    '${(report.completionRate * 100).round()}%',
                                    Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  if (report.topHabits.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        '🏆 ${report.topHabits.first}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(BuildContext context, String text, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    return '${_monthName(start.month)} ${start.day} - ${_monthName(end.month)} ${end.day}';
  }

  String _monthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}
