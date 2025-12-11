import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Onboarding tutorial carousel
class OnboardingTutorial extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingTutorial({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingTutorial> createState() => _OnboardingTutorialState();
}

class _OnboardingTutorialState extends State<OnboardingTutorial> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      emoji: '🎯',
      title: 'Track Your Habits',
      description:
          'Set goals and track your daily habits with ease. Build consistency one day at a time.',
    ),
    OnboardingPage(
      emoji: '🔥',
      title: 'Build Streaks',
      description:
          'Maintain your daily streaks and watch your progress grow. Every day counts!',
    ),
    OnboardingPage(
      emoji: '🛡️',
      title: 'Streak Protection',
      description:
          'Use streak freezes to protect your progress when life gets busy.',
    ),
    OnboardingPage(
      emoji: '🤖',
      title: 'Meet Wind 🌬️',
      description:
          'Meet Wind, your personal habit guide. Get personalized insights and motivation.',
    ),
    OnboardingPage(
      emoji: '🏆',
      title: 'Earn Rewards',
      description:
          'Complete challenges, level up, and unlock achievements as you build better habits.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: DesignTokens.durationNormal,
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: DesignTokens.fontSizeMD,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], isDark);
                },
              ),
            ),

            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color(0xFFFFA94A)
                        : (isDark ? Colors.white30 : Colors.black26),
                  ),
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.space6),

            // Next button
            Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space4,
                    ),
                    backgroundColor: const Color(0xFFFFA94A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignTokens.borderRadiusLG,
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeLG,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFA94A).withValues(alpha: 0.2),
                  const Color(0xFF1FD1A5).withValues(alpha: 0.15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 72),
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: DesignTokens.fontSize3XL,
              fontWeight: DesignTokens.fontWeightBold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: DesignTokens.space4),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeLG,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String emoji;
  final String title;
  final String description;

  const OnboardingPage({
    required this.emoji,
    required this.title,
    required this.description,
  });
}
