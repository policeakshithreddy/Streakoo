import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

import '../models/level_reward.dart';
import '../models/user_level.dart';

/// Full-screen level-up reward modal (Duolingo-style)
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
  late ConfettiController _confettiController;
  bool _showRewards = false;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Sequence animations
    Future.delayed(const Duration(milliseconds: 500), () {
      _confettiController.play();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showRewards = true);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.2,
              colors: const [
                Color(0xFFFFD700),
                Color(0xFFFFA500),
                Color(0xFFFF6B6B),
                Color(0xFF4ECDC4),
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Level up badge
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFA500),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
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
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Level up text
                const Text(
                  'LEVEL UP!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),

                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 40),

                // Rewards section
                if (_showRewards && widget.rewards.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Rewards Earned',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...widget.rewards.map((reward) => _RewardItem(
                              reward: reward,
                            )),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2, end: 0)
                else if (_showRewards)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Keep building your streak for rewards!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),

                const Spacer(),

                // Collect button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF58CC02),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'COLLECT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1500.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final LevelReward reward;

  const _RewardItem({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reward.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reward.color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: reward.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              reward.icon,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reward.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Badge or quantity
          if (reward.quantity != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: reward.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'x${reward.quantity}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0);
  }
}
