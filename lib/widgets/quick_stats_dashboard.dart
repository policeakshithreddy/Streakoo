import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/gradients.dart';
import '../widgets/animated_progress_ring.dart';

/// Quick stats dashboard for home screen
class QuickStatsDashboard extends StatelessWidget {
  final int completedToday;
  final int totalHabits;
  final int currentStreak;
  final int totalXP;
  final int todayXP;
  final bool isDark;

  const QuickStatsDashboard({
    super.key,
    required this.completedToday,
    required this.totalHabits,
    required this.currentStreak,
    required this.totalXP,
    this.todayXP = 0,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final completionRate = totalHabits > 0 ? completedToday / totalHabits : 0.0;

    return Container(
      margin: const EdgeInsets.all(DesignTokens.space4),
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.cardDark : AppGradients.cardLight,
        borderRadius: DesignTokens.borderRadiusLG,
        boxShadow: DesignTokens.shadowMD(Colors.black),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Today\'s Overview',
                style: TextStyle(
                  fontSize: DesignTokens.fontSize2XL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (completionRate == 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space3,
                    vertical: DesignTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppGradients.success,
                    borderRadius: DesignTokens.borderRadiusMD,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎉', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text(
                        'All Done!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: DesignTokens.space4),

          // Stats grid
          Row(
            children: [
              // Completion rate ring
              Expanded(
                flex: 2,
                child: _buildMainProgress(completionRate),
              ),

              const SizedBox(width: DesignTokens.space4),

              // Stats column
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: '🔥',
                            label: 'Streak',
                            value: '$currentStreak',
                            subtitle: 'days',
                            gradient: AppGradients.fire,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.space2),
                        Expanded(
                          child: _buildStatCard(
                            icon: '⭐',
                            label: 'Total XP',
                            value: _formatNumber(totalXP),
                            subtitle: todayXP > 0 ? '+$todayXP today' : '',
                            gradient: AppGradients.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    _buildProgressBar(completionRate),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainProgress(double progress) {
    return Column(
      children: [
        AnimatedProgressRing(
          progress: progress,
          size: 100,
          strokeWidth: 10,
          gradient:
              progress == 1.0 ? AppGradients.success : AppGradients.primary,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completedToday',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'of $totalHabits',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String label,
    required String value,
    required String subtitle,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        gradient: gradient.withOpacity(0.1),
        borderRadius: DesignTokens.borderRadiusMD,
        border: Border.all(
          color: gradient.colors.first.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Progress',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: DesignTokens.borderRadiusSM,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0
                  ? const Color(0xFF27AE60)
                  : const Color(0xFFFFA94A),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

extension GradientOpacity on Gradient {
  Gradient withOpacity(double opacity) {
    if (this is LinearGradient) {
      final linear = this as LinearGradient;
      return LinearGradient(
        colors: linear.colors.map((c) => c.withValues(alpha: opacity)).toList(),
        begin: linear.begin,
        end: linear.end,
      );
    }
    return this;
  }
}
