import 'package:flutter/material.dart';
import '../models/accountability_partner.dart';

class AccountabilityPrivacySheet extends StatefulWidget {
  final AccountabilityPrivacySettings initialSettings;
  final Function(AccountabilityPrivacySettings) onSave;
  final String partnerName;

  const AccountabilityPrivacySheet({
    super.key,
    required this.initialSettings,
    required this.onSave,
    required this.partnerName,
  });

  @override
  State<AccountabilityPrivacySheet> createState() =>
      _AccountabilityPrivacySheetState();
}

class _AccountabilityPrivacySheetState
    extends State<AccountabilityPrivacySheet> {
  late AccountabilityPrivacySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.privacy_tip_outlined, color: theme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sharing Settings',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Connected with ${widget.partnerName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose what you want to share with your new partner. You can change this later in settings.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 32),
          _buildToggle(
            title: 'Share Streak Number',
            subtitle: 'Let them see your total active streak days.',
            value: _settings.shareStreak,
            onChanged: (val) => setState(
                () => _settings = _settings.copyWith(shareStreak: val)),
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
          const Divider(height: 32),
          _buildToggle(
            title: 'Share Health Score',
            subtitle: 'Share your overall weekly health performance.',
            value: _settings.shareHealthScore,
            onChanged: (val) => setState(
                () => _settings = _settings.copyWith(shareHealthScore: val)),
            icon: Icons.favorite,
            color: Colors.redAccent,
          ),
          const Divider(height: 32),
          _buildToggle(
            title: 'Share Achievements',
            subtitle: 'Display your badges and milestones.',
            value: _settings.shareAchievements,
            onChanged: (val) => setState(
                () => _settings = _settings.copyWith(shareAchievements: val)),
            icon: Icons.emoji_events,
            color: Colors.amber,
          ),
          const Divider(height: 32),
          _buildToggle(
            title: 'Share Habit Details',
            subtitle: 'Show which habits you are currently tracking.',
            value: _settings.shareHabitDetails,
            onChanged: (val) => setState(
                () => _settings = _settings.copyWith(shareHabitDetails: val)),
            icon: Icons.list_alt,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_settings);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save and Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}
