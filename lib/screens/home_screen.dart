import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/celebration_config.dart';
import '../models/streak_milestone.dart';
import '../models/level_reward.dart';
import '../state/app_state.dart';
import '../services/celebration_engine.dart';
import '../services/sync_service.dart';
import '../widgets/habit_card.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/milestone_celebration_overlay.dart';
import '../widgets/achievement_banner.dart';
import '../widgets/spectacular_level_up.dart';
import '../widgets/guest_status_banner.dart';
import '../services/notification_engine.dart';
import '../widgets/level_badge.dart';
import '../utils/slide_route.dart';
import '../widgets/modern_ui.dart'
    hide slideFromRight, slideFromBottom, fadeTransition;

import 'habit_detail_screen.dart';
import 'add_habit_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';
import '../widgets/freeze_animation_overlay.dart';
import '../services/health_service.dart';
import '../services/streak_predictor_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Initialize notification engine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      debugPrint('🔔 Starting notification engine initialization...');

      // Initialize notification engine
      await NotificationEngine.instance.initialize();
      debugPrint(
          '✅ Notification engine initialized: ${NotificationEngine.instance.isInitialized}');

      // Initialize sync service
      await SyncService.instance.initialize();
      debugPrint('✅ Sync service initialized');

      // Schedule focus task reminders
      if (mounted) {
        final appState = context.read<AppState>();

        try {
          await NotificationEngine.instance
              .scheduleFocusTaskReminders(appState.habits);
          debugPrint(
              '✅ Focus task reminders scheduled for ${appState.habits.length} habits');

          // Schedule predictive streak warnings
          await NotificationEngine.instance
              .schedulePredictiveWarnings(appState.habits);
          debugPrint('✅ Predictive streak warnings scheduled');
        } catch (e) {
          debugPrint('⚠️ Failed to schedule reminders: $e');
        }

        // Sync health habits on startup
        appState.syncHealthHabits();

        // Auto-sync to cloud on app open
        await SyncService.instance.syncOnAppOpen(
          appState.habits,
          appState.userLevel,
        );

        debugPrint('✅ All initialization complete!');

        // Show streak warning popup if there are at-risk habits
        _showStreakWarningPopup(appState);
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
      case HealthMetricType.heartRate:
        return 'bpm';
    }
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

    // Trigger single habit celebration sound only (no overlay, no snackbar spam)
    CelebrationEngine.instance.celebrateSingleHabit(habit.name);

    // Priority 1: Check for level up (highest priority)
    if (newLevel > oldLevel) {
      final title = appState.userLevel.titleName;
      final rewards = LevelReward.getRewardsForLevel(newLevel);
      CelebrationEngine.instance.celebrateLevelUp(newLevel, title);

      // Show spectacular level-up screen immediately
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black87,
          pageBuilder: (context, animation, secondaryAnimation) =>
              SpectacularLevelUpScreen(
            newLevel: newLevel,
            title: title,
            userLevel: appState.userLevel,
            rewards: rewards,
            onComplete: () {},
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
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
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    // Guest status banner - shows only for guest users
                    GuestStatusBanner(
                      onUpgrade: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ),
                    ),
                    // Daily progress header
                    _buildDailyProgressHeader(appState,
                        Theme.of(context).brightness == Brightness.dark),
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
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: habits.length,
                          itemBuilder: (context, index) {
                            final habit = habits[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: BouncyButton(
                                onTap: () => _openDetails(context, habit),
                                child: GestureDetector(
                                  key: ValueKey(habit.id),
                                  onLongPress: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => Container(
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
                                                Navigator.pop(context);
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
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
                                                                context),
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          appState.deleteHabit(
                                                              habit.id);
                                                          Navigator.pop(
                                                              context);
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
                                  child: Dismissible(
                                    key: ValueKey('dismissible_${habit.id}'),
                                    direction: habit.completedToday
                                        ? DismissDirection
                                            .endToStart // Only allow uncomplete if already done
                                        : DismissDirection
                                            .horizontal, // Allow both directions
                                    confirmDismiss: (direction) async {
                                      final appState = context.read<AppState>();

                                      if (direction ==
                                          DismissDirection.startToEnd) {
                                        // Swipe RIGHT → Complete the habit
                                        if (!habit.completedToday) {
                                          // Check if this is a health-tracked habit with goals
                                          if (habit.isHealthTracked &&
                                              habit.healthGoalValue != null &&
                                              habit.healthMetric != null) {
                                            // Show informative dialog
                                            if (mounted) {
                                              final metricUnit =
                                                  _getHealthMetricUnit(
                                                      habit.healthMetric!);
                                              await showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .health_and_safety,
                                                          color: Color(
                                                              0xFF1FD1A5)),
                                                      SizedBox(width: 8),
                                                      Text(
                                                          'Auto-Tracked Habit'),
                                                    ],
                                                  ),
                                                  content: Text(
                                                    'This habit is automatically completed when you meet your health goal of ${habit.healthGoalValue} $metricUnit.\n\n'
                                                    'Your progress is tracked by AI using your health data. Keep going! 💪',
                                                    style: const TextStyle(
                                                        height: 1.5),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: const Text('OK'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          } else {
                                            // Regular habit - complete normally
                                            await _handleComplete(
                                                context, appState, habit);
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
                                                      BorderRadius.circular(12),
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
                                                      BorderRadius.circular(12),
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
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
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
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
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
                      ),
                    ),
                  ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
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

              // Habit list
              ...predictions.take(3).map((pred) => ListTile(
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
                  )),

              const SizedBox(height: 8),

              // Dismiss button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
}
