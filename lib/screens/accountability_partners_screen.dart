import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../services/accountability_service.dart';
import '../services/team_service.dart';
import '../models/accountability_partner.dart';
import '../models/team.dart';

import '../widgets/accountability_privacy_sheet.dart';
import 'partner_profile_screen.dart';
import 'team_waiting_room_screen.dart';
import 'team_dashboard_screen.dart';

/// Screen for managing accountability partners
class AccountabilityPartnersScreen extends StatefulWidget {
  const AccountabilityPartnersScreen({super.key});

  @override
  State<AccountabilityPartnersScreen> createState() =>
      _AccountabilityPartnersScreenState();
}

class _AccountabilityPartnersScreenState
    extends State<AccountabilityPartnersScreen> with WidgetsBindingObserver {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _myInviteCode;
  String? _error;

  // Team mode state
  bool _isTeamMode = false;
  int _teamSize = 3;

  // Pending team invites
  List<Map<String, dynamic>> _pendingTeamInvites = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await AccountabilityService.instance.initialize();
      await AccountabilityService.instance.refreshPartners();

      // Load user's teams
      await TeamService.instance.refreshTeams();

      // Load pending team invites
      final invites = await TeamService.instance.getPendingInvites();
      if (mounted) {
        setState(() => _pendingTeamInvites = invites);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final partners = AccountabilityService.instance.activePartners;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Accountability Partners'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pending Team Invites Banner
                    if (_pendingTeamInvites.isNotEmpty) ...[
                      _buildPendingInvitesBanner(isDark),
                      const SizedBox(height: 16),
                    ],

                    // Header
                    _buildHeader(isDark),
                    const SizedBox(height: 24),

                    // Invite Section
                    _buildInviteSection(isDark),
                    const SizedBox(height: 24),

                    // Connect with Code
                    _buildConnectSection(isDark),
                    const SizedBox(height: 32),

                    // Partners List
                    if (partners.isNotEmpty) ...[
                      Text(
                        'Your Partners',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...partners.map((p) => _buildPartnerCard(p, isDark)),
                    ] else
                      _buildEmptyState(isDark),

                    // Your Teams Section
                    if (TeamService.instance.teams.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text(
                        'Your Teams',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...TeamService.instance.teams
                          .map((team) => _buildTeamCard(team, isDark)),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPendingInvitesBanner(bool isDark) {
    return Column(
      children: _pendingTeamInvites.map((invite) {
        final teamData = invite['teams'] as Map<String, dynamic>?;
        final teamName = teamData?['name'] ?? 'A Team';
        final teamEmoji = teamData?['emoji'] ?? '🔥';
        final inviteId = invite['id'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFA94A).withValues(alpha: isDark ? 0.25 : 0.15),
                const Color(0xFFFF6B6B).withValues(alpha: isDark ? 0.15 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFA94A).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(teamEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎯 Team Invite!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFA94A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join "$teamName"',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToInvite(inviteId, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondToInvite(inviteId, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA94A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _respondToInvite(String inviteId, bool accept) async {
    try {
      final success =
          await TeamService.instance.respondToInvite(inviteId, accept);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(accept ? '🎉 You joined the team!' : 'Invite declined'),
            backgroundColor: accept ? const Color(0xFF1FD1A5) : Colors.grey,
          ),
        );
        await _loadData(); // Refresh to remove the invite from list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTeamCard(Team team, bool isDark) {
    final memberCount = team.members.length;
    final statusText =
        team.status == TeamStatus.active ? 'Active' : 'Waiting for members';
    final statusColor = team.status == TeamStatus.active
        ? const Color(0xFF1FD1A5)
        : const Color(0xFFFFA94A);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamDashboardScreen(team: team),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Team Emoji
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFA94A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  team.teamEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Team Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$memberCount/${team.maxMembers} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final partners = AccountabilityService.instance.activePartners;
    const maxFriends = 4;
    final remaining = maxFriends - partners.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFA94A).withValues(alpha: 0.2),
            const Color(0xFFFF6B6B).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🤝', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay Accountable!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Partners get notified when you miss a habit.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Friends capacity indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(maxFriends, (i) {
                  final isFilled = i < partners.length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isFilled ? Icons.person : Icons.person_outline,
                      color: isFilled
                          ? const Color(0xFFFFA94A)
                          : (isDark ? Colors.white30 : Colors.black26),
                      size: 20,
                    ),
                  );
                }),
                const SizedBox(width: 10),
                Text(
                  remaining > 0 ? '$remaining slots available' : 'Full!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        remaining > 0 ? const Color(0xFF1FD1A5) : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildInviteSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.link, color: Color(0xFFFFA94A)),
              const SizedBox(width: 8),
              Text(
                'Create Invite',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Partner/Team Toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isTeamMode = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isTeamMode
                          ? const Color(0xFFFFA94A).withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      border: Border.all(
                        color: !_isTeamMode
                            ? const Color(0xFFFFA94A)
                            : Colors.grey.withValues(alpha: 0.3),
                        width: !_isTeamMode ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text('👥', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          'Partner',
                          style: TextStyle(
                            fontWeight: !_isTeamMode
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: !_isTeamMode
                                ? const Color(0xFFFFA94A)
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                        Text(
                          '1 on 1',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isTeamMode = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isTeamMode
                          ? const Color(0xFFFFA94A).withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(12),
                      ),
                      border: Border.all(
                        color: _isTeamMode
                            ? const Color(0xFFFFA94A)
                            : Colors.grey.withValues(alpha: 0.3),
                        width: _isTeamMode ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text('🚀', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          'Team',
                          style: TextStyle(
                            fontWeight: _isTeamMode
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _isTeamMode
                                ? const Color(0xFFFFA94A)
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                        Text(
                          '2-4 people',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Team Size Selector (only when team mode)
          if (_isTeamMode) ...[
            Text(
              'Team Size:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [2, 3, 4].map((size) {
                final isSelected = _teamSize == size;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _teamSize = size),
                    child: Container(
                      margin: EdgeInsets.only(right: size < 4 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFA94A).withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFA94A)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$size',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFFFFA94A)
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                          Text(
                            'people',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Show existing code or generate button
          if (!_isTeamMode && _myInviteCode != null) ...[
            // Partner invite code display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA94A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Partner Code:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _myInviteCode!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Color(0xFFFFA94A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _myInviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Color(0xFFFFA94A)),
                  ),
                  IconButton(
                    onPressed: () {
                      Share.share(
                        'Join me on Streakoo! Use my partner code: $_myInviteCode',
                      );
                    },
                    icon: const Icon(Icons.share, color: Color(0xFFFFA94A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Code expires in 24 hours',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ] else ...[
            // Generate code button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTeamMode ? _createTeam : _generateInviteCode,
                icon: Icon(_isTeamMode ? Icons.group_add : Icons.add),
                label: Text(_isTeamMode
                    ? 'Create Team ($_teamSize people)'
                    : 'Generate Partner Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTeamMode
                      ? const Color(0xFFFFA94A)
                      : const Color(0xFFFFA94A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Future<void> _createTeam() async {
    // Get existing partners for selection
    final existingPartners = AccountabilityService.instance.activePartners;
    final selectedPartnerIds = <String>{};

    // Show name + partner selection dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: 'My Team');
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Your Team'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Fitness Squad',
                          labelText: 'Team Name',
                        ),
                        autofocus: true,
                      ),
                      if (existingPartners.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Invite Existing Partners',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'They\'ll receive a notification to join',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...existingPartners.map((partner) => CheckboxListTile(
                              value: selectedPartnerIds
                                  .contains(partner.partnerUserId),
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selectedPartnerIds
                                        .add(partner.partnerUserId);
                                  } else {
                                    selectedPartnerIds
                                        .remove(partner.partnerUserId);
                                  }
                                });
                              },
                              title: Text(partner.partnerName),
                              subtitle: Text(
                                '🔥 ${partner.partnerCurrentStreak} day streak',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white38 : Colors.black45,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              activeColor: const Color(0xFFFFA94A),
                              secondary: CircleAvatar(
                                backgroundColor: const Color(0xFFFFA94A)
                                    .withValues(alpha: 0.2),
                                child: Text(
                                  partner.partnerName.isNotEmpty
                                      ? partner.partnerName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFA94A),
                                  ),
                                ),
                              ),
                            )),
                      ] else ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFA94A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 20, color: Color(0xFFFFA94A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Connect with partners first, then invite them to teams!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'name': controller.text.trim(),
                    'partnerIds': selectedPartnerIds.toList(),
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA94A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    final teamName = result['name'] as String?;
    final partnerIds = result['partnerIds'] as List<String>? ?? [];
    if (teamName == null || teamName.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // Create the team
      final team = await TeamService.instance.createTeam(
        name: teamName,
        maxMembers: _teamSize,
      );

      if (team == null) throw Exception('Failed to create team');

      // Generate invite code
      final inviteCode = await TeamService.instance.generateInviteCode(team.id);
      if (inviteCode == null) throw Exception('Failed to generate invite code');

      // Send invites to selected partners
      if (partnerIds.isNotEmpty) {
        for (final partnerId in partnerIds) {
          await TeamService.instance.sendTeamInvite(
            teamId: team.id,
            toUserId: partnerId,
            teamName: teamName,
          );
        }
        debugPrint('📨 Sent team invites to ${partnerIds.length} partners');
      }

      // Navigate to waiting room
      if (mounted) {
        if (partnerIds.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '🎉 Team created! Invites sent to ${partnerIds.length} partner(s)'),
              backgroundColor: const Color(0xFF1FD1A5),
            ),
          );
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamWaitingRoomScreen(
              team: team,
              inviteCode: inviteCode,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildConnectSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.person_add, color: Color(0xFFFFA94A)),
              const SizedBox(width: 8),
              Text(
                'Connect with Partner',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter partner or team invite code',
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.qr_code),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _connectWithCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA94A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Connect'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildPartnerCard(AccountabilityPartner partner, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PartnerProfileScreen(partner: partner),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: partner.hasMissedToday
                  ? Colors.orange.withValues(alpha: 0.5)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFFA94A).withValues(alpha: 0.2),
                child: Text(
                  partner.partnerName.isNotEmpty
                      ? partner.partnerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFA94A),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.partnerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${partner.partnerCurrentStreak} day streak',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    if (partner.hasMissedToday)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⚠️ Missed a habit today',
                          style: TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ),
                  ],
                ),
              ),

              // Nudge button
              IconButton(
                onPressed: partner.canSendNudge
                    ? () => _showNudgeDialog(partner)
                    : null,
                icon: Icon(
                  Icons.notifications_active,
                  color: partner.canSendNudge
                      ? const Color(0xFFFFA94A)
                      : Colors.grey,
                ),
                tooltip: partner.canSendNudge
                    ? 'Send Nudge'
                    : 'Cooldown: ${partner.nudgeCooldownRemaining?.inMinutes}min',
              ),

              // More options menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    _confirmRemovePartner(partner);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Remove Partner',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1);
  }

  Future<void> _confirmRemovePartner(AccountabilityPartner partner) async {
    // Calculate connection duration
    final connectionDays =
        DateTime.now().difference(partner.connectedAt).inDays;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Remove ${partner.partnerName}?',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Streak warning box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                    Colors.orange.withValues(alpha: isDark ? 0.1 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connection Streak Lost!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          connectionDays > 0
                              ? 'Your $connectionDays day connection will be gone forever'
                              : 'Your connection will be removed',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Partner info summary
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      const Color(0xFFFFA94A).withValues(alpha: 0.2),
                  child: Text(
                    partner.partnerName.isNotEmpty
                        ? partner.partnerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFA94A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.partnerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '🔥 ${partner.partnerCurrentStreak} day streak',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone. You will need a new invite code to reconnect.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yes, Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await AccountabilityService.instance.removePartner(partner.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${partner.partnerName} has been removed.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('👥', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'No partners yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite a friend to stay accountable together!',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _generateInviteCode() async {
    setState(() => _isLoading = true);
    try {
      final code = await AccountabilityService.instance.generateInviteCode();
      setState(() => _myInviteCode = code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectWithCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // Try joining as team first, but catch errors so we can fall through to partner
      Team? team;
      try {
        team = await TeamService.instance.joinTeamWithCode(code);
      } catch (teamError) {
        // Log but don't throw - we'll try partner connection next
        debugPrint('⚠️ Team join failed (trying partner): $teamError');
      }

      if (team != null) {
        _codeController.clear();
        await _loadData(); // Reload to show the new team

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Joined team "${team.name}"!'),
              backgroundColor: const Color(0xFF1FD1A5),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to team dashboard
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamDashboardScreen(team: team!),
            ),
          );
        }
        return;
      }

      // If not a team, try connecting as a partner
      final partner =
          await AccountabilityService.instance.connectWithCode(code);

      if (partner != null) {
        _codeController.clear();
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Connected with partner!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Show privacy settings popup
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AccountabilityPrivacySheet(
              partnerName: partner.partnerName,
              initialSettings:
                  AccountabilityPrivacySettings(), // Default settings
              onSave: (settings) {
                debugPrint(
                    'Privacy settings saved for ${partner.id}: ${settings.toJson()}');
                AccountabilityService.instance
                    .updatePrivacySettings(partner.id, settings);
              },
            ),
          );
        }
      } else {
        throw Exception('Invalid invite code');
      }
    } catch (e) {
      if (mounted) {
        // formatting error message to be more user friendly
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (errorMessage.contains('Invalid invite code')) {
          errorMessage = 'Invalid invite code. Please check and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNudgeDialog(AccountabilityPartner partner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _NudgeSheet(
        partner: partner,
        onSend: (message) async {
          await AccountabilityService.instance.sendNudge(
            partner.id,
            message,
          );
          if (mounted && context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📲 Nudge sent!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }
}

/// Bottom sheet for sending nudges
class _NudgeSheet extends StatelessWidget {
  final AccountabilityPartner partner;
  final Function(String) onSend;

  const _NudgeSheet({required this.partner, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Nudge to ${partner.partnerName}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Quick messages
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NudgeMessages.encouraging.take(4).map((msg) {
              return GestureDetector(
                onTap: () => onSend(msg),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA94A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Gentle messages
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NudgeMessages.gentle.take(3).map((msg) {
              return GestureDetector(
                onTap: () => onSend(msg),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
