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
import 'welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // App theme colors
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryTeal = Color(0xFF1FD1A5);

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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Could not open email app: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool showArrow = true,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: (iconColor ?? _primaryOrange).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (iconColor ?? _primaryOrange)
                .withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? _primaryOrange, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: trailing ??
            (showArrow
                ? Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themeMode = appState.themeMode;
    final supabase = SupabaseService();
    final user = supabase.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            if (supabase.isAuthenticated) ...[
              _buildSectionHeader(
                      context, 'Profile', Icons.person_rounded, _primaryOrange)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: -0.1, end: 0),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1E1E), const Color(0xFF1A1A1A)]
                        : [Colors.white, const Color(0xFFFFF8F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _primaryOrange.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryOrange.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryOrange,
                          _primaryOrange.withValues(alpha: 0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: user?.userMetadata?['picture'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              user!.userMetadata!['picture'],
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.person_rounded,
                            color: Colors.white, size: 28),
                  ),
                  title: Text(
                    user?.userMetadata?['full_name'] ??
                        user?.email?.split('@')[0] ??
                        'User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'View your profile & stats',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  trailing: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _primaryOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: _primaryOrange),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 50.ms)
                  .slideX(begin: 0.1, end: 0),
            ],

            // Health Data Section
            _buildSectionHeader(context, 'Health', Icons.favorite_rounded,
                    Colors.redAccent.shade200)
                .animate()
                .fadeIn(duration: 300.ms, delay: 100.ms)
                .slideX(begin: -0.1, end: 0),
            const HealthConnectionCard()
                .animate()
                .fadeIn(duration: 300.ms, delay: 150.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // Appearance Section
            _buildSectionHeader(context, 'Appearance', Icons.color_lens_rounded,
                    _primaryOrange)
                .animate()
                .fadeIn(duration: 300.ms, delay: 200.ms)
                .slideX(begin: -0.1, end: 0),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  _buildThemeOption(
                      context,
                      'System',
                      Icons.settings_suggest_rounded,
                      ThemeMode.system,
                      themeMode),
                  Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1)),
                  _buildThemeOption(context, 'Light', Icons.light_mode_rounded,
                      ThemeMode.light, themeMode),
                  Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1)),
                  _buildThemeOption(context, 'Dark', Icons.dark_mode_rounded,
                      ThemeMode.dark, themeMode),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 250.ms)
                .slideX(begin: 0.1, end: 0),

            const SizedBox(height: 8),

            // Account Section
            _buildSectionHeader(context, 'Account',
                    Icons.person_outline_rounded, Colors.blueGrey)
                .animate()
                .fadeIn(duration: 300.ms, delay: 300.ms)
                .slideX(begin: -0.1, end: 0),
            Builder(
              builder: (context) {
                final supabase = SupabaseService();
                final isSignedIn = supabase.isAuthenticated;

                return _buildSettingsTile(
                  context: context,
                  icon: isSignedIn ? Icons.logout_rounded : Icons.login_rounded,
                  iconColor: isSignedIn ? Colors.redAccent : _secondaryTeal,
                  title: isSignedIn ? 'Sign Out' : 'Sign In',
                  subtitle: isSignedIn
                      ? supabase.currentUser?.email ?? 'Signed in'
                      : 'Required for cloud backup',
                  onTap: () async {
                    if (isSignedIn) {
                      await LogoutService.performLogout(context);
                    } else {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthScreen(),
                        ),
                      );

                      if (result == true && context.mounted) {
                        (context as Element).markNeedsBuild();
                      }
                    }
                  },
                );
              },
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 350.ms)
                .slideX(begin: 0.1, end: 0),

            const SizedBox(height: 8),

            // Support Section
            _buildSectionHeader(context, 'Support',
                    Icons.chat_bubble_outline_rounded, _primaryOrange)
                .animate()
                .fadeIn(duration: 300.ms, delay: 400.ms)
                .slideX(begin: -0.1, end: 0),
            _buildSettingsTile(
              context: context,
              icon: Icons.mail_outline_rounded,
              iconColor: _primaryOrange,
              title: 'Contact Developer',
              subtitle: 'Send feedback or report issues',
              onTap: () => _contactDeveloper(context),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 450.ms)
                .slideX(begin: 0.1, end: 0),

            const SizedBox(height: 8),

            // Data Section
            _buildSectionHeader(
                    context, 'Data', Icons.folder_open_rounded, _primaryOrange)
                .animate()
                .fadeIn(duration: 300.ms, delay: 500.ms)
                .slideX(begin: -0.1, end: 0),
            _buildSettingsTile(
              context: context,
              icon: Icons.cloud_upload_rounded,
              iconColor: _primaryOrange,
              title: 'Backup to Cloud',
              subtitle: 'Sync your data to Supabase',
              onTap: () => _performBackup(context),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 550.ms)
                .slideX(begin: 0.1, end: 0),
            _buildSettingsTile(
              context: context,
              icon: Icons.delete_forever_rounded,
              iconColor: Colors.redAccent,
              title: 'Reset All Data & Start Fresh',
              subtitle: 'Delete everything and restart',
              onTap: () => _performReset(context),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 600.ms)
                .slideX(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            // App version footer
            Center(
              child: Text(
                'Streakoo v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 650.ms),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String label, IconData icon,
      ThemeMode mode, ThemeMode currentMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = mode == currentMode;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryOrange.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? _primaryOrange
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? _primaryOrange
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: _primaryOrange, size: 22)
          : null,
      onTap: () {
        context.read<AppState>().setThemeMode(mode);
      },
    );
  }

  Future<void> _performBackup(BuildContext context) async {
    final appState = context.read<AppState>();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Backing up...'),
            ],
          ),
          backgroundColor: _secondaryTeal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 30),
        ),
      );
    }

    try {
      await appState.backupToCloud();

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Backup successful!'),
              ],
            ),
            backgroundColor: _secondaryTeal,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Backup failed: $e')),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _performReset(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Reset Everything?'),
          ],
        ),
        content: const Text(
          'This will permanently delete:\n\n'
          '• All your habits\n'
          '• All streaks & progress\n'
          '• Level & XP data\n'
          '• Health challenges\n\n'
          'You will be signed out and returned to the welcome screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Resetting all data...'),
            ],
          ),
          backgroundColor: _primaryOrange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      final appState = context.read<AppState>();
      await appState.resetAll();

      final supabase = SupabaseService();
      if (supabase.isAuthenticated) {
        await supabase.signOut();
      }

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }
}
