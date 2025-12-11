import 'package:flutter/material.dart';

/// Simple, subtle slide transition.
Route<T> SlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (_, animation, __, child) {
      // Subtle slide + fade for a smoother feel
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0.08, 0.0), // Much smaller slide distance
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      );

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
  );
}

/// Alias some older code might still use.
Route<T> slideFromRight<T>(Widget page) => SlideRoute<T>(page);
