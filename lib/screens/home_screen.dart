import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/celebration_config.dart';
import '../models/streak_milestone.dart';
import '../state/app_state.dart';
import '../services/celebration_engine.dart';
import '../services/sync_service.dart';
import '../widgets/habit_card.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/milestone_celebration_overlay.dart';
import '../widgets/achievement_banner.dart';
import '../widgets/guest_status_banner.dart';
import '../services/smart_notification_service.dart';
import '../widgets/level_badge.dart';
import '../utils/slide_route.dart';
import '../widgets/modern_ui.dart'
    hide slideFromRight, slideFromBottom, fadeTransition;

import 'habit_detail_screen.dart';
import 'add_habit_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';
import 'reorder_habits_screen.dart';
import '../widgets/freeze_animation_overlay.dart';
import '../widgets/whats_new_dialog.dart';
import '../services/health_service.dart';
import '../services/streak_predictor_service.dart';
import '../services/duplicate_habit_service.dart';
import '../widgets/duplicate_merge_dialog.dart';
import '../services/tour_service.dart';
import '../widgets/emoji_pet_widget.dart';
import '../services/seasonal_event_service.dart';
import 'pet_screen.dart';
import '../services/guest_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'level_up_reward_screen.dart';
import '../models/level_reward.dart';
import 'loot_box_screen.dart';

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

  // App theme colors
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryTeal = Color(0xFF1FD1A5);

  // Tour keys for targeting UI elements
  final GlobalKey _addHabitButtonKey = GlobalKey();
  final GlobalKey _settingsButtonKey = GlobalKey();
  final GlobalKey _dailyProgressKey = GlobalKey();
  TutorialCoachMark? _tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    // Initialize notification engine and show What's New dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
      _showWhatsNewIfNeeded();
      _showWelcomeTourIfNeeded();
    });
  }

  Future<void> _showWhatsNewIfNeeded() async {
    // Small delay to let UI settle
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      WhatsNewDialog.showIfNeeded(context);
    }
  }

  /// Show welcome tour for new users
  Future<void> _showWelcomeTourIfNeeded() async {
    // Wait for UI to be ready
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Check if tour has been shown
    await TourService.instance.loadTourState();
    if (TourService.instance.hasShownHomeTour) {
      debugPrint('⏭️ Home tour already shown');
      return;
    }

    debugPrint('🎓 Starting welcome tour...');

    // Create tour targets
    final targets = <TargetFocus>[];
    int step = 0;
    const totalSteps = 3;

    // Target 1: Add habit button
    step++;
    targets.add(
      TourService.instance.createTarget(
        identify: 'add_habit',
        keyTarget: _addHabitButtonKey,
        title: 'Create Your First Habit',
        description:
            'Tap here to add a new habit. You can choose from templates or create custom habits with AI assistance!',
        currentStep: step,
        totalSteps: totalSteps,
        onNext: () async {
          await TourService.instance.scrollToTarget(_dailyProgressKey);
          _tutorialCoachMark?.next();
        },
        onSkip: () => _tutorialCoachMark?.skip(),
        align: ContentAlign.top,
      ),
    );

    // Target 2: Daily progress
    step++;
    targets.add(
      TourService.instance.createTarget(
        identify: 'daily_progress',
        keyTarget: _dailyProgressKey,
        title: 'Track Your Progress',
        description:
            'See your daily progress here. Complete habits by swiping right, and watch your streak grow!',
        currentStep: step,
        totalSteps: totalSteps,
        onNext: () async {
          await TourService.instance.scrollToTarget(_settingsButtonKey);
          _tutorialCoachMark?.next();
        },
        onSkip: () => _tutorialCoachMark?.skip(),
        align: ContentAlign.bottom,
      ),
    );

    // Target 3: Settings button
    step++;
    targets.add(
      TourService.instance.createTarget(
        identify: 'settings',
        keyTarget: _settingsButtonKey,
        title: 'Customize Your Experience',
        description:
            'Access settings, themes, backup options, and health integrations here. You can always replay this tour from settings!',
        currentStep: step,
        totalSteps: totalSteps,
        onNext: () => _tutorialCoachMark?.next(),
        onSkip: () => _tutorialCoachMark?.skip(),
        align: ContentAlign.bottom,
      ),
    );

    // Create and show tour
    _tutorialCoachMark = TourService.instance.createTour(
      targets: targets,
      onFinish: () async {
        debugPrint('✅ Welcome tour completed');
        await TourService.instance.markTourAsShown('home');
      },
      onSkip: () async {
        debugPrint('⏭️ Welcome tour skipped');
        await TourService.instance.markTourAsShown('home');
      },
    );

    // Scroll to first target before showing tour
    await TourService.instance.scrollToTarget(_addHabitButtonKey);
    if (mounted) _tutorialCoachMark?.show(context: context);
  }

  Future<void> _initializeNotifications() async {
    try {
      debugPrint('🔔 Starting notification initialization...');

      // Run in parallel - don't wait for each to complete
      if (mounted) {
        final appState = context.read<AppState>();

        // Group 1: Quick sync operations (run in parallel)
        final syncFutures = <Future>[
          SyncService.instance.initialize().then((_) {
            debugPrint('✅ Sync service initialized');
          }),
        ];

        // Wait for sync service first as others depend on it
        await Future.wait(syncFutures, eagerError: false);

        // Group 2: Notification scheduling (non-blocking - don't await)
        Future(() async {
          try {
            await SmartNotificationService.instance
                .scheduleAllHabitReminders(appState.habits);
            debugPrint(
                '✅ Habit reminders scheduled for ${appState.habits.length} habits');
          } catch (e) {
            debugPrint('⚠️ Failed to schedule reminders: $e');
          }
        });

        // Sync health habits on startup (non-blocking)
        appState.syncHealthHabits();

        // Cloud sync (non-blocking - run in background)
        Future(() async {
          await SyncService.instance.syncOnAppOpen(
            appState.habits,
            appState.userLevel,
          );
        });

        debugPrint('✅ All initialization complete!');

        // UI-related checks - defer slightly to ensure smooth rendering
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;

          // Show streak warning popup if there are at-risk habits
          if (!appState.hasShownStreakWarningSession) {
            _showStreakWarningPopup(appState);
            appState.markStreakWarningShown();
          }

          // Check for duplicate habits
          debugPrint(
              '🔍 Duplicate check - hasShownSession: ${appState.hasShownDuplicateWarningSession}, habits: ${appState.habits.length}');
          if (!appState.hasShownDuplicateWarningSession) {
            _checkForDuplicates(appState);
          } else {
            debugPrint(
                '⏭️ Skipping duplicate check - already shown this session');
          }
        });

        // Run daily notifications in background (non-blocking) - only for signed-in users
        Future(() async {
          // Skip notifications for guest users
          final isGuest = await GuestService.instance.isGuestUser();
          if (isGuest) {
            debugPrint('⏭️ Skipping notifications - user is guest');
            return;
          }

          await SmartNotificationService.instance.runDailyNotifications(
            appState.habits,
            morningQuotesEnabled: appState.morningQuotesEnabled,
            streakAlertsEnabled: appState.streakAlertsEnabled,
            milestoneCelebrationEnabled: appState.milestoneCelebrationEnabled,
          );
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Notification initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
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

  /// Check for duplicate habits and show merge dialog if any are found
  void _checkForDuplicates(AppState appState) {
    debugPrint(
        '🔍 Running duplicate detection on ${appState.habits.length} habits:');
    for (final h in appState.habits) {
      debugPrint('   - ${h.emoji} ${h.name} (category: ${h.category})');
    }

    final duplicates =
        DuplicateHabitService.instance.detectDuplicates(appState.habits);

    if (duplicates.isEmpty) {
      debugPrint('✅ No duplicate habits found');
      return;
    }

    debugPrint('⚠️ Found ${duplicates.length} potential duplicate habit pairs');

    // Mark as shown for this session
    appState.markDuplicateWarningShown();

    // Small delay to let UI settle before showing dialog
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      debugPrint('📋 Showing DuplicateMergeDialog now...');
      DuplicateMergeDialog.show(
        context,
        duplicates: duplicates,
        onMergeAll: (mergeRequests) async {
          // Process all merge requests
          int successCount = 0;

          for (final request in mergeRequests) {
            try {
              // Find the habits
              final primary =
                  appState.habits.firstWhere((h) => h.id == request.primaryId);
              final secondary = appState.habits
                  .firstWhere((h) => h.id == request.secondaryId);

              // Merge using service
              final merged = DuplicateHabitService.instance.mergeHabits(
                primary,
                secondary,
                request.options,
              );

              // Update in app state
              await appState.mergeHabits(
                  request.primaryId, request.secondaryId, merged);
              successCount++;
            } catch (e) {
              debugPrint('❌ Failed to merge: $e');
            }
          }

          // Show single snackbar for all merges
          if (mounted && successCount > 0) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgColor = isDark ? const Color(0xFF191919) : Colors.white;
            final txtColor = isDark ? Colors.white : const Color(0xFF191919);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Merged $successCount habit${successCount > 1 ? 's' : ''} successfully',
                  style: TextStyle(
                    color: txtColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: bgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isDark
                      ? BorderSide(
                          color: Colors.white.withAlpha(0x1A), width: 1)
                      : BorderSide(
                          color: Colors.black.withAlpha(0x0D),
                          width: 1), // Subtle border
                ),
                elevation: isDark ? 0 : 4,
              ),
            );
          }
        },
        onDismiss: () {
          debugPrint('📝 Duplicate merge dialog dismissed');
        },
      );
    });
  }

  String _getHealthMetricUnit(HealthMetricType metric) {
    switch (metric) {
      case HealthMetricType.steps:
        return 'steps';
      case HealthMetricType.sleep:
        return 'hours';
      case HealthMetricType.distance:
        return 'km';
      case HealthMetricType.calories:
        return 'calories';
    }
  }

  Future<void> _handleComplete(AppState appState, Habit habit) async {
    // Check state before completion
    final wasAllDoneBefore = appState.wasAllCompletedBeforeThis(habit);
    final oldLevel = appState.userLevel.level;

    // Complete the habit
    appState.completeHabit(habit);

    // Cancel streak alert since habit is now completed
    SmartNotificationService.instance.cancelStreakAlert(habit.id);

    // Check state after completion
    final newLevel = appState.userLevel.level;
    final isAllDoneAfter = appState.allCompletedToday;

    // Trigger single habit celebration sound only (no overlay, no snackbar spam)
    CelebrationEngine.instance.celebrateSingleHabit(habit.name);

    // Priority 1: Check for level up (highest priority)
    if (newLevel > oldLevel) {
      final title = appState.userLevel.titleName;

      CelebrationEngine.instance.celebrateLevelUp(newLevel, title);

      // Show spectacular level-up screen
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      await Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: false,
          pageBuilder: (context, animation, secondaryAnimation) =>
              LevelUpRewardScreen(
            newLevel: newLevel,
            title: title,
            userLevel: appState.userLevel,
            rewards: LevelReward.getRewardsForLevel(newLevel),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );

      // Check for loot box after level up
      if (mounted && appState.hasPendingLootBox) {
        final lootBox = appState.pendingLootBox!;
        await Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: false,
            pageBuilder: (context, animation, secondaryAnimation) =>
                LootBoxScreen(
              lootBox: lootBox,
              onClaimed: () {
                // Reward will be applied from the returned result
              },
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
        appState.clearPendingLootBox();
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
    else if (!wasAllDoneBefore && isAllDoneAfter) {
      CelebrationEngine.instance.celebrateAllHabits();

      // Show Day Completed Toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Day Completed! You are unstoppable! 🎉🔥'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFFFA94A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Center(
                child: CompactEmojiPet(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PetScreen()),
                  ),
                ),
              ),
            ),
            leadingWidth: 120,
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
                    size: 36,
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
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    // Guest status banner - shows only for guest users
                    GuestStatusBanner(
                      onUpgrade: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ),
                    ),
                    // Seasonal event banner (if active)
                    _buildSeasonalEventBanner(),
                    // Daily progress header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Spacer(),
                        ],
                      ),
                    ),
                    _buildDailyProgressHeader(appState,
                        Theme.of(context).brightness == Brightness.dark),
                    // Health summary - removed for cleaner UI
                    // _buildHealthSummary(
                    //     Theme.of(context).brightness == Brightness.dark),
                    // Streak warnings section
                    _buildStreakWarnings(appState),
                    // Habits list
                    Expanded(
                      child: BrandedRefreshIndicator(
                        onRefresh: () async {
                          // Sync health habits on pull-to-refresh
                          final appState = context.read<AppState>();
                          await appState.syncHealthHabits();
                          // Retry pending sync operations
                          await SyncService.instance.retryPendingSync();
                          // Small delay for visual feedback
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                        },
                        child: ReorderableListView.builder(
                          onReorder: (oldIndex, newIndex) {
                            appState.reorderHabits(oldIndex, newIndex);
                            HapticFeedback.mediumImpact();
                          },
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final scale =
                                    lerpDouble(1.0, 1.03, animation.value)!;
                                final elevation =
                                    lerpDouble(0, 12, animation.value)!;
                                return Transform.scale(
                                  scale: scale,
                                  child: Material(
                                    elevation: elevation,
                                    borderRadius: BorderRadius.circular(22),
                                    shadowColor:
                                        _primaryOrange.withValues(alpha: 0.4),
                                    color: Colors.transparent,
                                    child: child,
                                  ),
                                );
                              },
                              child: child,
                            );
                          },
                          physics: const ClampingScrollPhysics(),
                          buildDefaultDragHandles: false,
                          padding: const EdgeInsets.all(16),
                          itemCount: habits.length,
                          itemBuilder: (context, index) {
                            final habit = habits[index];

                            return ReorderableDelayedDragStartListener(
                              key: ValueKey(habit.id),
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onLongPress: () {
                                    HapticFeedback.mediumImpact();
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (ctx) => Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(24),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Reorder button
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const ReorderHabitsScreen(),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                margin: const EdgeInsets.only(
                                                    bottom: 16),
                                                decoration: BoxDecoration(
                                                  color: _primaryOrange
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: _primaryOrange
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.swap_vert,
                                                        color: _primaryOrange,
                                                        size: 22),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Reorder Habits',
                                                      style: TextStyle(
                                                        color: _primaryOrange,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Icon(
                                                        Icons.arrow_forward_ios,
                                                        color: _primaryOrange,
                                                        size: 14),
                                                  ],
                                                ),
                                              ),
                                            ),
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
                                                Navigator.pop(ctx);
                                                Navigator.of(context).push(
                                                  slideFromRight(AddHabitScreen(
                                                      existing: habit)),
                                                );
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              title: const Text(
                                                'Delete Habit',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                showDialog(
                                                  context: context,
                                                  builder: (dialogCtx) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Delete Habit?'),
                                                    content: Text(
                                                      'Are you sure you want to delete "${habit.name}"?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                dialogCtx),
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          appState.deleteHabit(
                                                              habit.id);
                                                          Navigator.pop(
                                                              dialogCtx);
                                                        },
                                                        child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red),
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
                                  child: BouncyButton(
                                    onTap: () => _openDetails(context, habit),
                                    child: Dismissible(
                                      key: ValueKey('dismissible_${habit.id}'),
                                      direction: habit.completedToday
                                          ? DismissDirection
                                              .endToStart // Only allow uncomplete if already done
                                          : DismissDirection
                                              .horizontal, // Allow both directions
                                      confirmDismiss: (direction) async {
                                        final appState =
                                            context.read<AppState>();

                                        if (direction ==
                                            DismissDirection.startToEnd) {
                                          // Swipe RIGHT → Complete the habit
                                          if (!habit.completedToday) {
                                            // Check if this is a health-tracked habit with goals
                                            if (habit.isHealthTracked &&
                                                habit.healthGoalValue != null &&
                                                habit.healthMetric != null) {
                                              // Show confirmation dialog with "Don't show again" option
                                              bool? shouldComplete = true;

                                              // Check preference - if user hid warning, skip dialog
                                              if (appState
                                                  .hideManualCompletionWarning) {
                                                shouldComplete = true;
                                              } else if (mounted) {
                                                final metricUnit =
                                                    _getHealthMetricUnit(
                                                        habit.healthMetric!);

                                                // Use StatefulBuilder inside showDialog to handle checkbox state
                                                shouldComplete =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) {
                                                    bool doNotShowAgain = false;
                                                    return StatefulBuilder(
                                                      builder:
                                                          (context, setState) {
                                                        return AlertDialog(
                                                          title: const Row(
                                                            children: [
                                                              Icon(
                                                                  Icons
                                                                      .edit_note_rounded,
                                                                  color: Color(
                                                                      0xFFFFA94A)), // Orange for manual override
                                                              SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                  'Manual Completion?'),
                                                            ],
                                                          ),
                                                          content: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'This habit is usually tracked automatically by your health data (${habit.healthGoalValue} $metricUnit).\n\n'
                                                                'Do you want to mark it as complete manually?',
                                                                style:
                                                                    const TextStyle(
                                                                        height:
                                                                            1.5),
                                                              ),
                                                              const SizedBox(
                                                                  height: 16),
                                                              InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    doNotShowAgain =
                                                                        !doNotShowAgain;
                                                                  });
                                                                },
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                                child: Row(
                                                                  children: [
                                                                    SizedBox(
                                                                      height:
                                                                          24,
                                                                      width: 24,
                                                                      child:
                                                                          Checkbox(
                                                                        value:
                                                                            doNotShowAgain,
                                                                        onChanged:
                                                                            (val) {
                                                                          setState(
                                                                              () {
                                                                            doNotShowAgain =
                                                                                val ?? false;
                                                                          });
                                                                        },
                                                                        activeColor:
                                                                            const Color(0xFFFFA94A),
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(4),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            8),
                                                                    const Text(
                                                                      "Don't show again",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              14),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      false),
                                                              child: Text(
                                                                'Cancel',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                ),
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                // Save preference if checked
                                                                if (doNotShowAgain) {
                                                                  appState
                                                                      .setHideManualCompletionWarning(
                                                                          true);
                                                                }
                                                                Navigator.pop(
                                                                    context,
                                                                    true);
                                                              },
                                                              child: const Text(
                                                                'Complete Manually',
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                      0xFFFFA94A),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                );
                                              }

                                              if (shouldComplete == true) {
                                                try {
                                                  await _handleComplete(
                                                      appState, habit);
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Failed to complete habit: ${e.toString()}'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                            } else {
                                              // Regular habit - complete normally
                                              try {
                                                await _handleComplete(
                                                    appState, habit);
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Failed to complete habit: ${e.toString()}'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          }
                                        } else {
                                          // Swipe LEFT → Skip/Uncomplete
                                          if (habit.completedToday) {
                                            // Undo completion
                                            appState.uncompleteHabit(habit);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      '↩️ "${habit.name}" unmarked'),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  duration: const Duration(
                                                      milliseconds: 1500),
                                                ),
                                              );
                                            }
                                          } else {
                                            // Skip for today
                                            appState.skipHabit(habit);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      '⏭️ "${habit.name}" skipped for today'),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  duration: const Duration(
                                                      milliseconds: 1500),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                        // Don't remove the tile from UI
                                        return false;
                                      },
                                      // Right swipe background (Complete) - Green
                                      background: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF4CAF50),
                                              Color(0xFF81C784)
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF4CAF50)
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: Colors.white, size: 32),
                                            SizedBox(width: 8),
                                            Text('Complete',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                      // Left swipe background (Skip/Uncomplete) - Orange/Red
                                      secondaryBackground: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          gradient: LinearGradient(
                                            colors: habit.completedToday
                                                ? [
                                                    const Color(0xFFFF9800),
                                                    const Color(0xFFFFB74D)
                                                  ] // Orange for undo
                                                : [
                                                    const Color(0xFFE57373),
                                                    const Color(0xFFEF5350)
                                                  ], // Red for skip
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (habit.completedToday
                                                      ? const Color(0xFFFF9800)
                                                      : const Color(0xFFE57373))
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                                habit.completedToday
                                                    ? 'Undo'
                                                    : 'Skip',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                            const SizedBox(width: 8),
                                            Icon(
                                                habit.completedToday
                                                    ? Icons.undo
                                                    : Icons.close,
                                                color: Colors.white,
                                                size: 32),
                                          ],
                                        ),
                                      ),
                                      child: HabitCard(
                                        habit: habit,
                                        onTap: () =>
                                            _openDetails(context, habit),
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
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            key: _addHabitButtonKey,
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

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryOrange.withValues(alpha: isDark ? 0.2 : 0.15),
                    _secondaryTeal.withValues(alpha: isDark ? 0.15 : 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _primaryOrange.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text(
                  '🚀',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 28),

            Text(
              'No habits yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 8),

            Text(
              'Start building your streak by\ncreating your first habit',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 32),

            GestureDetector(
              onTap: () => _openAddHabit(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryOrange, Color(0xFFFFBB6E)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Create First Habit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyProgressHeader(AppState appState, bool isDark) {
    final habits = appState.sortedHabits;
    final completed = habits.where((h) => h.completedToday).length;
    final total = habits.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      key: _dailyProgressKey,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryOrange.withValues(alpha: isDark ? 0.15 : 0.1),
            _secondaryTeal.withValues(alpha: isDark ? 0.1 : 0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_primaryOrange),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress == 1.0 ? 'All done! 🎉' : 'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed of $total habits completed',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Level badge
          if (appState.userLevel.level > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    'Lv ${appState.userLevel.level}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  /// Build streak warnings section - now empty, warnings shown as popup
  Widget _buildStreakWarnings(AppState appState) {
    // Warnings are now shown as popup dialog, not inline
    return const SizedBox.shrink();
  }

  /// Show streak warning popup if there are at-risk habits
  void _showStreakWarningPopup(AppState appState) {
    final predictions = StreakPredictorService.instance
        .getHabitsNeedingWarning(appState.habits);

    if (predictions.isEmpty || !mounted) return;

    // Show bottom sheet with warnings
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              physics:
                  const ClampingScrollPhysics(), // Prevent bouncing if not needed
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Removed health summary for cleaner UI
                            // _buildHealthSummary(
                            //   isDark,
                            // ),
                            Text(
                              'Streaks Need Attention!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${predictions.length} habit${predictions.length > 1 ? 's' : ''} at risk today',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                // Habit list items
                ...predictions.take(5).map((pred) {
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getRiskColor(pred.riskLevel)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(pred.emoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    title: Text(pred.habitName),
                    subtitle: Text(pred.reason,
                        style: TextStyle(
                          color: _getRiskColor(pred.riskLevel),
                          fontSize: 12,
                        )),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRiskColor(pred.riskLevel)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔥 ${pred.currentStreak}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(pred.riskLevel),
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      final habit = appState.habits.firstWhere(
                        (h) => h.id == pred.habitId,
                        orElse: () => appState.habits.first,
                      );
                      _openDetails(context, habit);
                    },
                  );
                }),

                const SizedBox(height: 8),

                // Dismiss button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it, I\'ll complete them!'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRiskColor(StreakRiskLevel level) {
    switch (level) {
      case StreakRiskLevel.critical:
        return Colors.red;
      case StreakRiskLevel.high:
        return Colors.orange;
      case StreakRiskLevel.moderate:
        return Colors.amber;
      case StreakRiskLevel.safe:
        return Colors.green;
    }
  }

  // /// Build health summary widget - REMOVED for cleaner UI
  // Widget _buildHealthSummary(bool isDark) {
  //   // Only show if we have any health data
  //   if (_todaySleepHours == 0.0 && _todaySteps == 0 && _todayDistance == 0.0) {
  //     return const SizedBox.shrink();
  //   }
  //
  //   return Container(
  //     margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(
  //         color: _secondaryTeal.withValues(alpha: 0.2),
  //       ),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         _buildHealthMetric(
  //           icon: '😴',
  //           label: 'Sleep',
  //           value: _todaySleepHours.toStringAsFixed(1),
  //           unit: 'hrs',
  //           isDark: isDark,
  //         ),
  //         Container(
  //           width: 1,
  //           height: 40,
  //           color: isDark
  //               ? Colors.white.withValues(alpha: 0.1)
  //               : Colors.black.withValues(alpha: 0.1),
  //         ),
  //         _buildHealthMetric(
  //           icon: '🚶',
  //           label: 'Steps',
  //           value: _todaySteps.toString(),
  //           unit: '',
  //           isDark: isDark,
  //         ),
  //         Container(
  //           width: 1,
  //           height: 40,
  //           color: isDark
  //               ? Colors.white.withValues(alpha: 0.1)
  //               : Colors.black.withValues(alpha: 0.1),
  //         ),
  //         _buildHealthMetric(
  //           icon: '📍',
  //           label: 'Distance',
  //           value: _todayDistance.toStringAsFixed(1),
  //           unit: 'km',
  //           isDark: isDark,
  //         ),
  //       ],
  //     ),
  //   ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  // }

  /// Build seasonal event banner if there's an active event
  Widget _buildSeasonalEventBanner() {
    final event = SeasonalEventService.instance.activeEvent;
    if (event == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            event.primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
            event.secondaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            event.type.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.daysRemaining} days left • ${event.xpMultiplier}x XP',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: event.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${event.exclusiveBadges.length} 🏅',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
