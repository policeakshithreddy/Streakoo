import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../models/year_in_review.dart';
import '../services/year_in_review_cloud_service.dart';

class YearInReviewScreen extends StatefulWidget {
  final int year;

  const YearInReviewScreen({super.key, required this.year});

  @override
  State<YearInReviewScreen> createState() => _YearInReviewScreenState();
}

class _YearInReviewScreenState extends State<YearInReviewScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // Cloud-based state management
  YearInReview? _review;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;
  final _cloudService = YearInReviewCloudService.instance;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });

    // Fetch wrapped data from cloud
    _loadYearInReview();
  }

  Future<void> _loadYearInReview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final review = await _cloudService.fetchYearInReview(widget.year);
      setState(() {
        _review = review;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateYearInReview() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final review = await _cloudService.generateYearInReview(widget.year);
      setState(() {
        _review = review;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate: ${e.toString()}';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return _LoadingScreen(year: widget.year);
    }

    // Error state
    if (_error != null) {
      return _ErrorScreen(
        year: widget.year,
        error: _error!,
        onRetry: _loadYearInReview,
      );
    }

    // No data - show generation screen
    if (_review == null) {
      return _GenerationScreen(
        year: widget.year,
        isGenerating: _isGenerating,
        onGenerate: _generateYearInReview,
      );
    }

    // Display wrapped data
    final pages = [
      _IntroPage(year: widget.year),
      _TotalCompletionsPage(review: _review!),
      _LongestStreakPage(review: _review!),
      _MostConsistentPage(review: _review!),
      _BestMonthPage(review: _review!),
      _PerfectDaysPage(review: _review!),
      _XPTotalPage(review: _review!),
      _HabitBreakdownPage(review: _review!),
      _FinalePage(review: _review!),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            itemBuilder: (context, index) => pages[index],
          ),

          // Progress indicator
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(
                pages.length,
                (index) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 50,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Navigation hint
          if (_currentPage < pages.length - 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Swipe for more',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 1000.ms)
                    .fadeOut(delay: 2000.ms, duration: 1000.ms),
              ),
            ),
        ],
      ),
    );
  }
}

// ============ INTRO PAGE ============
class _IntroPage extends StatelessWidget {
  final int year;

