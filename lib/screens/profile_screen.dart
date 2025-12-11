import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/user_level.dart';
import '../services/supabase_service.dart';
import '../services/health_service.dart';

import 'focus_task_manager_screen.dart';
import 'settings_screen.dart';
import '../services/logout_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // App theme colors (Orange gradient)
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryOrange =
      Color(0xFFFF8C42); // Deeper orange for gradient

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    final userLevel = appState.userLevel;
    final supabase = SupabaseService();
    final user = supabase.currentUser;
    final photoUrl =
        user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'];
    final userName = user?.userMetadata?['full_name'] ??
        user?.email?.split('@')[0] ??
        'Streak Master';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: _primaryOrange.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: _secondaryOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.settings_rounded,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Hero Profile Card
                      _buildProfileHero(
                        context,
                        isDark,
                        userName,
                        photoUrl,
                        user?.email,
                        userLevel,
                      ).animate().fadeIn().slideY(begin: 0.1),

                      const SizedBox(height: 28),

                      // Stats Section
                      _buildSectionHeader(
                          'Your Stats', Icons.bar_chart_rounded, isDark),
                      const SizedBox(height: 14),
                      _buildStatsGrid(appState, isDark),

                      const SizedBox(height: 28),

                      // Quick Actions
                      _buildSectionHeader(
                          'Quick Actions', Icons.flash_on_rounded, isDark),
                      const SizedBox(height: 14),
                      _buildQuickActions(context, appState, isDark),

                      const SizedBox(height: 28),

                      // Health Integration
                      _buildSectionHeader(
                          'Health', Icons.favorite_rounded, isDark),
                      const SizedBox(height: 14),
                      _HealthDataCard(isDark: isDark),

                      const SizedBox(height: 28),

                      // Achievements Preview
                      _buildSectionHeader(
                          'Achievements', Icons.emoji_events_rounded, isDark),
                      const SizedBox(height: 14),
                      _buildAchievementsPreview(context, appState, isDark),

                      const SizedBox(height: 28),

                      // Account Actions
                      if (supabase.isAuthenticated) ...[
                        _buildAccountActions(context, supabase, isDark),
                      ],

                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primaryOrange.withValues(alpha: 0.15),
                _secondaryOrange.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _primaryOrange),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHero(
    BuildContext context,
    bool isDark,
    String userName,
    String? photoUrl,
    String? email,
    UserLevel userLevel,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  _primaryOrange.withValues(alpha: 0.25),
                  _secondaryOrange.withValues(alpha: 0.15),
                ]
              : [
                  _primaryOrange.withValues(alpha: 0.15),
                  _secondaryOrange.withValues(alpha: 0.08),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Avatar with glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_primaryOrange, _secondaryOrange],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryOrange.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  image: photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photoUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: _primaryOrange.withValues(alpha: 0.7),
                      )
                    : null,
              ),
              // Level badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryOrange, _secondaryOrange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryOrange.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    'Lvl ${userLevel.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name and Title
          Text(
            userName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              userLevel.titleName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _primaryOrange,
              ),
            ),
          ),
          if (email != null) ...[
            const SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // XP Progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${userLevel.currentXP} XP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${userLevel.xpToNextLevel} XP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: userLevel.progress),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return Container(
                              width: constraints.maxWidth * value,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryOrange, _secondaryOrange],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AppState appState, bool isDark) {
    final stats = [
      {
        'icon': Icons.emoji_events_rounded,
        'label': 'Habits',
        'value': '${appState.totalHabits}',
        'colors': [const Color(0xFFFFA94A), const Color(0xFFFF6B6B)],
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'label': 'Streaks',
        'value': '${appState.totalStreaks}',
        'colors': [const Color(0xFFEF4444), const Color(0xFFF97316)],
      },
      {
        'icon': Icons.stars_rounded,
        'label': 'Badges',
        'value': '${appState.achievements.length}',
        'colors': [_primaryOrange, _secondaryOrange],
      },
      {
        'icon': Icons.ac_unit_rounded,
        'label': 'Freezes',
        'value': '${appState.streakFreezes}',
        'colors': [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          stat['icon'] as IconData,
          stat['label'] as String,
          stat['value'] as String,
          stat['colors'] as List<Color>,
          isDark,
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
            );
      },
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    List<Color> colors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, AppState appState, bool isDark) {
    final focusCount = appState.habits.where((h) => h.isFocusTask).length;

    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            Icons.star_rounded,
            'Focus Tasks',
            '$focusCount active',
            [_primaryOrange, const Color(0xFFFF6B6B)],
            isDark,
            () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FocusTaskManagerScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            Icons.brush_rounded,
            'Themes',
            'Coming soon',
            [_secondaryOrange, const Color(0xFF34D399)],
            isDark,
            () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium themes coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    List<Color> colors,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsPreview(
      BuildContext context, AppState appState, bool isDark) {
    final achievements = appState.achievements;
    final displayAchievements = achievements.take(4).toList();

    return GestureDetector(
      onTap: () => _showAllAchievements(context, appState, isDark),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with count
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryOrange, _secondaryOrange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryOrange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 22),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 2.seconds, color: Colors.white24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${achievements.length} Earned',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Tap to view all badges',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _primaryOrange,
                    size: 20,
                  ),
                ),
              ],
            ),

            if (displayAchievements.isNotEmpty) ...[
              const SizedBox(height: 16),
              // Achievement badges preview
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: displayAchievements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final achievement = entry.value;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryOrange.withValues(alpha: 0.15),
                          _secondaryOrange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _primaryOrange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          achievement['icon'] ?? '🏆',
                          style: const TextStyle(fontSize: 18),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                              duration: 1500.ms,
                              delay: Duration(milliseconds: index * 200),
                            ),
                        const SizedBox(width: 6),
                        Text(
                          achievement['name'] ?? 'Achievement',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 100 * index));
                }).toList(),
              ),
              if (achievements.length > 4) ...[
                const SizedBox(height: 8),
                Text(
                  '+${achievements.length - 4} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: _primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              Text(
                'Complete streaks to earn your first badge! 🎯',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  void _showAllAchievements(
      BuildContext context, AppState appState, bool isDark) {
    final achievements = appState.achievements;

    // All possible achievements
    final allBadges = [
      {
        'icon': '🔥',
        'name': 'First Streak',
        'desc': 'Complete your first 3-day streak',
        'unlocked': achievements.any((a) => a['name'] == 'First Streak')
      },
      {
        'icon': '🌟',
        'name': 'Week Warrior',
        'desc': 'Complete a 7-day streak',
        'unlocked': achievements.any((a) => a['name'] == 'Week Warrior')
      },
      {
        'icon': '💪',
        'name': 'Habit Master',
        'desc': 'Complete a 14-day streak',
        'unlocked': achievements.any((a) => a['name'] == 'Habit Master')
      },
      {
        'icon': '🏆',
        'name': 'Month Champion',
        'desc': 'Complete a 30-day streak',
        'unlocked': achievements.any((a) => a['name'] == 'Month Champion')
      },
      {
        'icon': '💎',
        'name': 'Diamond Streak',
        'desc': 'Complete a 60-day streak',
        'unlocked': achievements.any((a) => a['name'] == 'Diamond Streak')
      },
      {
        'icon': '👑',
        'name': 'Streak Royalty',
        'desc': 'Complete a 100-day streak',
        'unlocked': achievements.any((a) => a['name'] == 'Streak Royalty')
      },
      {
        'icon': '🎯',
        'name': 'Perfect Day',
        'desc': 'Complete all habits in a day',
        'unlocked': achievements.any((a) => a['name'] == 'Perfect Day')
      },
      {
        'icon': '⚡',
        'name': 'Speed Demon',
        'desc': 'Complete 5 habits before noon',
        'unlocked': achievements.any((a) => a['name'] == 'Speed Demon')
      },
      {
        'icon': '🌅',
        'name': 'Early Bird',
        'desc': 'Complete a habit before 6 AM',
        'unlocked': achievements.any((a) => a['name'] == 'Early Bird')
      },
      {
        'icon': '🦉',
        'name': 'Night Owl',
        'desc': 'Complete a habit after 11 PM',
        'unlocked': achievements.any((a) => a['name'] == 'Night Owl')
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryOrange, _secondaryOrange],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Achievements',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${achievements.length}/${allBadges.length} unlocked',
                          style: TextStyle(
                            fontSize: 13,
                            color: _primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badges Grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: allBadges.length,
                  itemBuilder: (context, index) {
                    final badge = allBadges[index];
                    final isUnlocked = badge['unlocked'] as bool;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? null
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.grey[100]),
                        gradient: isUnlocked
                            ? LinearGradient(
                                colors: [
                                  _primaryOrange.withValues(alpha: 0.2),
                                  _secondaryOrange.withValues(alpha: 0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUnlocked
                              ? _primaryOrange.withValues(alpha: 0.3)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey[200]!),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            badge['icon'] as String,
                            style: TextStyle(
                              fontSize: 32,
                              color: isUnlocked ? null : Colors.grey,
                            ),
                          )
                              .animate(
                                  onPlay: isUnlocked
                                      ? (c) => c.repeat(reverse: true)
                                      : null)
                              .scale(
                                begin: const Offset(1, 1),
                                end: isUnlocked
                                    ? const Offset(1.15, 1.15)
                                    : const Offset(1, 1),
                                duration: 1200.ms,
                              )
                              .shimmer(
                                duration: 2.seconds,
                                color: isUnlocked
                                    ? _primaryOrange.withValues(alpha: 0.3)
                                    : Colors.transparent,
                              ),
                          const SizedBox(height: 8),
                          Text(
                            badge['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isUnlocked
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge['desc'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                          if (!isUnlocked) ...[
                            const SizedBox(height: 4),
                            Icon(Icons.lock_outline,
                                size: 14, color: Colors.grey[400]),
                          ],
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 50 * index))
                        .scale(
                          begin: const Offset(0.9, 0.9),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActions(
    BuildContext context,
    SupabaseService supabase,
    bool isDark,
  ) {
    return Column(
      children: [
        // Logout
        GestureDetector(
          onTap: () => LogoutService.performLogout(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Delete Account
        GestureDetector(
          onTap: () => _showDeleteAccountDialog(context, supabase),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    SupabaseService supabase,
  ) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Delete Account?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This action is irreversible. All your habits, streaks, and data will be permanently deleted.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Enter password to confirm',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (passwordController.text.isEmpty) return;
                        setState(() => isLoading = true);
                        try {
                          await supabase.deleteAccount(passwordController.text);
                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.of(context).pushReplacementNamed('/');
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                child: const Text(
                  'Delete Forever',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Health Data Card
class _HealthDataCard extends StatefulWidget {
  final bool isDark;
  const _HealthDataCard({required this.isDark});

  @override
  State<_HealthDataCard> createState() => _HealthDataCardState();
}

class _HealthDataCardState extends State<_HealthDataCard> {
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryOrange = Color(0xFFFF8C42);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: HealthService.instance.hasHealthDataAccess(),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isConnected
                            ? [Colors.pink, Colors.red]
                            : [Colors.grey, Colors.grey],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: isConnected ? Colors.white : Colors.grey[300],
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Health Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (isConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Synced',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (isConnected)
                FutureBuilder<Map<String, dynamic>>(
                  future: _fetchHealthStats(),
                  builder: (context, statsSnapshot) {
                    final stats = statsSnapshot.data ?? {};
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHealthStat(
                          Icons.directions_walk_rounded,
                          'Steps',
                          stats['steps']?.toString() ?? '-',
                          Colors.orange,
                        ),
                        _buildHealthStat(
                          Icons.bedtime_rounded,
                          'Sleep',
                          stats['sleep'] != null
                              ? '${stats['sleep'].toStringAsFixed(1)}h'
                              : '-',
                          Colors.indigo,
                        ),
                        _buildHealthStat(
                          Icons.favorite_rounded,
                          'Heart',
                          stats['heart'] != null ? '${stats['heart']}bpm' : '-',
                          Colors.red,
                        ),
                      ],
                    );
                  },
                )
              else
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ).then((_) => setState(() {}));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryOrange, _secondaryOrange],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryOrange.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Connect Health Data',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthStat(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _fetchHealthStats() async {
    final health = HealthService.instance;
    final now = DateTime.now();
    final steps = await health.getStepCount(now);
    return {
      'steps': steps,
      'sleep': null,
      'heart': null,
    };
  }
}
