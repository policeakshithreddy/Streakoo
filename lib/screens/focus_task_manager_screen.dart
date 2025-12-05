import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/habit.dart';

/// Screen for managing which habits are focus tasks
/// Focus tasks get streak freeze protection
class FocusTaskManagerScreen extends StatefulWidget {
  const FocusTaskManagerScreen({super.key});

  @override
  State<FocusTaskManagerScreen> createState() => _FocusTaskManagerScreenState();
}

class _FocusTaskManagerScreenState extends State<FocusTaskManagerScreen> {
  static const int maxFocusTasks = 5;
  List<Habit> _workingHabits = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  void _loadHabits() {
    final appState = context.read<AppState>();
    _workingHabits = appState.habits.map((h) => h).toList();

    // Sort: focus tasks first (by priority), then others
    _workingHabits.sort((a, b) {
      if (a.isFocusTask && !b.isFocusTask) return -1;
      if (!a.isFocusTask && b.isFocusTask) return 1;
      if (a.isFocusTask && b.isFocusTask) {
        return (a.focusTaskPriority ?? 0).compareTo(b.focusTaskPriority ?? 0);
      }
      return 0;
    });
  }

  int get _focusTaskCount => _workingHabits.where((h) => h.isFocusTask).length;

  bool get _canAddMore => _focusTaskCount < maxFocusTasks;

  void _toggleFocusTask(Habit habit) {
    setState(() {
      final index = _workingHabits.indexWhere((h) => h.id == habit.id);
      if (index == -1) return;

      if (habit.isFocusTask) {
        // Remove from focus
        _workingHabits[index] = habit.copyWith(
          isFocusTask: false,
          focusTaskPriority: null,
        );
      } else {
        // Add to focus (if under limit)
        if (!_canAddMore) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum $maxFocusTasks focus tasks allowed'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        _workingHabits[index] = habit.copyWith(
          isFocusTask: true,
          focusTaskPriority: _focusTaskCount, // Add at end
        );
      }

      _hasChanges = true;
      _reorderFocusTasks();
    });
  }

  void _reorderFocusTasks() {
    // Recalculate priorities for focus tasks
    final focusTasks = _workingHabits.where((h) => h.isFocusTask).toList();

    for (var i = 0; i < focusTasks.length; i++) {
      final index = _workingHabits.indexWhere((h) => h.id == focusTasks[i].id);
      _workingHabits[index] = _workingHabits[index].copyWith(
        focusTaskPriority: i,
      );
    }

    // Re-sort
    _workingHabits.sort((a, b) {
      if (a.isFocusTask && !b.isFocusTask) return -1;
      if (!a.isFocusTask && b.isFocusTask) return 1;
      if (a.isFocusTask && b.isFocusTask) {
        return (a.focusTaskPriority ?? 0).compareTo(b.focusTaskPriority ?? 0);
      }
      return 0;
    });
  }

  void _saveChanges() {
    final appState = context.read<AppState>();
    for (final habit in _workingHabits) {
      appState.updateHabit(habit);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusTasks = _workingHabits.where((h) => h.isFocusTask).toList();
    final regularTasks = _workingHabits.where((h) => !h.isFocusTask).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Focus Tasks'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Info banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'About Focus Tasks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '❄️ Streak freezes only protect your focus tasks\n'
                    '🎯 Choose 3-5 most important habits\n'
                    '💎 Regular tasks won\'t get freeze protection',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Focus task counter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Focus Tasks',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text('$_focusTaskCount / $maxFocusTasks'),
                    backgroundColor: _canAddMore
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : theme.colorScheme.error.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Focus tasks list (reorderable)
          if (focusTasks.isNotEmpty)
            SliverReorderableList(
              itemCount: focusTasks.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;

                  final item = focusTasks.removeAt(oldIndex);
                  focusTasks.insert(newIndex, item);

                  // Update working list
                  _workingHabits.removeWhere((h) => h.isFocusTask);
                  _workingHabits.insertAll(0, focusTasks);

                  _hasChanges = true;
                  _reorderFocusTasks();
                });
              },
              itemBuilder: (context, index) {
                final habit = focusTasks[index];
                return _FocusTaskTile(
                  key: ValueKey(habit.id),
                  habit: habit,
                  isFocus: true,
                  onToggle: () => _toggleFocusTask(habit),
                  index: index,
                );
              },
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No focus tasks yet.\nTap ⭐ on habits below to add them.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ),
              ),
            ),

          // Divider
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Divider(),
            ),
          ),

          // Regular tasks header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Other Habits',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.disabledColor,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Regular tasks list
          if (regularTasks.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final habit = regularTasks[index];
                  return _FocusTaskTile(
                    key: ValueKey(habit.id),
                    habit: habit,
                    isFocus: false,
                    onToggle: () => _toggleFocusTask(habit),
                  );
                },
                childCount: regularTasks.length,
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'All habits are focus tasks!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _FocusTaskTile extends StatelessWidget {
  final Habit habit;
  final bool isFocus;
  final VoidCallback onToggle;
  final int? index; // For reorderable list

  const _FocusTaskTile({
    super.key,
    required this.habit,
    required this.isFocus,
    required this.onToggle,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: isFocus
            ? ReorderableDragStartListener(
                index: index!,
                child: const Icon(Icons.drag_handle),
              )
            : null,
        title: Row(
          children: [
            Text(
              habit.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isFocus ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          habit.category,
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: Icon(
            isFocus ? Icons.star : Icons.star_outline,
            color: isFocus ? Colors.amber : theme.disabledColor,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
