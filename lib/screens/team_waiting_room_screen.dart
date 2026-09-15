import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../models/team.dart';
import '../services/team_service.dart';
import 'team_dashboard_screen.dart';

/// Screen shown while waiting for team members to join
class TeamWaitingRoomScreen extends StatefulWidget {
  final Team team;
  final TeamInviteCode inviteCode;

  const TeamWaitingRoomScreen({
    super.key,
    required this.team,
    required this.inviteCode,
  });

  @override
  State<TeamWaitingRoomScreen> createState() => _TeamWaitingRoomScreenState();
}

class _TeamWaitingRoomScreenState extends State<TeamWaitingRoomScreen> {
  late Team _team;
  late TeamInviteCode _inviteCode;
  bool _isRefreshing = false;

  // 2-minute countdown timer
  int _remainingSeconds = 120; // 2 minutes
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _team = widget.team;
    _inviteCode = widget.inviteCode;
    _startPolling();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _team.status == TeamStatus.active || _isExpired) return;

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _handleExpiry();
      } else {
        _startCountdown();
      }
    });
  }

  void _handleExpiry() async {
    if (_team.members.length <= 1) {
      // Only creator, no one joined - auto delete
      setState(() => _isExpired = true);

      try {
        await TeamService.instance.leaveTeam(_team.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏰ Team expired - no one joined in time'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('❌ Failed to delete expired team: $e');
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startPolling() {
    // Poll every 5 seconds to check for new members
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _team.status == TeamStatus.pending && !_isExpired) {
        _refreshTeam();
        _startPolling();
      }
    });
  }

  Future<void> _refreshTeam() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      await TeamService.instance.refreshTeams();
      final updatedTeam =
          TeamService.instance.teams.where((t) => t.id == _team.id).firstOrNull;

      if (updatedTeam != null && mounted) {
        setState(() => _team = updatedTeam);

        // Reset timer if someone joined
        if (updatedTeam.members.length > 1 && _remainingSeconds < 60) {
          setState(() => _remainingSeconds = 60); // Give 1 more minute
        }

        // Check if team is now active
        if (updatedTeam.isActive) {
          _navigateToTeamDashboard();
        }
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _navigateToTeamDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TeamDashboardScreen(team: _team),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingSlots = _team.maxMembers - _team.members.length;
    final expiryDuration = _inviteCode.timeUntilExpiry;
    final hours = expiryDuration.inHours;
    final minutes = expiryDuration.inMinutes % 60;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Team Waiting Room'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTeam,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header with team emoji
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFA94A).withValues(alpha: 0.3),
                      const Color(0xFFFF8A3D).withValues(alpha: 0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _team.teamEmoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ).animate().scale(delay: 100.ms),

            const SizedBox(height: 24),

            // Team name
            Center(
              child: Text(
                _team.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 8),

            // Status
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFFFFA94A)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for $remainingSlots more member${remainingSlots > 1 ? 's' : ''}...',
                      style: const TextStyle(
                        color: Color(0xFFFFA94A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            // Expiry Timer
            if (!_isExpired && _team.members.length <= 1)
              Center(
                child: Text(
                  'Expires in $_formattedTime',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),

            // Invite Code Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFA94A).withValues(alpha: 0.15),
                    const Color(0xFFFF8A3D).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Share this code with your team:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _inviteCode.code,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: Color(0xFFFFA94A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        icon: Icons.copy,
                        label: 'Copy',
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: _inviteCode.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied!')),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () {
                          Share.share(
                            'Join my team "${_team.name}" on Streakoo! Use code: ${_inviteCode.code}',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Expires in ${hours}h ${minutes}m',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          expiryDuration.inHours < 2 ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),

            // Members List
            Container(
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
                      const Spacer(),
                      if (_isRefreshing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Member slots
                  ...List.generate(_team.maxMembers, (index) {
                    if (index < _team.members.length) {
                      final member = _team.members[index];
                      return _buildMemberTile(
                        name: member.displayName ?? 'Member ${index + 1}',
                        isCreator: member.isCreator,
                        isJoined: true,
                        isDark: isDark,
                      );
                    } else {
                      return _buildMemberTile(
                        name: 'Waiting...',
                        isCreator: false,
                        isJoined: false,
                        isDark: isDark,
                      );
                    }
                  }),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Cancel button
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Team?'),
                    content: const Text(
                        'This will delete the team and the invite code. '
                        'Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Cancel Team'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  if (!context.mounted) return;
                  // TODO: Delete team via service
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Cancel Team',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFA94A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile({
    required String name,
    required bool isCreator,
    required bool isJoined,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isJoined
                  ? const Color(0xFFFFA94A).withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isJoined ? Icons.check : Icons.hourglass_empty,
              color: isJoined ? const Color(0xFFFFA94A) : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isJoined
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                    if (isCreator) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Creator',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFFFA94A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isJoined)
                  Text(
                    'Pending...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
