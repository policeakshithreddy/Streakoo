import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Interactive tappable insight card with detail expansion
class InteractiveInsightCard extends StatefulWidget {
  final String title;
  final String summary;
  final String detailedExplanation;
  final IconData icon;
  final Color color;
  final List<String>? actionItems;
  final bool isDark;

  const InteractiveInsightCard({
    super.key,
    required this.title,
    required this.summary,
    required this.detailedExplanation,
    required this.icon,
    required this.color,
    this.actionItems,
    required this.isDark,
  });

  @override
  State<InteractiveInsightCard> createState() => _InteractiveInsightCardState();
}

class _InteractiveInsightCardState extends State<InteractiveInsightCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.color.withValues(alpha: widget.isDark ? 0.2 : 0.1),
              widget.color.withValues(alpha: widget.isDark ? 0.1 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.4),
            width: _isExpanded ? 2 : 1,
          ),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
              : [],
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
                    color: widget.color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.summary,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.expand_more,
                    color: widget.color,
                  ),
                ),
              ],
            ),

            // Expanded content
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.detailedExplanation,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            widget.isDark ? Colors.grey[300] : Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                    if (widget.actionItems != null &&
                        widget.actionItems!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'What you can do:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.actionItems!.map((action) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: widget.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    action,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: widget.isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(
                    begin: -0.1,
                    end: 0,
                  ),
            ],
          ],
        ),
      ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),
    );
  }
}

/// Predictive insight card showing future predictions
class PredictiveInsightCard extends StatelessWidget {
  final double predictedScore;
  final String trend;
  final String confidence;
  final String message;
  final bool isDark;

  const PredictiveInsightCard({
    super.key,
    required this.predictedScore,
    required this.trend,
    required this.confidence,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color trendColor;
    final IconData trendIcon;

    switch (trend) {
      case 'improving':
        trendColor = const Color(0xFF4CAF50);
        trendIcon = Icons.trending_up_rounded;
        break;
      case 'declining':
        trendColor = const Color(0xFFEF5350);
        trendIcon = Icons.trending_down_rounded;
        break;
      default:
        trendColor = const Color(0xFFFFA726);
        trendIcon = Icons.trending_flat_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            trendColor.withValues(alpha: isDark ? 0.2 : 0.1),
            trendColor.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: trendColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: trendColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: trendColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(trendIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Week Prediction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '$confidence confidence',
                      style: TextStyle(
                        fontSize: 13,
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Predicted score
          Row(
            children: [
              Text(
                'Predicted Score:',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                predictedScore.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: trendColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
        );
  }
}
