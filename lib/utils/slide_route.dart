import 'package:flutter/material.dart';

/// Simple right-to-left slide transition.
Route<T> SlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      );
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

/// Alias some older code might still use.
Route<T> slideFromRight<T>(Widget page) => SlideRoute<T>(page);
