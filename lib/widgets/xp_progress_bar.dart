import 'package:flutter/material.dart';

import '../models/user_level.dart';

/// Duolingo-style XP progress bar
/// Shows progress to next level with animated fill
class XpProgressBar extends StatefulWidget {
  final UserLevel userLevel;
  final bool showLabels;
  final double height;
  final bool animate;

  const XpProgressBar({
    super.key,
    required this.userLevel,
    this.showLabels = true,
    this.height = 24,
    this.animate = true,
  });

  @override
  State<XpProgressBar> createState() => _XpProgressBarState();
}

class _XpProgressBarState extends State<XpProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(XpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userLevel.currentXP != widget.userLevel.currentXP) {
      if (widget.animate) {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = widget.userLevel.level;
    final currentXP = widget.userLevel.currentXP;
    final xpToNext = widget.userLevel.xpToNextLevel;
    final progress = xpToNext > 0 ? currentXP / xpToNext : 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Level labels
        if (widget.showLabels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level $currentLevel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Level ${currentLevel + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 6),

        // Progress bar
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                border: Border.all(
                  color: const Color(0xFF58CC02).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.height / 2),
                child: Stack(
                  children: [
                    // Progress fill
                    FractionallySizedBox(
                      widthFactor:
                          (progress * _animation.value).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF58CC02), // Duolingo green
                              Color(0xFF78D817), // Lighter green
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF58CC02).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Shimmer effect
                    if (progress > 0 && progress < 1)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),

                    // XP text in center
                    Center(
                      child: Text(
                        '$currentXP / $xpToNext XP',
                        style: TextStyle(
                          fontSize: widget.height * 0.5,
                          fontWeight: FontWeight.bold,
                          color: progress > 0.3
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          shadows: progress > 0.3
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Percentage text
        if (widget.showLabels)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${(progress * 100).toStringAsFixed(0)}% to next level',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
      ],
    );
  }
}
