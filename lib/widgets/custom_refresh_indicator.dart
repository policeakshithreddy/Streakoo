import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/design_tokens.dart';
import '../theme/gradients.dart';

/// Custom branded refresh indicator with logo animation
class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Gradient? gradient;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFFFA94A),
      backgroundColor: Theme.of(context).cardColor,
      displacement: 60,
      strokeWidth: 3,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      // Custom builder for animated indicator
      child: child,
    );
  }
}

/// Animated refresh header widget
class RefreshHeader extends StatefulWidget {
  final double pullDistance;
  final RefreshStatus status;

  const RefreshHeader({
    super.key,
    required this.pullDistance,
    required this.status,
  });

  @override
  State<RefreshHeader> createState() => _RefreshHeaderState();
}

class _RefreshHeaderState extends State<RefreshHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(RefreshHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == RefreshStatus.refreshing) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.pullDistance / 100).clamp(0.0, 1.0);

    return Container(
      height: 60,
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: widget.status == RefreshStatus.refreshing
                ? _rotationController.value * 2 * math.pi
                : progress * math.pi * 2,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
                boxShadow: DesignTokens.glowSM(
                  const Color(0xFFFFA94A),
                  alpha: progress * 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  '🔥',
                  style: TextStyle(
                    fontSize: 24 * progress,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum RefreshStatus {
  idle,
  pulling,
  readyToRefresh,
  refreshing,
  completed,
}

/// Alternative: Simple branded refresh indicator
class BrandedRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const BrandedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFFFA94A),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      displacement: 50,
      strokeWidth: 3.0,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }
}
