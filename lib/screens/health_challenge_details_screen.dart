import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/health_challenge.dart';
import '../widgets/glass_card.dart';

class HealthChallengeDetailsScreen extends StatelessWidget {
  final HealthChallenge challenge;

  const HealthChallengeDetailsScreen({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Animated Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                          theme.colorScheme.secondary.withValues(alpha: 0.1),
                          theme.scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),

                  // Animated Particles/Orbs (Simple CSS-like effects)
                  Positioned(
                    top: 50,
                    right: -30,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                        duration: 4.seconds),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'AI PERSONALIZED PLAN',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideX(),
                        const SizedBox(height: 12),
                        Text(
                          challenge.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideX(),
                        const SizedBox(height: 8),
                        Text(
                          '${challenge.durationWeeks} Week Program • Type: ${_formatType(challenge.type)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
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
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. My Goal Section
                _buildSectionHeader(theme, 'MY GOAL', Icons.flag_outlined),
                const SizedBox(height: 12),
                GlassCard(
                  opacity: 0.05,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.description,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 32),

                // 2. The Strategy
                _buildSectionHeader(
                    theme, 'THE STRATEGY', Icons.lightbulb_outline),
                const SizedBox(height: 12),
                GlassCard(
                  opacity: 0.05,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.aiInsight.isNotEmpty
                            ? challenge.aiInsight
                            : 'Your AI coach has designed this plan to restart your metabolism and build consistency.',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                // 3. Daily Habits
                _buildSectionHeader(
                    theme, 'DAILY HABITS', Icons.check_circle_outline),
                const SizedBox(height: 12),
                if (challenge.recommendedHabits.isNotEmpty)
                  ...challenge.recommendedHabits.map((habit) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GlassCard(
                          opacity: 0.03,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(habit.emoji,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                            title: Text(habit.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(habit.frequency),
                          ),
                        ),
                      ))
                else
                  const Text('No specific habits linked.'),

                const SizedBox(height: 32),

                // 4. Progress
                _buildSectionHeader(theme, 'PROGRESS', Icons.timeline),
                const SizedBox(height: 12),
                GlassCard(
                  opacity: 0.05,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        value: ((challenge.progressSnapshots?.length ?? 0) /
                                (challenge.durationWeeks * 7))
                            .clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor:
                            theme.colorScheme.surface.withValues(alpha: 0.2),
                        valueColor:
                            AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Week 1 of ${challenge.durationWeeks}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
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
