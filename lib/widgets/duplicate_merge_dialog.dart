import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/habit.dart';
import '../services/duplicate_habit_service.dart';

/// Dialog to display and merge duplicate habits - List View with Batch Processing
class DuplicateMergeDialog extends StatefulWidget {
  final List<DuplicateHabitPair> duplicates;
  final Function(List<MergeRequest> merges) onMergeAll;
  final VoidCallback onDismiss;

  const DuplicateMergeDialog({
    super.key,
    required this.duplicates,
    required this.onMergeAll,
    required this.onDismiss,
  });

  /// Show as a bottom sheet
  static Future<void> show(
    BuildContext context, {
    required List<DuplicateHabitPair> duplicates,
    required Function(List<MergeRequest> merges) onMergeAll,
    required VoidCallback onDismiss,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => DuplicateMergeDialog(
        duplicates: duplicates,
        onMergeAll: onMergeAll,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<DuplicateMergeDialog> createState() => _DuplicateMergeDialogState();
}

class _DuplicateMergeDialogState extends State<DuplicateMergeDialog> {
  // Track which pairs are selected for merging
  late Set<int> _selectedIndices;

  // Track merge options for each pair
  late Map<int, MergeOptions> _mergeOptions;

  // Track which cards are expanded
  late Set<int> _expandedIndices;

  @override
  void initState() {
    super.initState();
    // Initially, all pairs are selected
    _selectedIndices =
        Set.from(List.generate(widget.duplicates.length, (i) => i));
    // Default options for each pair
    _mergeOptions = {
      for (int i = 0; i < widget.duplicates.length; i++)
        i: MergeOptions.keepPrimary
    };
    // No cards expanded initially
    _expandedIndices = {};
  }

  int get _selectedCount => _selectedIndices.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryOrange = Color(0xFFFFA94A);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildHeader(theme, isDark, primaryOrange),

          Divider(
            height: 1,
            color:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          ),

          // List of duplicate pairs
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.duplicates.length,
              itemBuilder: (context, index) => _buildDuplicatePairCard(
                index,
                theme,
                isDark,
                primaryOrange,
              ),
            ),
          ),

          // Bottom action bar
          _buildActionBar(theme, primaryOrange),
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0, duration: 300.ms).fadeIn();
  }

  Widget _buildHeader(ThemeData theme, bool isDark, Color primaryOrange) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryOrange.withValues(alpha: 0.25),
                  primaryOrange.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.compare_arrows,
              color: Color(0xFFFFA94A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duplicate Habits Found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.duplicates.length} pairs detected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDismiss();
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicatePairCard(
    int index,
    ThemeData theme,
    bool isDark,
    Color primaryOrange,
  ) {
    final pair = widget.duplicates[index];
    final primary = pair.originalHabit;
    final secondary = pair.duplicateHabit;
    final isSelected = _selectedIndices.contains(index);
    final isExpanded = _expandedIndices.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? primaryOrange.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.black12),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Main card content (tappable to toggle selection)
          InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedIndices.remove(index);
                } else {
                  _selectedIndices.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                    activeColor: primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Habit pair preview
                  Expanded(
                    child: Row(
                      children: [
                        // Primary habit
                        _buildHabitMiniCard(primary, theme, isDark),

                        // Merge arrow
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.4),
                          ),
                        ),

                        // Secondary habit (to be merged)
                        _buildHabitMiniCard(secondary, theme, isDark,
                            isFaded: true),
                      ],
                    ),
                  ),

                  // Expand button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedIndices.remove(index);
                        } else {
                          _expandedIndices.add(index);
                        }
                      });
                    },
                    icon: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded settings section
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: _buildMergeOptionsSection(index, theme, isDark),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms, delay: (index * 50).ms);
  }

  Widget _buildHabitMiniCard(Habit habit, ThemeData theme, bool isDark,
      {bool isFaded = false}) {
    final opacity = isFaded ? 0.5 : 1.0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03 * opacity)
              : Colors.grey.withValues(alpha: 0.08 * opacity),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(habit.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: opacity),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '🔥 ${habit.streak}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.5 * opacity),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMergeOptionsSection(int index, ThemeData theme, bool isDark) {
    final pair = widget.duplicates[index];
    final primary = pair.originalHabit;
    final secondary = pair.duplicateHabit;
    final options = _mergeOptions[index] ?? MergeOptions.keepPrimary;

    final hasGoal = primary.habitGoal != null || secondary.habitGoal != null;
    final hasReminder =
        primary.reminderTime != null || secondary.reminderTime != null;
    final hasHealth = primary.isHealthTracked || secondary.isHealthTracked;

    if (!hasGoal && !hasReminder && !hasHealth) {
      return Text(
        'No automation settings to configure',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keep settings from:',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (hasGoal)
          _buildOptionToggle(
            title: '🎯 Goal',
            primaryValue: primary.habitGoal ?? 'None',
            secondaryValue: secondary.habitGoal ?? 'None',
            isKeepPrimary: options.keepGoalFrom == 'primary',
            onChanged: (keepPrimary) {
              setState(() {
                _mergeOptions[index] = MergeOptions(
                  keepGoalFrom: keepPrimary ? 'primary' : 'secondary',
                  keepReminderFrom: options.keepReminderFrom,
                  keepHealthGoalFrom: options.keepHealthGoalFrom,
                );
              });
            },
            theme: theme,
            isDark: isDark,
          ),
        if (hasReminder) ...[
          const SizedBox(height: 8),
          _buildOptionToggle(
            title: '⏰ Reminder',
            primaryValue: primary.reminderTime ?? 'None',
            secondaryValue: secondary.reminderTime ?? 'None',
            isKeepPrimary: options.keepReminderFrom == 'primary',
            onChanged: (keepPrimary) {
              setState(() {
                _mergeOptions[index] = MergeOptions(
                  keepGoalFrom: options.keepGoalFrom,
                  keepReminderFrom: keepPrimary ? 'primary' : 'secondary',
                  keepHealthGoalFrom: options.keepHealthGoalFrom,
                );
              });
            },
            theme: theme,
            isDark: isDark,
          ),
        ],
        if (hasHealth) ...[
          const SizedBox(height: 8),
          _buildOptionToggle(
            title: '❤️ Health',
            primaryValue: primary.healthGoalValue?.toInt().toString() ?? 'None',
            secondaryValue:
                secondary.healthGoalValue?.toInt().toString() ?? 'None',
            isKeepPrimary: options.keepHealthGoalFrom == 'primary',
            onChanged: (keepPrimary) {
              setState(() {
                _mergeOptions[index] = MergeOptions(
                  keepGoalFrom: options.keepGoalFrom,
                  keepReminderFrom: options.keepReminderFrom,
                  keepHealthGoalFrom: keepPrimary ? 'primary' : 'secondary',
                );
              });
            },
            theme: theme,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildOptionToggle({
    required String title,
    required String primaryValue,
    required String secondaryValue,
    required bool isKeepPrimary,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            title,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _buildToggleOption(
                label: 'Original',
                value: primaryValue,
                isSelected: isKeepPrimary,
                onTap: () => onChanged(true),
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildToggleOption(
                label: 'Duplicate',
                value: secondaryValue,
                isSelected: !isKeepPrimary,
                onTap: () => onChanged(false),
                theme: theme,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    const primaryOrange = Color(0xFFFFA94A);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryOrange.withValues(alpha: 0.15)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? primaryOrange
                  : (isDark ? Colors.white12 : Colors.black12),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? primaryOrange
                      : theme.textTheme.bodySmall?.color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 9,
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme, Color primaryOrange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Dismiss button
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDismiss();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: const Text('Dismiss'),
              ),
            ),

            const SizedBox(width: 12),

            // Merge All Selected button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _selectedCount > 0 ? _handleMergeAll : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryOrange.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.merge, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Merge Selected ($_selectedCount)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMergeAll() {
    // Build list of merge requests
    final mergeRequests = <MergeRequest>[];

    for (final index in _selectedIndices) {
      final pair = widget.duplicates[index];
      final options = _mergeOptions[index] ?? MergeOptions.keepPrimary;

      mergeRequests.add(MergeRequest(
        primaryId: pair.originalHabit.id,
        secondaryId: pair.duplicateHabit.id,
        options: options,
      ));
    }

    // Call the batch merge callback
    widget.onMergeAll(mergeRequests);

    // Close the dialog
    Navigator.pop(context);
    widget.onDismiss();
  }
}
