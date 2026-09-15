import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/habit.dart';

/// Screen for reordering habits with a simple drag interface
class ReorderHabitsScreen extends StatefulWidget {
  const ReorderHabitsScreen({super.key});

  @override
  State<ReorderHabitsScreen> createState() => _ReorderHabitsScreenState();
}

class _ReorderHabitsScreenState extends State<ReorderHabitsScreen> {
  late List<Habit> _habits;
  bool _hasChanges = false;
  List<String> _originalOrder = [];

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _habits = List.from(appState.habits);
    _originalOrder = _habits.map((h) => h.id).toList();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _habits.removeAt(oldIndex);
      _habits.insert(newIndex, item);

      // Check if order has changed from original
      final currentOrder = _habits.map((h) => h.id).toList();
      _hasChanges = !_listEquals(currentOrder, _originalOrder);
    });
    HapticFeedback.lightImpact();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _saveOrder() {
    final appState = context.read<AppState>();

    // Apply the new order
    for (int i = 0; i < _habits.length; i++) {
      final originalIndex =
          appState.habits.indexWhere((h) => h.id == _habits[i].id);
      if (originalIndex != i && originalIndex != -1) {
        appState.reorderHabits(originalIndex, i);
      }
    }

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reorder Habits'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Habits list
          ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            buildDefaultDragHandles: false,
            onReorder: _onReorder,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final scale = lerpDouble(1.0, 1.05, animation.value)!;
                  final elevation = lerpDouble(0, 16, animation.value)!;
                  return Transform.scale(
                    scale: scale,
                    child: Material(
                      elevation: elevation,
                      borderRadius: BorderRadius.circular(16),
                      shadowColor:
                          const Color(0xFFFFA94A).withValues(alpha: 0.4),
                      color: Colors.transparent,
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            itemCount: _habits.length,
            itemBuilder: (context, index) {
              final habit = _habits[index];

              return ReorderableDragStartListener(
                key: ValueKey('reorder_${habit.id}'),
                index: index,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Drag handle
                      Icon(
                        Icons.drag_indicator,
                        color: isDark ? Colors.white54 : Colors.black38,
                      ),
                      const SizedBox(width: 12),
                      // Emoji
                      Text(
                        habit.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 12),
                      // Name
                      Expanded(
                        child: Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      // Position indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFA94A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Color(0xFFFFA94A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating Save Button (only shows when there are changes)
          if (_hasChanges)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _hasChanges ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _saveOrder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA94A), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFFA94A).withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Save Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
