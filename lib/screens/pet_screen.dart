import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../models/streakoo_pet.dart';
import '../models/health_challenge.dart';
import '../models/habit.dart';
import '../state/app_state.dart';
import '../widgets/emoji_pet_widget.dart';

import 'pet_chat_screen.dart';
import 'health_coaching_dashboard.dart';

/// Full screen pet page with animated chicken design and naming
class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  String? _petName;

  // Challenge progress mode: 'all' or 'focused'
  String _challengeProgressMode = 'all';
  static const _prefsChallengeProgressMode = 'pet_challenge_progress_mode';

  @override
  void initState() {
    super.initState();
    // Use AppState for pet name if available, or fetch from service if needed
    // Assuming pet name is stored in AppState or similar. The original code used StreakooPetService.
    // For now we'll rely on AppState as per the previous working version logic
    final appState = Provider.of<AppState>(context, listen: false);
    _petName = appState.petName;

    // Load challenge progress mode preference
    _loadChallengeProgressMode();

    // Check if user needs to name their pet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (appState.petName.isEmpty || appState.petName == 'Your Pet') {
        _showNamingDialog();
      }
    });
  }

  Future<void> _loadChallengeProgressMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_prefsChallengeProgressMode) ?? 'all';
    if (mounted) {
      setState(() => _challengeProgressMode = mode);
    }
  }

  Future<void> _setChallengeProgressMode(String mode) async {
    setState(() => _challengeProgressMode = mode);
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsChallengeProgressMode, mode);
  }

  Future<void> _showNamingDialog() async {
    final controller = TextEditingController(text: _petName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Your Pet 🐣'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Chirpy, Nugget...',
            border: OutlineInputBorder(),
          ),
          maxLength: 15,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      if (!mounted) return;
      StreakooPetService.instance.setCustomName(name);
      context.read<AppState>().setPetName(name);
      setState(() => _petName = name);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFF8F0),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final pet = _buildPet(appState);
          final level = appState.userLevel.level;
          final displayName = _petName ?? pet.stage.name;

          return CustomScrollView(
            slivers: [
              // Gradient App Bar
              SliverAppBar(
                expandedHeight: 60,
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Rename button
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: _showNamingDialog,
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Top padding for emojis
                      const SizedBox(height: 16),
                      // Emoji pet with animations
                      const EmojiPetWidget(
                        size: 120,
                        enableHatching: true,
                      ),
                      const SizedBox(height: 24),

                      // Pet name with glow
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ).animate().fadeIn().slideY(begin: 0.2),
                      const SizedBox(height: 16),

                      // Interaction buttons (Feed, Play, Pet)
                      _buildInteractionButtons(isDark),
                      const SizedBox(height: 16),

                      // Level + Stage
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFA94A).withValues(alpha: 0.2),
                              const Color(0xFFFFD54F).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                const Color(0xFFFFA94A).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Level $level • ${pet.stage.name}',
                          style: const TextStyle(
                            color: Color(0xFFFFA94A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
                      const SizedBox(height: 32),

                      // Stats cards
                      _buildStatsSection(appState, isDark),
                      const SizedBox(height: 20),

                      // Challenge progress mode toggle
                      _buildChallengeProgressToggle(appState, isDark),
                      const SizedBox(height: 12),

                      // Challenge progress card
                      _buildChallengeCard(appState, isDark),
                      const SizedBox(height: 20),

                      // Mood card
                      _buildMoodCard(pet, isDark),
                      const SizedBox(height: 20),

                      // Evolution progress
                      _buildEvolutionCard(pet, level, isDark),
                      const SizedBox(height: 20),

                      // Health Plan Progress (Replaces Customization)
                      _buildHealthPlanProgressCard(appState, isDark),
                      const SizedBox(height: 20),

                      // Pet care tips
                      _buildPetTipsCard(pet, isDark),
                      const SizedBox(height: 20),

                      // Pet diary
                      _buildPetDiary(isDark),
                      const SizedBox(height: 20),

                      // Achievements section
                      _buildAchievementsSection(appState, isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  StreakooPet _buildPet(AppState appState) {
    final completionsToday =
        appState.habits.where((h) => h.completedToday).length;
    final streaksAtRisk =
        appState.habits.where((h) => h.streak > 0 && !h.completedToday).length;

    // Calculate XP progress within current level
    final userLevel = appState.userLevel;
    final double progressWithinLevel = userLevel.xpToNextLevel > 0
        ? userLevel.currentXP / userLevel.xpToNextLevel
        : 0.0;

    return StreakooPet.fromUserState(
      userLevel: appState.userLevel.level,
      completionsToday: completionsToday,
      totalHabits: appState.habits.length,
      streaksAtRisk: streaksAtRisk,
      lastCompletion:
          DateTime.now(), // Ideally should be real last completion time
      hasMissedHabitToday: appState.hasMissedHabitToday,
      progressWithinLevel: progressWithinLevel,
    );
  }

  Widget _buildStatsSection(AppState appState, bool isDark) {
    final completedToday =
        appState.habits.where((h) => h.completedToday).length;
    final totalHabits = appState.habits.length;
    final longestStreak = appState.habits.isEmpty
        ? 0
        : appState.habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                '$completedToday/$totalHabits', 'Today', isDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('$longestStreak', 'Best Streak', isDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                '${appState.userLevel.totalXP}', 'Total XP', isDark)),
      ],
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.15);
  }

  Widget _buildStatCard(String value, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFFFFA94A).withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // Track interaction cooldowns
  DateTime? _lastFeedTime;

  Widget _buildInteractionButtons(bool isDark) {
    final now = DateTime.now();
    final canFeed = _lastFeedTime == null ||
        now.difference(_lastFeedTime!) > const Duration(hours: 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Feed button
        _buildActionButton(
          emoji: '🍖',
          label: 'Feed',
          enabled: canFeed,
          onTap: () {
            if (!canFeed) return;
            setState(() => _lastFeedTime = now);
            HapticFeedback.mediumImpact();
            _showFeedingAnimation(context);
          },
          isDark: isDark,
        ),
        const SizedBox(width: 12), // Spacing between buttons

        // Pet button (no cooldown)
        _buildActionButton(
          emoji: '❤️',
          label: 'Pet',
          enabled: true,
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('💕 Your pet loves you!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          isDark: isDark,
        ),
        const SizedBox(width: 12), // Spacing between buttons

        // Chat button
        _buildActionButton(
          emoji: '💬',
          label: 'Chat',
          enabled: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PetChatScreen(),
              ),
            );
          },
          isDark: isDark,
        ),
      ],
    ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildActionButton({
    required String emoji,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFA94A).withValues(alpha: isDark ? 0.2 : 0.15),
                const Color(0xFFFFD54F).withValues(alpha: isDark ? 0.1 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedingAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const _FeedingAnimationDialog(),
    );
  }

  /// Build the toggle to switch between All Habits and Focus Tasks progress
  Widget _buildChallengeProgressToggle(AppState appState, bool isDark) {
    final focusHabits = appState.habits.where((h) => h.isFocusTask).toList();
    final hasFocusHabits = focusHabits.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _setChallengeProgressMode('all'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: _challengeProgressMode == 'all'
                    ? const Color(0xFFFFA94A).withValues(alpha: 0.2)
                    : (isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(
                  color: _challengeProgressMode == 'all'
                      ? const Color(0xFFFFA94A)
                      : (isDark ? Colors.white24 : Colors.black12),
                  width: _challengeProgressMode == 'all' ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📊', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'All Habits',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _challengeProgressMode == 'all'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _challengeProgressMode == 'all'
                          ? const Color(0xFFFFA94A)
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: hasFocusHabits
                ? () => _setChallengeProgressMode('focused')
                : null,
            child: Opacity(
              opacity: hasFocusHabits ? 1.0 : 0.4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: _challengeProgressMode == 'focused'
                      ? const Color(0xFF1FD1A5).withValues(alpha: 0.2)
                      : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05)),
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(12)),
                  border: Border.all(
                    color: _challengeProgressMode == 'focused'
                        ? const Color(0xFF1FD1A5)
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: _challengeProgressMode == 'focused' ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'Focus Tasks',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _challengeProgressMode == 'focused'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _challengeProgressMode == 'focused'
                            ? const Color(0xFF1FD1A5)
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                    if (!hasFocusHabits) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(0)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildChallengeCard(AppState appState, bool isDark) {
    // Check what mode we're showing
    final focusHabits = appState.habits.where((h) => h.isFocusTask).toList();

    // FOCUSED mode: show focused habits progress only
    if (_challengeProgressMode == 'focused' && focusHabits.isNotEmpty) {
      return _buildAggregateChallengeProgress(focusHabits, isDark);
    }

    // ALL mode: show all habits progress
    if (_challengeProgressMode == 'all') {
      return _buildAllHabitsProgress(appState, isDark);
    }

    // Fallback: if focused mode but no focus habits, show all habits
    return _buildAllHabitsProgress(appState, isDark);
  }

  /// Build progress card based on ALL habits completion
  Widget _buildAllHabitsProgress(AppState appState, bool isDark) {
    if (appState.habits.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate aggregate streak across all habits
    final int streak = _calculateAggregateStreak(appState.habits.toList());

    // Use 7-day as default target for aggregate progress
    const int targetDays = 7;
    // final progress = (streak / targetDays).clamp(0.0, 1.0); // Unused
    final isCompleted = streak >= targetDays;

    final completedToday =
        appState.habits.where((h) => h.completedToday).length;
    final totalHabits = appState.habits.length;
    final allDoneToday = completedToday == totalHabits;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [
                  const Color(0xFF1FD1A5).withValues(alpha: 0.2),
                  const Color(0xFF1FD1A5).withValues(alpha: 0.05)
                ]
              : [
                  const Color(0xFFFFA94A)
                      .withValues(alpha: isDark ? 0.15 : 0.1),
                  const Color(0xFFFFD54F)
                      .withValues(alpha: isDark ? 0.05 : 0.03)
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF1FD1A5).withValues(alpha: 0.3)
              : const Color(0xFFFFA94A).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Circular progress - shows TODAY's completion
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: totalHabits > 0 ? completedToday / totalHabits : 0,
                    strokeWidth: 6,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(
                      allDoneToday
                          ? const Color(0xFF1FD1A5)
                          : const Color(0xFFFFA94A),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      allDoneToday ? '✅' : '📊',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      '$completedToday/$totalHabits',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Habits Challenge',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allDoneToday
                      ? '🎉 All $totalHabits habits done today!'
                      : '$completedToday/$totalHabits completed today',
                  style: TextStyle(
                    fontSize: 13,
                    color: allDoneToday
                        ? const Color(0xFF1FD1A5)
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  streak > 0
                      ? '$streak day${streak > 1 ? 's' : ''} with all habits done!'
                      : 'Complete all habits daily to build streak',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.15);
  }

  /// Build Aggregate Challenge Card (for Focus Habits)
  /// Progress increases only if ALL focus habits are completed for a day
  Widget _buildAggregateChallengeProgress(
      List<Habit> focusHabits, bool isDark) {
    // 1. Calculate Aggregate Streak
    final int streak = _calculateAggregateStreak(focusHabits);

    // 2. Determine Target (use the maximum target found in the group)
    final int targetDays = focusHabits
        .map((h) => h.challengeTargetDays ?? 7)
        .reduce((a, b) => a > b ? a : b);

    final progress = (streak / targetDays).clamp(0.0, 1.0);
    final isCompleted = streak >= targetDays;

    String challengeTitle;
    String badge;

    if (targetDays >= 30) {
      challengeTitle = '30-Day Focus Challenge';
      badge = '🥇';
    } else if (targetDays >= 14) {
      challengeTitle = '14-Day Focus Challenge';
      badge = '🥈';
    } else {
      challengeTitle = '7-Day Focus Challenge';
      badge = '🥉';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [
                  const Color(0xFF1FD1A5).withValues(alpha: 0.2),
                  const Color(0xFF1FD1A5).withValues(alpha: 0.05)
                ]
              : [
                  const Color(0xFFFFA94A)
                      .withValues(alpha: isDark ? 0.15 : 0.1),
                  const Color(0xFFFFD54F)
                      .withValues(alpha: isDark ? 0.05 : 0.03)
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF1FD1A5).withValues(alpha: 0.3)
              : const Color(0xFFFFA94A).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation(
                          isCompleted
                              ? const Color(0xFF1FD1A5)
                              : const Color(0xFFFFA94A),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          badge,
                          style: const TextStyle(fontSize: 20),
                        ),
                        Text(
                          '$streak/$targetDays',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challengeTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted
                          ? '🎉 Congrats on your first challenge!'
                          : '${focusHabits.length} habits linked to this challenge',
                      style: TextStyle(
                        fontSize: 13,
                        color: isCompleted
                            ? const Color(0xFF1FD1A5)
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                    if (!isCompleted) ...[
                      const SizedBox(height: 8),
                      // Helper text to explain the strict rule
                      Text(
                        'Complete all ${focusHabits.length} focus habits daily to progress!',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isCompleted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  // Determine next tier
                  int nextTarget = 7;
                  if (targetDays == 7) {
                    nextTarget = 15;
                  } else if (targetDays == 15) {
                    nextTarget = 30;
                  } else {
                    nextTarget =
                        30; // Max out at 30 for now or loop back? Let's say 30.
                  }

                  context.read<AppState>().resetChallengeForHabits(
                        focusHabits.map((h) => h.id).toList(),
                        nextTarget,
                      );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('🚀 New $nextTarget-Day Challenge Started!'),
                      backgroundColor: const Color(0xFF1FD1A5),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Text('🔥', style: TextStyle(fontSize: 16)),
                label: const Text('Start Another Challenge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FD1A5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.15);
  }

  int _calculateAggregateStreak(List<Habit> habits) {
    if (habits.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    // Loop backwards from today
    while (true) {
      final dateKey = _dateToKey(checkDate);
      bool allCompleted = true;

      for (var h in habits) {
        if (!h.completionDates.contains(dateKey)) {
          allCompleted = false;
          break;
        }
      }

      if (allCompleted) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // If today is not completed, check if it's the very first iteration (today)
        // If it is today, we don't break yet, we just check yesterday to see if there is an existing streak
        // (Standard streak behavior: "streak of 5" means 5 past days, doesn't reset to 0 just because I haven't done it TODAY yet)
        if (dateKey == _dateToKey(DateTime.now())) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        } else {
          break; // Streak broken
        }
      }
    }
    return streak;
  }

  String _dateToKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Dialog to select a habit and challenge duration

  /// Build day indicators showing completed (✓), frozen (❄️), and pending (○) days

  Widget _buildMoodCard(StreakooPet pet, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFA94A).withValues(alpha: isDark ? 0.15 : 0.1),
            const Color(0xFFFFD54F).withValues(alpha: isDark ? 0.05 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Mood emoji
          Text(pet.mood.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feeling ${pet.mood.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pet.mood.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA94A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${pet.happinessLevel}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.15);
  }

  Widget _buildHealthPlanProgressCard(AppState appState, bool isDark) {
    final challenge = appState.activeHealthChallenge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '❤️ Health Dashboard Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (challenge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1FD1A5).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF1FD1A5).withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Color(0xFF1FD1A5),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF43F5E)
                    .withValues(alpha: isDark ? 0.15 : 0.1), // Rose
                const Color(0xFFFB7185).withValues(alpha: isDark ? 0.05 : 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
            ),
          ),
          child: challenge == null
              ? _buildEmptyPlanState(isDark)
              : _buildActivePlanState(challenge, isDark),
        ),
      ],
    ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.15);
  }

  Widget _buildEmptyPlanState(bool isDark) {
    return Column(
      children: [
        const Icon(Icons.favorite_border_rounded,
            size: 48, color: Color(0xFFF43F5E)),
        const SizedBox(height: 12),
        Text(
          'No Active Health Plan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Start a plan to track your health goals!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Navigate to Health Dashboard
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HealthCoachingDashboard(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF43F5E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Start Plan'),
        ),
      ],
    );
  }

  Widget _buildActivePlanState(HealthChallenge challenge, bool isDark) {
    final now = DateTime.now();
    final startDate = challenge.startDate;
    final durationDays = challenge.durationWeeks * 7;

    final daysPassed = now.difference(startDate).inDays.clamp(0, durationDays);
    final daysRemaining = durationDays - daysPassed;
    final progress = daysPassed / durationDays;
    final isCompleted = progress >= 1.0;

    return GestureDetector(
      onTap: () async {
        if (isCompleted) {
          // Complete the challenge (awards streak freezes) and go to create new one
          final appState = context.read<AppState>();
          final freezeReward = challenge.durationWeeks >= 4
              ? 6
              : challenge.durationWeeks >= 2
                  ? 3
                  : 2;

          await appState.completeCurrentHealthChallenge();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '🎉 Challenge completed! +$freezeReward streak freeze(s) earned!'),
                backgroundColor: const Color(0xFF1FD1A5),
              ),
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HealthCoachingDashboard(),
              ),
            );
          }
        } else {
          // Navigate to health dashboard for active challenge
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HealthCoachingDashboard(),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1FD1A5).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF1FD1A5).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: Color(0xFF1FD1A5)),
                      SizedBox(width: 4),
                      Text(
                        'Completed!',
                        style: TextStyle(
                          color: Color(0xFF1FD1A5),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isCompleted
                ? '🎉 Tap to claim rewards & start new challenge!'
                : 'Day $daysPassed of $durationDays',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              color: isCompleted
                  ? const Color(0xFF1FD1A5)
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(
                isCompleted ? const Color(0xFF1FD1A5) : const Color(0xFFF43F5E),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                isCompleted ? Icons.celebration : Icons.timer_outlined,
                size: 16,
                color: isCompleted
                    ? const Color(0xFF1FD1A5)
                    : const Color(0xFFF43F5E),
              ),
              const SizedBox(width: 8),
              Text(
                isCompleted
                    ? 'Tap to start a new challenge →'
                    : '$daysRemaining days remaining',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? const Color(0xFF1FD1A5)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionCard(StreakooPet pet, int level, bool isDark) {
    final nextStage = pet.stage.nextStage;
    final progress = pet.progressToNextStage(level);

    if (nextStage == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFA94A), Color(0xFFFFD54F)],
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: const Row(
          children: [
            Text('🦅', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Text(
              'Legendary Status Achieved!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ).animate(delay: 400.ms).fadeIn().shimmer(duration: 2.seconds);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Evolution: ${pet.stage.name} → ${nextStage.name}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFFFFA94A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFA94A)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${pet.stage.levelsUntilNext(level)} levels until ${nextStage.name}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.15);
  }

  Widget _buildPetDiary(bool isDark) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final entries = appState.petDiary.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📖 Pet Diary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (appState.petDiary.length > 5)
                  TextButton(
                    onPressed: () => _showFullDiary(context, appState, isDark),
                    child: const Text('See All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4CAF50)
                        .withValues(alpha: isDark ? 0.15 : 0.1),
                    const Color(0xFF8BC34A)
                        .withValues(alpha: isDark ? 0.05 : 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                ),
              ),
              child: entries.isEmpty
                  ? Text(
                      'No diary entries yet. Complete focus tasks or milestones to start!',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 13,
                      ),
                    )
                  : Column(
                      children: entries
                          .map((entry) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black
                                                .withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(entry.moodEmoji,
                                          style: const TextStyle(fontSize: 18)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.message,
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.9)
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(entry.date),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ).animate(delay: 380.ms).fadeIn().slideY(begin: 0.15);
      },
    );
  }

  void _showFullDiary(BuildContext context, AppState appState, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  'Pet Diary',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: appState.petDiary.length,
                itemBuilder: (context, index) {
                  final entry = appState.petDiary[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2C)
                                    : const Color(0xFFF5F5F5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF4CAF50)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(entry.moodEmoji,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                            if (index < appState.petDiary.length - 1)
                              Container(
                                width: 2,
                                height: 40,
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatDate(entry.date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }

  Widget _buildPetTipsCard(StreakooPet pet, bool isDark) {
    String tip;
    String emoji;

    switch (pet.mood) {
      case PetMood.excited:
        tip = "Your pet is thriving! Keep up the amazing work!";
        emoji = "🌟";
        break;
      case PetMood.happy:
        tip = "Complete more habits to make your pet even happier!";
        emoji = "💝";
        break;
      case PetMood.content:
        tip = "Your pet is doing well. Try maintaining your streaks!";
        emoji = "🍀";
        break;
      case PetMood.neutral:
        tip = "Complete a habit today to cheer up your pet!";
        emoji = "💡";
        break;
      case PetMood.worried:
        tip = "Your pet misses you! Don't let your streaks break.";
        emoji = "💔";
        break;
      case PetMood.sleepy:
        tip = "Your pet needs some action! Start your habits!";
        emoji = "⚡";
        break;
      case PetMood.disappointed:
        tip = "Oh no! We missed a goal... Let's get back on track!";
        emoji = "😢";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1FD1A5).withValues(alpha: isDark ? 0.15 : 0.1),
            const Color(0xFF4ADBC4).withValues(alpha: isDark ? 0.05 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1FD1A5).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pet Care Tip',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.15);
  }

  Widget _buildAchievementsSection(AppState appState, bool isDark) {
    final achievements = <Map<String, dynamic>>[];

    // Check achievements
    final longestStreak = appState.habits.isEmpty
        ? 0
        : appState.habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    final totalHabits = appState.habits.length;
    final level = appState.userLevel.level;

    if (longestStreak >= 7) {
      achievements.add(
          {'emoji': '🔥', 'title': 'Week Warrior', 'desc': '7-day streak'});
    }
    if (longestStreak >= 30) {
      achievements.add(
          {'emoji': '⚡', 'title': 'Month Master', 'desc': '30-day streak'});
    }
    if (totalHabits >= 5) {
      achievements
          .add({'emoji': '📋', 'title': 'Habit Builder', 'desc': '5+ habits'});
    }
    if (level >= 5) {
      achievements
          .add({'emoji': '⭐', 'title': 'Rising Star', 'desc': 'Level 5+'});
    }
    if (level >= 10) {
      achievements
          .add({'emoji': '🏆', 'title': 'Champion', 'desc': 'Level 10+'});
    }

    if (achievements.isEmpty) {
      achievements.add({
        'emoji': '🎯',
        'title': 'Getting Started',
        'desc': 'Begin your journey'
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pet Achievements',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: achievements.map((a) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(a['emoji'] as String,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        a['desc'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.15);
  }
}

/// Feeding animation dialog with sequential eating phases
class _FeedingAnimationDialog extends StatefulWidget {
  const _FeedingAnimationDialog();

  @override
  State<_FeedingAnimationDialog> createState() =>
      _FeedingAnimationDialogState();
}

class _FeedingAnimationDialogState extends State<_FeedingAnimationDialog> {
  int _phase = 0;
  // Phases: 0=food drops, 1=notices, 2=excited, 3=chomping, 4=satisfied, 5=burp

  @override
  void initState() {
    super.initState();
    _runAnimation();
  }

  void _runAnimation() async {
    // Phase 0: Food appears and drops
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _phase = 1);
    HapticFeedback.lightImpact();

    // Phase 1: Pet notices
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _phase = 2);
    HapticFeedback.lightImpact();

    // Phase 2: Excited reaction
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _phase = 3);
    HapticFeedback.mediumImpact();

    // Phase 3: Chomping (repeat a few times)
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      HapticFeedback.selectionClick();
    }

    // Phase 4: Satisfied
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _phase = 4);
    HapticFeedback.mediumImpact();

    // Phase 5: Burp/Content
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _phase = 5);
    HapticFeedback.heavyImpact();

    // Auto close
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background glow in satisfied phase
            if (_phase >= 4)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFA94A).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ).animate().fadeIn(duration: 300.ms),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Food falling animation (phase 0)
                if (_phase == 0)
                  const Text('🍖', style: TextStyle(fontSize: 40))
                      .animate()
                      .slideY(
                          begin: -2,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.bounceOut)
                      .fadeIn(),

                // Pet emoji with expressions
                _buildPetWithExpression(),

                const SizedBox(height: 16),

                // Status text
                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFA94A),
                  ),
                ).animate().fadeIn(),

                // Subtitle
                Text(
                  _getSubtitle(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // Food item near pet during eating
            if (_phase >= 1 && _phase <= 3)
              Positioned(
                bottom: 80,
                right: 50,
                child: Text(
                  '🍖',
                  style: TextStyle(
                    fontSize: _phase == 3 ? 20 : 30, // Shrinks during chomping
                  ),
                )
                    .animate(onPlay: (c) => _phase == 3 ? c.repeat() : null)
                    .shake(hz: 3, duration: 200.ms),
              ),

            // Sparkles on satisfied
            if (_phase >= 4) ...[
              Positioned(
                top: 30,
                left: 30,
                child: const Text('✨', style: TextStyle(fontSize: 20))
                    .animate()
                    .fadeIn()
                    .scale(begin: const Offset(0.5, 0.5)),
              ),
              Positioned(
                top: 40,
                right: 40,
                child: const Text('⭐', style: TextStyle(fontSize: 18))
                    .animate(delay: 100.ms)
                    .fadeIn()
                    .scale(begin: const Offset(0.5, 0.5)),
              ),
            ],

            // Hearts on final phase
            if (_phase == 5) ...[
              Positioned(
                top: 50,
                child: const Text('💕', style: TextStyle(fontSize: 24))
                    .animate()
                    .fadeIn()
                    .slideY(begin: 0.5, end: 0),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPetWithExpression() {
    String petEmoji = '🐥';
    String expressionEmoji = '';

    switch (_phase) {
      case 0:
        expressionEmoji = ''; // Waiting
        break;
      case 1:
        expressionEmoji = '😲'; // Notices food
        break;
      case 2:
        expressionEmoji = '🤩'; // Excited
        break;
      case 3:
        expressionEmoji = '😋'; // Eating
        break;
      case 4:
        expressionEmoji = '😊'; // Satisfied
        break;
      case 5:
        expressionEmoji = '😌'; // Content/Burp
        break;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Main pet
        Text(
          petEmoji,
          style: const TextStyle(fontSize: 80),
        )
            .animate(
              onPlay: (c) => _phase == 3 ? c.repeat() : null,
            )
            .shake(hz: _phase == 3 ? 8 : 0, duration: 200.ms)
            .scale(
              begin: const Offset(1, 1),
              end: Offset(_phase == 3 ? 1.1 : 1, _phase == 3 ? 0.9 : 1),
            ),

        // Expression overlay
        if (expressionEmoji.isNotEmpty)
          Positioned(
            top: -10,
            right: -5,
            child: Text(
              expressionEmoji,
              style: const TextStyle(fontSize: 30),
            )
                .animate()
                .fadeIn(duration: 200.ms)
                .scale(
                    begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2))
                .then()
                .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1)),
          ),
      ],
    );
  }

  String _getStatusText() {
    switch (_phase) {
      case 0:
        return 'Here comes food!';
      case 1:
        return 'Ooh! Food!';
      case 2:
        return 'Yay! 🎉';
      case 3:
        return 'Nom nom nom...';
      case 4:
        return 'Delicious!';
      case 5:
        return 'So happy! 💕';
      default:
        return '';
    }
  }

  String _getSubtitle() {
    switch (_phase) {
      case 0:
        return '🍖 dropping...';
      case 1:
        return 'Pet noticed the treat!';
      case 2:
        return 'Getting excited!';
      case 3:
        return 'Eating happily...';
      case 4:
        return 'That was tasty!';
      case 5:
        return '+10 Happiness!';
      default:
        return '';
    }
  }
}
