import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';

import '../models/celebration_config.dart';

class CelebrationOverlay extends StatefulWidget {
  final CelebrationConfig config;
  final VoidCallback? onComplete;

  const CelebrationOverlay({
    super.key,
    required this.config,
    this.onComplete,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;

  late ConfettiController _confettiController;
  late ConfettiController _confettiController2;
  late ConfettiController _confettiController3;

  bool _showFireworks = false;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();

    // Shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Confetti controllers
    _confettiController = ConfettiController(
      duration: widget.config.duration,
    );
    _confettiController2 = ConfettiController(
      duration: widget.config.duration,
    );
    _confettiController3 = ConfettiController(
      duration: widget.config.duration,
    );

    _startCelebration();
  }

  void _startCelebration() async {
    // Start fade in
    _fadeController.forward();

    // Vibration for major celebrations
    if (widget.config.trigger == CelebrationTrigger.allHabitsCompleted ||
        widget.config.trigger == CelebrationTrigger.levelUp) {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 200, amplitude: 128);
      }
    }

    // Stage 1: Shake (if major celebration)
    if (widget.config.trigger == CelebrationTrigger.allHabitsCompleted ||
        widget.config.trigger == CelebrationTrigger.levelUp) {
      await Future.delayed(const Duration(milliseconds: 100));
      _shakeController.forward();
    }

    // Stage 2: Confetti
    if (widget.config.showConfetti) {
      await Future.delayed(const Duration(milliseconds: 300));
      _confettiController.play();
      _confettiController2.play();
      _confettiController3.play();
    }

    // Stage 3: Fireworks
    if (widget.config.showFireworks) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _showFireworks = true);
      }
    }

    // Stage 4: Banner
    if (widget.config.showBanner) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _showBanner = true);
      }
    }

    // Auto-dismiss after duration
    await Future.delayed(widget.config.duration);
    if (mounted) {
      _fadeController.reverse().then((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    _confettiController2.dispose();
    _confettiController3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAllHabits =
        widget.config.trigger == CelebrationTrigger.allHabitsCompleted;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              sin(_shakeAnimation.value) * 5,
              cos(_shakeAnimation.value) * 5,
            ),
            child: child,
          );
        },
        child: Container(
          color: Colors.black.withValues(alpha: isAllHabits ? 0.85 : 0.6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Confetti from top-left
              if (widget.config.showConfetti)
                Align(
                  alignment: Alignment.topLeft,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 4, // 45 degrees
                    emissionFrequency: isAllHabits ? 0.12 : 0.08,
                    numberOfParticles: isAllHabits ? 80 : 40,
                    gravity: 0.2,
                    colors: const [
                      Color(0xFFFF6B6B),
                      Color(0xFF4ECDC4),
                      Color(0xFFFFE66D),
                      Color(0xFF95E1D3),
                      Color(0xFFF38181),
                      Color(0xFFA8E6CF),
                      Color(0xFFDCEDC1),
                    ],
                  ),
                ),

              // Confetti from top-right
              if (widget.config.showConfetti)
                Align(
                  alignment: Alignment.topRight,
                  child: ConfettiWidget(
                    confettiController: _confettiController2,
                    blastDirection: 3 * pi / 4, // 135 degrees
                    emissionFrequency: isAllHabits ? 0.12 : 0.08,
                    numberOfParticles: isAllHabits ? 80 : 40,
                    gravity: 0.2,
                    colors: const [
                      Color(0xFFFF6B6B),
                      Color(0xFF4ECDC4),
                      Color(0xFFFFE66D),
                      Color(0xFF95E1D3),
                      Color(0xFFF38181),
                      Color(0xFFA8E6CF),
                      Color(0xFFDCEDC1),
                    ],
                  ),
                ),

              // Explosive Center Confetti for All Habits
              if (isAllHabits)
                Align(
                  alignment: Alignment.center,
                  child: ConfettiWidget(
                    confettiController: _confettiController3,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.04,
                    numberOfParticles: 70,
                    gravity: 0.1,
                    colors: const [
                      Colors.white,
                      Colors.amber,
                      Colors.orange,
                      Colors.pink,
                      Color(0xFFFFD700), // Gold
                      Color(0xFFFF69B4), // Hot pink
                    ],
                  ),
                ),

              // Additional bottom-up confetti burst for all habits
              if (isAllHabits)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController3,
                    blastDirection: -pi / 2, // Straight up
                    emissionFrequency: 0.08,
                    numberOfParticles: 60,
                    gravity: 0.15,
                    colors: const [
                      Color(0xFFFFA94A),
                      Color(0xFFFF6B6B),
                      Color(0xFFFFE66D),
                      Color(0xFF4ECDC4),
                    ],
                  ),
                ),

              // Fireworks - Multiple positions for fuller effect
              if (_showFireworks)
                Positioned(
                  top: 80,
                  left: 30,
                  child: Lottie.asset(
                    'assets/lottie/flame_burst.json',
                    width: 180,
                    repeat: false,
                  ),
                ),

              if (_showFireworks)
                Positioned(
                  top: 80,
                  right: 30,
                  child: Lottie.asset(
                    'assets/lottie/flame_burst.json',
                    width: 180,
                    repeat: false,
                  ),
                ),

              // Additional fireworks for all habits celebration
              if (_showFireworks && isAllHabits)
                Positioned(
                  top: 200,
                  left: MediaQuery.of(context).size.width / 2 - 90,
                  child: Lottie.asset(
                    'assets/lottie/flame_burst.json',
                    width: 180,
                    repeat: false,
                  ),
                ),

              if (_showFireworks && isAllHabits)
                Positioned(
                  bottom: 150,
                  left: 60,
                  child: Lottie.asset(
                    'assets/lottie/flame_burst.json',
                    width: 150,
                    repeat: false,
                  ),
                ),

              if (_showFireworks && isAllHabits)
                Positioned(
                  bottom: 150,
                  right: 60,
                  child: Lottie.asset(
                    'assets/lottie/flame_burst.json',
                    width: 150,
                    repeat: false,
                  ),
                ),

              // Banner message
              if (_showBanner && widget.config.bannerMessage != null)
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value +
                            (isAllHabits ? sin(value * pi * 2) * 0.1 : 0),
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: isAllHabits
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFFFF9966),
                                  Color(0xFFFF5E62),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [
                                  Color(0xFFFF6B6B),
                                  Color(0xFFFFE66D),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: (isAllHabits ? Colors.orange : Colors.black)
                                .withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAllHabits)
                            const Text(
                              '👑',
                              style: TextStyle(fontSize: 60),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            widget.config.bannerMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isAllHabits ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
