import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/habit_template.dart';
import '../services/groq_ai_service.dart';
import '../services/ai_goal_parser_service.dart';
import '../services/health_service.dart';

/// Result from the confirmation page
class TemplateConfirmationResult {
  final bool confirmed;
  final Map<String, HabitConfirmationData> habitData; // template.id -> data

  const TemplateConfirmationResult({
    required this.confirmed,
    required this.habitData,
  });
}

/// Confirmation data for a single habit
class HabitConfirmationData {
  final String? goal;
  final double? healthGoalValue;
  final HealthMetricType? healthMetric;
  final String? reminderTime; // HH:MM format
  final int? focusModeDuration; // Duration in minutes for focus mode

  const HabitConfirmationData({
    this.goal,
    this.healthGoalValue,
    this.healthMetric,
    this.reminderTime,
    this.focusModeDuration,
  });
}

/// A single habit goal editor item with parsed data
class _HabitGoalItem {
  final HabitTemplate template;
  String? goal;
  ParsedGoalData? parsedData;
  bool isLoading;
  bool isSkipped;
  bool healthGoalEnabled; // User toggle for health goal
  bool reminderEnabled; // User toggle for reminder
  bool focusModeEnabled; // User toggle for focus mode

  _HabitGoalItem({
    required this.template,
    this.goal,
    this.isLoading = false,
  })  : isSkipped = false,
        healthGoalEnabled = false,
        reminderEnabled = false,
        focusModeEnabled = false;
}

/// Confirmation page for adding template pack with AI-generated goals
class TemplateConfirmationPage extends StatefulWidget {
  final HabitTemplatePack pack;

  const TemplateConfirmationPage({
    super.key,
    required this.pack,
  });

  static Future<TemplateConfirmationResult?> show({
    required BuildContext context,
    required HabitTemplatePack pack,
  }) {
    return Navigator.of(context).push<TemplateConfirmationResult>(
      MaterialPageRoute(
        builder: (context) => TemplateConfirmationPage(pack: pack),
      ),
    );
  }

  @override
  State<TemplateConfirmationPage> createState() =>
      _TemplateConfirmationPageState();
}

class _TemplateConfirmationPageState extends State<TemplateConfirmationPage> {
  late List<_HabitGoalItem> _habitItems;
  bool _isGeneratingAll = true;
  final _parser = AiGoalParserService.instance;

