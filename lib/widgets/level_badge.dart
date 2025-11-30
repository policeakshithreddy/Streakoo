import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/user_level.dart';

class LevelBadge extends StatelessWidget {
  final UserLevel userLevel;
  final bool showProgress;
  final bool showTitle;
  final double size;

  const LevelBadge({
    super.key,
    required this.userLevel,
    this.showProgress = true,
    this.showTitle = true,
    this.size = 80,
  });

  Color _getLevelColor(int level) {
    if (level >= 20) return const Color(0xFFFFD700); // Gold
    if (level >= 15) return const Color(0xFFFF6B6B); // Red
    if (level >= 10) return const Color(0xFF9B59B6); // Purple
    if (level >= 5) return const Color(0xFF3498DB); // Blue
    return const Color(0xFF95A5A6); // Gray
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(userLevel.level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level badge with progress ring
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              if (showProgress)
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: userLevel.progressToNextLevel,
                    strokeWidth: 4,
                    backgroundColor: levelColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(levelColor),
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),

              // Level number
              Container(
                width: size - 16,
                height: size - 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      levelColor,
                      levelColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${userLevel.level}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (showTitle) ...[
          const SizedBox(height: 8),

          // Title
          Text(
            userLevel.titleName,
            style: TextStyle(
              color: levelColor,
              fontSize: size * 0.15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // XP progress text
        if (showProgress)
          Text(
            '${userLevel.currentXP} / ${userLevel.xpToNextLevel} XP',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: size * 0.12,
            ),
          ),
      ],
    );
  }
}
