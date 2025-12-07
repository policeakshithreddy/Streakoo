import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/slide_route.dart';
import 'ai_analyzing_screen.dart';

class ChallengeSelectionScreen extends StatefulWidget {
  final String displayName;
  final int age;
  final List<String> goals;
  final List<String> struggles;
  final String timeOfDay;

  const ChallengeSelectionScreen({
    super.key,
    required this.displayName,
    required this.age,
    required this.goals,
    required this.struggles,
    required this.timeOfDay,
  });

  @override
  State<ChallengeSelectionScreen> createState() =>
      _ChallengeSelectionScreenState();
}

class _ChallengeSelectionScreenState extends State<ChallengeSelectionScreen> {
  int _selectedDays = 7;

  // App theme colors
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryTeal = Color(0xFF1FD1A5);

  final List<_ChallengeOption> _challenges = [
    _ChallengeOption(
      days: 7,
      title: 'Quick Start',
      subtitle: 'Perfect for beginners',
      description: 'Build your foundation with a week of consistency',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFCD7F32), // Bronze
      gradient: [const Color(0xFFCD7F32), const Color(0xFFE9A968)],
    ),
    _ChallengeOption(
      days: 15,
      title: 'Momentum Builder',
      subtitle: 'For serious commitment',
      description: 'Two weeks to create lasting neural pathways',
      icon: Icons.trending_up_rounded,
      color: const Color(0xFFC0C0C0), // Silver
      gradient: [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)],
    ),
    _ChallengeOption(
      days: 30,
      title: 'Transformation',
      subtitle: 'The ultimate challenge',
      description: 'A full month to transform habits into lifestyle',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFFD700), // Gold
      gradient: [const Color(0xFFFFB300), const Color(0xFFFFD54F)],
    ),
  ];

  void _continue() {
    Navigator.of(context).push(
      slideFromRight(
        AiAnalyzingScreen(
          displayName: widget.displayName,
          goals: widget.goals,
          struggles: widget.struggles,
          timeOfDay: widget.timeOfDay,
          age: widget.age,
          challengeTargetDays: _selectedDays,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Choose Your Challenge',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'How long is your challenge?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 8),

                    Text(
                      'Complete your habits daily to earn the badge!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                    const SizedBox(height: 28),

                    // Challenge cards
                    ...List.generate(_challenges.length, (index) {
                      final challenge = _challenges[index];
                      final isSelected = _selectedDays == challenge.days;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildChallengeCard(
                          challenge: challenge,
                          isSelected: isSelected,
                          isDark: isDark,
                          index: index,
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Info card
                    _buildInfoCard(isDark),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: _continue,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryOrange, Color(0xFFFFBB6E)],
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start My Challenge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 300.ms)
                  .slideY(begin: 0.1, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard({
    required _ChallengeOption challenge,
    required bool isSelected,
    required bool isDark,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDays = challenge.days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    challenge.gradient[0]
                        .withValues(alpha: isDark ? 0.25 : 0.15),
                    challenge.gradient[1]
                        .withValues(alpha: isDark ? 0.15 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? challenge.color
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: challenge.color.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Badge icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? challenge.gradient
                      : [
                          isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: challenge.color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                challenge.icon,
                size: 28,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? challenge.color.withValues(alpha: 0.2)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${challenge.days} days',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? challenge.color
                                : (isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(colors: challenge.gradient)
                    : null,
                border: Border.all(
                  color: isSelected
                      ? challenge.color
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.4)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: 150 + index * 100), duration: 350.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoCard(bool isDark) {
    final selected = _challenges.firstWhere((c) => c.days == _selectedDays);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? _secondaryTeal.withValues(alpha: 0.1)
            : _secondaryTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _secondaryTeal.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _secondaryTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: _secondaryTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pro tip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _secondaryTeal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete $_selectedDays days in a row without missing to earn your ${selected.title} badge!',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(key: ValueKey(_selectedDays))
        .fadeIn(duration: 250.ms)
        .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
  }
}

class _ChallengeOption {
  final int days;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  _ChallengeOption({
    required this.days,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}