  const _IntroPage({required this.year});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1DB954), // Spotify green
            Color(0xFF1ED760),
            Color(0xFF1FDF64),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated background circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                    duration: 3000.ms,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0)),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                    duration: 4000.ms,
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(0.9, 0.9)),
          ),
          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$year',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 110,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      height: 0.9,
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(
                      delay: 200.ms,
                      duration: 800.ms,
                      curve: Curves.elasticOut),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: Text(
                      'YOUR YEAR IN REVIEW',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(
                      begin: 0.3, end: 0, delay: 800.ms, duration: 600.ms),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '✨',
                        style: const TextStyle(fontSize: 24),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .rotate(duration: 2000.ms, begin: -0.05, end: 0.05)
                          .then()
                          .rotate(duration: 2000.ms, begin: 0.05, end: -0.05),
                      const SizedBox(width: 12),
                      Text(
                        'Streakoo Wrapped',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '✨',
                        style: const TextStyle(fontSize: 24),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .rotate(duration: 2000.ms, begin: 0.05, end: -0.05)
                          .then()
                          .rotate(duration: 2000.ms, begin: -0.05, end: 0.05),
                    ],
                  ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ TOTAL COMPLETIONS PAGE ============
class _TotalCompletionsPage extends StatelessWidget {
  final YearInReview review;

  const _TotalCompletionsPage({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
        ),
      ),
      child: Stack(
        children: [
          // Animated pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _DotPatternPainter(),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'YOU COMPLETED',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ).animate().fadeIn(duration: 600.ms),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: Text(
                      '${review.totalCompletions}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 600.ms).scale(
                      delay: 300.ms,
                      duration: 1000.ms,
                      curve: Curves.elasticOut),
                  const SizedBox(height: 40),
                  Text(
                    review.totalCompletions == 1 ? 'HABIT' : 'HABITS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
                  const SizedBox(height: 8),
                  Text(
                    'THIS YEAR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
                  const SizedBox(height: 50),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: Text(
                      review.avgCompletionRate >= 0.8
                          ? '🔥 INCREDIBLE CONSISTENCY'
                          : review.avgCompletionRate >= 0.6
                              ? '💪 GREAT PROGRESS'
                              : '📈 BUILDING MOMENTUM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ).animate().fadeIn(delay: 1300.ms, duration: 600.ms).slideY(
                      begin: 0.3, end: 0, delay: 1300.ms, duration: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for dot pattern
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============ LONGEST STREAK PAGE ============
class _LongestStreakPage extends StatelessWidget {
  final YearInReview review;

  const _LongestStreakPage({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F), Color(0xFFC44569)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated flame icon
              const Text(
                '🔥',
                style: TextStyle(fontSize: 100),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(duration: 800.ms, curve: Curves.elasticOut)
                  .scale(
                      duration: 1500.ms,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1)),
              const SizedBox(height: 40),
              Text(
                'YOUR LONGEST STREAK',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${review.longestStreak}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 130,
                      fontWeight: FontWeight.w900,
                      height: 0.9,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, left: 8),
                    child: Text(
                      review.longestStreak == 1 ? 'DAY' : 'DAYS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms).scale(
                  delay: 600.ms, duration: 1000.ms, curve: Curves.elasticOut),
              const SizedBox(height: 50),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: Text(
                  review.streakRank.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, delay: 1200.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ MOST CONSISTENT PAGE ============
class _MostConsistentPage extends StatelessWidget {
  final YearInReview review;

  const _MostConsistentPage({required this.review});

  @override
  Widget build(BuildContext context) {
    return _GradientPage(
      colors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED), Color(0xFF6D28D9)],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Your most consistent habit',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 24,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 40),
          Text(
            review.mostConsistentEmoji,
            style: const TextStyle(fontSize: 100),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
              .scale(delay: 300.ms, duration: 800.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              review.mostConsistentHabit,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate()
              .fadeIn(delay: 900.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0, delay: 900.ms, duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            'with ${review.habitBreakdown[review.mostConsistentHabit] ?? 0} completions',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
        ],
      ),
    );
  }
}

// ============ BEST MONTH PAGE ============
class _BestMonthPage extends StatelessWidget {
  final YearInReview review;

  const _BestMonthPage({required this.review});

  @override
  Widget build(BuildContext context) {
    return _GradientPage(
      colors: const [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1D4ED8)],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🌟',
            style: TextStyle(fontSize: 80),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(duration: 800.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          const Text(
            'Your best month was',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 24,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            review.bestMonth,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .scale(delay: 600.ms, duration: 800.ms, curve: Curves.elasticOut),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              '✨ Peak performance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 1200.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0, delay: 1200.ms, duration: 600.ms),
        ],
      ),
    );
  }
}

// ============ PERFECT DAYS PAGE ============
class _PerfectDaysPage extends StatelessWidget {
  final YearInReview review;

  const _PerfectDaysPage({required this.review});

  @override
  Widget build(BuildContext context) {
    return _GradientPage(
      colors: const [Color(0xFFEC4899), Color(0xFFDB2777), Color(0xFFBE185D)],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'You had',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 24,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 32),
          Text(
            '${review.perfectDays}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 100,
              fontWeight: FontWeight.bold,
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
              .scale(delay: 300.ms, duration: 800.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            review.perfectDays == 1 ? 'perfect day' : 'perfect days',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 24,
            ),
          ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            '(100% completion)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
          const SizedBox(height: 40),
          const Text(
            '🎯',
            style: TextStyle(fontSize: 60),
          )
              .animate()
              .fadeIn(delay: 1500.ms, duration: 600.ms)
              .scale(delay: 1500.ms, duration: 600.ms),
        ],
      ),
    );
  }
}

// ============ XP TOTAL PAGE ============
class _XPTotalPage extends StatelessWidget {
  final YearInReview review;

  const _XPTotalPage({required this.review});

  @override
  Widget build(BuildContext context) {
    return _GradientPage(
      colors: const [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Total XP earned',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 24,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 32),
          const Text(
            '⭐',
            style: TextStyle(fontSize: 80),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
              .scale(delay: 300.ms, duration: 800.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            '${review.totalXP}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 100,
              fontWeight: FontWeight.bold,
            ),
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .scale(delay: 600.ms, duration: 800.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          const Text(
            'XP',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 24,
            ),
          ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Level ${(review.totalXP / 100).floor()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 1200.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0, delay: 1200.ms, duration: 600.ms),
        ],
      ),
    );
  }
}

// ============ HABIT BREAKDOWN PAGE ============
class _HabitBreakdownPage extends StatelessWidget {
  final YearInReview review;

  const _HabitBreakdownPage({required this.review});

  @override
  Widget build(BuildContext context) {
    final sortedHabits = review.habitBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topHabits = sortedHabits.take(5).toList();

    return _GradientPage(
      colors: const [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Your Top Habits',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 40),
              ...topHabits.asMap().entries.map((entry) {
                final index = entry.key;
                final habit = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          habit.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${habit.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: (300 + index * 200).ms, duration: 600.ms)
                    .slideX(
                        begin: 0.2,
                        end: 0,
                        delay: (300 + index * 200).ms,
                        duration: 600.ms);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ FINALE PAGE ============
class _FinalePage extends StatelessWidget {
  final YearInReview review;

  const _FinalePage({required this.review});

  @override
  Widget build(BuildContext context) {
    return _GradientPage(
      colors: const [
        Color(0xFF1F2937),
        Color(0xFF111827),
        Color(0xFF000000),
      ],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                review.motivationalMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 600.ms).scale(duration: 800.ms),
              const SizedBox(height: 40),
              Text(
                '${review.totalDaysActive} active days',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
              const SizedBox(height: 16),
              Text(
                '${(review.avgCompletionRate * 100).toStringAsFixed(1)}% completion rate',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: () {
                  _shareReview(context, review);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Your Year'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, delay: 1200.ms, duration: 600.ms),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back to Stats',
                  style: TextStyle(color: Colors.white70),
                ),
              ).animate().fadeIn(delay: 1500.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _shareReview(BuildContext context, YearInReview review) {
    final text = '''
🎉 My ${review.year} Streakoo Wrapped 🎉

✅ ${review.totalCompletions} habits completed
🔥 ${review.longestStreak} day longest streak
${review.mostConsistentEmoji} ${review.mostConsistentHabit} was my most consistent
🌟 ${review.bestMonth} was my best month
🎯 ${review.perfectDays} perfect days
⭐ ${review.totalXP} XP earned

${review.motivationalMessage}

#StreakooWrapped #HabitTracking
''';

    Share.share(text);
  }
}

// ============ LOADING SCREEN ============
class _LoadingScreen extends StatelessWidget {
  final int year;

  const _LoadingScreen({required this.year});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF6366F1),
                strokeWidth: 3,
              ),
              const SizedBox(height: 32),
              Text(
                'Loading your $year Wrapped...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ ERROR SCREEN ============
class _ErrorScreen extends StatelessWidget {
  final int year;
  final String error;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.year,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '⚠️',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============ GENERATION SCREEN ============
class _GenerationScreen extends StatelessWidget {
  final int year;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _GenerationScreen({
    required this.year,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
              const Color(0xFFEC4899),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$year',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(duration: 800.ms),
                  const SizedBox(height: 24),
                  const Text(
                    'Ready to see your\nYear in Review?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                  const SizedBox(height: 48),
                  if (isGenerating) ...[
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Creating your wrapped...\nThis may take a few seconds',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: onGenerate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Generate My Wrapped',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.auto_awesome),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(
                        begin: 0.2, end: 0, delay: 600.ms, duration: 600.ms),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Maybe later',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ EMPTY STATE (NO HABITS) ============

// ============ GRADIENT PAGE HELPER ============
class _GradientPage extends StatelessWidget {
  final List<Color> colors;
  final Widget child;

  const _GradientPage({
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: SafeArea(child: Center(child: child)),
    );
  }
}
