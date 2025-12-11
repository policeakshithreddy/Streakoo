import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/design_tokens.dart';

/// Shimmer loading skeleton for smooth loading states
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isDark;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius ?? DesignTokens.borderRadiusMD,
        ),
      ),
    );
  }
}

/// Shimmer skeleton for habit card
class HabitCardSkeleton extends StatelessWidget {
  final bool isDark;

  const HabitCardSkeleton({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space3),
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: DesignTokens.borderRadiusLG,
        boxShadow: DesignTokens.shadowSM(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and emoji
          Row(
            children: [
              ShimmerLoading(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                isDark: isDark,
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: double.infinity,
                      height: 18,
                      isDark: isDark,
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    ShimmerLoading(
                      width: 120,
                      height: 14,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              ShimmerLoading(
                width: 60,
                height: 32,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          // Progress bar
          ShimmerLoading(
            width: double.infinity,
            height: 8,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for stats card
class StatsCardSkeleton extends StatelessWidget {
  final bool isDark;

  const StatsCardSkeleton({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: DesignTokens.borderRadiusLG,
        boxShadow: DesignTokens.shadowSM(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(
            width: 100,
            height: 16,
            isDark: isDark,
          ),
          const SizedBox(height: DesignTokens.space3),
          ShimmerLoading(
            width: double.infinity,
            height: 60,
            isDark: isDark,
          ),
          const SizedBox(height: DesignTokens.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (index) => ShimmerLoading(
                width: 80,
                height: 40,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for list items
class ListItemSkeleton extends StatelessWidget {
  final bool isDark;
  final int count;

  const ListItemSkeleton({
    super.key,
    this.isDark = false,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space3),
          child: Row(
            children: [
              ShimmerLoading(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                isDark: isDark,
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: double.infinity,
                      height: 16,
                      isDark: isDark,
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    ShimmerLoading(
                      width: 200,
                      height: 12,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton for circular progress
class CircularProgressSkeleton extends StatelessWidget {
  final double size;
  final bool isDark;

  const CircularProgressSkeleton({
    super.key,
    this.size = 60,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      isDark: isDark,
    );
  }
}

/// Full screen loading state
class FullScreenSkeleton extends StatelessWidget {
  final bool isDark;

  const FullScreenSkeleton({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              ShimmerLoading(
                width: 150,
                height: 32,
                isDark: isDark,
              ),
              const SizedBox(height: DesignTokens.space6),

              // Stats card
              StatsCardSkeleton(isDark: isDark),
              const SizedBox(height: DesignTokens.space4),

              // List items
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => HabitCardSkeleton(
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
