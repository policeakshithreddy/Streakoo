import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/habit_template.dart';
import '../state/app_state.dart';

/// Screen to browse and add habit template packs
class HabitTemplatesScreen extends StatefulWidget {
  const HabitTemplatesScreen({super.key});

  @override
  State<HabitTemplatesScreen> createState() => _HabitTemplatesScreenState();
}

class _HabitTemplatesScreenState extends State<HabitTemplatesScreen> {
  // Orange theme colors
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryOrange = Color(0xFFFF6B6B);

  String? _selectedPackId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          _primaryOrange.withValues(alpha: 0.12),
                          const Color(0xFF0D0D0D),
                        ]
                      : [
                          _primaryOrange.withValues(alpha: 0.06),
                          Colors.white,
                        ],
                ),
              ),
            ),
          ),

          // Decorative orb
          Positioned(
            top: -80,
            right: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: _primaryOrange.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Habit Templates',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryOrange, _secondaryOrange],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Quick Start',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(duration: 2.seconds, color: Colors.white30),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Ready-Made Packs',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add multiple related habits with one tap',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Template Packs Grid
                        ...HabitTemplates.allPacks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final pack = entry.value;
                          final isSelected = _selectedPackId == pack.id;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _TemplatePackCard(
                              pack: pack,
                              isSelected: isSelected,
                              index: index,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedPackId = isSelected ? null : pack.id;
                                });
                              },
                              onAdd: () => _addPack(pack),
                            ),
                          )
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 80 * index),
                                duration: 400.ms,
                              )
                              .slideY(begin: 0.1, end: 0);
                        }),

                        const SizedBox(height: 80), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addPack(HabitTemplatePack pack) async {
    HapticFeedback.mediumImpact();

    final appState = context.read<AppState>();
    int addedCount = 0;

    for (final template in pack.habits) {
      final habit = template.toHabit();
      // Check if habit with same name already exists
      final exists = appState.habits.any(
        (h) => h.name.toLowerCase() == habit.name.toLowerCase(),
      );

      if (!exists) {
        appState.addHabit(habit);
        addedCount++;
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              addedCount > 0 ? Icons.check_circle : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                addedCount > 0
                    ? 'Added $addedCount habits from ${pack.name}!'
                    : 'All habits from this pack already exist',
              ),
            ),
          ],
        ),
        backgroundColor: addedCount > 0 ? _primaryOrange : Colors.grey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (addedCount > 0) {
      Navigator.pop(context);
      Navigator.pop(context); // Also pop the AddHabitScreen
    }
  }
}

class _TemplatePackCard extends StatelessWidget {
  final HabitTemplatePack pack;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  // Pack gradient colors
  static const List<List<Color>> _packGradients = [
    [Color(0xFF8B5CF6), Color(0xFFEC4899)], // Purple-Pink
    [Color(0xFF10B981), Color(0xFF34D399)], // Green
    [Color(0xFF3B82F6), Color(0xFF60A5FA)], // Blue
    [Color(0xFFF59E0B), Color(0xFFFBBF24)], // Orange
    [Color(0xFFEF4444), Color(0xFFF87171)], // Red
    [Color(0xFF6366F1), Color(0xFF818CF8)], // Indigo
  ];

  const _TemplatePackCard({
    required this.pack,
    required this.isSelected,
    required this.index,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _packGradients[index % _packGradients.length];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? gradientColors[0]
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? gradientColors[0].withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: isSelected ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Pack Emoji with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      pack.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: gradientColors[0].withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.checklist_rounded,
                                  size: 12,
                                  color: gradientColors[0],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${pack.habits.length} habits',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: gradientColors[0],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '~${pack.estimatedTimeMinutes}m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Add Button
                if (isSelected)
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().scale(),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              pack.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),

            // Expanded Content (when selected)
            if (isSelected) ...[
              const SizedBox(height: 16),

              // Benefits
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradientColors[0].withValues(alpha: 0.1),
                      gradientColors[1].withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: gradientColors[0].withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: gradientColors[0],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Benefits',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: gradientColors[0],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...pack.benefits.map((benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: gradientColors[0],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 14),

              // Habits List
              Text(
                'Included Habits:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pack.habits.asMap().entries.map((entry) {
                  final habit = entry.value;
                  final habitIndex = entry.key;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          gradientColors[0].withValues(alpha: 0.12),
                          gradientColors[1].withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: gradientColors[0].withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(habit.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 50 * habitIndex))
                      .scale(begin: const Offset(0.9, 0.9));
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
