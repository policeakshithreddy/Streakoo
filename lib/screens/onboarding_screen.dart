// ignore_for_file: use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures, unnecessary_brace_in_string_interps

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:streakoo/providers/app_provider.dart';
import 'package:streakoo/providers/habit_provider.dart';
import 'package:streakoo/models/habit.dart';
import 'package:streakoo/models/app_settings.dart';
import 'package:streakoo/utils/constants.dart';
import 'package:streakoo/widgets/bottom_sheets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _AnimatedActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _AnimatedActionButton({required this.label, required this.onPressed});

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (d) {
        _onTapUp(d);
        widget.onPressed();
      },
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          child: Text(widget.label),
        ),
      ),
    );
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _habitController = TextEditingController();
  int _selectedChallengeDays = 0; // 0 = none, 7, 15, 30
  // Each habit is a map with 'name' and 'emoji'
  final List<Map<String, String>> _habitList = [
    {'name': 'Go to the gym', 'emoji': '🏋️'},
    {'name': 'Read 15 mins', 'emoji': '📚'},
    {'name': 'Drink 8 glasses of water', 'emoji': '💧'},
    {'name': 'Meditate', 'emoji': '🧘‍♂️'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _habitController.dispose();
    super.dispose();
  }

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page ?? 0.0;
      final idx = page.round();
      if (idx != _currentPage) {
        setState(() => _currentPage = idx);
      }
    });
  }

  // Default emoji to use when adding a new habit
  // Use a neutral sparkle emoji instead of the check mark
  String _newHabitEmoji = '✨';

  // We only support the system emoji input (device keyboard) for selection.

  Future<String?> _openSystemEmojiInput(BuildContext ctx,
      {String? initial}) async {
    // Best-effort approach: open a bottom sheet with a focused TextField so the
    // OS keyboard appears. Users should switch to their emoji keyboard and
    // pick an emoji. We cannot programmatically force the emoji selector on
    // every platform, but requesting focus and showing the keyboard is the
    // standard UX.
    // Use a self-contained sheet widget that owns its controller/focus node.
    final result = await showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      builder: (dctx) => SystemEmojiSheet(initial: initial),
    );
    return result;
  }

  Future<void> _editHabitDialog(int index) async {
    final habit = Map<String, String>.from(_habitList[index]);
    final controller = TextEditingController(text: habit['name']);
    String emoji = habit['emoji'] ?? '✨';

    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Habit')),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Emoji:'),
                const SizedBox(width: 8),
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () async {
                    final picked =
                        await _openSystemEmojiInput(context, initial: emoji);
                    if (picked != null && picked.isNotEmpty) {
                      setState(() => emoji = picked);
                    }
                  },
                  child: const Text('Change'),
                )
              ],
            )
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _habitList[index] = {
                  'name': controller.text.trim(),
                  'emoji': emoji
                };
              });
              Navigator.of(c).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Avoid disposing the dialog controller immediately to prevent use-after-
    // dispose timing issues with the widget tree during dialog teardown.
  }

  void _onContinue() {
    // Page indices: 0=welcome, 1=name, 2=habits, 3=challenge
    // Save name on the second page
    if (_pageController.page == 1.0) {
      if (_nameController.text.trim().isNotEmpty) {
        Provider.of<AppProvider>(context, listen: false)
            .setUserName(_nameController.text.trim());
      }
    }

    // Save challenge and finish onboarding on the last page
    if (_pageController.page == 3.0) {
      if (_selectedChallengeDays > 0) {
        _finishOnboarding();
      } else {
        // Show a snackbar if no challenge is selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a challenge to start!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Don't proceed
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  void _finishOnboarding() {
    // Add user-provided habits or defaults
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    if (_habitList.isNotEmpty) {
      for (var item in _habitList) {
        final name = item['name'] ?? '';
        final emoji = item['emoji'] ?? '✨';
        if (name.trim().isEmpty) continue;
        habitProvider.addHabit(
            Habit(name: name.trim(), iconName: emoji, completedDays: []));
      }
    } else {
      habitProvider.addDefaultHabits();
    }

    // Set challenge length and mark as onboarded
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.setChallengeLength(_selectedChallengeDays);
    appProvider.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage == 0)
            IconButton(
              tooltip: 'Import backup',
              icon: const Icon(Icons.file_upload_outlined),
              onPressed: () => _handleImport(),
            )
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: [
          _buildWelcomePage(),
          _buildNamePage(),
          _buildHabitsPage(),
          _buildChallengePage(),
        ],
      ),
    );
  }

  Widget _buildHabitsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Which habits would you like to build?",
            style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold) ??
                AppColors.headingStyle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _habitController,
                  decoration: InputDecoration(
                    hintText: 'Add a habit (e.g., Read 15 mins)',
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkCard
                        : Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Row(
                    children: [
                      _AnimatedActionButton(
                        label: 'Add',
                        onPressed: () async {
                          final text = _habitController.text.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              _habitList
                                  .add({'name': text, 'emoji': _newHabitEmoji});
                              _habitController.clear();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      // Only show the system emoji input button (user can open device emoji keyboard)
                      IconButton(
                        tooltip: 'Pick emoji (system keyboard)',
                        icon: Text(_newHabitEmoji,
                            style: const TextStyle(fontSize: 22)),
                        onPressed: () async {
                          final sys = await _openSystemEmojiInput(context,
                              initial: _newHabitEmoji);
                          if (sys != null && sys.isNotEmpty) {
                            setState(() => _newHabitEmoji = sys);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _habitList.asMap().entries.map((entry) {
              final i = entry.key;
              final h = entry.value;
              final display = '${h['emoji'] ?? ''} ${h['name'] ?? ''}';
              return GestureDetector(
                onTap: () => _editHabitDialog(i),
                child: Chip(
                  label: Text(display,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                  onDeleted: () => setState(() => _habitList.removeAt(i)),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  deleteIcon: Icon(Icons.close,
                      size: 18, color: Theme.of(context).colorScheme.onSurface),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: _AnimatedActionButton(
              label: 'Continue',
              onPressed: () {
                if (_habitList.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please add at least one habit or press Continue to use defaults.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                _onContinue();
              },
            ),
          )
        ],
      ),
    );
  }

  // Small animated button used across onboarding pages

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Streakoo!',
              style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 28, fontWeight: FontWeight.bold) ??
                  AppColors.headingStyle.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The app that helps you build habits and maintain your streak, one day at a time.',
              style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontSize: 18) ??
                  const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _onContinue,
              child: const Text('Get Started'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) return; // user cancelled

      String content;
      if (result.files.single.path != null) {
        content = await File(result.files.single.path!).readAsString();
      } else if (result.files.single.bytes != null) {
        content = utf8.decode(result.files.single.bytes!);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to read selected file')));
        return;
      }

      final Map<String, dynamic> payload = jsonDecode(content);

      // Basic validation
      if (!payload.containsKey('habits') ||
          !payload.containsKey('appSettings')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid backup file')));
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Import Backup'),
          content: const Text(
              'Importing will overwrite existing habits and settings. Do you want to continue?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('Import')),
          ],
        ),
      );
      if (confirm != true) return;

      // Show loading dialog with a small animation/quote
      final quotes = [
        'Small steps every day.',
        'Consistency beats intensity.',
        'One day at a time.',
        'Progress, not perfection.'
      ];
      final r = Random();
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(quotes[r.nextInt(quotes.length)]),
              ],
            ),
          ),
        ),
      );

      // Perform import
      try {
        // Habits
        final habitBox = Hive.box<Habit>(kHabitBoxName);
        await habitBox.clear();
        final List<dynamic> habits = payload['habits'];
        for (var h in habits) {
          final name = h['name'] ?? '';
          final iconName = h['iconName'] ?? '';
          final completedRaw = h['completedDays'] as List<dynamic>? ?? [];
          final completed = completedRaw
              .map<DateTime>((e) => DateTime.parse(e as String))
              .toList();
          final habit =
              Habit(name: name, iconName: iconName, completedDays: completed);
          await habitBox.add(habit);
        }

        // Settings
        final settingsBox = Hive.box(kAppSettingsBoxName);
        final Map<String, dynamic> s =
            Map<String, dynamic>.from(payload['appSettings']);
        final appSettings = AppSettings(
          hasOnboarded: s['hasOnboarded'] ?? true,
          userName: s['userName'] ?? 'Friend',
          challengeLength: s['challengeLength'] ?? 7,
          challengeCompleted: s['challengeCompleted'] ?? false,
        );
        await settingsBox.put(0, appSettings);

        // Streak events
        final streakBox = await Hive.openBox('streak_events');
        await streakBox.clear();
        final List<dynamic> streaks = payload['streak_events'] ?? [];
        for (var e in streaks) {
          await streakBox.add(e);
        }

        // Close loading dialog
        if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();

        // Show success and refresh onboarding (show welcome with imported name)
        if (mounted) {
          Provider.of<AppProvider>(context, listen: false)
              .setUserName(appSettings.userName);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Import complete')));
        }
      } catch (e) {
        if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import error: $e')));
    }
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What should we call you?",
            style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold) ??
                AppColors.headingStyle,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard
                  : Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onContinue,
              child: const Text('Continue'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChallengePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Start your first challenge!",
            style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold) ??
                AppColors.headingStyle,
          ),
          const SizedBox(height: 8),
          Text(
            "Commit to your new habits for a set period.",
            style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 16) ??
                const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildChallengeOption(7),
          const SizedBox(height: 16),
          _buildChallengeOption(15),
          const SizedBox(height: 16),
          _buildChallengeOption(30),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onContinue,
              child: const Text('Start My Streak!'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChallengeOption(int days) {
    final bool isSelected = _selectedChallengeDays == days;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChallengeDays = days;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // FIX: Changed 'circle_outline' to 'circle_outlined'
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined),
            const SizedBox(width: 16),
            Text(
              '$days Day Challenge',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ],
        ),
      ),
    );
  }
}
