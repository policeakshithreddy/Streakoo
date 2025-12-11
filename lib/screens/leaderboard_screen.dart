import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_score.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardEntry> _globalLeaderboard = [];
  List<LeaderboardEntry> _weeklyLeaderboard = [];
  bool _isLoading = true;
  bool _hasAskedPermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPrivacyAndLoad();
  }

  Future<void> _checkPrivacyAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _hasAskedPermission = prefs.getBool('leaderboard_privacy_asked') ?? false;

    if (!_hasAskedPermission) {
      // First time - show privacy dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPrivacyDialog();
      });
    } else {
      _loadLeaderboards();
    }
  }

  Future<void> _showPrivacyDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPrivacyDialog(),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('leaderboard_privacy_asked', true);
      await prefs.setBool('leaderboard_public', result);

      setState(() {
        _hasAskedPermission = true;
      });

      if (result) {
        // User opted in - sync their score to leaderboard
        // TODO: Implement this when leaderboard sync is ready
        // if (mounted) {
        //   final appState = context.read<AppState>();
        //   appState.updateLeaderboardScore();
        // }
      }

      _loadLeaderboards();
    }
  }

  Widget _buildPrivacyDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFF8B5CF6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Join the Leaderboard?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compete with users worldwide and see how you rank!',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your username and score will be visible to others',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You can change this anytime in Settings.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Stay Private'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
          ),
          child: const Text('Join Leaderboard'),
        ),
      ],
    );
  }

  Future<void> _loadLeaderboards() async {
    setState(() => _isLoading = true);

    try {
      final global = await LeaderboardService.instance.fetchGlobalLeaderboard();
      final weekly = await LeaderboardService.instance.fetchWeeklyLeaderboard();

      setState(() {
        _globalLeaderboard = global;
        _weeklyLeaderboard = weekly;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading leaderboards: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      appBar: AppBar(
        title: const Text('🏆 Leaderboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          labelColor: const Color(0xFF8B5CF6),
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Weekly'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLeaderboards,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildLeaderboardList(_globalLeaderboard, isDark,
                      isWeekly: false),
                  _buildLeaderboardList(_weeklyLeaderboard, isDark,
                      isWeekly: true),
                ],
              ),
      ),
    );
  }

  Widget _buildLeaderboardList(
    List<LeaderboardEntry> entries,
    bool isDark, {
    required bool isWeekly,
  }) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No rankings yet',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length + 1, // +1 for podium
      itemBuilder: (context, index) {
        // Podium (top 3)
        if (index == 0) {
          return _buildPodium(entries.take(3).toList(), isDark);
        }

        // Regular entries
        final entry = entries[index - 1];
        if (index <= 3)
          return const SizedBox.shrink(); // Skip top 3 (shown in podium)

        return _buildLeaderboardTile(entry, isDark, isWeekly: isWeekly);
      },
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> topThree, bool isDark) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            const Color(0xFFEC4899).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🏆 Top 3',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              if (topThree.length > 1)
                _buildPodiumPlace(topThree[1], 2, isDark, height: 100),
              // 1st place (tallest)
              _buildPodiumPlace(topThree[0], 1, isDark, height: 130),
              // 3rd place
              if (topThree.length > 2)
                _buildPodiumPlace(topThree[2], 3, isDark, height: 80),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(
    LeaderboardEntry entry,
    int place,
    bool isDark, {
    required double height,
  }) {
    return Column(
      children: [
        Text(
          entry.rankBadge,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 4),
        Text(
          entry.userScore.username,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${entry.userScore.totalScore} pts',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B5CF6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                const Color(0xFFEC4899).withValues(alpha: 0.6),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$place',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(
    LeaderboardEntry entry,
    bool isDark, {
    required bool isWeekly,
  }) {
    final score = isWeekly
        ? entry.userScore.currentWeekScore
        : entry.userScore.totalScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
            : isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isCurrentUser
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
              : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey[200]!,
          width: entry.isCurrentUser ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.rankBadge,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: entry.isCurrentUser
                    ? const Color(0xFF8B5CF6)
                    : isDark
                        ? Colors.white70
                        : Colors.black54,
              ),
            ),
          ],
        ),
        title: Text(
          entry.userScore.username,
          style: TextStyle(
            fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          entry.userScore.scoreTier,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B5CF6),
          ),
        ),
        trailing: Text(
          '$score pts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: entry.isCurrentUser
                ? const Color(0xFF8B5CF6)
                : isDark
                    ? Colors.white
                    : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
