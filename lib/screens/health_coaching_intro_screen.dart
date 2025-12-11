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
                          _primaryPurple.withValues(alpha: 0.15),
                          const Color(0xFF0D0D0D),
                        ]
                      : [
                          _primaryPurple.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                ),
              ),
            ),
          ),

          // Decorative circles
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
                    _primaryPurple.withValues(alpha: 0.2),
                    _primaryPurple.withValues(alpha: 0),
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

                        // Hero Icon with gradient
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryPurple, _secondaryPink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryPurple.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 48,
                            color: Colors.white,
                          ),
                        )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 28),

                        // Title
                        Text(
                          'Health Coaching',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -1,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Your AI-powered wellness journey',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 100.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 36),

                        // Steps Section Title
                        Row(
                          children: [
                            Text(
                              'How it works',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 150.ms),

                        const SizedBox(height: 16),

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
                              'Wind creates a custom 4-week plan tailored to your data.',
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
                              'Get daily tips, track progress, and celebrate milestones.',
                          delay: 500,
                          isDark: isDark,
                          isLast: true,
                        ),

                        const SizedBox(height: 24),

                        // Privacy Note
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                  color: _primaryPurple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your data stays private and is only used for your personal coaching.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
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
                    color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[200]!,
                      ),
                    ),
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
                            minimumSize: const Size(double.infinity, 52),
                            foregroundColor: _primaryPurple,
                            side: const BorderSide(color: _primaryPurple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryPurple, _secondaryPink],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryPurple.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
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
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20),
                            ],
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
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey[200]!,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Number Badge
            Container(
              width: 44,
              height: 44,
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
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: _primaryPurple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }
}
