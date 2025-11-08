// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streakoo/providers/app_provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final subtitleStyle = theme.textTheme.bodySmall
        ?.copyWith(color: colorScheme.onSurface.withOpacity(0.65));
    final sectionStyle =
        theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('General', style: sectionStyle),
          const SizedBox(height: 8),
          Card(
            color: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTile(
                    context,
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English',
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final choice = await showModalBottomSheet<String>(
                          context: context,
                          builder: (_) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                    title: const Text('English'),
                                    onTap: () =>
                                        Navigator.pop(context, 'English')),
                                ListTile(
                                    title: const Text('Spanish'),
                                    onTap: () =>
                                        Navigator.pop(context, 'Spanish')),
                              ],
                            );
                          });
                      if (choice != null && mounted) {
                        messenger.showSnackBar(
                            SnackBar(content: Text('Language set to $choice')));
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildTile(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'Week starts on',
                    subtitle: 'Monday',
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final choice = await showModalBottomSheet<String>(
                          context: context,
                          builder: (_) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                    title: const Text('Sunday'),
                                    onTap: () =>
                                        Navigator.pop(context, 'Sunday')),
                                ListTile(
                                    title: const Text('Monday'),
                                    onTap: () =>
                                        Navigator.pop(context, 'Monday')),
                              ],
                            );
                          });
                      if (choice != null && mounted) {
                        messenger.showSnackBar(
                            SnackBar(content: Text('Week starts on $choice')));
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildTile(
                    context,
                    icon: Icons.brightness_6_outlined,
                    title: 'Theme',
                    subtitle: app.themeMode == ThemeMode.dark
                        ? 'Dark'
                        : app.themeMode == ThemeMode.light
                            ? 'Light'
                            : 'System',
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Appearance', style: sectionStyle),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            value: ThemeMode.system,
            groupValue: app.themeMode,
            onChanged: (v) => app.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: app.themeMode,
            onChanged: (v) => app.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: app.themeMode,
            onChanged: (v) => app.setThemeMode(v!),
          ),
          const SizedBox(height: 24),
          Text('About', style: sectionStyle),
          const SizedBox(height: 8),
          Card(
            color: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTile(
                    context,
                    icon: Icons.info_outline,
                    title: 'About this app',
                    subtitle: 'Streakoo — build habits, track streaks',
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    onTap: null,
                  ),
                  const SizedBox(height: 6),
                  _buildTile(
                    context,
                    icon: Icons.cloud_download_outlined,
                    title: 'Backups',
                    subtitle: 'Export and import your data',
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final choice = await showModalBottomSheet<String>(
                          context: context,
                          builder: (_) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                    leading: const Icon(Icons.upload_outlined),
                                    title: const Text('Export'),
                                    onTap: () =>
                                        Navigator.pop(context, 'export')),
                                ListTile(
                                    leading:
                                        const Icon(Icons.download_outlined),
                                    title: const Text('Import'),
                                    onTap: () =>
                                        Navigator.pop(context, 'import')),
                              ],
                            );
                          });
                      if (choice == 'export') {
                        await Clipboard.setData(const ClipboardData(
                            text: 'backup-data-placeholder'));
                        if (mounted) {
                          messenger.showSnackBar(const SnackBar(
                              content: Text('Backup copied to clipboard')));
                        }
                      } else if (choice == 'import') {
                        if (mounted) {
                          messenger.showSnackBar(const SnackBar(
                              content: Text('Import not implemented yet')));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildTile(
                    context,
                    icon: Icons.archive_outlined,
                    title: 'Archived Habits',
                    subtitle: 'Access your archived habits',
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    onTap: () {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Archived Habits not implemented')));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Engage', style: sectionStyle),
          const SizedBox(height: 8),
          Card(
            color: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTile(
                    context,
                    icon: Icons.share,
                    title: 'Share app',
                    subtitle: 'Share Habit Streak with a friend!',
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      const shareText =
                          'Check out Streakoo — build habits and track streaks!';
                      await Clipboard.setData(
                          const ClipboardData(text: shareText));
                      if (mounted) {
                        messenger.showSnackBar(const SnackBar(
                            content: Text('Share text copied to clipboard')));
                      }
                    },
                    iconBgColor: Colors.green,
                  ),
                  const SizedBox(height: 6),
                  _buildTile(
                    context,
                    icon: Icons.star,
                    title: 'Review app',
                    subtitle:
                        'Help us grow by leaving a 5 stars review in the store!',
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final url = Uri.parse('https://example.com/review');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        await Clipboard.setData(
                            ClipboardData(text: url.toString()));
                        if (mounted) {
                          messenger.showSnackBar(const SnackBar(
                              content:
                                  Text('Review link copied to clipboard')));
                        }
                      }
                    },
                    iconBgColor: Colors.orange,
                  ),
                  const SizedBox(height: 6),
                  _buildTile(
                    context,
                    icon: Icons.mail_outline,
                    title: 'Contact developer',
                    subtitle: 'Let me know how I can help you :)',
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: 'policeakshithreddy@gmail.com',
                      );
                      if (await canLaunchUrl(emailLaunchUri)) {
                        await launchUrl(emailLaunchUri);
                      } else {
                        await Clipboard.setData(const ClipboardData(
                            text: 'policeakshithreddy@gmail.com'));
                        if (mounted) {
                          messenger.showSnackBar(const SnackBar(
                              content:
                                  Text('Cannot open mail app — email copied')));
                        }
                      }
                    },
                    iconBgColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    VoidCallback? onTap,
    Color? iconBgColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultBg = isDark ? Colors.grey[800] : Colors.grey[200];
    final bg = iconBgColor ?? defaultBg;
    final iconColor = iconBgColor != null
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final shadowColor = isDark ? Colors.black26 : Colors.black12;

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: shadowColor, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: titleStyle ?? theme.textTheme.titleMedium),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: subtitleStyle ?? theme.textTheme.bodySmall),
      onTap: onTap,
    );
  }
}
