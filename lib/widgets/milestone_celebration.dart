import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

/// Celebration widget for health score milestones
class MilestoneCelebration extends StatefulWidget {
  final double score;
  final double previousScore;
  final VoidCallback onComplete;

  const MilestoneCelebration({
    super.key,
    required this.score,
    required this.previousScore,
    required this.onComplete,
  });

  @override
  State<MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<MilestoneCelebration> {
  late ConfettiController _confettiController;
  String _message = '';
  String _emoji = '';

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _checkMilestone();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkMilestone() {
    // Check if crossed a milestone threshold
    final milestones = [25, 50, 75, 90, 100];

    for (final milestone in milestones) {
      if (widget.previousScore < milestone && widget.score >= milestone) {
        // Crossed this milestone!
        _confettiController.play();

        setState(() {
          switch (milestone) {
            case 25:
              _emoji = '🎯';
              _message = 'Great Start!';
              break;
            case 50:
              _emoji = '🚀';
              _message = 'Halfway There!';
              break;
            case 75:
              _emoji = '⭐';
              _message = 'Fantastic Progress!';
              break;
            case 90:
              _emoji = '🏆';
              _message = 'Almost Perfect!';
              break;
            case 100:
              _emoji = '👑';
              _message = 'Perfect Score!';
              break;
          }
        });

        // Auto-dismiss after animation
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            widget.onComplete();
          }
        });

        break; // Only celebrate first milestone crossed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onComplete,
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ),

        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Color(0xFF8B5CF6),
              Color(0xFFEC4899),
              Color(0xFF4CAF50),
              Color(0xFFFFA726),
            ],
          ),
        ),

        // Celebration message
        Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _emoji,
                  style: const TextStyle(fontSize: 64),
                )
                    .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true))
                    .scale(
                      duration: 1000.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                    ),
                const SizedBox(height: 16),
                Text(
                  _message,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Health Score: ${widget.score.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: widget.onComplete,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).scale(),
              ],
            ),
          )
              .animate()
              .scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(),
        ),
      ],
    );
  }
}
