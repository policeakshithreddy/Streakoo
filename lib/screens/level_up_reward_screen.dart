import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/level_reward.dart';
import '../models/user_level.dart';

/// Modern, sleek level-up celebration screen
/// Inspired by gaming apps with smooth, premium animations
class LevelUpRewardScreen extends StatefulWidget {
  final int newLevel;
  final String title;
  final UserLevel userLevel;
  final List<LevelReward> rewards;

  const LevelUpRewardScreen({
    super.key,
    required this.newLevel,
    required this.title,
    required this.userLevel,
    required this.rewards,
  });

  @override
  State<LevelUpRewardScreen> createState() => _LevelUpRewardScreenState();
}

class _LevelUpRewardScreenState extends State<LevelUpRewardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  bool _showContent = false;

  // App theme colors
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryTeal = Color(0xFF1FD1A5);

  @override
  void initState() {
    super.initState();

    // Haptic feedback on open
    HapticFeedback.heavyImpact();

    // Pulse animation for the badge glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Slow rotation for background elements
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Delayed content reveal
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(isDark),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 28,
                      ),
                    ),
                  ),
                ).animate(delay: 800.ms).fadeIn(duration: 400.ms),

                const Spacer(flex: 2),

                if (_showContent) ...[
                  // Animated level badge
                  _buildLevelBadge(),

                  const SizedBox(height: 32),

                  // "LEVEL UP" text with gradient
                  _buildLevelUpText(),

                  const SizedBox(height: 12),

                  // Title/Rank
                  _buildTitleText(),

                  const SizedBox(height: 40),

                  // Rewards section
                  if (widget.rewards.isNotEmpty) _buildRewardsSection(isDark),
                ],

                const Spacer(flex: 3),

                // Continue button with gradient
                _buildContinueButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                _primaryOrange.withValues(alpha: 0.15),
                isDark ? const Color(0xFF0A0A0A) : const Color(0xFF1A1A1A),
                isDark ? Colors.black : const Color(0xFF0D0D0D),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Rotating glow orbs
              Positioned(
                top: -100,
                left: -100,
                child: Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _primaryOrange.withValues(alpha: 0.3),
                          _primaryOrange.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                right: -100,
                child: Transform.rotate(
                  angle: -_rotateController.value * 2 * math.pi,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _secondaryTeal.withValues(alpha: 0.2),
                          _secondaryTeal.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelBadge() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = 1.0 + (_pulseController.value * 0.08);
        return Transform.scale(
          scale: pulseValue,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFB347),
                  _primaryOrange,
                  Color(0xFFFF8C00),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryOrange.withValues(
                      alpha: 0.5 + (_pulseController.value * 0.3)),
                  blurRadius: 40 + (_pulseController.value * 20),
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: _primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.newLevel}',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'LEVEL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    )
        .animate()
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 300.ms);
  }

  Widget _buildLevelUpText() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [_primaryOrange, Color(0xFFFFD700), _primaryOrange],
      ).createShader(bounds),
      child: const Text(
        'LEVEL UP!',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 4,
        ),
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack)
        .shimmer(
          delay: 600.ms,
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.3),
        );
  }

  Widget _buildTitleText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryOrange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    )
        .animate(delay: 350.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildRewardsSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard_rounded,
                color: _primaryOrange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'REWARDS UNLOCKED',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white60,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.rewards.asMap().entries.map((entry) {
            final index = entry.key;
            final reward = entry.value;
            return _ModernRewardItem(
              reward: reward,
              delay: Duration(milliseconds: 500 + (index * 120)),
            );
          }),
        ],
      ),
    )
        .animate(delay: 450.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15, end: 0);
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryOrange, Color(0xFFFF8C00)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _primaryOrange.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(18),
              child: const Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: 700.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, end: 0);
  }
}

/// Modern reward item with sleek styling
class _ModernRewardItem extends StatelessWidget {
  final LevelReward reward;
  final Duration delay;

  const _ModernRewardItem({
    required this.reward,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: reward.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reward.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Gradient icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  reward.color,
                  reward.color.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: reward.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              reward.icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reward.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (reward.quantity != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: reward.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${reward.quantity}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.15, end: 0, curve: Curves.easeOutCubic);
  }
}
