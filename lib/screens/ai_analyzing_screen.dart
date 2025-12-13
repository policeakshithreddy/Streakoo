import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/ai_habit_engine.dart';
import 'suggestion_screen.dart';

class AiAnalyzingScreen extends StatefulWidget {
  final String displayName;
  final List<String> goals;
  final List<String> struggles;
  final String timeOfDay;
  final int age;
  final int challengeTargetDays;

  const AiAnalyzingScreen({
    super.key,
    required this.displayName,
    required this.goals,
    required this.struggles,
    required this.timeOfDay,
    required this.age,
    required this.challengeTargetDays,
  });

  @override
  State<AiAnalyzingScreen> createState() => _AiAnalyzingScreenState();
}

class _AiAnalyzingScreenState extends State<AiAnalyzingScreen>
    with TickerProviderStateMixin {
  // App theme colors
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryTeal = Color(0xFF1FD1A5);

  int _currentStep = 0;
  late AnimationController _pulseController;

  final List<_AnalysisStep> _steps = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Build steps from user's answers
    _steps.addAll([
      _AnalysisStep(
        icon: Icons.flag_rounded,
        label: 'Analyzing your goals',
        detail: widget.goals.take(2).join(', '),
      ),
      _AnalysisStep(
        icon: Icons.psychology_rounded,
        label: 'Understanding challenges',
        detail: widget.struggles.take(2).join(', '),
      ),
      _AnalysisStep(
        icon: Icons.schedule_rounded,
        label: 'Optimizing for ${widget.timeOfDay.toLowerCase()}',
        detail: 'Best time for your habits',
      ),
      _AnalysisStep(
        icon: Icons.auto_awesome_rounded,
        label: 'Generating personalized habits',
        detail: 'Creating your perfect plan',
      ),
    ]);

    _runAnalysis();
  }

  void _runAnalysis() async {
    // Animate through each step
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _currentStep = i + 1);
    }

    // Small delay before navigation
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Generate suggestions
    final suggestions = const AiHabitEngine().buildFromAnswers(
      mainGoal: widget.goals.isNotEmpty ? widget.goals.first : 'General',
      struggles: widget.struggles,
      timeOfDay: [widget.timeOfDay],
      age: widget.age,
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SuggestionScreen(
          displayName: widget.displayName,
          suggestions: suggestions,
          challengeTargetDays: widget.challengeTargetDays,
        ),
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 150),
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
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Main animation area
              _buildMainAnimation(isDark),

              const SizedBox(height: 48),

              // Steps list
              ...List.generate(_steps.length, (index) {
                return _buildStepItem(index, isDark);
              }),

              const Spacer(),

              // Bottom text
              Text(
                'Please wait...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainAnimation(bool isDark) {
    return Column(
      children: [
        // Animated icon container
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.08);
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryOrange.withValues(alpha: isDark ? 0.3 : 0.2),
                  _secondaryTeal.withValues(alpha: isDark ? 0.2 : 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: _primaryOrange.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryOrange.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 48,
              color: _primaryOrange,
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),

        const SizedBox(height: 28),

        // Title
        Text(
          'Analyzing Your Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

        const SizedBox(height: 8),

        Text(
          'Creating personalized habits for ${widget.displayName}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
      ],
    );
  }

  Widget _buildStepItem(int index, bool isDark) {
    final step = _steps[index];
    final isComplete = _currentStep > index;
    final isActive = _currentStep == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Status indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isComplete
                  ? _secondaryTeal
                  : (isActive
                      ? _primaryOrange.withValues(alpha: 0.2)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.1))),
              shape: BoxShape.circle,
              border:
                  isActive ? Border.all(color: _primaryOrange, width: 2) : null,
            ),
            child: isComplete
                ? const Icon(Icons.check, size: 20, color: Colors.white)
                : (isActive
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_primaryOrange),
                        ),
                      )
                    : Icon(
                        step.icon,
                        size: 18,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      )),
          ),

          const SizedBox(width: 16),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive || isComplete
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: isComplete
                        ? _secondaryTeal
                        : (isActive
                            ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                            : (isDark ? Colors.grey[600] : Colors.grey[500])),
                  ),
                  child: Text(step.label),
                ),
                if ((isActive || isComplete) && step.detail.isNotEmpty)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isActive || isComplete ? 1.0 : 0.0,
                    child: Text(
                      step.detail,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }
}

class _AnalysisStep {
  final IconData icon;
  final String label;
  final String detail;

  _AnalysisStep({
    required this.icon,
    required this.label,
    required this.detail,
  });
}
