import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'coach_overview_screen.dart';

class NavWrapper extends StatefulWidget {
  const NavWrapper({super.key});

  @override
  State<NavWrapper> createState() => _NavWrapperState();
}

class _NavWrapperState extends State<NavWrapper> {
  int index = 0;

  final screens = const [
    HomeScreen(),
    StatsScreen(),
    CoachOverviewScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,

        // 🔥 When a tab is selected
        indicatorColor: color.primary.withValues(alpha: 0.15),

        onDestinationSelected: (i) => setState(() => index = i),

        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: color.onSurface.withValues(alpha: 0.7), // unselected
            ),
            selectedIcon: Icon(
              Icons.home,
              color: color.primary, // selected icon color
            ),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(
              Icons.bar_chart_rounded,
              color: color.onSurface.withValues(alpha: 0.7),
            ),
            selectedIcon: Icon(
              Icons.bar_chart_rounded,
              color: color.primary,
            ),
            label: "Stats",
          ),
          NavigationDestination(
            icon: Icon(
              Icons.smart_toy_outlined,
              color: color.onSurface.withValues(alpha: 0.7),
            ),
            selectedIcon: Icon(
              Icons.smart_toy,
              color: color.primary,
            ),
            label: "Coach",
          ),
        ],
      ),
    );
  }
}
