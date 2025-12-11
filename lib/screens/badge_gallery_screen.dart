import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/gradients.dart';
import '../models/achievement.dart';

/// Badge gallery screen showing all achievements
class BadgeGalleryScreen extends StatelessWidget {
  final List<Achievement> achievements;
  final List<Achievement> lockedAchievements;

  const BadgeGalleryScreen({
    super.key,
    required this.achievements,
    required this.lockedAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allAchievements = [...achievements, ...lockedAchievements];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: DesignTokens.space4),
              child: Text(
                '${achievements.length}/${allAchievements.length}',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeLG,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: const Color(0xFFFFA94A),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(DesignTokens.space4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: DesignTokens.space3,
          mainAxisSpacing: DesignTokens.space3,
          childAspectRatio: 0.85,
        ),
        itemCount: allAchievements.length,
        itemBuilder: (context, index) {
          final achievement = allAchievements[index];
          final isUnlocked = achievements.contains(achievement);

          return _BadgeCard(
            achievement: achievement,
            isUnlocked: isUnlocked,
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final bool isDark;

  const _BadgeCard({
    required this.achievement,
    required this.isUnlocked,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isUnlocked ? _getRarityGradient().withOpacity(0.2) : null,
        color: !isUnlocked
            ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
            : null,
        borderRadius: DesignTokens.borderRadiusLG,
        border: Border.all(
          color: isUnlocked
              ? _getRarityColor().withValues(alpha: 0.5)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge/Emoji
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: isUnlocked ? _getRarityGradient() : null,
              color: !isUnlocked
                  ? (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05))
                  : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isUnlocked ? achievement.iconEmoji : '🔒',
                style: TextStyle(
                  fontSize: 36,
                  color: !isUnlocked
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.26))
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.space3),

          // Title
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
            child: Text(
              achievement.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white30 : Colors.black26),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 4),

          // Description or Progress
          if (isUnlocked)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
              child: Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: DesignTokens.borderRadiusSM,
              ),
              child: Text(
                'Locked',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ),
            ),
        ],
      ),
    );
  }

  LinearGradient _getRarityGradient() {
    // You can customize based on achievement type
    return AppGradients.gold;
  }

  Color _getRarityColor() {
    return const Color(0xFFFFD700);
  }
}
