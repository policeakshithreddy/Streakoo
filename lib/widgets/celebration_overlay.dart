import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
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
              // Confetti from top-left corner
              if (widget.config.showConfetti)
                Align(
                  alignment: Alignment.topLeft,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 4, // 45 degrees (down-right)
                    emissionFrequency: isAllHabits ? 0.1 : 0.06,
                    numberOfParticles: isAllHabits ? 40 : 25,
                    gravity: 0.25,
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

              // Confetti from top-center
              if (widget.config.showConfetti)
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController2,
                    blastDirection: pi / 2, // Straight down
                    emissionFrequency: isAllHabits ? 0.1 : 0.06,
                    numberOfParticles: isAllHabits ? 40 : 25,
                    gravity: 0.25,
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

              // Confetti from top-right corner
              if (widget.config.showConfetti)
                Align(
                  alignment: Alignment.topRight,
                  child: ConfettiWidget(
                    confettiController: _confettiController3,
                    blastDirection: 3 * pi / 4, // 135 degrees (down-left)
                    emissionFrequency: isAllHabits ? 0.1 : 0.06,
                    numberOfParticles: isAllHabits ? 40 : 25,
                    gravity: 0.25,
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
            ],
          ),
        ),
      ),
    );
  }
}
