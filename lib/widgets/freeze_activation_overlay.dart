import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vibration/vibration.dart';

/// Full-screen overlay shown when a streak freeze is activated
class FreezeActivationOverlay extends StatefulWidget {
  final List<String> protectedHabitNames;
  final VoidCallback onComplete;

  const FreezeActivationOverlay({
    super.key,
    required this.protectedHabitNames,
    required this.onComplete,
  });

  @override
  State<FreezeActivationOverlay> createState() =>
      _FreezeActivationOverlayState();
}

class _FreezeActivationOverlayState extends State<FreezeActivationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _freezeController;
  late AnimationController _shieldController;
  late AnimationController _fadeController;

  late Animation<double> _freezeAnimation;
  late Animation<double> _shieldScaleAnimation;
  late Animation<double> _shieldOpacityAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Freeze effect controller (0.8s)
    _freezeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Shield formation controller (1.2s)
    _shieldController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Fade out controller (0.5s)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Freeze wave animation
    _freezeAnimation = CurvedAnimation(
      parent: _freezeController,
      curve: Curves.easeOutCubic,
    );

    // Shield scale animation
    _shieldScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shieldController,
        curve: Curves.elasticOut,
      ),
    );

    // Shield opacity animation
    _shieldOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shieldController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Fade out animation
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInCubic,
      ),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Haptic feedback
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib) {
        Vibration.vibrate(duration: 200, amplitude: 128);
      }
    } catch (e) {
      // Vibration not supported
    }

    // Stage 1: Freeze wave
    await _freezeController.forward();

    // Stage 2: Shield formation (overlapping)
    await Future.delayed(const Duration(milliseconds: 200));
    _shieldController.forward();

    // Wait for shield to form
    await Future.delayed(const Duration(milliseconds: 1500));

    // Stage 3: Fade out
    await _fadeController.forward();

    // Complete
    widget.onComplete();
  }

  @override
  void dispose() {
    _freezeController.dispose();
    _shieldController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withValues(alpha: 0.85),
        child: Stack(
          children: [
            // Freeze Wave Effect
            AnimatedBuilder(
              animation: _freezeAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FreezeWavePainter(
                    progress: _freezeAnimation.value,
                  ),
                  size: size,
                );
              },
            ),

            // Ice Particles
            AnimatedBuilder(
              animation: _freezeAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _IceParticlesPainter(
                    progress: _freezeAnimation.value,
                  ),
                  size: size,
                );
              },
            ),

            // Center Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shield Icon with Animation
                  AnimatedBuilder(
                    animation: _shieldController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _shieldOpacityAnimation.value,
                        child: Transform.scale(
                          scale: _shieldScaleAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF00CED1)
                                      .withValues(alpha: 0.3),
                                  const Color(0xFF00CED1)
                                      .withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00CED1)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shield,
                                size: 64,
                                color: Color(0xFF00CED1),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Title
                  AnimatedBuilder(
                    animation: _shieldController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _shieldOpacityAnimation.value,
                        child: const Text(
                          '🛡️ Streak Protected!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Description
                  AnimatedBuilder(
                    animation: _shieldController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _shieldOpacityAnimation.value *
                            (_shieldController.value > 0.3 ? 1.0 : 0.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Column(
                            children: [
                              Text(
                                'A Streak Freeze was used to protect:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ...widget.protectedHabitNames
                                  .map((name) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text('❄️ ',
                                                style: TextStyle(fontSize: 16)),
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF00CED1),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Freeze Count Info
                  AnimatedBuilder(
                    animation: _shieldController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _shieldOpacityAnimation.value *
                            (_shieldController.value > 0.5 ? 1.0 : 0.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF00CED1).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF00CED1)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Your streak continues! 🔥',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for freeze wave effect
class _FreezeWavePainter extends CustomPainter {
  final double progress;

  _FreezeWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 1.5;

    // Draw expanding freeze wave
    final radius = maxRadius * progress;
    final paint = Paint()
      ..color =
          const Color(0xFF00CED1).withValues(alpha: (0.4 * (1 - progress)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, paint);

    // Draw inner wave
    if (progress > 0.2) {
      final innerRadius = maxRadius * (progress - 0.2) / 0.8;
      final innerPaint = Paint()
        ..color =
            const Color(0xFF00CED1).withValues(alpha: (0.2 * (1 - progress)))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, innerRadius, innerPaint);
    }
  }

  @override
  bool shouldRepaint(_FreezeWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Custom painter for ice particles
class _IceParticlesPainter extends CustomPainter {
  final double progress;

  _IceParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent particles
    const particleCount = 30;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = size.width / 2 * progress;
      final x = size.width / 2 + math.cos(angle) * distance;
      final y = size.height / 2 + math.sin(angle) * distance;

      final particleSize = random.nextDouble() * 4 + 2;
      final opacity = (1 - progress) * random.nextDouble();

      final paint = Paint()
        ..color = const Color(0xFF00CED1).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_IceParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
