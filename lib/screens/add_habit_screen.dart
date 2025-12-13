import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/habit_data.dart';
import '../models/habit.dart';
import '../state/app_state.dart';
import '../widgets/emoji_picker_widget.dart';
import '../services/health_service.dart';
import '../widgets/ai_habit_assistant_modal.dart';
import 'habit_templates_screen.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? existing;

  const AddHabitScreen({
    super.key,
    this.existing,
  });

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  // Orange theme colors for Templates button
  static const _primaryOrange = Color(0xFFFFA94A);

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    // Initialize keys for each category
    for (var category in habitCategories) {
      _categoryKeys[category.id] = GlobalKey();
    }

    // If editing, we might want to show the form directly, but for now
    // let's assume this screen is mostly for adding new habits.
    // If 'existing' is passed, we should probably just open the form immediately.
    if (widget.existing != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCustomHabitForm(existing: widget.existing);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String categoryId) {
    // Wait for next frame to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _categoryKeys[categoryId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration:
              const Duration(milliseconds: 600), // Slower for better visual
          curve: Curves.easeInOutCubic, // Smoother curve
          alignment: 0.0, // Align to top
        );
      }
    });
  }

  void _showCustomHabitForm(
      {Habit? existing,
      String? prefillName,
      String? prefillEmoji,
      String? prefillCategory}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomHabitForm(
        existing: existing,
        prefillName: prefillName,
        prefillEmoji: prefillEmoji,
        prefillCategory: prefillCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'New Habit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Templates Button with new style
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HabitTemplatesScreen(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _primaryOrange, // "boundaries... light orange"
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryOrange.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: _primaryOrange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Templates',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Quick Navigation
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: habitCategories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => _scrollToCategory(category.id),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.iconEmoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Scrollable Categories
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                children: habitCategories.map((category) {
                  return Column(
                    key: _categoryKeys[category.id], // Assign GlobalKey
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Header
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category.iconEmoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    category.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category Suggestions
                      ...category.suggestions.map((suggestion) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191919),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              // "bowdaries of it should be light orange"
                              color: _primaryOrange.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _showCustomHabitForm(
                                  prefillName: suggestion.name,
                                  prefillEmoji: suggestion.emoji,
                                  prefillCategory: suggestion.targetCategory ??
                                      category.name,
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: theme.scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        suggestion.emoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            suggestion.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            suggestion.subtitle,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      color:
                                          _primaryOrange.withValues(alpha: 0.8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomHabitForm(),
        backgroundColor: const Color(0xFF191919),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create custom habit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _CustomHabitForm extends StatefulWidget {
  final Habit? existing;
  final String? prefillName;
  final String? prefillEmoji;
  final String? prefillCategory;

  const _CustomHabitForm({
    this.existing,
    this.prefillName,
    this.prefillEmoji,
    this.prefillCategory,
  });

  @override
  State<_CustomHabitForm> createState() => _CustomHabitFormState();
}

class _CustomHabitFormState extends State<_CustomHabitForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emojiCtrl = TextEditingController(text: '🔥');
  final TextEditingController _goalValueCtrl = TextEditingController();
  final TextEditingController _habitGoalCtrl = TextEditingController();

  // Goal AI suggestion state
  bool _isLoadingGoalSuggestion = false;

  // Frequency
  String _frequency = 'Daily'; // Daily, Weekly, Monthly
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // 1=Mon, 7=Sun

  // Reminder
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  // Health
  bool _isHealthTracked = false;
  HealthMetricType? _healthMetric;

  String _category = 'General';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final h = widget.existing!;
      _nameCtrl.text = h.name;
      _emojiCtrl.text = h.emoji;
      _category = h.category;
      _selectedDays = List.from(h.frequencyDays);
      _reminderEnabled = h.reminderEnabled;

      if (h.reminderTime != null) {
        final parts = h.reminderTime!.split(':');
        _reminderTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      // Health
      _isHealthTracked = h.isHealthTracked;
      _healthMetric = h.healthMetric;
      if (h.healthGoalValue != null) {
        _goalValueCtrl.text = h.healthGoalValue.toString();
      }
      // Habit Goal
      if (h.habitGoal != null) {
        _habitGoalCtrl.text = h.habitGoal!;
      }

      // Determine frequency label
      if (_selectedDays.length == 7) {
        _frequency = 'Daily';
      } else {
        _frequency = 'Weekly';
      }
    } else {
      if (widget.prefillName != null) _nameCtrl.text = widget.prefillName!;
      if (widget.prefillEmoji != null) _emojiCtrl.text = widget.prefillEmoji!;
      if (widget.prefillCategory != null) {
        _category = widget.prefillCategory!;
        if (_category == 'Health' || _category == 'Sports') {
          _isHealthTracked = true;
          // Set default metric based on name if possible
          if (_nameCtrl.text.toLowerCase().contains('step')) {
            _healthMetric = HealthMetricType.steps;
            _goalValueCtrl.text = '10000';
          } else if (_nameCtrl.text.toLowerCase().contains('sleep')) {
            _healthMetric = HealthMetricType.sleep;
            _goalValueCtrl.text = '8';
          } else if (_nameCtrl.text.toLowerCase().contains('run') ||
              _nameCtrl.text.toLowerCase().contains('walk') ||
              _nameCtrl.text.toLowerCase().contains('cycl')) {
            _healthMetric = HealthMetricType.distance;
            _goalValueCtrl.text = '5';
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _goalValueCtrl.dispose();
    _habitGoalCtrl.dispose();
    super.dispose();
  }

  void _openAiAssistant() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name first')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiHabitAssistantModal(
        habitName: _nameCtrl.text.trim(),
        category: _category,
        onApply: (goal, reminderTimeStr, healthVal, healthMet, focusDur) {
          setState(() {
            _habitGoalCtrl.text = goal;

            // Apply reminder
            if (reminderTimeStr != null) {
              _reminderEnabled = true;
              final parts = reminderTimeStr.split(':');
              if (parts.length == 2) {
                final h = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                if (h != null && m != null) {
                  _reminderTime = TimeOfDay(hour: h, minute: m);
                }
              }
            }

            // Apply health goal
            if (healthVal != null && healthMet != null) {
              _isHealthTracked = true;
              _healthMetric = healthMet;
              _goalValueCtrl.text = healthVal.toInt().toString();
            }

            // Focus duration (if implemented in UI state in future)
            // if (focusDur != null) {}
          });
        },
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    final name = _nameCtrl.text.trim();
    final emoji =
        _emojiCtrl.text.trim().isEmpty ? '🔥' : _emojiCtrl.text.trim();

    final reminderTimeStr =
        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

    double? healthGoal;
    if (_isHealthTracked && _goalValueCtrl.text.isNotEmpty) {
      healthGoal = double.tryParse(_goalValueCtrl.text);
    }

    // Habit Goal
    final habitGoalText = _habitGoalCtrl.text.trim().isNotEmpty
        ? _habitGoalCtrl.text.trim()
        : null;

    if (widget.existing == null) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final habit = Habit(
        id: id,
        name: name,
        emoji: emoji,
        category: _category,
        frequencyDays: _selectedDays,
        reminderEnabled: _reminderEnabled,
        reminderTime: _reminderEnabled ? reminderTimeStr : null,
        isHealthTracked: _isHealthTracked,
        healthMetric: _healthMetric,
        healthGoalValue: healthGoal,
        habitGoal: habitGoalText,
      );
      appState.addHabit(habit);
    } else {
      final updated = widget.existing!.copyWith(
        name: name,
        emoji: emoji,
        category: _category,
        frequencyDays: _selectedDays,
        reminderEnabled: _reminderEnabled,
        reminderTime: _reminderEnabled ? reminderTimeStr : null,
        isHealthTracked: _isHealthTracked,
        healthMetric: _healthMetric,
        healthGoalValue: healthGoal,
        habitGoal: habitGoalText,
      );
      appState.updateHabit(updated);
    }

    Navigator.of(context).pop(); // Close sheet
    if (widget.existing == null) {
      Navigator.of(context).pop(); // Close AddHabitScreen if creating new
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.existing != null
                        ? 'Edit Habit'
                        : 'Create Custom Habit',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Habit Name + Emoji
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: IconButton(
                      icon: Text(
                        _emojiCtrl.text.isEmpty ? '🔥' : _emojiCtrl.text,
                        style: const TextStyle(fontSize: 32),
                      ),
                      onPressed: () async {
                        final picked = await showDialog<String>(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: theme.scaffoldBackgroundColor,
                            child: EmojiPickerWidget(
                              onEmojiSelected: (emoji) {
                                Navigator.pop(context, emoji);
                              },
                            ),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            _emojiCtrl.text = picked;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      cursorColor: const Color(0xFFFFA94A), // Brand orange
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'e.g. Read 10 pages',
                        hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFFFFA94A), width: 2),
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a name'
                          : null,
                    ),
                  ),
                ],
              ),

              // Category Selector
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text(
                  'Category',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Color(0xFFFFA94A), width: 2),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: habitCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.name,
                    child: Row(
                      children: [
                        Text(cat.iconEmoji),
                        const SizedBox(width: 8),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                      // Reset health tracking if not relevant
                      if (_category != 'Health' && _category != 'Sports') {
                        _isHealthTracked = false;
                      }
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // Habit Goal Field (for Sports/Health categories)
              if (_category == 'Health' || _category == 'Sports') ...[
                Row(
                  children: [
                    const Text(
                      'Habit Goal',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191919),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFFA94A), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 12, color: Color(0xFFFFA94A)),
                          SizedBox(width: 4),
                          Text(
                            'Smart AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a specific, measurable goal for this habit',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _habitGoalCtrl,
                        maxLines: 2,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'e.g., Run 5km in under 30 minutes',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: Color(0xFFFFA94A), width: 2),
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // AI Suggestion Button
                    GestureDetector(
                      onTap: _isLoadingGoalSuggestion ? null : _openAiAssistant,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919), // Black
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFFFA94A),
                              width: 1.5), // Orange border
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isLoadingGoalSuggestion
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Frequency Selector
              const Text(
                'Frequency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: ['Daily', 'Weekly', 'Monthly'].map((freq) {
                  final isSelected = _frequency == freq;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(freq),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _frequency = freq;
                            if (freq == 'Daily') {
                              _selectedDays = [1, 2, 3, 4, 5, 6, 7];
                            }
                          });
                        }
                      },
                      backgroundColor: theme.cardColor,
                      selectedColor: theme.colorScheme.primary,
                      checkmarkColor: theme.colorScheme.onPrimary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide.none,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Day Selector
              Text(
                'Choose at least 1 day',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DayToggle(
                    label: 'M',
                    day: 1,
                    isSelected: _selectedDays.contains(1),
                    onTap: _toggleDay,
                    isEnabled: _frequency != 'Daily',
                    theme: theme,
                  ),
                  _DayToggle(
                    label: 'T',
                    day: 2,
                    isSelected: _selectedDays.contains(2),
                    onTap: _toggleDay,
                    isEnabled: _frequency != 'Daily',
                    theme: theme,
                  ),
                  _DayToggle(
                    label: 'W',
                    day: 3,
                    isSelected: _selectedDays.contains(3),
                    onTap: _toggleDay,
                    isEnabled: _frequency != 'Daily',
                    theme: theme,
                  ),
                  _DayToggle(
                    label: 'T',
                    day: 4,
                    isSelected: _selectedDays.contains(4),
                    onTap: _toggleDay,
                    isEnabled: _frequency != 'Daily',
                    theme: theme,
                  ),
                  _DayToggle(
                    label: 'F',
                    day: 5,
                    isSelected: _selectedDays.contains(5),
                    onTap: _toggleDay,
                    isEnabled: _frequency != 'Daily',
                    theme: theme,
                  ),
                  _DayToggle(
                    label: 'S',
                    day: 6,
                    isSelected: _selectedDays.contains(6),
                    onTap: _toggleDay,
                    isEnabled: _frequency != 'Daily',
                    theme: theme,
                  ),
                  _DayToggle(
                    label: 'S',
                    day: 7,
                    isSelected: _selectedDays.contains(7),
                    onTap: _toggleDay,
                    isEnabled: _frequency != 'Daily',
                    theme: theme,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Health Goal Integration
              if (_category == 'Health' || _category == 'Sports') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Health Goal',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: _isHealthTracked,
                      onChanged: (val) =>
                          setState(() => _isHealthTracked = val),
                      activeThumbColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
                if (_isHealthTracked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Metric Type',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<HealthMetricType>(
                          initialValue: _healthMetric,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: HealthMetricType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _healthMetric = val),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Daily Target',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _goalValueCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'e.g. 10000',
                            suffixText: _healthMetric?.name == 'steps'
                                ? 'steps'
                                : _healthMetric?.name == 'sleep'
                                    ? 'hours'
                                    : 'units',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // Reminder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminder',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: _reminderEnabled,
                    onChanged: (val) => setState(() => _reminderEnabled = val),
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ],
              ),

              if (_reminderEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                      );
                      if (time != null) {
                        setState(() => _reminderTime = time);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 20, color: theme.colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text(
                            _reminderTime.format(context),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down,
                              color: theme.colorScheme.onSurface),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.existing != null ? 'Save Changes' : 'Create habit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDay(int day) {
    if (_frequency == 'Daily') return;

    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        }
      } else {
        _selectedDays.add(day);
      }
    });
  }
}

class _DayToggle extends StatelessWidget {
  final String label;
  final int day;
  final bool isSelected;
  final Function(int) onTap;
  final bool isEnabled;
  final ThemeData theme;

  const _DayToggle({
    required this.label,
    required this.day,
    required this.isSelected,
    required this.onTap,
    required this.isEnabled,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? () => onTap(day) : null,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
