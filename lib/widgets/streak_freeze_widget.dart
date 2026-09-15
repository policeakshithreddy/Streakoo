import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/streak_freeze.dart';

/// Widget displaying streak freeze status in app bar or home screen
class StreakFreezeWidget extends StatelessWidget {
  final StreakFreeze freeze;
  final int userLevel;
  final VoidCallback? onTap;
  final bool compact;

  const StreakFreezeWidget({
    super.key,
    required this.freeze,
    required this.userLevel,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysUntilNext = freeze.daysUntilNextFreeze(userLevel);

    if (compact) {
      return _buildCompact(context, isDark, daysUntilNext);
    }

    return _buildFull(context, isDark, daysUntilNext);
  }

  Widget _buildCompact(BuildContext context, bool isDark, int daysUntilNext) {
    return GestureDetector(
      onTap: onTap ?? () => _showFreezeDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF64B5F6).withValues(alpha: isDark ? 0.3 : 0.2),
              const Color(0xFF42A5F5).withValues(alpha: isDark ? 0.1 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛡️', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '${freeze.availableFreezes}',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, bool isDark, int daysUntilNext) {
    return GestureDetector(
      onTap: onTap ?? () => _showFreezeDetails(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF64B5F6).withValues(alpha: isDark ? 0.2 : 0.15),
              const Color(0xFF42A5F5).withValues(alpha: isDark ? 0.05 : 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Shield icon with count
            Stack(
              alignment: Alignment.center,
              children: [
                const Text('🛡️', style: TextStyle(fontSize: 32)),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF64B5F6),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${freeze.availableFreezes}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak Freezes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitle(daysUntilNext),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            // Progress indicator
            _buildProgressRing(isDark),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildProgressRing(bool isDark) {
    final progress = freeze.availableFreezes / freeze.maxFreezes;
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF64B5F6)),
          ),
          Text(
            '${freeze.availableFreezes}/${freeze.maxFreezes}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle(int daysUntilNext) {
    if (freeze.availableFreezes >= freeze.maxFreezes) {
      return 'Maximum reached!';
    }
    if (daysUntilNext == 0) {
      return 'New freeze available!';
    }
    if (daysUntilNext == 1) {
      return 'Next freeze tomorrow';
    }
    return 'Next freeze in $daysUntilNext days';
  }

  void _showFreezeDetails(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Text('🛡️', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streak Freezes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Protect your streaks when life gets busy',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${freeze.availableFreezes}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64B5F6),
                          ),
                        ),
                        Text(
                          'Available',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${freeze.maxFreezes}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        Text(
                          'Maximum',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Level info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up,
                      color: Color(0xFFFFA94A), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getLevelMessage(),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recent usage
            if (freeze.usageHistory.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Usage',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...freeze.usageHistory.take(3).map((usage) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          usage.habitName,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(usage.usedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Close button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelMessage() {
    if (userLevel >= 40) {
      return 'Level $userLevel: You earn 1 freeze per week (max 4)';
    } else if (userLevel >= 30) {
      return 'Level $userLevel: You earn 1 freeze every 10 days (max 3)';
    } else if (userLevel >= 20) {
      return 'Level $userLevel: You earn 1 freeze every 2 weeks (max 3)';
    } else if (userLevel >= 10) {
      return 'Level $userLevel: You earn 1 freeze every 2 weeks (max 2)';
    } else {
      return 'Level $userLevel: You earn 1 freeze per week (max 1). Reach level 10 for more!';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}';
  }
}
