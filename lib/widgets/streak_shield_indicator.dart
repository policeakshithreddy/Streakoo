import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Streak Shield Indicator - Shows available streak freezes with animated protection visual
class StreakShieldIndicator extends StatefulWidget {
  final int freezeCount;
  final bool hasActiveProtection;
  final VoidCallback? onTap;

  const StreakShieldIndicator({
    super.key,
    required this.freezeCount,
    this.hasActiveProtection = false,
    this.onTap,
  });

  @override
  State<StreakShieldIndicator> createState() => _StreakShieldIndicatorState();
}

class _StreakShieldIndicatorState extends State<StreakShieldIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    if (widget.hasActiveProtection) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StreakShieldIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasActiveProtection && !oldWidget.hasActiveProtection) {
      _controller.repeat(reverse: true);
    } else if (!widget.hasActiveProtection && oldWidget.hasActiveProtection) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFreeze = widget.freezeCount > 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.hasActiveProtection
              ? const Color(0xFF00CED1).withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
          border: widget.hasActiveProtection
              ? Border.all(
                  color: const Color(0xFF00CED1).withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield Icon with Animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale:
                      widget.hasActiveProtection ? _pulseAnimation.value : 1.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Particle Glow Effect for Active Protection
                      if (widget.hasActiveProtection)
                        ...List.generate(8, (index) {
                          final angle =
                              (index * math.pi / 4) + _rotateAnimation.value;
                          final offset = Offset(
                              math.cos(angle) * 12, math.sin(angle) * 12);
                          return Transform.translate(
                            offset: offset,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00CED1)
                                    .withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00CED1)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                      // Shield Icon
                      Icon(
                        Icons.shield,
                        size: 24,
                        color: hasFreeze
                            ? (widget.hasActiveProtection
                                ? const Color(0xFF00CED1)
                                : const Color(0xFF4FC3F7))
                            : (isDark ? Colors.white30 : Colors.black26),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(width: 6),

            // Freeze Count Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasFreeze
                    ? const Color(0xFF00CED1).withValues(alpha: 0.2)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '❄️',
                    style: TextStyle(
                      fontSize: 10,
                      color: hasFreeze ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${widget.freezeCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: hasFreeze
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey,
                    ),
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

/// Freeze Details Bottom Sheet
class FreezeDetailsSheet extends StatelessWidget {
  final int freezeCount;
  final List<String> frozenDates;

  const FreezeDetailsSheet({
    super.key,
    required this.freezeCount,
    required this.frozenDates,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white30 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CED1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield,
                  color: Color(0xFF00CED1),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Shield',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '$freezeCount ${freezeCount == 1 ? 'freeze' : 'freezes'} available',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00CED1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00CED1).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('❄️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'How Streak Freezes Work',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  '🎯',
                  'Only protects Focus Tasks',
                  isDark,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  '🛡️',
                  'Auto-activated when you miss a day',
                  isDark,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  '✨',
                  'Earn more by completing challenges',
                  isDark,
                ),
              ],
            ),
          ),

          // Frozen Dates History
          if (frozenDates.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Protection',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...frozenDates.take(5).map((date) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.ac_unit,
                        size: 16,
                        color: Color(0xFF00CED1),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: 16),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00CED1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
