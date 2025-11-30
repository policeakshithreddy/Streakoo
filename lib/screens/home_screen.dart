import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/celebration_config.dart';
import '../models/streak_milestone.dart';
import '../models/level_reward.dart';
import '../state/app_state.dart';
import '../services/celebration_engine.dart';
import '../widgets/habit_card.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/milestone_celebration_overlay.dart';
import '../widgets/achievement_banner.dart';
import '../screens/level_up_reward_screen.dart';
import '../services/notification_engine.dart';
import '../widgets/level_badge.dart';
import '../utils/slide_route.dart';

import '../widgets/bouncy_button.dart';
import 'habit_detail_screen.dart';
import 'add_habit_screen.dart';
import 'settings_screen.dart';
import '../widgets/freeze_animation_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CelebrationConfig? _activeCelebration;
  StreakMilestone? _activeMilestone;
  String? _achievementBannerMessage;
  String? _achievementBannerEmoji;

  @override
  void initState() {
    super.initState();
    // Initialize notification engine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    // Initialize engine
    await NotificationEngine.instance.initialize();

    // Schedule focus task reminders
    if (mounted) {
      final appState = context.read<AppState>();
      await NotificationEngine.instance
          .scheduleFocusTaskReminders(appState.habits);

      // Sync health habits on startup
      appState.syncHealthHabits();

      print('✅ Notification Engine initialized & Focus Reminders scheduled');
    }
  }

  void _openDetails(BuildContext context, Habit habit) {
    Navigator.of(context).push(
      slideFromRight(HabitDetailScreen(habit: habit)),
    );
  }

  void _openAddHabit(BuildContext context) {
    Navigator.of(context).push(
      slideFromRight(const AddHabitScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      slideFromRight(const SettingsScreen()),
    );
  }

  Future<void> _handleComplete(
      BuildContext context, AppState appState, Habit habit) async {
    // Check state before completion
    final wasAllDoneBefore = appState.wasAllCompletedBeforeThis(habit);
    final oldLevel = appState.userLevel.level;

    // Complete the habit
    appState.completeHabit(habit);

    // Update notification pattern (for learning, but don't auto-schedule)
    NotificationEngine.instance.updatePattern(habit);

    // Check state after completion
    final newLevel = appState.userLevel.level;
    final isAllDoneAfter = appState.allCompletedToday;
    final xpGained = habit.actualXP;

    // Show XP snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Nice! "${habit.name}" done for today. +$xpGained XP! 🎯'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }

    // Trigger single habit celebration sound only (no overlay)
    CelebrationEngine.instance.celebrateSingleHabit(habit.name);

    // Priority 1: Check for level up (highest priority)
    if (newLevel > oldLevel) {
      final title = appState.userLevel.titleName;
      final rewards = LevelReward.getRewardsForLevel(newLevel);
      CelebrationEngine.instance.celebrateLevelUp(newLevel, title);

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _activeCelebration = CelebrationConfig.levelUp(newLevel, title);
        });

        // Show level-up reward screen after celebration
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() => _activeCelebration = null);
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LevelUpRewardScreen(
                newLevel: newLevel,
                title: title,
                userLevel: appState.userLevel,
                rewards: rewards,
              ),
            ),
          );
        }
      }
    }
    // Priority 2: Check for streak milestones
    else if (StreakMilestone.isMilestone(habit.streak)) {
      final milestone = StreakMilestone.forDays(habit.streak);
      if (milestone != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _activeMilestone = milestone;
          });
        }
      }
    }
    // Priority 3: Check for all habits completed
    else if (wasAllDoneBefore && isAllDoneAfter) {
      CelebrationEngine.instance.celebrateAllHabits();

      // Show Day Completed Toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Day Completed! You are unstoppable! 🎉🔥'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFFFFA94A),
            duration: Duration(seconds: 3),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _activeCelebration = CelebrationConfig.allHabits();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final habits = appState.sortedHabits; // Focus tasks appear first!
    final userLevel = appState.userLevel;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Streakoo 🔥'),
            actions: [
              // Level badge in app bar
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    // Show level details dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Your Progress'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LevelBadge(
                              userLevel: userLevel,
                              showProgress: true,
                              size: 120,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Total XP: ${appState.totalXP}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: LevelBadge(
                    userLevel: userLevel,
                    showProgress: false,
                    showTitle: false,
                    size: 40,
                  ),
                ),
              ),
              // Settings button
              IconButton(
                onPressed: () => _openSettings(context),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: habits.isEmpty
              ? const Center(
                  child: Text(
                    'No habits yet.\nTap + to create your first one!',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final habit = habits[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BouncyButton(
                        onPressed: () => _openDetails(context, habit),
                        child: GestureDetector(
                          key: ValueKey(habit.id),
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.edit,
                                          color: Theme.of(context)
                                              .iconTheme
                                              .color),
                                      title: Text(
                                        'Edit Habit',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          slideFromRight(
                                              AddHabitScreen(existing: habit)),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete,
                                          color: Colors.red),
                                      title: const Text(
                                        'Delete Habit',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Habit?'),
                                            content: Text(
                                              'Are you sure you want to delete "${habit.name}"?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  appState
                                                      .deleteHabit(habit.id);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Dismissible(
                            key: ValueKey('dismissible_${habit.id}'),
                            direction: DismissDirection.horizontal,
                            confirmDismiss: (direction) async {
                              final appState = context.read<AppState>();
                              await _handleComplete(context, appState, habit);
                              // Don't remove the tile from UI
                              return false;
                            },
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                color: Theme.of(context).cardColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFA94A)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: const Icon(Icons.check_circle,
                                  color: Color(0xFFFFA94A), size: 32),
                            ),
                            secondaryBackground: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                color: Theme.of(context).cardColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFA94A)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: const Icon(Icons.check_circle,
                                  color: Color(0xFFFFA94A), size: 32),
                            ),
                            child: HabitCard(
                              habit: habit,
                              // Pass null or empty callback if we want BouncyButton to handle tap
                              // But HabitCard might need it for ripple.
                              // Let's pass the same callback just in case.
                              onTap: () => _openDetails(context, habit),
                            )
                                .animate()
                                .fadeIn(
                                  duration: 350.ms,
                                  delay: (index * 70).ms,
                                )
                                .slideY(begin: 0.08, end: 0),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openAddHabit(context),
            backgroundColor: const Color(0xFF191919),
            foregroundColor: Colors.white,
            elevation: 6,
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          ),
        ),

        // Achievement banner (top)
        if (_achievementBannerMessage != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AchievementBanner(
                message: _achievementBannerMessage!,
                emoji: _achievementBannerEmoji ?? '🎉',
                onDismiss: () {
                  setState(() {
                    _achievementBannerMessage = null;
                    _achievementBannerEmoji = null;
                  });
                },
              ),
            ),
          ),

        // Full celebration overlay
        if (_activeCelebration != null)
          CelebrationOverlay(
            config: _activeCelebration!,
            onComplete: () {
              if (mounted) {
                setState(() => _activeCelebration = null);
              }
            },
          ),

        // Milestone celebration overlay
        if (_activeMilestone != null)
          MilestoneCelebrationOverlay(
            milestone: _activeMilestone!,
            onComplete: () {
              if (mounted) {
                setState(() => _activeMilestone = null);
              }
            },
          ),

        // Freeze Animation Overlay
        if (appState.hasRecentlyFrozenHabits)
          FreezeAnimationOverlay(
            onComplete: () {
              appState.consumeRecentlyFrozenHabits();
            },
          ),
      ],
    );
  }
}
