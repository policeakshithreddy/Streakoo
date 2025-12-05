import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class FreezeAnimationOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const FreezeAnimationOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<FreezeAnimationOverlay> createState() => _FreezeAnimationOverlayState();
}

class _FreezeAnimationOverlayState extends State<FreezeAnimationOverlay> {
  @override
  void initState() {
    super.initState();
    // Auto-complete after animation duration
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Frosty Overlay (Blur + Blue Tint)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.lightBlue.withValues(alpha: 0.3),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .then(delay: 1500.ms)
              .fadeOut(duration: 500.ms),
        ),

        // 2. Ice Crystals / Snowflakes
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.ac_unit,
                size: 100,
                color: Colors.white,
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .then()
                  .shimmer(duration: 1000.ms, color: Colors.lightBlueAccent)
                  .then()
                  .fadeOut(duration: 400.ms),
              const SizedBox(height: 20),
              const Text(
                'Streak Frozen!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.blue,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0)
                  .then(delay: 1000.ms)
                  .fadeOut(duration: 400.ms),
              const SizedBox(height: 8),
              const Text(
                'Focus Task Protected ❄️',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms)
                  .then(delay: 1000.ms)
                  .fadeOut(duration: 400.ms),
            ],
          ),
        ),

        // 3. Falling Snowflakes (Random positions)
        ...List.generate(10, (index) {
          final randomX = (index * 40.0) % 300 - 150;
          final randomDelay = index * 100;
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + randomX,
            top: -50,
            child: const Icon(Icons.ac_unit, color: Colors.white70, size: 24)
                .animate()
                .moveY(
                  begin: 0,
                  end: MediaQuery.of(context).size.height + 100,
                  duration: (2000 + index * 100).ms,
                  delay: randomDelay.ms,
                  curve: Curves.easeInOut,
                )
                .fadeOut(delay: 1500.ms),
          );
        }),
      ],
    );
  }
}
