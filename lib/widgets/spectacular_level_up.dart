import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../models/level_reward.dart';
import '../models/user_level.dart';

/// Spectacular Level Up Animation Screen with premium effects
class SpectacularLevelUpScreen extends StatefulWidget {
  final int newLevel;
  final String title;
  final UserLevel userLevel;
  final List<LevelReward> rewards;
  final VoidCallback? onComplete;

  const SpectacularLevelUpScreen({
    super.key,
    required this.newLevel,
    required this.title,
    required this.userLevel,
    required this.rewards,
    this.onComplete,
  });

  @override
  State<SpectacularLevelUpScreen> createState() =>
      _SpectacularLevelUpScreenState();
}

class _SpectacularLevelUpScreenState extends State<SpectacularLevelUpScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  bool _showBadge = false;
  bool _showTitle = false;
  bool _showRewards = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _startCelebration();
  }

  void _startCelebration() async {
    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Start confetti immediately
    _confettiController.play();

    // Show badge with delay
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _showBadge = true);
    HapticFeedback.mediumImpact();

    // Show title
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _showTitle = true);

    // Show rewards
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showRewards = true);

    // Show button
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _showButton = true);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),

          // Floating particles
          ...List.generate(20, (i) => _buildFloatingParticle(i, size)),

          // Confetti explosions from multiple points
          _buildConfettiLayers(),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spectacular badge with glow
                    if (_showBadge) _buildSpectacularBadge(theme),

                    const SizedBox(height: 32),

                    // Title with rainbow effect
                    if (_showTitle) _buildTitle(theme),

                    const SizedBox(height: 24),

                    // Rewards section
                    if (_showRewards && widget.rewards.isNotEmpty)
                      _buildRewardsSection(theme),

                    const SizedBox(height: 40),

                    // Continue button
                    if (_showButton) _buildContinueButton(theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2 + (_glowController.value * 0.3),
              colors: [
                const Color(0xFF1A1A2E),
                Colors.black.withValues(alpha: 0.95),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticle(int index, Size size) {
    final random = math.Random(index);
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + (index / 20)) % 1.0;
        final startX = random.nextDouble() * size.width;
        return Positioned(
          left: startX + math.sin(progress * math.pi * 2) * 30,
          top: size.height * (1 - progress),
          child: Container(
            width: 4 + random.nextDouble() * 4,
            height: 4 + random.nextDouble() * 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: [
                Colors.amber,
                Colors.orange,
                Colors.yellow,
                const Color(0xFF58CC02),
              ][index % 4]
                  .withValues(alpha: 0.6 * (1 - progress)),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfettiLayers() {
    return Stack(
      children: [
        // Top center burst
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.03,
            numberOfParticles: 30,
            gravity: 0.15,
            shouldLoop: true,
            colors: const [
              Color(0xFFFFD700), // Gold
              Color(0xFFFFA500), // Orange
              Color(0xFF58CC02), // Green
              Color(0xFF4A90E2), // Blue
              Color(0xFFFF6B6B), // Red
              Color(0xFFE040FB), // Purple
            ],
          ),
        ),
        // Left burst
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -math.pi / 4,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
            colors: const [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
        ),
        // Right burst
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -3 * math.pi / 4,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
            colors: const [Color(0xFF58CC02), Color(0xFF4A90E2)],
          ),
        ),
      ],
    );
  }

  Widget _buildSpectacularBadge(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_pulseController, _rotateController, _glowController]),
      builder: (context, child) {
        final pulseScale = 1.0 + (_pulseController.value * 0.08);
        final glowIntensity = 0.3 + (_glowController.value * 0.4);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating glow ring
            Transform.rotate(
              angle: _rotateController.value * 2 * math.pi,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0),
                      Colors.amber.withValues(alpha: glowIntensity),
                      Colors.orange.withValues(alpha: glowIntensity),
                      Colors.amber.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            // Inner glow
            Container(
              width: 180 * pulseScale,
              height: 180 * pulseScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: glowIntensity),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: glowIntensity * 0.5),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),

            // Badge background
            Transform.scale(
              scale: pulseScale,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                      Color(0xFFFF8C00),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '⭐',
                        style: TextStyle(fontSize: 50),
                      ),
                      Text(
                        '${widget.newLevel}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sparkle effects around badge
            ...List.generate(8, (i) {
              final angle =
                  (i / 8) * 2 * math.pi + _rotateController.value * math.pi;
              final radius =
                  90 + math.sin(_pulseController.value * math.pi) * 10;
              return Positioned(
                left: 100 + math.cos(angle) * radius - 8,
                top: 100 + math.sin(angle) * radius - 8,
                child: Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.white
                      .withValues(alpha: 0.6 + _glowController.value * 0.4),
                ),
              );
            }),
          ],
        );
      },
    )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 800.ms,
          curve: Curves.elasticOut,
        )
        .shimmer(duration: 2000.ms, delay: 500.ms);
  }

  Widget _buildTitle(ThemeData theme) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFFA500),
              Color(0xFFFF6B6B),
              Color(0xFFE040FB),
            ],
          ).createShader(bounds),
          child: const Text(
            'LEVEL UP!',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut)
            .shimmer(duration: 1500.ms, delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildRewardsSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🎁 Rewards Unlocked',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.rewards.asMap().entries.map((entry) {
            final index = entry.key;
            final reward = entry.value;
            return _buildRewardItem(reward, index)
                .animate(delay: Duration(milliseconds: 200 * index))
                .fadeIn()
                .slideX(begin: 0.2, end: 0);
          }),
        ],
      ),
    )
        .animate()
        .fadeIn()
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
  }

  Widget _buildRewardItem(LevelReward reward, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reward.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reward.color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: reward.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                reward.icon,
                color: reward.color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  reward.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: reward.color,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(ThemeData theme) {
    return FilledButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onComplete?.call();
        Navigator.of(context).pop();
      },
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF58CC02),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
        shadowColor: const Color(0xFF58CC02).withValues(alpha: 0.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Continue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded),
        ],
      ),
    )
        .animate()
        .fadeIn()
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut)
        .shimmer(duration: 2000.ms, delay: 500.ms);
  }
}