  // Theme colors
  static const _primaryGradient = [Color(0xFF8B5CF6), Color(0xFFEC4899)];
  static const _accentColor = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _initializeHabits();
    _generateAllGoals();
  }

  void _initializeHabits() {
    _habitItems = widget.pack.habits.map((template) {
      return _HabitGoalItem(
        template: template,
        goal: template.suggestedGoal,
        isLoading: template.suggestedGoal == null,
      );
    }).toList();
  }

  Future<void> _generateAllGoals() async {
    setState(() => _isGeneratingAll = true);

    // Generate goals for habits that don't have one
    final futures = <Future<void>>[];

    for (int i = 0; i < _habitItems.length; i++) {
      final item = _habitItems[i];
      if (item.goal == null && !item.isSkipped) {
        futures.add(_generateGoalForItem(i));
      } else if (item.goal != null) {
        // Parse existing goal
        final parsed = _parser.parseGoal(item.goal!);
        setState(() {
          _habitItems[i].parsedData = parsed;
          _habitItems[i].healthGoalEnabled = parsed.hasHealthGoal;
          _habitItems[i].reminderEnabled = parsed.hasReminder;
          _habitItems[i].focusModeEnabled = parsed.hasFocusDuration;
        });
      }
    }

    await Future.wait(futures);

    if (mounted) {
      setState(() => _isGeneratingAll = false);
    }
  }

  Future<void> _generateGoalForItem(int index) async {
    final item = _habitItems[index];

    try {
      final goal = await GroqAIService.instance.generateHabitGoalSuggestion(
        habitName: item.template.name,
        category: item.template.category,
        existingDescription: item.template.description,
      );

      if (mounted && goal != null) {
        final parsed = _parser.parseGoal(goal);
        setState(() {
          _habitItems[index].goal = goal;
          _habitItems[index].parsedData = parsed;
          _habitItems[index].healthGoalEnabled = parsed.hasHealthGoal;
          _habitItems[index].reminderEnabled = parsed.hasReminder;
          _habitItems[index].focusModeEnabled = parsed.hasFocusDuration;
          _habitItems[index].isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _habitItems[index].isLoading = false;
        });
      }
    }
  }

  void _confirmAndAdd() {
    HapticFeedback.mediumImpact();

    final habitData = <String, HabitConfirmationData>{};
    for (final item in _habitItems) {
      if (!item.isSkipped) {
        habitData[item.template.id] = HabitConfirmationData(
          goal: item.goal,
          healthGoalValue:
              item.healthGoalEnabled ? item.parsedData?.healthGoalValue : null,
          healthMetric:
              item.healthGoalEnabled ? item.parsedData?.healthMetric : null,
          reminderTime: item.reminderEnabled
              ? item.parsedData?.suggestedReminderTime
              : null,
          focusModeDuration:
              item.focusModeEnabled ? item.parsedData?.focusDuration : null,
        );
      }
    }

    Navigator.of(context).pop(TemplateConfirmationResult(
      confirmed: true,
      habitData: habitData,
    ));
  }

  void _cancel() {
    Navigator.of(context).pop(null);
  }

  void _toggleSkip(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _habitItems[index].isSkipped = !_habitItems[index].isSkipped;
    });
  }

  void _toggleHealthGoal(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _habitItems[index].healthGoalEnabled =
          !_habitItems[index].healthGoalEnabled;
    });
  }

  void _toggleReminder(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _habitItems[index].reminderEnabled = !_habitItems[index].reminderEnabled;
    });
  }

  void _toggleFocusMode(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _habitItems[index].focusModeEnabled =
          !_habitItems[index].focusModeEnabled;
    });
  }

  void _editGoal(int index) async {
    final item = _habitItems[index];
    final controller = TextEditingController(text: item.goal ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF191919) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Text(item.template.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Edit Goal',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Enter your goal...',
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: _accentColor),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      final newGoal = result.isNotEmpty ? result : null;
      final parsed = newGoal != null ? _parser.parseGoal(newGoal) : null;

      setState(() {
        _habitItems[index].goal = newGoal;
        _habitItems[index].parsedData = parsed;
        _habitItems[index].healthGoalEnabled = parsed?.hasHealthGoal ?? false;
        _habitItems[index].reminderEnabled = parsed?.hasReminder ?? false;
      });
    }
  }

  void _regenerateGoal(int index) async {
    HapticFeedback.selectionClick();
    setState(() {
      _habitItems[index].isLoading = true;
    });
    await _generateGoalForItem(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitsWithGoals =
        _habitItems.where((i) => !i.isSkipped && i.goal != null).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.grey[50],
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
                          _primaryGradient[0].withValues(alpha: 0.1),
                          const Color(0xFF0D0D0D),
                        ]
                      : [
                          _primaryGradient[0].withValues(alpha: 0.05),
                          Colors.grey[50]!,
                        ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _cancel,
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.pack.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.pack.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.pack.habits.length} habits • Smart goals with auto-detection',
                              style: TextStyle(
                                fontSize: 13,
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
                ),

                // AI Badge
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryGradient[0].withValues(alpha: 0.15),
                        _primaryGradient[1].withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Color(0xFF8B5CF6), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isGeneratingAll
                              ? 'Generating smart goals...'
                              : 'AI detected health goals & reminders ✨',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      if (_isGeneratingAll)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                const SizedBox(height: 16),

                // Habit list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _habitItems.length,
                    itemBuilder: (context, index) {
                      final item = _habitItems[index];
                      return _buildHabitCard(item, index, isDark)
                          .animate(delay: (index * 50).ms)
                          .fadeIn()
                          .slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),

                // Bottom action bar
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF191919) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$habitsWithGoals of ${_habitItems.length} habits',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'ready to add',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          gradient:
                              const LinearGradient(colors: _primaryGradient),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryGradient[0].withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          onPressed: _isGeneratingAll ? null : _confirmAndAdd,
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text(
                            'Add Pack',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.white54,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(_HabitGoalItem item, int index, bool isDark) {
    final isSkipped = item.isSkipped;
    final parsed = item.parsedData;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: isSkipped ? 0.02 : 0.05)
            : isSkipped
                ? Colors.grey[100]
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSkipped
              ? Colors.transparent
              : _accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        _accentColor.withValues(alpha: isSkipped ? 0.05 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      item.template.emoji,
                      style: TextStyle(
                        fontSize: 20,
                        color: isSkipped ? Colors.grey : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.template.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSkipped
                              ? Colors.grey
                              : (isDark ? Colors.white : Colors.black87),
                          decoration:
                              isSkipped ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        item.template.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Skip toggle
                IconButton(
                  onPressed: () => _toggleSkip(index),
                  icon: Icon(
                    isSkipped
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    color: isSkipped ? Colors.green : Colors.grey,
                    size: 22,
                  ),
                  tooltip: isSkipped ? 'Include habit' : 'Skip habit',
                ),
              ],
            ),
          ),

          // Goal section
          if (!isSkipped)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: item.isLoading
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                _accentColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Generating goal...',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Goal text
                        Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 14,
                              color: _accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Goal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _accentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.goal ?? 'No goal set',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: item.goal != null
                                  ? (isDark ? Colors.white70 : Colors.black87)
                                  : Colors.grey,
                              fontStyle:
                                  item.goal == null ? FontStyle.italic : null,
                            ),
                          ),
                        ),

                        // Auto-detected features
                        if (parsed != null &&
                            (parsed.hasHealthGoal || parsed.hasReminder)) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Auto-detected:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Health goal toggle
                          if (parsed.hasHealthGoal)
                            _buildToggleChip(
                              icon: Icons.trending_up,
                              label:
                                  'Health Goal: ${_parser.getHealthGoalDisplayString(parsed.healthGoalValue!, parsed.healthMetric!)}',
                              isEnabled: item.healthGoalEnabled,
                              onToggle: () => _toggleHealthGoal(index),
                              isDark: isDark,
                            ),

                          if (parsed.hasHealthGoal && parsed.hasReminder)
                            const SizedBox(height: 8),

                          // Reminder toggle
                          if (parsed.hasReminder)
                            _buildToggleChip(
                              icon: Icons.alarm,
                              label:
                                  'Reminder: ${_parser.getReminderDisplayTime(parsed.suggestedReminderTime!)}',
                              isEnabled: item.reminderEnabled,
                              onToggle: () => _toggleReminder(index),
                              isDark: isDark,
                            ),

                          if ((parsed.hasHealthGoal || parsed.hasReminder) &&
                              parsed.hasFocusDuration)
                            const SizedBox(height: 8),

                          // Focus mode toggle
                          if (parsed.hasFocusDuration)
                            _buildToggleChip(
                              icon: Icons.timer_outlined,
                              label:
                                  'Focus Mode: ${parsed.focusDuration} min timer',
                              isEnabled: item.focusModeEnabled,
                              onToggle: () => _toggleFocusMode(index),
                              isDark: isDark,
                            ),
                        ],

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildActionButton(
                              icon: Icons.edit_outlined,
                              label: 'Edit',
                              onTap: () => _editGoal(index),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.refresh,
                              label: 'Regenerate',
                              onTap: () => _regenerateGoal(index),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

          if (isSkipped)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Text(
                'This habit will not be added',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isEnabled
              ? const Color(0xFF27AE60).withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled
                ? const Color(0xFF27AE60)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isEnabled ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: isEnabled ? const Color(0xFF27AE60) : Colors.grey,
            ),
            const SizedBox(width: 10),
            Icon(
              icon,
              size: 14,
              color: isEnabled
                  ? const Color(0xFF27AE60)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isEnabled
                      ? const Color(0xFF27AE60)
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _accentColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
