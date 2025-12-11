import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/design_tokens.dart';
import '../theme/gradients.dart';

/// Horizontal scrollable carousel showing top streaks
class StreaksCarousel extends StatelessWidget {
  final List<Habit> habits;
  final Function(Habit)? onHabitTap;
  final bool isDark;

  const StreaksCarousel({
    super.key,
    required this.habits,
    this.onHabitTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get top streaks (minimum 1 day, sorted descending)
    final topStreaks = habits.where((h) => h.streak > 0).toList()
      ..sort((a, b) => b.streak.compareTo(a.streak));

    final displayHabits = topStreaks.take(5).toList();

    if (displayHabits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
          child: Row(
            children: [
              Text(
                '🔥 Top Streaks',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (topStreaks.length > 5)
                Text(
                  '+${topStreaks.length - 5} more',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSM,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
            itemCount: displayHabits.length,
            itemBuilder: (context, index) {
              final habit = displayHabits[index];
              return _StreakCard(
                habit: habit,
                onTap: () => onHabitTap?.call(habit),
                rank: index + 1,
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onTap;
  final int rank;
  final bool isDark;

  const _StreakCard({
    required this.habit,
    this.onTap,
    required this.rank,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: DesignTokens.space3),
        decoration: BoxDecoration(
          gradient: _getRankGradient(),
          borderRadius: DesignTokens.borderRadiusLG,
          boxShadow: DesignTokens.shadowMD(Colors.black),
          border: Border.all(
            color: _getRankColor().withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rank badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: DesignTokens.borderRadiusSM,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getRankEmoji(),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#$rank',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Habit emoji
                  Text(
                    habit.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),

                  const SizedBox(height: 4),

                  // Habit name
                  Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Streak count
                  Row(
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.streak} days',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Particle effects for top 3
            if (rank <= 3)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SparklesPainter(rank: rank),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getRankGradient() {
    switch (rank) {
      case 1:
        return AppGradients.gold;
      case 2:
        return AppGradients.silver;
      case 3:
        return AppGradients.bronze;
      default:
        return AppGradients.fire;
    }
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFFFF6347);
    }
  }

  String _getRankEmoji() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🔥';
    }
  }
}

class _SparklesPainter extends CustomPainter {
  final int rank;

  _SparklesPainter({required this.rank});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw sparkle stars for top ranking
    if (rank == 1) {
      _drawStar(canvas, size, const Offset(20, 20), 6, paint);
      _drawStar(canvas, size, Offset(size.width - 20, 30), 4, paint);
      _drawStar(
          canvas, size, Offset(size.width - 30, size.height - 40), 5, paint);
    }
  }

  void _drawStar(
      Canvas canvas, Size size, Offset center, double radius, Paint paint) {
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SparklesPainter oldDelegate) => false;
}
