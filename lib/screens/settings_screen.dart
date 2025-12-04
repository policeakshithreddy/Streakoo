import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../services/supabase_service.dart';
import '../widgets/health_connection_card.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import '../services/logout_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _contactDeveloper(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'policeakshithreddy@gmail.com',
      queryParameters: {
        'subject': 'Streakoo App Feedback',
      },
    );

    try {
      await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email app: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themeMode = appState.themeMode;
    final supabase = SupabaseService();
    final user = supabase.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            if (supabase.isAuthenticated) ...[
              const Text(
                'Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: user?.userMetadata?['picture'] != null
                      ? NetworkImage(user!.userMetadata!['picture'])
                      : null,
                  child: user?.userMetadata?['picture'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(user?.userMetadata?['full_name'] ??
                    user?.email?.split('@')[0] ??
                    'User'),
                subtitle: const Text('View your profile & stats'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 50.ms)
                  .slideX(begin: 0.1, end: 0),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Health Data Section with comprehensive card
            const HealthConnectionCard()
                .animate()
                .fadeIn(duration: 300.ms, delay: 100.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            const Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 150.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 8),
            RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  context.read<AppState>().setThemeMode(mode);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('System'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Light'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Dark'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 200.ms)
                .slideX(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            const Text(
              'Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 250.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final supabase = SupabaseService();
                final isSignedIn = supabase.isAuthenticated;

                return ListTile(
                  leading: Icon(isSignedIn ? Icons.logout : Icons.login),
                  title: Text(isSignedIn ? 'Sign Out' : 'Sign In'),
                  subtitle: isSignedIn
                      ? Text(supabase.currentUser?.email ?? 'Signed in')
                      : const Text('Required for cloud backup'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    if (isSignedIn) {
                      await LogoutService.performLogout(context);
                    } else {
                      // Navigate to auth screen
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthScreen(),
                        ),
                      );

                      if (result == true && context.mounted) {
                        // Refresh the screen
                        (context as Element).markNeedsBuild();
                      }
                    }
                  },
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 300.ms)
                    .slideX(begin: 0.1, end: 0);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Support',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 350.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Contact Developer'),
              subtitle: const Text('Send feedback or report issues'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _contactDeveloper(context),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 400.ms)
                .slideX(begin: 0.1, end: 0),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 450.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Backup to Cloud'),
              subtitle: const Text('Sync your data to Supabase'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final appState = context.read<AppState>();

                // Show loading
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Backing up...'),
                        ],
                      ),
                      duration: Duration(seconds: 30),
                    ),
                  );
                }

                try {
                  await appState.backupToCloud();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Text('Backup successful!'),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Backup failed: $e')),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 500.ms)
                .slideX(begin: 0.1, end: 0),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Reset all habits & progress'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset everything?'),
                    content: const Text(
                        'This will remove all habits, streaks, and stats.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  context.read<AppState>().resetAll();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 550.ms)
                .slideX(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
}
