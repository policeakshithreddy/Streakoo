import 'package:flutter/material.dart';
import '../models/daily_challenge.dart';
import '../theme/design_tokens.dart';
import '../theme/gradients.dart';
import '../utils/haptic_service.dart';
import 'animated_progress_ring.dart';

/// Daily challenge card widget
class DailyChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final VoidCallback? onTap;

  const DailyChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeLeft = challenge.expiresAt.difference(DateTime.now());
    final hoursLeft = timeLeft.inHours;

    return GestureDetector(
      onTap: () {
        HapticService.instance.light();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.space3),
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          gradient: challenge.isCompleted
              ? AppGradients.success.withOpacity(0.1)
              : (isDark ? AppGradients.cardDark : AppGradients.cardLight),
          borderRadius: DesignTokens.borderRadiusLG,
          border: Border.all(
            color: challenge.isCompleted
                ? const Color(0xFF27AE60).withValues(alpha: 0.3)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1)),
          ),
          boxShadow: DesignTokens.shadowSM(Colors.black),
        ),
        child: Row(
          children: [
            // Progress ring with emoji
            AnimatedProgressRing(
              progress: challenge.progressPercent,
              size: 60,
              strokeWidth: 4,
              gradient: _getChallengeGradient(challenge.type),
              child: Text(
                challenge.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),

            const SizedBox(width: DesignTokens.space3),

            // Challenge info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeMD,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (challenge.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF27AE60).withValues(alpha: 0.2),
                            borderRadius: DesignTokens.borderRadiusSM,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: Color(0xFF27AE60),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF27AE60),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge.description,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeSM,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Progress and rewards
                  Row(
                    children: [
                      // Progress
                      Text(
                        '${challenge.currentProgress}/${challenge.targetValue}',
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFA94A),
                        ),
                      ),

                      const SizedBox(width: DesignTokens.space3),

                      // XP reward
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: DesignTokens.borderRadiusSM,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '⭐',
                              style: TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '+${challenge.xpReward} XP',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Time left
                      if (!challenge.isCompleted && hoursLeft < 6)
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: hoursLeft < 2
                                  ? Colors.red
                                  : (isDark ? Colors.white54 : Colors.black54),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${hoursLeft}h left',
                              style: TextStyle(
                                fontSize: 11,
                                color: hoursLeft < 2
                                    ? Colors.red
                                    : (isDark
                                        ? Colors.white54
                                        : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getChallengeGradient(ChallengeType type) {
    switch (type) {
      case ChallengeType.perfectDay:
        return AppGradients.gold;
      case ChallengeType.streakBoost:
        return AppGradients.fire;
      case ChallengeType.earlyBird:
        return const LinearGradient(
          colors: [
            Color(0xFFFF6B6B),
            Color(0xFFFFD93D),
            Color(0xFFFFA94A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ChallengeType.focusTaskMaster:
        return AppGradients.primary;
      case ChallengeType.weekendWarrior:
        return AppGradients.sunset;
      default:
        return AppGradients.secondary;
    }
  }
}
