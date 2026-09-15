import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/team.dart';
import '../services/team_service.dart';
import '../services/team_notification_manager.dart';

/// Main dashboard for a team showing progress, leaderboard, and habits
class TeamDashboardScreen extends StatefulWidget {
  final Team team;

  const TeamDashboardScreen({super.key, required this.team});

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  late Team _team;
  List<TeamHabit> _habits = [];
  Map<String, List<TeamHabitProgress>> _habitProgress = {};
  Map<String, int> _memberCompletions = {};
  bool _isLoading = false;
  Timer? _refreshTimer;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _team = widget.team;
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadData();
    _startAutoRefresh();

    // Initialize Real-time Team Notifications
    TeamNotificationManager.instance.initialize();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _confettiController.dispose();
    TeamNotificationManager.instance.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 30 seconds for real-time feel
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData(showLoading: false);
    });
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      // Refresh team data
      await TeamService.instance.refreshTeams();
      final updatedTeam =
          TeamService.instance.teams.where((t) => t.id == _team.id).firstOrNull;
      if (updatedTeam != null) {
        _team = updatedTeam;
      }

      // Load habits
      _habits = await TeamService.instance.getTeamHabits(_team.id);

      // Load progress for each habit
      _habitProgress = {};
      _memberCompletions = {};

      for (final habit in _habits) {
        final progress =
            await TeamService.instance.getHabitProgress(habit.id, days: 7);
        _habitProgress[habit.id] = progress;

        // Count completions per member
        for (final p in progress) {
          _memberCompletions[p.userId] =
              (_memberCompletions[p.userId] ?? 0) + 1;
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _getMemberProgressForHabit(String habitId, String userId) {
    final progress = _habitProgress[habitId] ?? [];
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final completedToday = progress.any((p) =>
        p.userId == userId &&
        p.completedDate.toIso8601String().split('T')[0] == todayStr);

    return completedToday ? 1.0 : 0.0;
  }

  bool _hasCompletedHabitToday(String habitId) {
    final userId = TeamService.instance.teams.isNotEmpty
        ? _team.members.firstOrNull?.userId
        : null;
    if (userId == null) return false;
    return _getMemberProgressForHabit(habitId, userId) >= 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                // App Bar
                _buildAppBar(isDark),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Loading indicator
                      if (_isLoading)
                        const LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(Color(0xFFFFA94A)),
                        ),

                      // Quick Reactions Bar
                      _buildQuickReactionsBar(isDark),
                      const SizedBox(height: 20),

                      // Team Progress
                      // Team Progress
                      _buildTeamProgressCard(isDark),
                      const SizedBox(height: 20),

                      // Achievements Section
                      _buildAchievementsSection(isDark),
                      const SizedBox(height: 20),

                      // Leaderboard
                      _buildLeaderboard(isDark),
                      const SizedBox(height: 20),

                      // Team Habits
                      _buildTeamHabitsSection(isDark),
                      const SizedBox(height: 20),

                      // Members Section
                      _buildMembersSection(isDark),

                      const SizedBox(height: 20),

                      // Invite More Members (if not full)
                      if (_team.members.length < _team.maxMembers)
                        _buildInviteMoreCard(isDark),

                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.2,
              colors: const [
                Color(0xFFFFA94A),
                Color(0xFFFFA94A),
                Color(0xFFFFD700),
                Colors.white,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHabitSheet,
        backgroundColor: const Color(0xFFFFA94A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Habit', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFA94A).withValues(alpha: 0.3),
                const Color(0xFFFF8A3D).withValues(alpha: 0.2),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showEmojiPicker,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _team.teamEmoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _showRenameDialog,
                              child: Row(
                                children: [
                                  Text(
                                    _team.name,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black38,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${_team.members.length} members',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                if (_team.teamStreak > 0) ...[
                                  const Text(' · '),
                                  Text(
                                    '🔥 ${_team.teamStreak} day streak',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareTeam,
          tooltip: 'Share Team',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                _showTeamSettings();
                break;
              case 'leave':
                _confirmLeaveTeam();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Team Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'leave',
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Leave Team', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickReactionsBar(bool isDark) {
    final reactions = ['👏', '🔥', '💪', '🎉', '❤️', '⭐'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: reactions.map((emoji) {
          return GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              await TeamService.instance.sendReaction(
                teamId: _team.id,
                emoji: emoji,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$emoji sent to team!'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA94A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildTeamProgressCard(bool isDark) {
    if (_habits.isEmpty) return const SizedBox.shrink();

    // Filter habits to only show those with at least one completion today
    final activeHabits = _habits.where((habit) {
      final completedMembers = _team.members.where((member) {
        final progress = _getMemberProgressForHabit(habit.id, member.userId);
        return progress >= 1.0;
      }).toList();
      return completedMembers.isNotEmpty;
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Chart
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTeamPulseChart(isDark),
                const SizedBox(height: 8),
                Text(
                  'Team Pulse',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Right: Active Habits (only if any completed)
          if (activeHabits.isNotEmpty) ...[
            Container(
              width: 1,
              height: 80,
              color:
                  isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: activeHabits
                    .map((habit) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildHabitProgressRow(habit, isDark,
                              compact: true),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildTeamPulseChart(bool isDark) {
    int totalPossible = _habits.length * _team.members.length;
    int completedCount = 0;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    for (var habit in _habits) {
      final progress = _habitProgress[habit.id] ?? [];
      completedCount += progress
          .where((p) =>
              p.completedDate.toIso8601String().split('T')[0] == todayStr)
          .length;
    }

    // Default to 100% if no work (avoid div by 0), but only if no habits
    if (_habits.isEmpty) return const SizedBox.shrink();

    double percentage = totalPossible > 0 ? completedCount / totalPossible : 0;
    final percentageInt = (percentage * 100).toInt();

    return SizedBox(
      height: 100,
      width: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4, // Add spacing for modern look
              centerSpaceRadius: 30,
              startDegreeOffset: 270, // Start from top
              sections: [
                PieChartSectionData(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFA94A), // Orange
                      Color(0xFFFF7043), // Deep Orange
                    ],
                  ),
                  value: percentage > 0 ? percentage * 100 : 0.1, // Show sliver
                  title: '',
                  radius: 14, // Slightly thicker for emphasis
                  showTitle: false,
                  badgeWidget: percentage == 1.0
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Color(0xFFFFA94A),
                          ),
                        )
                      : null,
                  badgePositionPercentageOffset: 0.9,
                ),
                PieChartSectionData(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  value: (1 - percentage) * 100,
                  title: '',
                  radius: 10, // Thinner for background
                  showTitle: false,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentageInt%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitProgressRow(TeamHabit habit, bool isDark,
      {bool compact = false}) {
    // Calculate completion stats
    final completedMembers = _team.members.where((member) {
      final progress = _getMemberProgressForHabit(habit.id, member.userId);
      return progress >= 1.0;
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 6 : 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA94A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(compact ? 8 : 12),
            ),
            child: Text(habit.emoji,
                style: TextStyle(fontSize: compact ? 16 : 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 13 : 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: compact ? 2 : 6),
                if (completedMembers.isNotEmpty) ...[
                  if (compact)
                    Text(
                        '${completedMembers.length}/${_team.members.length} done',
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.black54))
                  else
                    SizedBox(
                      height: 24,
                      child: Stack(
                        children: [
                          for (int i = 0; i < completedMembers.length; i++)
                            if (i < 5)
                              Positioned(
                                left: i * 16.0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      width: 1.5,
                                    ),
                                    color: const Color(0xFFFFA94A),
                                    image:
                                        completedMembers[i].profilePictureUrl !=
                                                null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    completedMembers[i]
                                                        .profilePictureUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: completedMembers[i]
                                              .profilePictureUrl ==
                                          null
                                      ? Center(
                                          child: Text(
                                            (completedMembers[i].displayName ??
                                                    '?')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                          if (completedMembers.length > 5)
                            Positioned(
                              left: 5 * 16.0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${completedMembers.length - 5}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                ] else
                  Text(
                    'No completions yet',
                    style: TextStyle(
                      fontSize: compact ? 10 : 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${completedMembers.length}/${_team.members.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildLeaderboard(bool isDark) {
    // Sort members by completions
    final sortedMembers = List<TeamMember>.from(_team.members)
      ..sort((a, b) => (_memberCompletions[b.userId] ?? 0)
          .compareTo(_memberCompletions[a.userId] ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard, color: Color(0xFFFFD700)),
              const SizedBox(width: 8),
              Text(
                'This Week\'s Leaderboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(sortedMembers.length, (index) {
            final member = sortedMembers[index];
            final completions = _memberCompletions[member.userId] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                          : index == 1
                              ? Colors.grey.withValues(alpha: 0.3)
                              : index == 2
                                  ? const Color(0xFFCD7F32)
                                      .withValues(alpha: 0.3)
                                  : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        index == 0
                            ? '👑'
                            : index == 1
                                ? '🥈'
                                : index == 2
                                    ? '🥉'
                                    : '${index + 1}',
                        style: TextStyle(
                          fontSize: index < 3 ? 14 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFFFA94A),
                    backgroundImage: member.profilePictureUrl != null
                        ? NetworkImage(member.profilePictureUrl!)
                        : null,
                    child: member.profilePictureUrl == null
                        ? Text(
                            (member.displayName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      member.displayName ?? 'Member ${index + 1}',
                      style: TextStyle(
                        fontWeight:
                            index == 0 ? FontWeight.bold : FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completions ✅',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildTeamHabitsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt, color: Color(0xFFFFA94A)),
              const SizedBox(width: 8),
              Text(
                'Team Habits',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${_habits.length} active',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_habits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      'No habits yet',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showAddHabitSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first habit'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._habits.map((habit) => _buildHabitTile(habit, isDark)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildHabitTile(TeamHabit habit, bool isDark) {
    final isCompleted = _hasCompletedHabitToday(habit.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        // Use a stable key to prevent widget recreation during swipe updates
        key: Key(habit.id),
        // Allow bidirectional swipe if not completed (Right=Complete, Left=Skip)
        // If completed, only allow Left swipe (Undo)
        direction: isCompleted
            ? DismissDirection.endToStart
            : DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();

          if (direction == DismissDirection.startToEnd) {
            // Swipe RIGHT -> Complete (only if not completed)
            if (!isCompleted) {
              await TeamService.instance.completeTeamHabit(habit.id);
              if (mounted) {
                _confettiController.play();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Text('${habit.emoji} ${habit.name} completed!'),
                        const Text(' 🎉'),
                      ],
                    ),
                    backgroundColor:
                        const Color(0xFF4CAF50), // Green for success
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                _loadData(showLoading: false);
              }
            }
            return false; // Don't dismiss from list, just update state
          } else {
            // Swipe LEFT -> Skip (if not completed) or Undo (if completed)
            if (isCompleted) {
              // UNDO
              await TeamService.instance.undoTeamHabit(habit.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('↩️ "${habit.name}" unmarked'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                _loadData(showLoading: false);
              }
              return false;
            } else {
              // SKIP
              // Since persistent skip isn't ready, we show visual feedback
              // and keep it in the list (return false). This mimics 'Undo' behavior loop
              // but acknowledges the 'Skip' gesture the user wanted.
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⏭️ "${habit.name}" skipped for today'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFFE57373), // Red
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
                // Future: Add TeamService.skipTeamHabit(habit.id)
                return false;
              }
            }
          }
          return false;
        },
        // Right swipe background (Complete) - Green Gradient
        background: Container(
          margin: const EdgeInsets.only(bottom: 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 32),
              SizedBox(width: 8),
              Text(
                'Complete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // Left swipe background (Undo / Skip) - Orange or Red Gradient
        secondaryBackground: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isCompleted
                  ? [
                      const Color(0xFFFF9800),
                      const Color(0xFFFFB74D)
                    ] // Orange (Undo)
                  : [
                      const Color(0xFFE57373),
                      const Color(0xFFEF5350)
                    ], // Red (Skip)
            ),
            boxShadow: [
              BoxShadow(
                color: (isCompleted
                        ? const Color(0xFFFF9800)
                        : const Color(0xFFE57373))
                    .withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                isCompleted ? 'Undo' : 'Skip',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCompleted ? Icons.undo : Icons.close,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFFFA94A).withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFFFFA94A)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.2)),
              width: isCompleted ? 1.5 : 1,
            ),
            boxShadow: isCompleted
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: const Color(0xFFFFA94A),
                        decorationThickness: 2,
                      ),
                    ),
                    if (habit.description != null &&
                        habit.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          habit.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (!isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Swipe right to complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white30 : Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFFA94A),
                  size: 28,
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFFFFA94A)),
              const SizedBox(width: 8),
              Text(
                'Members (${_team.members.length}/${_team.maxMembers})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _team.members.map((member) {
              final completions = _memberCompletions[member.userId] ?? 0;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA94A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFFFA94A),
                      backgroundImage: member.profilePictureUrl != null
                          ? NetworkImage(member.profilePictureUrl!)
                          : null,
                      child: member.profilePictureUrl == null
                          ? Text(
                              (member.displayName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      member.displayName ?? 'Member',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (member.isCreator) ...[
                      const SizedBox(width: 4),
                      const Text('👑', style: TextStyle(fontSize: 12)),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      '$completions✅',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildAchievementsSection(bool isDark) {
    // Define Achievements
    final achievements = [
      {
        'title': 'Streak Starter',
        'emoji': '🔥',
        'desc': '3 Day Team Streak',
        'unlocked': _team.teamStreak >= 3,
        'color': Colors.orange
      },
      {
        'title': 'Week Warrior',
        'emoji': '⚔️',
        'desc': '7 Day Team Streak',
        'unlocked': _team.teamStreak >= 7,
        'color': Colors.red
      },
      {
        'title': 'Full Squad',
        'emoji': '🚀',
        'desc': 'Max members joined',
        'unlocked': _team.members.length >= _team.maxMembers,
        'color': Colors.blue
      },
      {
        'title': 'Consistent',
        'emoji': '💎',
        'desc': '30 Day Streak',
        'unlocked': _team.teamStreak >= 30,
        'color': Colors.purple
      },
      {
        'title': 'Centurion',
        'emoji': '💯',
        'desc': '100 Day Streak',
        'unlocked': _team.teamStreak >= 100,
        'color': Colors.amber
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFFA94A)),
              const SizedBox(width: 8),
              Text(
                'Team Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = achievements[index];
              final isUnlocked = item['unlocked'] as bool;
              final color = item['color'] as Color;

              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? color.withValues(alpha: 0.1)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUnlocked
                        ? color.withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: isUnlocked ? 1.5 : 0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isUnlocked ? (item['emoji'] as String) : '🔒',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white38 : Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
      ],
    );
  }

  Widget _buildInviteMoreCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA94A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_add, color: Color(0xFFFFA94A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite more friends!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '${_team.maxMembers - _team.members.length} spot${_team.maxMembers - _team.members.length > 1 ? 's' : ''} available',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _generateNewInviteCode,
            child: const Text('Invite'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  // Helper methods
  void _showEmojiPicker() {
    final emojis = ['🔥', '💪', '🎯', '⭐', '🏆', '💎', '🦁', '🐺', '🦅', '🚀'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Team Emoji',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: emojis
                  .map((emoji) => GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          // TODO: Update team emoji via service
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Emoji updated to $emoji')),
                          );
                        },
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 40)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog() async {
    final controller = TextEditingController(text: _team.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Team'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            hintText: 'Enter new name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA94A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _team.name) {
      await TeamService.instance.updateTeamName(_team.id, newName);
      _loadData();
    }
  }

  void _shareTeam() async {
    final code = await TeamService.instance.generateInviteCode(_team.id);
    if (code != null) {
      Share.share(
        'Join my team "${_team.name}" on Streakoo! Use code: ${code.code}',
      );
    }
  }

  // NOTIFICATIONS
  // NOTIFICATIONS
  Future<Map<String, bool>> _getAllNotificationStates() async {
    final prefs = await SharedPreferences.getInstance();
    final teamId = _team.id;
    return {
      'habits': prefs.getBool('team_notifications_${teamId}_habits') ?? true,
      'reactions':
          prefs.getBool('team_notifications_${teamId}_reactions') ?? true,
      'achievements':
          prefs.getBool('team_notifications_${teamId}_achievements') ?? true,
    };
  }

  Future<void> _setNotificationState(String type, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('team_notifications_${_team.id}_$type', value);

    // Also update Manager cache/settings if needed?
    // The manager reads directly from SharedPreferences so it's fine.
  }

  // MANAGE MEMBERS
  void _showManageMembersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Manage Members',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _team.members.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final member = _team.members[index];

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFFFA94A),
                        backgroundImage: member.profilePictureUrl != null
                            ? NetworkImage(member.profilePictureUrl!)
                            : null,
                        child: member.profilePictureUrl == null
                            ? Text(
                                (member.displayName ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(
                        member.displayName ?? 'Member',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        member.isCreator ? 'Owner' : 'Member',
                        style: TextStyle(
                            color: member.isCreator ? Colors.orange : null),
                      ),
                      trailing: member.isCreator
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: () => _confirmRemoveMember(member),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmRemoveMember(TeamMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text(
            'Are you sure you want to remove ${member.displayName ?? 'this member'} from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) Navigator.pop(context); // Close sheet

      final success =
          await TeamService.instance.removeMember(_team.id, member.userId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member removed successfully')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove member')),
          );
        }
      }
    }
  }

  // DELETE TEAM
  void _confirmDeleteTeam() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team?'),
        content: const Text(
            'Are you sure you want to delete this team? This action cannot be undone and all team data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Team'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        // Show loading overlay
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final success = await TeamService.instance.deleteTeam(_team.id);

      if (mounted) {
        Navigator.pop(context); // Pop loading

        if (success) {
          Navigator.pop(context); // Pop Dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete team')),
          );
        }
      }
    }
  }

  void _showTeamSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isCreator =
            _team.creatorId == Supabase.instance.client.auth.currentUser?.id;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Team Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Notifications Section
                          FutureBuilder<Map<String, bool>>(
                            future: _getAllNotificationStates(),
                            builder: (context, snapshot) {
                              final prefs = snapshot.data ??
                                  {
                                    'habits': true,
                                    'reactions': true,
                                    'achievements': true
                                  };
                              return ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.notifications_active,
                                      color: Colors.purple),
                                ),
                                title: const Text('Notifications'),
                                subtitle: const Text('Customize what you see'),
                                children: [
                                  SwitchListTile(
                                    title: const Text('Habit Updates'),
                                    subtitle: const Text(
                                        'When teammates finish tasks'),
                                    value: prefs['habits']!,
                                    onChanged: (val) {
                                      _setNotificationState('habits', val);
                                      setModalState(() {});
                                    },
                                  ),
                                  SwitchListTile(
                                    title: const Text('Reactions'),
                                    subtitle: const Text(
                                        'When someone reacts to you'),
                                    value: prefs['reactions']!,
                                    onChanged: (val) {
                                      _setNotificationState('reactions', val);
                                      setModalState(() {});
                                    },
                                  ),
                                  SwitchListTile(
                                    title: const Text('Achievements'),
                                    subtitle:
                                        const Text('Team milestones & badges'),
                                    value: prefs['achievements']!,
                                    onChanged: (val) {
                                      _setNotificationState(
                                          'achievements', val);
                                      setModalState(() {});
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person_add,
                                  color: Colors.blue),
                            ),
                            title: const Text('Invite Members'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              _generateNewInviteCode();
                            },
                          ),
                          if (isCreator) ...[
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.people,
                                    color: Colors.teal),
                              ),
                              title: const Text('Manage Members'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context);
                                _showManageMembersSheet();
                              },
                            ),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.edit,
                                    color: Colors.orange),
                              ),
                              title: const Text('Rename Team'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context);
                                _showRenameDialog();
                              },
                            ),
                          ],
                          const Divider(),
                          if (isCreator)
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete_forever,
                                    color: Colors.red),
                              ),
                              title: const Text('Delete Team',
                                  style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(context);
                                _confirmDeleteTeam();
                              },
                            )
                          else
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                    const Icon(Icons.logout, color: Colors.red),
                              ),
                              title: const Text('Leave Team',
                                  style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(context);
                                _confirmLeaveTeam();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _confirmLeaveTeam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Team?'),
        content: Text(
          'Are you sure you want to leave "${_team.name}"? '
          'You will need an invite code to rejoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TeamService.instance.leaveTeam(_team.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _generateNewInviteCode() async {
    final code = await TeamService.instance.generateInviteCode(_team.id);
    if (code != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invite Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code.code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Color(0xFFFFA94A),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Share this code with friends'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied!')),
                );
              },
              child: const Text('Copy'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Share.share(
                  'Join my team "${_team.name}" on Streakoo! Use code: ${code.code}',
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ],
        ),
      );
    }
  }

  void _showAddHabitSheet() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedEmoji = '✅';
    final emojis = ['✅', '💧', '🏃', '📚', '🧘', '💤', '🥗', '💊', '🎯', '💪'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_task, color: Color(0xFFFFA94A)),
                        const SizedBox(width: 8),
                        Text(
                          'Add Team Habit',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Emoji selector
                    Text(
                      'Choose an emoji:',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: emojis.map((emoji) {
                        final isSelected = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedEmoji = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFA94A)
                                      .withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFFA94A)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Name input
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Habit Name',
                        hintText: 'e.g. Drink 8 glasses of water',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description input (optional)
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'e.g. At least 2L per day',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a habit name')),
                            );
                            return;
                          }

                          final habit =
                              await TeamService.instance.createTeamHabit(
                            teamId: _team.id,
                            name: nameController.text.trim(),
                            emoji: selectedEmoji,
                            description: descController.text.trim().isEmpty
                                ? null
                                : descController.text.trim(),
                          );

                          if (habit != null && context.mounted) {
                            Navigator.pop(context);
                            _confettiController.play();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('$selectedEmoji ${habit.name} added!'),
                                  backgroundColor: const Color(0xFFFFA94A),
                                ),
                              );
                            }
                            _loadData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA94A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Habit',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
