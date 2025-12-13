import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What's New dialog to show recent app enhancements to returning users
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  // Current app version for tracking shown updates
  static const String currentVersion = '2.2.0';
  static const String _prefsKey = 'whats_new_version_shown';

  // App theme colors (Orange)
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryOrange = Color(0xFFFF8C42);

  /// Check if we should show the What's New dialog
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_prefsKey);
    return lastShown != currentVersion;
  }

  /// Mark the dialog as shown for this version
  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, currentVersion);
  }

  /// Show the What's New dialog if needed
  static Future<void> showIfNeeded(BuildContext context) async {
    if (await shouldShow()) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const WhatsNewDialog(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 650),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _primaryOrange.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryOrange.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryOrange.withValues(alpha: 0.15),
                    _secondaryOrange.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryOrange, _secondaryOrange],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryOrange.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(duration: 2.seconds, color: Colors.white30),
                  const SizedBox(height: 16),
                  Text(
                    "What's New! ✨",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version $currentVersion',
                    style: TextStyle(
                      fontSize: 13,
                      color: _primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Features list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem(
                      '🤖',
                      'AI Habit Coach',
                      'Meet your new personal assistant! Chat with AI to set perfect goals and get tailored advice.',
                      isDark,
                      0,
                    ),
                    _buildFeatureItem(
                      '🌬️',
                      'Wind Insights',
                      'Deep health analysis powered by Wind AI. Understand your patterns like never before.',
                      isDark,
                      1,
                    ),
                    _buildFeatureItem(
                      '🧘',
                      'Focus Mode',
                      'Boost productivity with the nested Focus Timer. Perfect for deep work and meditation.',
                      isDark,
                      2,
                    ),
                    _buildFeatureItem(
                      '📋',
                      'Habit Templates',
                      'Jumpstart your journey with curated templates for health, productivity, and mindfulness.',
                      isDark,
                      3,
                    ),
                    _buildFeatureItem(
                      '📊',
                      'Weekly Summary',
                      'Track your progress with the redesigned, premium weekly report card.',
                      isDark,
                      4,
                    ),
                    _buildFeatureItem(
                      '🎉',
                      'Year in Review',
                      'See your 2025 stats with beautiful animated slides and share your achievements.',
                      isDark,
                      5,
                    ),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  markAsShown();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryOrange, Color(0xFFFF8C42)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryOrange.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Let's Go! 🚀",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).scale(
                    begin: const Offset(0.9, 0.9),
                  ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(
          begin: const Offset(0.9, 0.9),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildFeatureItem(
    String emoji,
    String title,
    String description,
    bool isDark,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryOrange.withValues(alpha: 0.15),
                  _secondaryOrange.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(
          begin: 0.1,
        );
  }
}
