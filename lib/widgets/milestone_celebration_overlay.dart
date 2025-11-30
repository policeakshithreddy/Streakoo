import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';

import '../models/streak_milestone.dart';

/// Celebration overlay for streak milestones
class MilestoneCelebrationOverlay extends StatefulWidget {
  final StreakMilestone milestone;
  final VoidCallback? onComplete;

  const MilestoneCelebrationOverlay({
    super.key,
    required this.milestone,
    this.onComplete,
  });

  @override
  State<MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState
    extends State<MilestoneCelebrationOverlay> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late ConfettiController _confettiController1;
  late ConfettiController _confettiController2;
  late ConfettiController _confettiController3;

  bool _showBadge = false;
  bool _showMessage = false;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Confetti controllers
    _confettiController1 = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController2 = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController3 = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _startCelebration();
  }

  void _startCelebration() async {
    // Vibration
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 200, amplitude: 128);
    }

    // Fade in
    _fadeController.forward();

    // Start confetti
    await Future.delayed(const Duration(milliseconds: 200));
    _confettiController1.play();
    _confettiController2.play();
    _confettiController3.play();

    // Show badge
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _showBadge = true);
    }

    // Show message
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _showMessage = true);
    }

    // Auto-dismiss after 4 seconds
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      _fadeController.reverse().then((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _confettiController1.dispose();
    _confettiController2.dispose();
    _confettiController3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti from top-left
            Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: _confettiController1,
                blastDirection: pi / 4,
                emissionFrequency: 0.1,
                numberOfParticles: 60,
                gravity: 0.2,
                colors: widget.milestone.confettiColors
                    .map((c) => Color(c))
                    .toList(),
              ),
            ),

            // Confetti from top-right
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _confettiController2,
                blastDirection: 3 * pi / 4,
                emissionFrequency: 0.1,
                numberOfParticles: 60,
                gravity: 0.2,
                colors: widget.milestone.confettiColors
                    .map((c) => Color(c))
                    .toList(),
              ),
            ),

            // Explosive center confetti
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController3,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.15,
                colors: widget.milestone.confettiColors
                    .map((c) => Color(c))
                    .toList(),
              ),
            ),

            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge/Trophy
                if (_showBadge)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Transform.rotate(
                          angle: sin(value * pi * 2) * 0.1,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: widget.milestone.confettiColors
                              .take(2)
                              .map((c) => Color(c))
                              .toList(),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(widget.milestone.confettiColors.first)
                                .withOpacity(0.6),
                            blurRadius: 50,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.milestone.emoji,
                          style: const TextStyle(fontSize: 90),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Title
                if (_showBadge)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.milestone.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 16),

                // Day count
                if (_showBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Color(widget.milestone.confettiColors.first)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(widget.milestone.confettiColors.first)
                            .withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '${widget.milestone.days} Days',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(widget.milestone.confettiColors.first),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 32),

                // Message
                if (_showMessage)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      widget.milestone.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
