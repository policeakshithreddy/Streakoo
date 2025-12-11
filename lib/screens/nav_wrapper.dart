import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'coach_overview_screen.dart';

class NavWrapper extends StatefulWidget {
  final int initialIndex;

  const NavWrapper({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<NavWrapper> createState() => _NavWrapperState();
}

class _NavWrapperState extends State<NavWrapper> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }

  final screens = const [
    HomeScreen(),
    StatsScreen(),
    CoachOverviewScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
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
