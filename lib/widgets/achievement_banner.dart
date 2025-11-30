import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AchievementBanner extends StatelessWidget {
  final String message;
  final String emoji;
  final VoidCallback? onDismiss;

  const AchievementBanner({
    super.key,
    required this.message,
    required this.emoji,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFFFFE66D),
              Color(0xFFFF6B6B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji with shine effect
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: 2000.ms,
                  color: Colors.white.withValues(alpha: 0.5),
                ),

            const SizedBox(width: 16),

            // Message
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),

            // Dismiss button
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      )
          .animate()
          .slideY(
            begin: -1,
            end: 0,
            duration: 600.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 400.ms),
    );
  }
}
