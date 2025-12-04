import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A collection of reusable, performant animation widgets.
/// These are optimized to run smoothly on all devices.

/// Fade + Slide animation for list items
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration? duration;
  final Duration? delay;
  final bool slideFromLeft;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration,
    this.delay,
    this.slideFromLeft = true,
  });

  @override
  Widget build(BuildContext context) {
    final dur = duration ?? 350.ms;
    final del = delay ?? (index * 50).ms;

    return child.animate().fadeIn(duration: dur, delay: del).slideX(
          begin: slideFromLeft ? -0.1 : 0.1,
          end: 0,
          duration: dur,
          delay: del,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Pop-in animation for cards and containers
class AnimatedPopIn extends StatelessWidget {
  final Widget child;
  final Duration? duration;
  final Duration? delay;

  const AnimatedPopIn({
    super.key,
    required this.child,
    this.duration,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(duration: duration ?? 300.ms, delay: delay)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: duration ?? 300.ms,
          delay: delay,
          curve: Curves.easeOutBack,
        );
  }
}

/// Pulse animation for attention-grabbing elements
class AnimatedPulse extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const AnimatedPulse({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return child.animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 1000.ms,
          curve: Curves.easeInOut,
        );
  }
}

/// Shimmer loading effect
class AnimatedShimmer extends StatelessWidget {
  final Widget child;

  const AnimatedShimmer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: Colors.white24);
  }
}

/// Bounce animation for buttons and interactive elements
class AnimatedBounce extends StatelessWidget {
  final Widget child;
  final Duration? delay;

  const AnimatedBounce({
    super.key,
    required this.child,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return child.animate().scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 400.ms,
          delay: delay,
          curve: Curves.elasticOut,
        );
  }
}

/// Slide up animation for bottom sheets and modals
class AnimatedSlideUp extends StatelessWidget {
  final Widget child;
  final Duration? duration;

  const AnimatedSlideUp({
    super.key,
    required this.child,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return child.animate().fadeIn(duration: duration ?? 300.ms).slideY(
          begin: 0.3,
          end: 0,
          duration: duration ?? 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Counter animation for numbers (level, XP, streak)
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration? duration;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration ?? 500.ms,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '${prefix ?? ''}$value${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}

/// Staggered grid animation
class AnimatedStaggeredGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  const AnimatedStaggeredGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index]
            .animate()
            .fadeIn(duration: 350.ms, delay: (index * 80).ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 350.ms,
              delay: (index * 80).ms,
              curve: Curves.easeOutBack,
            );
      },
    );
  }
}

/// Extension methods for easy animation application
extension AnimationExtensions on Widget {
  /// Add a staggered fade+slide animation
  Widget animateListItem(int index) {
    return AnimatedListItem(index: index, child: this);
  }

  /// Add a pop-in animation
  Widget animatePopIn({Duration? delay}) {
    return AnimatedPopIn(delay: delay, child: this);
  }

  /// Add a slide-up animation
  Widget animateSlideUp() {
    return AnimatedSlideUp(child: this);
  }

  /// Add a bounce animation
  Widget animateBounce({Duration? delay}) {
    return AnimatedBounce(delay: delay, child: this);
  }
}
