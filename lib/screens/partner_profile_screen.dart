import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/accountability_partner.dart';
import '../models/pet_achievements.dart';
import '../services/accountability_service.dart';
import '../widgets/shared_challenges_section.dart';

/// A detailed profile screen for viewing a partner's shared data
class PartnerProfileScreen extends StatefulWidget {
  final AccountabilityPartner partner;

  const PartnerProfileScreen({super.key, required this.partner});

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  AccountabilityPrivacySettings? _partnerSettings;
  bool _isLoading = true;
  AccountabilityPartner? _partnerState; // Local state for updates

  // Getter that returns local state or widget partner
  AccountabilityPartner get _partner => _partnerState ?? widget.partner;

  @override
  void initState() {
    super.initState();
    _partnerState = widget.partner;
    _loadPartnerSettings();
  }

  Future<void> _loadPartnerSettings() async {
    // For now, we show all data. In a real implementation,
    // this would fetch the partner's privacy settings from the server
    _partnerSettings = AccountabilityPrivacySettings();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final partner = _partner; // Use local state for dynamic updates

    // App theme colors - consistent orange palette
    const primaryOrange = Color(0xFFFFA94A);
    const secondaryOrange = Color(0xFFFF8A3D);
    const accentCoral = Color(0xFFFF6B6B);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Glass app-themed AppBar
          SliverAppBar(
            expandedHeight: 185,
            pinned: true,
            backgroundColor: primaryOrange.withValues(alpha: 0.85),
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryOrange,
                          secondaryOrange,
                          accentCoral,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          // Avatar with orange glow
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.white,
                              child: Text(
                                partner.partnerName.isNotEmpty
                                    ? partner.partnerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: primaryOrange,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Name centered
                          Text(
                            partner.partnerName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          // Level & stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Level pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('⭐',
                                        style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Level ${(partner.partnerCurrentStreak ~/ 7) + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Streak pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥',
                                        style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${partner.partnerCurrentStreak} days',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
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
            ),
          ),

          // Main content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Quick Comparison Summary
                  _buildComparisonSummary(isDark),
                  const SizedBox(height: 16),

                  // 1. Connection Anniversary
                  _buildConnectionAnniversary(isDark),
                  const SizedBox(height: 16),

                  // Quick Reactions Bar
                  _buildQuickReactionsBar(isDark),
                  const SizedBox(height: 16),

                  // 2. Streak + Health Score (combined row with progress ring)
                  _buildCombinedStatsRow(isDark),
                  const SizedBox(height: 16),

                  // Mutual Challenges Banner (if any)
                  _buildMutualChallengesBanner(isDark),

                  // 3. Weekly Activity (habit tracking)
                  _buildWeeklyActivityCard(isDark),
                  const SizedBox(height: 16),

                  // Partner's Shared Habits
                  _buildSharedHabitsList(isDark),
                  const SizedBox(height: 16),

                  // 4. Activity Timeline
                  _buildActivityTimeline(isDark),
                  const SizedBox(height: 16),

                  // 5. Head-to-Head Stats
                  _buildHeadToHeadStats(isDark),
                  const SizedBox(height: 16),

                  // 6. Habit Chains Comparison
                  _buildHabitChainsComparison(isDark),
                  const SizedBox(height: 16),

                  // 7. Achievements
                  _buildAchievementsCard(isDark),
                  const SizedBox(height: 24),

                  // Optional: Shared Chain Challenges
                  SharedChallengesSection(
                    partnerId: partner.partnerUserId,
                    partnerName: partner.partnerName,
                    onCreateChallenge: () => _showCreateChallengeSheet(context),
                  ),
                  const SizedBox(height: 80), // Extra space for FAB
                ],
              ]),
            ),
          ),
        ],
      ),
      // Floating Action Button for Send Nudge
      floatingActionButton: FloatingActionButton.extended(
        onPressed: partner.canSendNudge ? () => _showNudgeSheet(context) : null,
        backgroundColor:
            partner.canSendNudge ? const Color(0xFFFFA94A) : Colors.grey,
        icon: const Icon(Icons.notifications_active, color: Colors.white),
        label: Text(
          partner.canSendNudge ? 'Nudge' : 'Limit reached',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Quick Comparison Summary - Shows friend's status
  Widget _buildComparisonSummary(bool isDark) {
    // Mock data - replace with real partner data
    const partnerHabitsCompleted = 3;
    const partnerTotalHabits = 5;
    final partnerName = widget.partner.partnerName;
    const allDone = partnerHabitsCompleted == partnerTotalHabits;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allDone
              ? [
                  const Color(0xFF1FD1A5).withValues(alpha: 0.2),
                  const Color(0xFF1FD1A5).withValues(alpha: 0.05)
                ]
              : [
                  const Color(0xFFFFA94A).withValues(alpha: 0.2),
                  const Color(0xFFFFA94A).withValues(alpha: 0.05)
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allDone
              ? const Color(0xFF1FD1A5).withValues(alpha: 0.3)
              : const Color(0xFFFFA94A).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Text(
            allDone ? '🎉' : '💪',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allDone
                  ? "$partnerName completed all habits today! Amazing! 🔥"
                  : "$partnerName completed $partnerHabitsCompleted/$partnerTotalHabits habits today",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  /// Quick Reactions Bar - Send emoji reactions
  Widget _buildQuickReactionsBar(bool isDark) {
    final reactions = ['👏', '🔥', '💪', '⭐', '❤️', '🎉'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            'Quick React:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          ...reactions.map((emoji) => GestureDetector(
                onTap: () => _sendReaction(emoji),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ).animate(onPlay: (c) => c.stop()).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 100.ms),
              )),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  void _sendReaction(String emoji) {
    // Show sent confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji sent to ${widget.partner.partnerName}!'),
        backgroundColor: const Color(0xFFFFA94A),
        duration: const Duration(seconds: 1),
      ),
    );
    // TODO: Actually send reaction via AccountabilityService
  }

  /// Mutual Challenges Banner - Highlights shared habits
  Widget _buildMutualChallengesBanner(bool isDark) {
    // Mock data - check for shared habits
    final mutualHabits = ['💧 Water', '🏃 Exercise']; // Mock shared habits

    if (mutualHabits.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            const Color(0xFFEC4899).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Shared Goals',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: mutualHabits
                .map((habit) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        habit,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          Text(
            'You both have these habits — compete together! 💪',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  /// Show Nudge Bottom Sheet
  void _showNudgeSheet(BuildContext context) {
    final partner = widget.partner;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('🔔', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Nudge ${partner.partnerName}?',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Send a friendly reminder to complete their habits!',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA94A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${partner.remainingNudgesToday} nudges left today',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFA94A),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendNudge();
                      },
                      icon: const Icon(Icons.notifications_active, size: 18),
                      label: const Text('Send Nudge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA94A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _sendNudge() async {
    try {
      await AccountabilityService.instance.sendNudge(
        _partner.id,
        'Hey! Time to complete your habits! 💪',
      );
      // Update local state with new count
      if (mounted) {
        final now = DateTime.now();
        final newCount = _partner.nudgesSentToday + 1;
        setState(() {
          _partnerState = _partner.copyWith(
            lastNudgeSent: now,
            nudgesTodayCount: newCount,
            nudgeCountResetDate: now,
          );
        });
        final remaining = _partner.remainingNudgesToday;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🔔 Nudge sent! ${remaining > 0 ? "$remaining nudges left today" : "No more nudges today"}'),
            backgroundColor: const Color(0xFFFFA94A), // App theme orange
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Shared Habits List - Shows partner's habits
  Widget _buildSharedHabitsList(bool isDark) {
    // Mock data - replace with actual partner habits
    final sharedHabits = [
      {'emoji': '💧', 'name': 'Drink Water', 'done': true},
      {'emoji': '🏃', 'name': 'Exercise', 'done': false},
      {'emoji': '📚', 'name': 'Read 30 mins', 'done': true},
      {'emoji': '🧘', 'name': 'Meditate', 'done': false},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '${widget.partner.partnerName}\'s Habits',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${sharedHabits.where((h) => h['done'] == true).length}/${sharedHabits.length} today',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sharedHabits.map((habit) {
              final done = habit['done'] as bool;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF1FD1A5).withValues(alpha: 0.15)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: done
                        ? const Color(0xFF1FD1A5).withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(habit['emoji'] as String,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      habit['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (done) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle,
                          size: 14, color: Color(0xFF1FD1A5)),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
  }

  /// Combined Streak + Health Score row
  Widget _buildCombinedStatsRow(bool isDark) {
    final partner = widget.partner;
    final settings = _partnerSettings;
    final streakValue = partner.partnerCurrentStreak;
    const healthScore = 78; // Mock - replace with actual data

    return Row(
      children: [
        // Streak Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: settings != null && !settings.shareStreak
                ? _buildNotSharedMini(
                    'Streak', Icons.local_fire_department, isDark)
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            streakValue >= 7 ? '🔥' : '✨',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$streakValue',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD84315),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day Streak',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      // Always show a badge for consistent height
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: streakValue >= 7
                              ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                              : const Color(0xFFFFA94A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          streakValue >= 7
                              ? '🔥 HOT'
                              : streakValue > 0
                                  ? '✨ Building'
                                  : '🌱 Start',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: streakValue >= 7
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFFFFA94A)),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // Health Score Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: settings != null && !settings.shareHealthScore
                ? _buildNotSharedMini('Health', Icons.favorite, isDark)
                : Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            healthScore >= 75
                                ? '💚'
                                : healthScore >= 50
                                    ? '💛'
                                    : '❤️',
                            style: TextStyle(fontSize: 24),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '$healthScore',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1FD1A5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Health Score',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF1FD1A5).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          healthScore >= 75
                              ? '👍 Great'
                              : healthScore >= 50
                                  ? '📈 Good'
                                  : '🎯 Improving',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1FD1A5)),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
  }

  Widget _buildNotSharedMini(String title, IconData icon, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(height: 4),
        Text(
          '🔒 Private',
          style: TextStyle(
              fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
        ),
      ],
    );
  }

  Widget _buildWeeklyActivityCard(bool isDark) {
    final settings = _partnerSettings;

    if (settings != null && !settings.shareStreak) {
      return const SizedBox.shrink();
    }

    // Mock weekly data
    final weeklyData = [3, 5, 4, 6, 2, 5, 4];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxValue = weeklyData.reduce((a, b) => a > b ? a : b).toDouble();
    final today = DateTime.now().weekday - 1; // 0-6 for M-S

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA94A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('📊', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1FD1A5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${weeklyData.reduce((a, b) => a + b)} habits',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1FD1A5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = weeklyData[index];
                final height = maxValue > 0 ? (value / maxValue) * 50 : 0.0;
                final isToday = index == today;
                final isPast = index < today;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Value label
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? const Color(0xFFFFA94A)
                            : (isDark ? Colors.white54 : Colors.black38),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 28,
                      height: height + 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isToday
                              ? [
                                  const Color(0xFFFFA94A),
                                  const Color(0xFFFF6B6B),
                                ]
                              : isPast
                                  ? [
                                      const Color(0xFFFFA94A)
                                          .withValues(alpha: 0.7),
                                      const Color(0xFFFF8A3D)
                                          .withValues(alpha: 0.5),
                                    ]
                                  : [
                                      Colors.grey.withValues(alpha: 0.3),
                                      Colors.grey.withValues(alpha: 0.2),
                                    ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFA94A)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    )
                        .animate(delay: (index * 50).ms)
                        .fadeIn()
                        .slideY(begin: 0.3),
                    const SizedBox(height: 6),
                    // Day label
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFFFFA94A)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.w600,
                            color: isToday
                                ? Colors.white
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildAchievementsCard(bool isDark) {
    final settings = _partnerSettings;

    if (settings != null && !settings.shareAchievements) {
      return _buildNotSharedCard('Achievements', Icons.emoji_events, isDark);
    }

    // Get REAL unlocked achievements from PetAchievementService
    final unlockedAchievements =
        PetAchievementService.instance.unlockedAchievements;

    if (unlockedAchievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'No achievements yet. Keep going!',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '${unlockedAchievements.length} Achievements Earned',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: unlockedAchievements
                .take(8) // Show max 8 achievements
                .map((achievement) => Tooltip(
                      message:
                          '${achievement.name}: ${achievement.description}',
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFA94A).withValues(alpha: 0.2),
                              const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                const Color(0xFFFFA94A).withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(achievement.emoji,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    ))
                .toList(),
          ),
          if (unlockedAchievements.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '+${unlockedAchievements.length - 8} more achievements',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildNotSharedCard(String title, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '🔒 Not shared by this partner',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Connection Anniversary Badge - Shows how long connected
  Widget _buildConnectionAnniversary(bool isDark) {
    final partner = widget.partner;
    final daysTogether = DateTime.now().difference(partner.connectedAt).inDays;

    // Growing plant emoji based on days - like behavior detector
    String getGrowthEmoji(int days) {
      if (days >= 365) return '🏆'; // Trophy for a year
      if (days >= 100) return '🌲'; // Big tree for 100+ days
      if (days >= 30) return '🌳'; // Tree for 30+ days
      if (days >= 7) return '🌿'; // Leaves for 7+ days
      return '🌱'; // Seedling for new
    }

    String getMilestoneText(int days) {
      if (days >= 365) return 'A full year of accountability!';
      if (days >= 100) return 'Century club! Amazing commitment!';
      if (days >= 30) return 'One month strong together!';
      if (days >= 7) return 'First week milestone!';
      return 'Just getting started!';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFA94A).withValues(alpha: 0.2),
                  const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                getGrowthEmoji(daysTogether),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected for $daysTogether days',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  getMilestoneText(daysTogether),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA94A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '🤝',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
  }

  /// Head-to-Head Stats - Weekly/Monthly comparison
  Widget _buildHeadToHeadStats(bool isDark) {
    // Mock data - in production, fetch from AccountabilityService
    const yourWeekly = 23;
    const theirWeekly = 19;
    const yourMonthly = 87;
    const theirMonthly = 92;
    final partner = widget.partner;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚔️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Head-to-Head',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // This Week
          _buildH2HRow(
            'This Week',
            'You',
            yourWeekly,
            partner.partnerName.split(' ').first,
            theirWeekly,
            isDark,
          ),
          const SizedBox(height: 16),
          // This Month
          _buildH2HRow(
            'This Month',
            'You',
            yourMonthly,
            partner.partnerName.split(' ').first,
            theirMonthly,
            isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildH2HRow(String label, String you, int yourScore, String them,
      int theirScore, bool isDark) {
    final youWin = yourScore > theirScore;
    final tie = yourScore == theirScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: youWin
                      ? const Color(0xFF1FD1A5).withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: youWin
                      ? Border.all(
                          color: const Color(0xFF1FD1A5).withValues(alpha: 0.4))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(you,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87)),
                    Text(
                      '$yourScore',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: youWin
                            ? const Color(0xFF1FD1A5)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(tie ? '=' : 'vs',
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38)),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: !youWin && !tie
                      ? const Color(0xFFFFA94A).withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: !youWin && !tie
                      ? Border.all(
                          color: const Color(0xFFFFA94A).withValues(alpha: 0.4))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        them,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$theirScore',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !youWin && !tie
                            ? const Color(0xFFFFA94A)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Habit Chains Comparison - Top 3 habits vs friend
  Widget _buildHabitChainsComparison(bool isDark) {
    // Mock data for top 3 habits
    final habits = [
      {'name': 'Exercise', 'emoji': '🏃', 'yourStreak': 12, 'theirStreak': 8},
      {'name': 'Reading', 'emoji': '📚', 'yourStreak': 5, 'theirStreak': 14},
      {'name': 'Meditation', 'emoji': '🧘', 'yourStreak': 7, 'theirStreak': 7},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔗', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Habit Chains',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...habits.map((habit) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(habit['emoji'] as String,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStreakPill('You',
                                  habit['yourStreak'] as int, true, isDark),
                              const SizedBox(width: 8),
                              _buildStreakPill(
                                  widget.partner.partnerName.split(' ').first,
                                  habit['theirStreak'] as int,
                                  false,
                                  isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.1);
  }

  Widget _buildStreakPill(String name, int streak, bool isYou, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isYou
            ? const Color(0xFF1FD1A5).withValues(alpha: 0.15)
            : const Color(0xFFFFA94A).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '🔥$streak',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isYou ? const Color(0xFF1FD1A5) : const Color(0xFFFFA94A),
            ),
          ),
        ],
      ),
    );
  }

  /// Comparative Insights - Timing and patterns

  /// Activity Timeline - Recent completions
  Widget _buildActivityTimeline(bool isDark) {
    final partner = widget.partner;
    // Mock activity data
    final activities = [
      {'time': '2h ago', 'text': 'Completed Morning Run 🏃', 'emoji': '✅'},
      {
        'time': '5h ago',
        'text': 'Started 7-day meditation challenge',
        'emoji': '🧘'
      },
      {
        'time': 'Yesterday',
        'text': 'Reached 10-day reading streak! 📚',
        'emoji': '🔥'
      },
      {
        'time': '2 days ago',
        'text': 'Completed all daily habits',
        'emoji': '🌟'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                "${partner.partnerName}'s Activity",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...activities.asMap().entries.map((entry) {
            final index = entry.key;
            final activity = entry.value;
            final isLast = index == activities.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA94A).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(activity['emoji']!,
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32,
                        color: isDark
                            ? Colors.white12
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['text']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity['time']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 750.ms).slideY(begin: 0.1);
  }

  void _showCreateChallengeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateSharedChallengeSheet(
        partnerId: widget.partner.partnerUserId,
        partnerName: widget.partner.partnerName,
      ),
    );
  }
}
