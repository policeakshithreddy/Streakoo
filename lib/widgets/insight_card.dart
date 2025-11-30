import 'package:flutter/material.dart';

import '../models/ai_insight.dart';

class InsightCard extends StatelessWidget {
  final AIInsight insight;
  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  insight.gradientColors[0].withOpacity(0.15),
                  insight.gradientColors[1].withOpacity(0.1)
                ]
              : [
                  insight.gradientColors[0].withOpacity(0.1),
                  insight.gradientColors[1].withOpacity(0.05)
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: insight.gradientColors[0].withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: insight.gradientColors[0].withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: insight.gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: insight.gradientColors[0].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        insight.icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Description
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.75),
                  ),
                ),

                // Action button
                if (insight.actionText != null) ...[
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: insight.gradientColors[0].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: insight.gradientColors[0].withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            insight.actionText!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: insight.gradientColors[0],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: insight.gradientColors[0],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Confidence indicator (subtle)
                if (insight.confidence < 0.8) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.4)
                            : Colors.black.withOpacity(0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Confidence: ${(insight.confidence * 100).round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withOpacity(0.4)
                              : Colors.black.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
