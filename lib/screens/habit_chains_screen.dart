import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/habit_chain.dart';
import '../state/app_state.dart';

/// Screen to create and manage habit chains
class HabitChainsScreen extends StatefulWidget {
  const HabitChainsScreen({super.key});

  @override
  State<HabitChainsScreen> createState() => _HabitChainsScreenState();
}

class _HabitChainsScreenState extends State<HabitChainsScreen> {
  @override
  void initState() {
    super.initState();
    HabitChainService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Habit Chains'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateChainSheet(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: HabitChainService.instance,
        builder: (context, _) {
          final chains = HabitChainService.instance.chains;

          if (chains.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chains.length,
            itemBuilder: (context, index) {
              final chain = chains[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChainCard(
                  chain: chain,
                  onTap: () => _showChainDetails(context, chain),
                  onDelete: () => _deleteChain(chain),
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 100 * index),
                    duration: 400.ms,
                  )
                  .slideX(begin: 0.1, end: 0);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateChainSheet(context),
        icon: const Icon(Icons.link_rounded),
        label: const Text('New Chain'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.link_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Habit Chains Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Link habits together to build powerful routines.\n"After I do X, I\'ll do Y"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateChainSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Chain'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChainSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateChainSheet(),
    );
  }

  void _showChainDetails(BuildContext context, HabitChain chain) {
    // TODO: Show chain details/edit screen
  }

  void _deleteChain(HabitChain chain) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chain?'),
        content: Text('Are you sure you want to delete "${chain.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HabitChainService.instance.deleteChain(chain.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chain deleted')),
        );
      }
    }
  }
}

class _ChainCard extends StatelessWidget {
  final HabitChain chain;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChainCard({
    required this.chain,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    // Get habit details
    final habits = chain.habitIds
        .map((id) => appState.habits.where((h) => h.id == id).firstOrNull)
        .whereType<dynamic>()
        .toList();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chain.isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  color:
                      chain.isActive ? theme.colorScheme.primary : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chain.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Toggle
                Switch(
                  value: chain.isActive,
                  onChanged: (_) {
                    HabitChainService.instance.toggleChainActive(chain.id);
                  },
                ),
              ],
            ),

            if (chain.description != null) ...[
              const SizedBox(height: 8),
              Text(
                chain.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Chain visualization
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < habits.length; i++) ...[
                    _ChainHabitChip(
                      emoji: habits[i].emoji,
                      name: habits[i].name,
                      isCompleted: habits[i].completedToday,
                    ),
                    if (i < habits.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainHabitChip extends StatelessWidget {
  final String emoji;
  final String name;
  final bool isCompleted;

  const _ChainHabitChip({
    required this.emoji,
    required this.name,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey[100]),
        borderRadius: BorderRadius.circular(20),
        border: isCompleted
            ? Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child:
                  Icon(Icons.check_circle, size: 14, color: Color(0xFF4CAF50)),
            ),
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            name.length > 12 ? '${name.substring(0, 12)}...' : name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCompleted ? FontWeight.bold : null,
              color: isCompleted
                  ? const Color(0xFF4CAF50)
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateChainSheet extends StatefulWidget {
  const _CreateChainSheet();

  @override
  State<_CreateChainSheet> createState() => _CreateChainSheetState();
}

class _CreateChainSheetState extends State<_CreateChainSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _selectedHabitIds = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    final habits = appState.habits;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                Text(
                  'Create Chain',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _selectedHabitIds.length >= 2 ? _saveChain : null,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chain Name
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Chain Name',
                      hintText: 'e.g., Morning Routine',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description (optional)
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'What\'s this chain for?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // Chain Order Preview
                  if (_selectedHabitIds.isNotEmpty) ...[
                    Text(
                      'Chain Order:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedHabitIds.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _selectedHabitIds.removeAt(oldIndex);
                          _selectedHabitIds.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final habitId = _selectedHabitIds[index];
                        final habit = habits.firstWhere((h) => h.id == habitId);
                        return ListTile(
                          key: ValueKey(habitId),
                          leading: Text('${index + 1}.'),
                          title: Text('${habit.emoji} ${habit.name}'),
                          trailing: const Icon(Icons.drag_handle),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Available Habits
                  Text(
                    'Select Habits (${_selectedHabitIds.length}/min 2):',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: habits.map((habit) {
                      final isSelected = _selectedHabitIds.contains(habit.id);
                      return FilterChip(
                        selected: isSelected,
                        label: Text('${habit.emoji} ${habit.name}'),
                        onSelected: (selected) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (selected) {
                              _selectedHabitIds.add(habit.id);
                            } else {
                              _selectedHabitIds.remove(habit.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveChain() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a chain name')),
      );
      return;
    }

    if (_selectedHabitIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 habits')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    await HabitChainService.instance.createChain(
      name: _nameController.text,
      habitIds: _selectedHabitIds,
      description:
          _descController.text.isNotEmpty ? _descController.text : null,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Chain "${_nameController.text}" created!'),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }
}
