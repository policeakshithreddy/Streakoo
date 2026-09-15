import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage "What's New" popup on app updates
class WhatsNewService {
  WhatsNewService._();
  static final WhatsNewService instance = WhatsNewService._();

  static const String _lastSeenVersionKey = 'whats_new_last_seen_version';

  // Current app version - UPDATE THIS ON EACH RELEASE
  static const String currentVersion = '2.3.0';

  /// Check if user should see What's New (new version since last seen)
  Future<bool> shouldShowWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenVersion = prefs.getString(_lastSeenVersionKey);

    if (lastSeenVersion == null) {
      // First time - don't show (assume new install)
      await prefs.setString(_lastSeenVersionKey, currentVersion);
      return false;
    }

    // Show if version has changed
    return lastSeenVersion != currentVersion;
  }

  /// Mark current version as seen
  Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenVersionKey, currentVersion);
  }

  /// Get what's new content for current version
  List<WhatsNewItem> getWhatsNewItems() {
    return [
      WhatsNewItem(
        emoji: '🏆',
        title: 'Team Achievements',
        description:
            'Unlock badges like "Streak Starter", "Full Squad", and "Consistent" as your team hits milestones!',
      ),
      WhatsNewItem(
        emoji: '🔒',
        title: 'Enhanced Team Security',
        description:
            'Added Creator-only permissions for removing members and deleting teams to keep your squad safe.',
      ),
      WhatsNewItem(
        emoji: '👆',
        title: 'Swipe to Complete',
        description:
            'Team habits now feel just like your personal ones. Swipe right to complete, swipe left to skip!',
      ),
      WhatsNewItem(
        emoji: '👥',
        title: 'Real Member Profiles',
        description:
            'No more "Member 1". See your team members\' real names and profile pictures in the leaderboard.',
      ),
    ];
  }
}

class WhatsNewItem {
  final String emoji;
  final String title;
  final String description;

  WhatsNewItem({
    required this.emoji,
    required this.title,
    required this.description,
  });
}

/// Show What's New modal bottom sheet
void showWhatsNewDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final items = WhatsNewService.instance.getWhatsNewItems();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA94A), Color(0xFFFF8A3D)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 28),
                  )
                      .animate()
                      .shimmer(duration: 2.seconds, color: Colors.white24),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What's New! 🎉",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Text(
                        'Version ${WhatsNewService.currentVersion}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFFA94A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Items
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 100 * index))
                      .slideX(begin: 0.1);
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    WhatsNewService.instance.markAsSeen();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA94A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Let's Go! 🚀",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
