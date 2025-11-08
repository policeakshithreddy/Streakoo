import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streakoo/providers/app_provider.dart';
import 'package:streakoo/screens/home_screen.dart';
import 'package:streakoo/screens/onboarding_screen.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.hasOnboarded) {
          return const HomeScreen();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}
