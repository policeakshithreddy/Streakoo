import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/streakoo_pet.dart';
import '../state/app_state.dart';

/// Animated chicken pet widget that displays on the home screen
class PetWidget extends StatefulWidget {
  final bool compact;
  final VoidCallback? onTap;

  const PetWidget({
    super.key,
    this.compact = false,
    this.onTap,
  });

  @override
  State<PetWidget> createState() => _PetWidgetState();
}

class _PetWidgetState extends State<PetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final pet = _buildPet(appState);
        final petName =
            StreakooPetService.instance.customName ?? pet.stage.name;

        if (widget.compact) {
          return _buildCompactPet(
              context, pet, petName, appState.userLevel.level);
        }

        return _buildFullPet(context, pet, petName, appState.userLevel.level);
      },
    );
  }

  StreakooPet _buildPet(AppState appState) {
    final completionsToday =
        appState.habits.where((h) => h.completedToday).length;
    final streaksAtRisk =
        appState.habits.where((h) => h.streak > 0 && !h.completedToday).length;

    return StreakooPet.fromUserState(
      userLevel: appState.userLevel.level,
      completionsToday: completionsToday,
      totalHabits: appState.habits.length,
      streaksAtRisk: streaksAtRisk,
      lastCompletion: DateTime.now(),
    );
  }

  Widget _buildCompactPet(
      BuildContext context, StreakooPet pet, String petName, int level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFA94A).withValues(alpha: isDark ? 0.25 : 0.15),
              const Color(0xFFFFD54F).withValues(alpha: isDark ? 0.1 : 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated chicken
            AnimatedBuilder(
              animation: _bounceController,
              builder: (context, child) {
                final bounce = _bounceController.value * 3;
                return Transform.translate(
                  offset: Offset(0, -bounce),
                  child: child,
                );
              },
              child: Text(
                _getChickenEmoji(pet.stage),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  petName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Lv.$level',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFA94A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 3.seconds,
          delay: 4.seconds,
          color: const Color(0xFFFFA94A).withValues(alpha: 0.15)),
    );
  }

  String _getChickenEmoji(PetStage stage) {
    switch (stage) {
      case PetStage.egg:
        return '🥚';
      case PetStage.hatchling:
        return '🐣';
      case PetStage.baby:
        return '🐥';
      case PetStage.teen:
        return '🐤';
      case PetStage.adult:
        return '🐔';
      case PetStage.master:
        return '🐓';
      case PetStage.legendary:
        return '🦅';
    }
  }

  Widget _buildFullPet(
      BuildContext context, StreakooPet pet, String petName, int level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFA94A).withValues(alpha: isDark ? 0.3 : 0.15),
              const Color(0xFFFFD54F).withValues(alpha: isDark ? 0.1 : 0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouncing chicken
            AnimatedBuilder(
              animation: _bounceController,
              builder: (context, child) {
                final bounce = _bounceController.value * 8;
                return Transform.translate(
                  offset: Offset(0, -bounce),
                  child: child,
                );
              },
              child: Text(
                _getChickenEmoji(pet.stage),
                style: const TextStyle(fontSize: 56),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              petName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              'Level $level',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFFA94A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
