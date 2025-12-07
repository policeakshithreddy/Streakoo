import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _floatController;
  late AnimationController _pulseController;

  // App theme colors
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryTeal = Color(0xFF1FD1A5);
  static const _bgDark = Color(0xFF050816);
  static const _bgLight = Color(0xFFFDFBF7);

  final List<OnboardingPage> _pages = [
    // Welcome intro page
    OnboardingPage(
      emoji: '🔥',
      title: 'Welcome to Streakoo',
      subtitle:
          'Your personal habit companion that helps you build lasting habits, track your health, and celebrate every win along the way.',
      description:
          'Join thousands of people who are transforming their lives one habit at a time.',
      isWelcome: true,
    ),
    // Feature pages
    OnboardingPage(
      emoji: '📊',
      title: 'Smart Habit Tracking',
      subtitle:
          'Create unlimited habits and track them daily with our intuitive interface.',
      description:
          '• Build powerful streaks that keep you motivated\n• Earn XP and level up as you complete habits\n• Set custom reminders for each habit\n• View detailed statistics and progress charts',
    ),
    OnboardingPage(
      emoji: '❤️',
      title: 'Health Integration',
      subtitle:
          'Connect Apple Health or Google Fit to auto-complete health habits.',
      description:
          '• Steps, sleep, and heart rate tracking\n• Automatic habit completion based on your data\n• Set personalized health goals\n• Get AI-powered health coaching and insights',
    ),
    OnboardingPage(
      emoji: '🤖',
      title: 'AI-Powered Coaching',
      subtitle: 'Get personalized guidance from your intelligent habit coach.',
      description:
          '• Daily briefs tailored to your progress\n• Smart insights based on your patterns\n• Personalized tips to improve consistency\n• Weekly reports and trend analysis',
    ),
    OnboardingPage(
      emoji: '🎉',
      title: 'Celebrate Every Win',
      subtitle:
          'Unlock achievements, earn rewards, and make habit building fun.',
      description:
          '• Beautiful celebration animations\n• Milestone achievements and badges\n• Level progression system\n• Share your wins with friends',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _start();
    }
  }

  void _start() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? _bgDark : _bgLight;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage > 0 && _currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _start,
                      style: TextButton.styleFrom(
                        foregroundColor: subtitleColor,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(index, isDark, textColor, subtitleColor);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildDot(index, isDark),
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: GestureDetector(
                onTap: _nextPage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryOrange, Color(0xFFFFBB6E)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryOrange.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getButtonText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              )
                  .animate(key: ValueKey(_currentPage))
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.05, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_currentPage == 0) return "Let's Begin";
    if (_currentPage == _pages.length - 1) return 'Get Started';
    return 'Continue';
  }

  Widget _buildPage(
      int index, bool isDark, Color textColor, Color? subtitleColor) {
    final page = _pages[index];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: page.isWelcome ? 40 : 20),

            // Animated icon/emoji container
            _buildAnimatedIcon(page, isDark, index),

            SizedBox(height: page.isWelcome ? 40 : 32),

            // Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: page.isWelcome ? 32 : 26,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            )
                .animate(key: ValueKey('title_$index'))
                .fadeIn(delay: 150.ms, duration: 350.ms)
                .slideY(begin: 0.15, end: 0),

            const SizedBox(height: 16),

            // Subtitle
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: subtitleColor,
                height: 1.6,
              ),
            )
                .animate(key: ValueKey('subtitle_$index'))
                .fadeIn(delay: 250.ms, duration: 350.ms)
                .slideY(begin: 0.15, end: 0),

            if (page.description.isNotEmpty) ...[
              const SizedBox(height: 28),

              // Description card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : _primaryOrange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : _primaryOrange.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Text(
                  page.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.7,
                  ),
                ),
              )
                  .animate(key: ValueKey('desc_$index'))
                  .fadeIn(delay: 350.ms, duration: 350.ms)
                  .slideY(begin: 0.1, end: 0),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(OnboardingPage page, bool isDark, int index) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final floatValue = (_floatController.value - 0.5) * 10;
        return Transform.translate(
          offset: Offset(0, floatValue),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue = 0.7 + (_pulseController.value * 0.3);
              return Container(
                width: page.isWelcome ? 180 : 140,
                height: page.isWelcome ? 180 : 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primaryOrange.withValues(alpha: 0.15 * pulseValue),
                      _secondaryTeal.withValues(alpha: 0.05 * pulseValue),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // Main icon container
          Container(
            width: page.isWelcome ? 140 : 110,
            height: page.isWelcome ? 140 : 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F8F8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(page.isWelcome ? 40 : 32),
              border: Border.all(
                color: _primaryOrange.withValues(alpha: isDark ? 0.4 : 0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryOrange.withValues(alpha: isDark ? 0.2 : 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: page.emoji == '❤️'
                  ? Icon(
                      Icons.favorite,
                      size: page.isWelcome ? 60 : 45,
                      color: Colors.red,
                    )
                  : Text(
                      page.emoji,
                      style: TextStyle(
                        fontSize: page.isWelcome ? 70 : 50,
                      ),
                    ),
            ),
          )
              .animate(key: ValueKey('icon_$index'))
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
                duration: 600.ms,
              ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, bool isDark) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? _primaryOrange
            : (isDark
                ? Colors.white.withValues(alpha: 0.25)
                : _primaryOrange.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final bool isWelcome;

  OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.description = '',
    this.isWelcome = false,
  });
}
