import 'package:flutter/material.dart';

enum InfoType { about, privacy }

class InfoScreen extends StatelessWidget {
  final InfoType type;

  const InfoScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFFFA94A); // Streakoo Orange

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          type == InfoType.about ? 'About Streakoo 🐣' : 'Privacy Policy 🛡️',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Big Header Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    type == InfoType.about ? '🚀' : '🔒',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Content
            if (type == InfoType.about) _buildAboutContent(context, isDark),
            if (type == InfoType.privacy) _buildPrivacyContent(context, isDark),

            const SizedBox(height: 48),

            // Footer
            Center(
              child: Text(
                'Made with ❤️ for you!',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('What is Streakoo?', '🌟'),
        _buildSectionText(
          'Streakoo is your friendly habit companion! It helps you build "superpowers" called habits. Every time you do something good (like drinking water or reading), you get stronger!',
          isDark,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Who is the Chicken?', '🐔'),
        _buildSectionText(
          'That\'s your new best friend! This little chicken watches you grow. If you keep your streaks going, the chicken stays happy and energetic. But if you forget your habits... the chicken might get sad!',
          isDark,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('What are Streaks?', '🔥'),
        _buildSectionText(
          'A streak is when you do something every single day without stopping. It shows how dedicated you are! Try to get a streak of 100 days... if you can!',
          isDark,
        ),
      ],
    );
  }

  Widget _buildPrivacyContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Your Secrets are Safe!', '🤫'),
        _buildSectionText(
          'Everything you do in Streakoo stays with you. We built this app to help YOU, not to spy on you.',
          isDark,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Where does data go?', '☁️'),
        _buildSectionText(
          'Your habits, your pet\'s name, and your streaks are saved on your phone. If you sign in, we save a backup in a secure cloud so you don\'t lose them if you change phones.',
          isDark,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('No Tracking!', '🚫'),
        _buildSectionText(
          'We don\'t track your location, we don\'t read your messages, and we don\'t verify what you eat. We trust you!',
          isDark,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily:
                    'Outfit', // Assuming app uses Outfit or similar rounded font
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionText(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: isDark ? Colors.grey[300] : Colors.grey[800],
        ),
      ),
    );
  }
}
