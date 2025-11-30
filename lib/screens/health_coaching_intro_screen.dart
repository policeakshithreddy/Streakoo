import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/health_service.dart';
import 'health_challenge_intake_screen.dart';

class HealthCoachingIntroScreen extends StatefulWidget {
  const HealthCoachingIntroScreen({super.key});

  @override
  State<HealthCoachingIntroScreen> createState() =>
      _HealthCoachingIntroScreenState();
}

class _HealthCoachingIntroScreenState extends State<HealthCoachingIntroScreen> {
  bool _hasHealthAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkHealthAccess();
  }

  Future<void> _checkHealthAccess() async {
    final hasAccess = await HealthService.instance.hasHealthDataAccess();
    if (mounted) {
      setState(() {
        _hasHealthAccess = hasAccess;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestAccess() async {
    final success = await HealthService.instance.requestPermissions();
    if (mounted) {
      setState(() {
        _hasHealthAccess = success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Hero Icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.health_and_safety,
                              size: 64,
                              color: theme.colorScheme.primary,
                            ),
                          ).animate().scale(
                              duration: 600.ms, curve: Curves.easeOutBack),
                        ),
                        const SizedBox(height: 40),

                        // Title & Pitch
                        Text(
                          'Unlock Your\nHealth Potential',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 16),
                        Text(
                          'Choose a personalized health challenge to get AI-driven coaching, daily tips, and smart habit tracking.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 48),

                        // Features List
                        _buildFeatureItem(
                          context,
                          icon: Icons.track_changes,
                          title: 'Focused Challenges',
                          description:
                              'Target specific goals like Weight Loss, Heart Health, or Better Sleep.',
                          delay: 300,
                        ),
                        _buildFeatureItem(
                          context,
                          icon: Icons.auto_awesome,
                          title: 'AI Coaching',
                          description:
                              'Get a personalized 4-week plan and daily insights based on your data.',
                          delay: 400,
                        ),
                        _buildFeatureItem(
                          context,
                          icon: Icons.insights,
                          title: 'Smart Feedback',
                          description:
                              'Visualize your progress with charts tailored to your specific goal.',
                          delay: 500,
                        ),

                        const SizedBox(height: 40),

                        // Privacy Note
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.privacy_tip_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your health data stays private and is only used to generate your personal plan.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Area
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_hasHealthAccess && !_isLoading) ...[
                        OutlinedButton.icon(
                          onPressed: _requestAccess,
                          icon: const Icon(Icons.sync),
                          label: const Text('Connect Health Data'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const HealthChallengeIntakeScreen(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: const Text(
                          'Choose a Challenge',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0);
  }
}
