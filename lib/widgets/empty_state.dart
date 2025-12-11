import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Enhanced empty state widget with illustration and CTA
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDark;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFA94A)
                        .withValues(alpha: isDark ? 0.2 : 0.15),
                    const Color(0xFF1FD1A5)
                        .withValues(alpha: isDark ? 0.15 : 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 56),
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.space6),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.fontSize2XL,
                fontWeight: DesignTokens.fontWeightBold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignTokens.space2),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeMD,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.space6),

              // CTA Button
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space6,
                    vertical: DesignTokens.space4,
                  ),
                  backgroundColor: const Color(0xFFFFA94A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: DesignTokens.borderRadiusLG,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 20),
                    const SizedBox(width: DesignTokens.space2),
                    Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeMD,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Predefined empty states
  static Widget noHabits({
    required VoidCallback onAdd,
    bool isDark = false,
  }) =>
      EmptyState(
        emoji: '🎯',
        title: 'No habits yet',
        description:
            'Start building your\nstreak by creating\nyour first habit',
        actionLabel: 'Create Habit',
        onAction: onAdd,
        isDark: isDark,
      );

  static Widget noStats({bool isDark = false}) => EmptyState(
        emoji: '📊',
        title: 'No stats yet',
        description: 'Complete some habits to\nsee your progress here',
        isDark: isDark,
      );

  static Widget noAchievements({bool isDark = false}) => EmptyState(
        emoji: '🏆',
        title: 'No achievements yet',
        description: 'Keep completing habits to\nunlock amazing badges',
        isDark: isDark,
      );

  static Widget noChallenges({bool isDark = false}) => EmptyState(
        emoji: '🎮',
        title: 'No challenges available',
        description: 'Check back tomorrow for\nnew daily challenges',
        isDark: isDark,
      );

  static Widget searchNotFound({bool isDark = false}) => EmptyState(
        emoji: '🔍',
        title: 'No results found',
        description:
            'Try adjusting your search\nto find what you\'re looking for',
        isDark: isDark,
      );
}
