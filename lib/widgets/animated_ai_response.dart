import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated AI Response Widget with spectacular reveal effects
/// Similar to the BMI calculator animation but for AI responses
class AnimatedAIResponse extends StatefulWidget {
  final String response;
  final Duration? analysisDelay;
  final VoidCallback? onComplete;
  final String? title;
  final IconData? icon;
  final List<String>? analysisSteps;
  final bool showTypingEffect;

  const AnimatedAIResponse({
    super.key,
    required this.response,
    this.analysisDelay = const Duration(milliseconds: 2500),
    this.onComplete,
    this.title,
    this.icon,
    this.analysisSteps,
    this.showTypingEffect = true,
  });

  @override
  State<AnimatedAIResponse> createState() => _AnimatedAIResponseState();
}

class _AnimatedAIResponseState extends State<AnimatedAIResponse>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  bool _isAnalyzing = true;
  int _currentStep = 0;
  String _displayedText = '';

  final List<String> _defaultSteps = [
    'Processing your request...',
    'Analyzing data patterns...',
    'Generating insights...',
    'Preparing response...',
  ];

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startAnalysis();
  }

  void _startAnalysis() async {
    final steps = widget.analysisSteps ?? _defaultSteps;
    final stepDelay = (widget.analysisDelay!.inMilliseconds ~/ steps.length);

    // Animate through steps
    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(Duration(milliseconds: stepDelay));
      if (!mounted) return;
      setState(() => _currentStep = i + 1);
      HapticFeedback.selectionClick();
    }

    // Show result
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
    });

    HapticFeedback.mediumImpact();

    // Start typing effect
    if (widget.showTypingEffect) {
      await _typeText();
    } else {
      setState(() => _displayedText = widget.response);
    }

    widget.onComplete?.call();
  }

  Future<void> _typeText() async {
    final text = widget.response;
    for (int i = 0; i <= text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 15));
      if (!mounted) return;
      setState(() => _displayedText = text.substring(0, i));
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      child:
          _isAnalyzing ? _buildAnalyzingState(theme) : _buildResultState(theme),
    );
  }

  Widget _buildAnalyzingState(ThemeData theme) {
    final steps = widget.analysisSteps ?? _defaultSteps;

    return Container(
      key: const ValueKey('analyzing'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated brain/AI icon
          _buildAnimatedIcon(theme),

          const SizedBox(height: 24),

          // Title
          Text(
            widget.title ?? 'AI Analyzing',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),

          const SizedBox(height: 24),

          // Progress steps
          ...List.generate(steps.length, (index) {
            final isComplete = index < _currentStep;
            final isCurrent = index == _currentStep - 1;

            return _buildStepItem(
              theme,
              text: steps[index],
              isComplete: isComplete,
              isCurrent: isCurrent,
              index: index,
            );
          }),

          const SizedBox(height: 16),

          // Wave progress bar
          _buildWaveProgress(theme),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _shimmerController]),
      builder: (context, child) {
        final pulseScale = 1.0 + (_pulseController.value * 0.1);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 100 * pulseScale,
              height: 100 * pulseScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                    theme.colorScheme.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),

            // Rotating ring
            Transform.rotate(
              angle: _shimmerController.value * 2 * math.pi,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0),
                      theme.colorScheme.primary.withValues(alpha: 0.6),
                      theme.colorScheme.secondary.withValues(alpha: 0.6),
                      theme.colorScheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            // Center icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                widget.icon ?? Icons.auto_awesome,
                color: theme.colorScheme.onPrimary,
                size: 30,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepItem(
    ThemeData theme, {
    required String text,
    required bool isComplete,
    required bool isCurrent,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Status indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color:
                    isCurrent ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: isComplete
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: theme.colorScheme.onPrimary,
                  )
                : isCurrent
                    ? _buildLoadingDot(theme)
                    : null,
          ),

          const SizedBox(width: 12),

          // Step text
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isComplete || isCurrent
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn()
        .slideX(begin: -0.1, end: 0);
  }

  Widget _buildLoadingDot(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(
              alpha: 0.5 + (_pulseController.value * 0.5),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveProgress(ThemeData theme) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: CustomPaint(
              painter: _WaveProgressPainter(
                progress: _waveController.value,
                color: theme.colorScheme.primary,
              ),
              size: const Size(double.infinity, 4),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultState(ThemeData theme) {
    return Container(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon ?? Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.title ?? 'AI Response',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),

          const SizedBox(height: 16),

          Divider(color: theme.dividerColor.withValues(alpha: 0.2)),

          const SizedBox(height: 16),

          // Response text with typing effect
          Text(
            _displayedText,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),

          // Cursor if still typing
          if (_displayedText.length < widget.response.length)
            Container(
              width: 2,
              height: 20,
              margin: const EdgeInsets.only(left: 2),
              color: theme.colorScheme.primary,
            )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(duration: 400.ms)
                .then()
                .fadeOut(duration: 400.ms),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeOutBack,
        );
  }
}

/// Custom wave progress painter
class _WaveProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      final x = i;
      final y = size.height / 2 +
          math.sin((i / size.width * 4 * math.pi) + (progress * 2 * math.pi)) *
              (size.height / 4);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Typing indicator with bouncing dots
class AITypingIndicator extends StatefulWidget {
  final Color? color;

  const AITypingIndicator({super.key, this.color});

  @override
  State<AITypingIndicator> createState() => _AITypingIndicatorState();
}

class _AITypingIndicatorState extends State<AITypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      _controllers[i].repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = widget.color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) {
              return Container(
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                child: Transform.translate(
                  offset: Offset(0, -4 * _animations[i].value),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor.withValues(
                        alpha: 0.5 + (0.5 * _animations[i].value),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Shimmer loading placeholder for AI content
class AIContentShimmer extends StatelessWidget {
  final int lines;
  final double? width;

  const AIContentShimmer({
    super.key,
    this.lines = 3,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (i) {
        final lineWidth = i == lines - 1
            ? (width ?? double.infinity) * 0.6
            : width ?? double.infinity;

        return Container(
          margin: EdgeInsets.only(bottom: i < lines - 1 ? 12 : 0),
          height: 16,
          width: lineWidth,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(
              duration: 1500.ms,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            );
      }),
    );
  }
}

/// Animated insight card for AI-generated insights
class AnimatedInsightCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Color? color;
  final int index;

  const AnimatedInsightCard({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.color,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }
}
