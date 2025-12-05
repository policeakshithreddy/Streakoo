import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'auth_screen.dart';
import '../widgets/modern_ui.dart'
    hide slideFromRight, slideFromBottom, fadeTransition;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  void _start() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFFF8F9FA),
                    const Color(0xFFE9ECEF),
                    const Color(0xFFDEE2E6),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Animated Logo/Icon Area
                _buildAnimatedLogo(isDark)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                        duration: 800.ms),

                const SizedBox(height: 40),

                // Main Title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF58CC02),
                      Color(0xFF2ECC71),
                      Color(0xFF27AE60)
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Streakoo',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  'Build habits that stick 🔥',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 60),

                // Feature highlights
                _buildFeatureCard(
                  icon: Icons.track_changes,
                  title: 'Track Daily Habits',
                  subtitle: 'Build streaks and stay consistent',
                  delay: 500,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.favorite,
                  title: 'Health Integration',
                  subtitle: 'Auto-complete with Apple Health data',
                  delay: 600,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.smart_toy,
                  title: 'AI Coach',
                  subtitle: 'Personalized tips and motivation',
                  delay: 700,
                  isDark: isDark,
                ),

                const Spacer(flex: 2),

                // CTA Button
                BouncyButton(
                  onTap: _start,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF58CC02), Color(0xFF2ECC71)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF58CC02).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 500.ms)
                    .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic)
                    .then()
                    .shimmer(delay: 500.ms, duration: 1500.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(bool isDark) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF58CC02), Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58CC02).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Flame icon
          const Text(
            '🔥',
            style: TextStyle(fontSize: 60),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),
          // Subtle pulse ring
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.2, 1.2),
                duration: 2000.ms,
              )
              .fadeOut(duration: 2000.ms),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int delay,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF58CC02),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
