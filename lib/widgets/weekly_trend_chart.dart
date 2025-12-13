import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Widget to display weekly health score trend
class WeeklyTrendChart extends StatefulWidget {
  final List<double> weeklyScores;
  final bool isDark;

  const WeeklyTrendChart({
    super.key,
    required this.weeklyScores,
    required this.isDark,
  });

  @override
  State<WeeklyTrendChart> createState() => _WeeklyTrendChartState();
}

class _WeeklyTrendChartState extends State<WeeklyTrendChart> {
  static const _primaryPurple = Color(0xFF8B5CF6);
  static const _secondaryPink = Color(0xFFEC4899);

  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.weeklyScores.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate max score for scaling
    final maxScore = widget.weeklyScores.reduce((a, b) => a > b ? a : b);
    final minScore = widget.weeklyScores.reduce((a, b) => a < b ? a : b);
    final range = maxScore - minScore;

    // Day labels
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDark
              ? [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[200]!,
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
                  gradient: const LinearGradient(
                    colors: [_primaryPurple, _secondaryPink],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '7-Day Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (_selectedIndex != null)
                Text(
                  'Tap bars to see scores',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                widget.weeklyScores.length > 7 ? 7 : widget.weeklyScores.length,
                (index) {
                  final score = widget.weeklyScores[index];
                  final normalizedHeight = range > 0
                      ? ((score - minScore) / range * 100 + 20)
                      : 50.0;

                  final isToday = index == widget.weeklyScores.length - 1;
                  final isSelected = _selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex =
                              _selectedIndex == index ? null : index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Score value on selection or for today
                            if (isToday || isSelected)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  score.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: isSelected ? 14 : 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? _secondaryPink
                                        : _primaryPurple,
                                  ),
                                ),
                              ),
                            if (isToday || isSelected)
                              const SizedBox(height: 4),

                            // Bar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: normalizedHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: (isToday || isSelected)
                                      ? [_primaryPurple, _secondaryPink]
                                      : [
                                          _primaryPurple.withValues(alpha: 0.3),
                                          _primaryPurple.withValues(alpha: 0.5),
                                        ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _primaryPurple.withValues(
                                              alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                            )
                                .animate()
                                .scaleY(
                                  begin: 0,
                                  end: 1,
                                  duration: 600.ms,
                                  delay: (index * 80).ms,
                                  curve: Curves.easeOutBack,
                                )
                                .fadeIn(delay: (index * 80).ms),

                            const SizedBox(height: 8),

                            // Day label
                            Text(
                              days[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: (isToday || isSelected)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _secondaryPink
                                    : (isToday
                                        ? _primaryPurple
                                        : (widget.isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600])),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Trend indicator
          _buildTrendIndicator(widget.isDark),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTrendIndicator(bool isDark) {
    if (widget.weeklyScores.length < 2) {
      return const SizedBox.shrink();
    }

    // Compare recent vs previous
    final recent = widget.weeklyScores.sublist(
      widget.weeklyScores.length - 3 > 0 ? widget.weeklyScores.length - 3 : 0,
    );
    final previous = widget.weeklyScores.sublist(
      0,
      widget.weeklyScores.length - 3 > 0 ? widget.weeklyScores.length - 3 : 1,
    );

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
    final change = ((recentAvg - previousAvg) / previousAvg * 100);

    final isImproving = change >= 1;
    final isStable = change > -1 && change < 1;

    IconData icon;
    Color color;
    String text;

    if (isImproving) {
      icon = Icons.trending_up_rounded;
      color = const Color(0xFF4CAF50);
      text = 'Improving +${change.toStringAsFixed(1)}%';
    } else if (isStable) {
      icon = Icons.trending_flat_rounded;
      color = const Color(0xFFFFA726);
      text = 'Stable';
    } else {
      icon = Icons.trending_down_rounded;
      color = const Color(0xFFEF5350);
      text = 'Declining ${change.toStringAsFixed(1)}%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
