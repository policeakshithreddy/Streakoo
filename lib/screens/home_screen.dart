import 'package:flutter/material.dart';
import 'dart:math';

import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:streakoo/providers/app_provider.dart';
import 'package:streakoo/providers/habit_provider.dart';
import 'package:streakoo/models/habit.dart';
import 'package:streakoo/tabs/daily_tracking_tab.dart';
import 'package:streakoo/tabs/progress_dashboard_tab.dart';
import 'package:streakoo/tabs/settings_tab.dart';
import 'package:streakoo/utils/constants.dart';
import 'package:streakoo/widgets/bottom_sheets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _habitListenerAdded = false;

  // Celebration state
  bool _celebrationDialogShown = false;
  DateTime? _lastAllDoneShownDate;

  @override
  void initState() {
    super.initState();
    // Listen to habit changes to check for celebrations
    // Defer registering the listener until after the first frame to avoid
    // using BuildContext synchronously during initState which can cause
    // framework lifecycle assertions.
    // Add the habit box listener after the first frame. Guard with mounted
    // and track whether we added it so dispose can safely remove it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context
            .read<HabitProvider>()
            .habitBoxNotifier
            .addListener(_checkCelebrations);
        _habitListenerAdded = true;
      } catch (_) {
        // If for some reason we can't add the listener, ignore — it's
        // non-fatal. The listener is best-effort for showing celebrations.
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_habitListenerAdded) {
      try {
        context.read<HabitProvider>().habitBoxNotifier.removeListener(
              _checkCelebrations,
            );
      } catch (_) {
        // ignore
      }
    }
    super.dispose();
  }

  void _checkCelebrations() {
    final habitProvider = context.read<HabitProvider>();
    final appProvider = context.read<AppProvider>();
    final today = DateTime.now();
    bool allDoneToday = habitProvider.areAllHabitsCompleted(today);

    if (allDoneToday) {
      // Show a small floating message once per day instead of the full
      // celebration dialog which in some environments can lead to a blank
      // screen; keep the trophy flow for challenge completion.
      final shownDate = _lastAllDoneShownDate;
      if (shownDate == null || !isSameDay(shownDate, today)) {
        final currentStreak = habitProvider.getOverallCurrentStreak();
        // Prepare random celebratory messages (one chosen per day)
        final messages = [
          '${currentStreak}d streak 🔥',
          '🎉 ${appProvider.userName}, $currentStreak day${currentStreak == 1 ? '' : 's'} strong!',
          '✨ $currentStreak day${currentStreak == 1 ? '' : 's'} — consistency wins',
        ];
        final rand = Random();
        final pick = messages[rand.nextInt(messages.length)];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(pick),
          ));
        }
        _lastAllDoneShownDate = today;
      }

      // Check for challenge completion (keep trophy flow)
      if (!appProvider.challengeCompleted) {
        int currentStreak = habitProvider.getOverallCurrentStreak();
        if (currentStreak >= appProvider.challengeLength) {
          _playTrophyCelebration();
          appProvider.completeChallenge();
        }
      }
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _playTrophyCelebration() {
    // Show trophy popup with options
    _showTrophyPopup();
  }

  Future<void> _showTrophyPopup() async {
    if (_celebrationDialogShown) return;
    _celebrationDialogShown = true;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset('assets/animations/trophy.json',
                      fit: BoxFit.contain)),
              const SizedBox(height: 12),
              Text('Congratulations! You completed the challenge!',
                  style: AppColors.headingStyle.copyWith(fontSize: 18),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(c).pop();
                    // User wants to start next challenge now. Run after pop and
                    // check mounted before using context-derived providers.
                    _pickNextChallenge().then((next) async {
                      if (next != null && next > 0) {
                        if (!mounted) return;
                        final prov = context.read<AppProvider>();
                        prov.setChallengeLength(next);
                        await prov.setChallengeCompleted(false);
                      }
                    });
                  },
                  child: const Text('Next challenge'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(c).pop();
                    // Later: nothing else to do
                  },
                  child: const Text('Later'),
                ),
              ])
            ]),
          ),
        );
      },
    );

    _celebrationDialogShown = false;
  }

  Future<int?> _pickNextChallenge() async {
    // show bottom sheet to pick 7/15/30
    return await showModalBottomSheet<int>(
      context: context,
      builder: (c) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Pick your next challenge',
                  style: AppColors.headingStyle),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElevatedButton(
                    onPressed: () => Navigator.of(c).pop(7),
                    child: const Text('7 days')),
                ElevatedButton(
                    onPressed: () => Navigator.of(c).pop(15),
                    child: const Text('15 days')),
                ElevatedButton(
                    onPressed: () => Navigator.of(c).pop(30),
                    child: const Text('30 days')),
              ])
            ]),
          ),
        );
      },
    );
  }

  // Manage habits modal
  void _openManageHabits() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) {
        final habitProvider = context.read<HabitProvider>();
        final TextEditingController newController = TextEditingController();
        // Default emoji for new habit entry (use sparkle emoji instead of check)
        String newEmoji = '✨';

        Future<String?> pickSystemEmojiLocal() async {
          return await showModalBottomSheet<String>(
            context: c,
            isScrollControlled: true,
            builder: (dctx) => const SystemEmojiSheet(),
          );
        }

        return Padding(
          padding: MediaQuery.of(c).viewInsets,
          child: SizedBox(
            height: MediaQuery.of(c).size.height * 0.75,
            child: Column(
              children: [
                AppBar(
                    title: const Text('Manage Habits'),
                    automaticallyImplyLeading: false),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: habitProvider.habitBoxNotifier,
                    builder: (context, box, _) {
                      final items = box.values.toList();
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final Habit h = items[i];
                          // Make each item dismissible (swipe to delete) and use a popup menu for edit/delete
                          return Dismissible(
                            key: ValueKey(h.hashCode + i),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.redAccent,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) async {
                              await h.delete();
                            },
                            child: ListTile(
                              leading: Text(h.iconName,
                                  style: const TextStyle(fontSize: 24)),
                              title: Text(h.name),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    // open inline editor bottom sheet
                                    final controller =
                                        TextEditingController(text: h.name);
                                    String emoji = h.iconName;
                                    await showModalBottomSheet<void>(
                                      context: c,
                                      isScrollControlled: true,
                                      builder: (editCtx) {
                                        return Padding(
                                          padding:
                                              MediaQuery.of(editCtx).viewInsets,
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(
                                                      controller: controller,
                                                      decoration:
                                                          const InputDecoration(
                                                              labelText:
                                                                  'Habit')),
                                                  const SizedBox(height: 12),
                                                  Row(children: [
                                                    Text(emoji,
                                                        style: const TextStyle(
                                                            fontSize: 24)),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(Icons
                                                          .emoji_emotions_outlined),
                                                      onPressed: () async {
                                                        // ignore: use_build_context_synchronously
                                                        final picked =
                                                            await pickSystemEmojiLocal();
                                                        if (picked != null &&
                                                            picked.isNotEmpty) {
                                                          emoji = picked;
                                                        }
                                                      },
                                                    )
                                                  ]),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        editCtx)
                                                                    .pop(),
                                                            child: const Text(
                                                                'Cancel')),
                                                        ElevatedButton(
                                                            onPressed:
                                                                () async {
                                                              h.name =
                                                                  controller
                                                                      .text
                                                                      .trim();
                                                              h.iconName =
                                                                  emoji;
                                                              final nav =
                                                                  Navigator.of(
                                                                      editCtx);
                                                              await h.save();
                                                              nav.pop();
                                                            },
                                                            child: const Text(
                                                                'Save'))
                                                      ])
                                                ]),
                                          ),
                                        );
                                      },
                                    );
                                    // Don't dispose here; avoid use-after-dispose
                                    // during sheet teardown animations.
                                  } else if (value == 'delete') {
                                    await h.delete();
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            controller: newController,
                            decoration:
                                const InputDecoration(hintText: 'New habit'))),
                    const SizedBox(width: 8),
                    // Only system emoji picker for new habit
                    IconButton(
                      icon:
                          Text(newEmoji, style: const TextStyle(fontSize: 22)),
                      onPressed: () async {
                        final p = await pickSystemEmojiLocal();
                        if (p != null && p.isNotEmpty) newEmoji = p;
                        setState(() {});
                      },
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final text = newController.text.trim();
                        if (text.isNotEmpty) {
                          await habitProvider.addHabit(Habit(
                              name: text,
                              iconName: newEmoji,
                              completedDays: []));
                          newController.clear();
                        }
                      },
                      child: const Text('Add'),
                    )
                  ]),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              DailyTrackingTab(),
              ProgressDashboardTab(),
              SettingsTab()
            ],
          ),
          // celebrations are shown as modal dialogs
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _openManageHabits,
              tooltip: 'Manage habits',
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }
}
