import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/health_challenge.dart';

class HealthChallengeDetailsScreen extends StatelessWidget {
  final HealthChallenge challenge;

  // Purple theme colors (matching Wind AI)
  static const _primaryPurple = Color(0xFF8B5CF6);
  static const _secondaryPink = Color(0xFFEC4899);

  const HealthChallengeDetailsScreen({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      body: CustomScrollView(
        slivers: [
          // Animated Header with purple gradient
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Purple Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                _primaryPurple.withValues(alpha: 0.25),
                                _secondaryPink.withValues(alpha: 0.1),
                                const Color(0xFF0D0D0D),
                              ]
                            : [
                                _primaryPurple.withValues(alpha: 0.15),
                                _secondaryPink.withValues(alpha: 0.08),
                                Colors.white,
                              ],
                      ),
                    ),
                  ),

                  // Animated Orb
                  Positioned(
                    top: 30,
                    right: -40,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: _primaryPurple.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                        duration: 4.seconds),
                  ),

                  // Second Orb
                  Positioned(
                    bottom: 60,
                    left: -30,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _secondaryPink.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wind AI Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryPurple, _secondaryPink],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'WIND AI PLAN',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideX(),
                        const SizedBox(height: 16),
                        Text(
                          challenge.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideX(),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primaryPurple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${challenge.durationWeeks} Weeks',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryPurple,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _secondaryPink.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatType(challenge.type),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _secondaryPink,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Body
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. My Goal Section
                _buildSectionHeader('MY GOAL', Icons.flag_rounded, isDark),
                const SizedBox(height: 12),
                _buildCard(
                  isDark: isDark,
                  child: Text(
                    challenge.description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 28),

                // 2. The Strategy
                _buildSectionHeader('AI STRATEGY', Icons.auto_awesome, isDark),
                const SizedBox(height: 12),
                _buildCard(
                  isDark: isDark,
                  child: Text(
                    challenge.aiInsight.isNotEmpty
                        ? challenge.aiInsight
                        : 'Wind AI has designed this plan to optimize your progress and build lasting habits.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 28),

                // 3. Daily Habits
                _buildSectionHeader(
                    'DAILY HABITS', Icons.check_circle_outline, isDark),
                const SizedBox(height: 12),
                if (challenge.recommendedHabits.isNotEmpty)
                  ...challenge.recommendedHabits.asMap().entries.map((entry) {
                    final index = entry.key;
                    final habit = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildHabitCard(habit, isDark)
                          .animate()
                          .fadeIn(delay: (300 + index * 100).ms)
                          .slideX(begin: 0.1),
                    );
                  })
                else
                  _buildCard(
                    isDark: isDark,
                    child: Text(
                      'No specific habits linked yet.',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),

                const SizedBox(height: 28),

                // 4. Progress
                _buildSectionHeader(
                    'PROGRESS', Icons.trending_up_rounded, isDark),
                const SizedBox(height: 12),
                _buildProgressCard(isDark),

                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primaryPurple.withValues(alpha: 0.15),
                _secondaryPink.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _primaryPurple),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _primaryPurple,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildHabitCard(dynamic habit, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryPurple.withValues(alpha: 0.15),
                  _secondaryPink.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(habit.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  habit.frequency,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(bool isDark) {
    final progressPercent = ((challenge.progressSnapshots?.length ?? 0) /
            (challenge.durationWeeks * 7))
        .clamp(0.0, 1.0);
    final currentWeek = ((challenge.progressSnapshots?.length ?? 0) / 7)
        .ceil()
        .clamp(1, challenge.durationWeeks);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  _primaryPurple.withValues(alpha: 0.15),
                  _secondaryPink.withValues(alpha: 0.1),
                ]
              : [
                  _primaryPurple.withValues(alpha: 0.08),
                  _secondaryPink.withValues(alpha: 0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progressPercent,
                    strokeWidth: 10,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(
                      _primaryPurple,
                    ),
                  ),
                ),
                Text(
                  '${(progressPercent * 100).round()}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Week $currentWeek of ${challenge.durationWeeks}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep going! You\'re making progress.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  String _formatType(ChallengeType type) {
    switch (type) {
      case ChallengeType.weightManagement:
        return 'Weight Mgmt';
      case ChallengeType.heartHealth:
        return 'Heart Health';
      case ChallengeType.nutritionWellness:
        return 'Nutrition';
      case ChallengeType.activityStrength:
        return 'Strength';
    }
  }
}
