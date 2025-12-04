import 'package:flutter/material.dart';

/// Custom page route with smooth fade + slide transition
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool slideFromRight;

  SmoothPageRoute({
    required this.page,
    this.slideFromRight = true,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Combine fade + slide for premium feel
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );

            final slideAnimation = Tween<Offset>(
              begin: Offset(slideFromRight ? 0.15 : -0.15, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Scale + fade transition for modals and dialogs
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnimation = Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ));

            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Extension for easy navigation with transitions
extension NavigatorExtensions on NavigatorState {
  Future<T?> pushSmooth<T>(Widget page, {bool slideFromRight = true}) {
    return push<T>(SmoothPageRoute(
      page: page,
      slideFromRight: slideFromRight,
    ));
  }

  Future<T?> pushScale<T>(Widget page) {
    return push<T>(ScalePageRoute(page: page));
  }

  Future<T?> pushReplacementSmooth<T, TO>(Widget page) {
    return pushReplacement<T, TO>(SmoothPageRoute(page: page));
  }
}
