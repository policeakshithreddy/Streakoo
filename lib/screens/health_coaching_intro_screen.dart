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

  // Purple theme colors
  static const _primaryPurple = Color(0xFF8B5CF6);
  static const _secondaryPink = Color(0xFFEC4899);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      body: Stack(
        children: [
          // Background Gradient with purple tint
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          _primaryPurple.withValues(alpha: 0.2),
                          const Color(0xFF0D0D0D),
                        ]
                      : [
                          _primaryPurple.withValues(alpha: 0.1),
                          Colors.white,
                        ],
                ),
              ),
            ),
          ),

          // Animated decorative circles
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primaryPurple.withValues(alpha: 0.3),
                    _primaryPurple.withValues(alpha: 0),
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: 3000.ms,
                  color: _primaryPurple.withValues(alpha: 0.1),
                ),
          ),

          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _secondaryPink.withValues(alpha: 0.2),
                    _secondaryPink.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryPurple, _secondaryPink],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Wind AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        // Hero Icon with gradient and pulse animation
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryPurple, _secondaryPink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryPurple.withValues(alpha: 0.5),
                                blurRadius: 32,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 56,
                            color: Colors.white,
                          ),
                        )
                            .animate(
                                onPlay: (controller) => controller.repeat())
                            .shimmer(
                              duration: 2000.ms,
                              color: Colors.white.withValues(alpha: 0.3),
                            )
                            .scale(
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),

                        const SizedBox(height: 32),

                        // Title with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_primaryPurple, _secondaryPink],
                          ).createShader(bounds),
                          child: Text(
                            'AI Health Coaching',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 12),

                        // Subtitle with emphasis
                        Text(
                          'Your personalized wellness journey\npowered by advanced AI',
                          style: TextStyle(
                            fontSize: 17,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 100.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 36),

                        // Success Metrics Section
                        _buildSuccessMetrics(isDark),

                        const SizedBox(height: 32),

                        // What You'll Get Section
                        _buildBenefitsSection(isDark),

                        const SizedBox(height: 32),

                        // How it works
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryPurple, _secondaryPink],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'How it works',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 150.ms),

                        const SizedBox(height: 20),

                        // Step 1
                        _buildStepCard(
                          context,
                          stepNumber: 1,
                          icon: Icons.flag_rounded,
                          title: 'Choose Your Goal',
                          description:
                              'Select a health challenge like Weight Loss, Better Sleep, or Heart Health.',
                          delay: 200,
                          isDark: isDark,
                        ),

                        // Step 2
                        _buildStepCard(
                          context,
                          stepNumber: 2,
                          icon: Icons.sync_rounded,
                          title: 'Connect Health Data',
                          description:
                              'Link Apple Health or Google Fit for personalized insights.',
                          delay: 300,
                          isDark: isDark,
                        ),

                        // Step 3
                        _buildStepCard(
                          context,
                          stepNumber: 3,
                          icon: Icons.auto_awesome,
                          title: 'Get AI-Powered Plan',
                          description:
                              'Wind analyzes 1000+ data points to create your custom 4-week plan.',
                          delay: 400,
                          isDark: isDark,
                        ),

                        // Step 4
                        _buildStepCard(
                          context,
                          stepNumber: 4,
                          icon: Icons.trending_up_rounded,
                          title: 'Track & Improve',
                          description:
                              'Get daily AI insights, track progress, and celebrate milestones.',
                          delay: 500,
                          isDark: isDark,
                          isLast: true,
                        ),

                        const SizedBox(height: 32),

                        // Enhanced Privacy Note
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      _primaryPurple.withValues(alpha: 0.1),
                                      _secondaryPink.withValues(alpha: 0.05),
                                    ]
                                  : [
                                      _primaryPurple.withValues(alpha: 0.05),
                                      _secondaryPink.withValues(alpha: 0.03),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _primaryPurple.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _primaryPurple.withValues(alpha: 0.2),
                                      _secondaryPink.withValues(alpha: 0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  size: 24,
                                  color: _primaryPurple,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Privacy Protected',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your data stays private and is only used for your personal coaching.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 600.ms).scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                            ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Enhanced Bottom Action Area
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[200]!,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_hasHealthAccess && !_isLoading) ...[
                        OutlinedButton.icon(
                          onPressed: _requestAccess,
                          icon: const Icon(Icons.sync, size: 20),
                          label: const Text('Connect Health Data'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            foregroundColor: _primaryPurple,
                            side: const BorderSide(
                              color: _primaryPurple,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryPurple, _secondaryPink],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryPurple.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const HealthChallengeIntakeScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start Your Journey',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: 2500.ms,
                            color: Colors.white.withValues(alpha: 0.2),
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

  Widget _buildSuccessMetrics(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [
                  _primaryPurple.withValues(alpha: 0.05),
                  _secondaryPink.withValues(alpha: 0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : _primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            '🎯 Success Stories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem('92%', 'Goal\nAchieved', isDark),
              Container(
                width: 1,
                height: 40,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[300],
              ),
              _buildMetricItem('4.8★', 'User\nRating', isDark),
              Container(
                width: 1,
                height: 40,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[300],
              ),
              _buildMetricItem('10k+', 'Active\nUsers', isDark),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMetricItem(String value, String label, bool isDark) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_primaryPurple, _secondaryPink],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPurple, _secondaryPink],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'What You\'ll Get',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildBenefitItem(
          icon: Icons.psychology_outlined,
          title: 'Personalized AI Coaching',
          description: 'Plans adapted to YOUR unique body and lifestyle',
          delay: 300,
          isDark: isDark,
        ),
        _buildBenefitItem(
          icon: Icons.insights_outlined,
          title: 'Smart Health Insights',
          description: 'Discover patterns and get actionable recommendations',
          delay: 350,
          isDark: isDark,
        ),
        _buildBenefitItem(
          icon: Icons.show_chart_outlined,
          title: 'Progress Analytics',
          description: 'Beautiful visualizations of your wellness journey',
          delay: 400,
          isDark: isDark,
        ),
        _buildBenefitItem(
          icon: Icons.calendar_today_outlined,
          title: 'Weekly AI Reports',
          description: 'Comprehensive summaries with expert guidance',
          delay: 450,
          isDark: isDark,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
    required bool isDark,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _primaryPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildStepCard(
    BuildContext context, {
    required int stepNumber,
    required IconData icon,
    required String title,
    required String description,
    required int delay,
    required bool isDark,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: _primaryPurple.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Number Badge with gradient
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPurple, _secondaryPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: _primaryPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.15, end: 0);
  }
}
