import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/user_level.dart';
import '../services/supabase_service.dart';
import '../services/health_service.dart';

import 'focus_task_manager_screen.dart';
import 'settings_screen.dart';
import '../widgets/bouncy_button.dart';
import '../services/logout_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final userLevel = appState.userLevel;
    final supabase = SupabaseService();
    final user = supabase.currentUser;
    final photoUrl =
        user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'];
    final userName = user?.userMetadata?['full_name'] ??
        user?.email?.split('@')[0] ??
        'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Info Card (NEW)
            if (supabase.isAuthenticated) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Level Card
            _LevelCard(userLevel: userLevel, photoUrl: photoUrl),
            const SizedBox(height: 24),

            // Stats Grid
            _StatsGrid(appState: appState),
            const SizedBox(height: 24),

            // Focus Tasks Button
            const _FocusTasksButton(),
            const SizedBox(height: 24),

            // Avatar Selection
            Text(
              'Choose Your Avatar',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _AvatarGrid(userLevel: userLevel),

            const SizedBox(height: 40),

            // Account Actions
            if (supabase.isAuthenticated) ...[
              const Divider(),
              const SizedBox(height: 16),
              BouncyButton(
                onPressed: () => LogoutService.performLogout(context),
                child: OutlinedButton.icon(
                  onPressed: null, // Handled by BouncyButton
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              BouncyButton(
                onPressed: () => _showDeleteAccountDialog(context, supabase),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_forever,
                          color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Text(
                        'Delete Account',
                        style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(
      BuildContext context, SupabaseService supabase) {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
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
              const Text('Please enter your password to confirm:'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
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
                          Navigator.pop(context); // Close dialog
                          Navigator.of(context)
                              .pushReplacementNamed('/'); // Go to login
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
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final UserLevel userLevel;
  final String? photoUrl;

  const _LevelCard({required this.userLevel, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Level and Title
          Text(
            'Level ${userLevel.level}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userLevel.titleName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${userLevel.currentXP} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${userLevel.xpToNextLevel} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: userLevel.progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
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
}

class _StatsGrid extends StatelessWidget {
  final AppState appState;

  const _StatsGrid({required this.appState});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _StatCard(
              icon: Icons.emoji_events,
              label: 'Total Habits',
              value: '${appState.totalHabits}',
              color: Colors.orange,
            ),
            _StatCard(
              icon: Icons.local_fire_department,
              label: 'Total Streaks',
              value: '${appState.totalStreaks}',
              color: Colors.red,
            ),
            _StatCard(
              icon: Icons.stars,
              label: 'Achievements',
              value: '${appState.achievements.length}',
              color: Colors.purple,
            ),
            _StatCard(
              icon: Icons.ac_unit,
              label: 'Streak Freezes',
              value: '${appState.streakFreezes}',
              color: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _HealthDataCard(),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AvatarGrid extends StatelessWidget {
  final UserLevel userLevel;

  const _AvatarGrid({required this.userLevel});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: availableAvatars.length,
      itemBuilder: (context, index) {
        final avatar = availableAvatars[index];
        final isUnlocked = userLevel.level >= avatar.unlockLevel;

        return _AvatarTile(
          avatar: avatar,
          isUnlocked: isUnlocked,
        );
      },
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final Avatar avatar;
  final bool isUnlocked;

  const _AvatarTile({
    required this.avatar,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked
            ? theme.cardColor
            : theme.cardColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.dividerColor.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUnlocked ? Icons.person : Icons.lock,
            size: 40,
            color: isUnlocked ? theme.colorScheme.primary : theme.disabledColor,
          ),
          const SizedBox(height: 8),
          Text(
            avatar.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isUnlocked ? null : theme.disabledColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 4),
            Text(
              'Lvl ${avatar.unlockLevel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.disabledColor,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FocusTasksButton extends StatelessWidget {
  const _FocusTasksButton();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final focusTaskCount = appState.habits.where((h) => h.isFocusTask).length;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const FocusTaskManagerScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Focus Tasks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Protected by streak freezes • $focusTaskCount active',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthDataCard extends StatefulWidget {
  const _HealthDataCard();

  @override
  State<_HealthDataCard> createState() => _HealthDataCardState();
}

class _HealthDataCardState extends State<_HealthDataCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<bool>(
      future: HealthService.instance.hasHealthDataAccess(),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.1),
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: isConnected ? Colors.pink : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Health Data',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isConnected) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Synced',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  if (isConnected)
                    FutureBuilder<Map<String, dynamic>>(
                      future: _fetchHealthStats(),
                      builder: (context, statsSnapshot) {
                        final stats = statsSnapshot.data ?? {};
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _HealthStat(
                              icon: Icons.directions_walk,
                              label: 'Steps',
                              value: stats['steps']?.toString() ?? '-',
                              color: Colors.orange,
                            ),
                            _HealthStat(
                              icon: Icons.bedtime,
                              label: 'Sleep',
                              value: stats['sleep'] != null
                                  ? '${stats['sleep'].toStringAsFixed(1)}h'
                                  : '-',
                              color: Colors.indigo,
                            ),
                            _HealthStat(
                              icon: Icons.favorite,
                              label: 'Heart',
                              value: stats['heart'] != null
                                  ? '${stats['heart']} bpm'
                                  : '-',
                              color: Colors.red,
                            ),
                          ],
                        );
                      },
                    )
                  else
                    // Blurred Placeholder Stats
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _HealthStat(
                          icon: Icons.directions_walk,
                          label: 'Steps',
                          value: '8,542',
                          isBlurred: true,
                        ),
                        _HealthStat(
                          icon: Icons.bedtime,
                          label: 'Sleep',
                          value: '7.5h',
                          isBlurred: true,
                        ),
                        _HealthStat(
                          icon: Icons.favorite,
                          label: 'Heart',
                          value: '72 bpm',
                          isBlurred: true,
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
              ),

              // Connect Overlay
              if (!isConnected)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: theme.cardColor.withOpacity(0.7),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SettingsScreen(),
                                        ),
                                      )
                                      .then((_) =>
                                          setState(() {})); // Refresh on return
                                },
                                icon: const Icon(Icons.link),
                                label: const Text('Connect Health Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Future<Map<String, dynamic>> _fetchHealthStats() async {
    final steps = await HealthService.instance.getTodaySteps();
    final sleep = await HealthService.instance.getTodaySleep();
    final heart = await HealthService.instance.getTodayHeartRate();
    return {
      'steps': steps,
      'sleep': sleep,
      'heart': heart,
    };
  }
}

class _HealthStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool isBlurred;

  const _HealthStat({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.isBlurred = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: isBlurred ? Colors.grey : (color ?? theme.colorScheme.primary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isBlurred ? Colors.grey : null,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isBlurred
                ? Colors.grey
                : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
