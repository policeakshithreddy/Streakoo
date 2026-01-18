import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../models/coach_message.dart';

class CoachMessageBubble extends StatefulWidget {
  final CoachMessage message;
  final bool isThinking;
  final bool animate;
  final Function(String)? onQuickReplyTap;
  final Function(String)? onReactionTap;

  const CoachMessageBubble({
    super.key,
    required this.message,
    this.isThinking = false,
    this.animate = true,
    this.onQuickReplyTap,
    this.onReactionTap,
  });

  @override
  State<CoachMessageBubble> createState() => _CoachMessageBubbleState();
}

class _CoachMessageBubbleState extends State<CoachMessageBubble> {
  String? _selectedReaction;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _selectedReaction = widget.message.reaction;
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // Auto-trigger confetti for celebration messages
    if (widget.message.messageType == CoachMessageType.celebration &&
        widget.animate) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = widget.message.isFromUser;

    Widget content = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Coach Avatar (only for coach messages)
              if (!isUser) ...[
                _AnimatedCoachAvatar(
                  isDark: isDark,
                  isThinking: widget.isThinking,
                  isCelebration: widget.message.messageType ==
                      CoachMessageType.celebration,
                ),
                const SizedBox(width: 8),
              ],

              // Message Bubble
              Flexible(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: isUser
                          ? _UserMessageBubble(
                              message: widget.message,
                              theme: theme,
                              isDark: isDark,
                            )
                          : widget.isThinking
                              ? _ThinkingBubble(isDark: isDark)
                              : _buildCoachBubble(theme, isDark),
                    ),
                    // Confetti for celebrations
                    if (widget.message.messageType ==
                        CoachMessageType.celebration)
                      Positioned(
                        top: -10,
                        left: 0,
                        right: 0,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirection: -pi / 2,
                          emissionFrequency: 0.3,
                          numberOfParticles: 10,
                          maxBlastForce: 20,
                          minBlastForce: 10,
                          gravity: 0.3,
                          colors: const [
                            Color(0xFFFFA94A),
                            Color(0xFFFF6B6B),
                            Color(0xFF4ECDC4),
                            Color(0xFFFFE66D),
                            Color(0xFF95E1D3),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Reaction bar for coach messages
          if (!isUser && !widget.isThinking && widget.onReactionTap != null)
            _ReactionBar(
              selectedReaction: _selectedReaction,
              onReactionTap: (emoji) {
                HapticFeedback.lightImpact();
                setState(() => _selectedReaction = emoji);
                widget.onReactionTap?.call(emoji);
              },
            ),

          // Quick reply chips
          if (!isUser &&
              widget.message.quickReplies.isNotEmpty &&
              !widget.isThinking)
            _QuickReplyChips(
              replies: widget.message.quickReplies,
              onTap: widget.onQuickReplyTap,
              isDark: isDark,
            ),
        ],
      ),
    );

    // Add entrance animation
    if (widget.animate && !widget.isThinking) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: content.animate().fadeIn(duration: 350.ms).slideX(
              begin: isUser ? 0.08 : -0.08,
              end: 0,
              curve: Curves.easeOutCubic,
            ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: content,
    );
  }

  Widget _buildCoachBubble(ThemeData theme, bool isDark) {
    switch (widget.message.messageType) {
      case CoachMessageType.tip:
        return _TipCard(message: widget.message, theme: theme, isDark: isDark);
      case CoachMessageType.celebration:
        return _CelebrationCard(
            message: widget.message, theme: theme, isDark: isDark);
      case CoachMessageType.normal:
        return _CoachMessageBubbleContent(
          message: widget.message,
          theme: theme,
          isDark: isDark,
        );
    }
  }
}

/// Animated Coach Avatar with pulse, breathing, and sparkle effects
class _AnimatedCoachAvatar extends StatefulWidget {
  final bool isDark;
  final bool isThinking;
  final bool isCelebration;

  const _AnimatedCoachAvatar({
    required this.isDark,
    this.isThinking = false,
    this.isCelebration = false,
  });

  @override
  State<_AnimatedCoachAvatar> createState() => _AnimatedCoachAvatarState();
}

class _AnimatedCoachAvatarState extends State<_AnimatedCoachAvatar>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _pulseController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing animation (subtle scale)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _breathingController.repeat(reverse: true);

    // Pulse animation for thinking
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    if (widget.isThinking) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedCoachAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking != oldWidget.isThinking) {
      if (widget.isThinking) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathingAnimation, _pulseAnimation]),
      builder: (context, child) {
        final scale = widget.isThinking
            ? _pulseAnimation.value
            : _breathingAnimation.value;

        return Stack(
          children: [
            // Glow effect when thinking
            if (widget.isThinking)
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFA94A).withValues(
                            alpha: 0.6 * (2 - _pulseAnimation.value)),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),

            // Main avatar
            Transform.scale(
              scale: scale,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isCelebration
                        ? [const Color(0xFFFFD700), const Color(0xFFFFA94A)]
                        : [const Color(0xFFFFA94A), const Color(0xFFFF6B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA94A).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.isCelebration ? '🎉' : '✨',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),

            // Sparkle particles for celebration
            if (widget.isCelebration)
              ...List.generate(3, (i) => _SparkleParticle(index: i)),
          ],
        );
      },
    );
  }
}

/// Floating sparkle particles
class _SparkleParticle extends StatelessWidget {
  final int index;

  const _SparkleParticle({required this.index});

  @override
  Widget build(BuildContext context) {
    final offsets = [
      const Offset(-8, -12),
      const Offset(12, -8),
      const Offset(8, 12),
    ];

    return Positioned(
      left: 18 + offsets[index].dx,
      top: 18 + offsets[index].dy,
      child: const Text('✦',
              style: TextStyle(fontSize: 10, color: Color(0xFFFFD700)))
          .animate(onPlay: (c) => c.repeat())
          .fadeIn(duration: 300.ms)
          .then(delay: (100 * index).ms)
          .fadeOut(duration: 300.ms)
          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2)),
    );
  }
}

/// iMessage-style thinking bubble with avatar and wave animation
class _ThinkingBubble extends StatelessWidget {
  final bool isDark;

  const _ThinkingBubble({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(6),
        bottomRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF2A2A3E).withValues(alpha: 0.9),
                      const Color(0xFF1E1E2E).withValues(alpha: 0.85),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      const Color(0xFFF8F9FF).withValues(alpha: 0.9),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFFFA94A).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: _WaveThinkingDots(isDark: isDark),
        ),
      ),
    );
  }
}

/// iMessage-style wave dots
class _WaveThinkingDots extends StatefulWidget {
  final bool isDark;

  const _WaveThinkingDots({required this.isDark});

  @override
  State<_WaveThinkingDots> createState() => _WaveThinkingDotsState();
}

class _WaveThinkingDotsState extends State<_WaveThinkingDots>
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
        duration: const Duration(milliseconds: 400),
      ),
    );

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOutSine),
      );
    }).toList();

    _startWaveAnimation();
  }

  void _startWaveAnimation() async {
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].forward();
        await Future.delayed(const Duration(milliseconds: 120));
      }
      await Future.delayed(const Duration(milliseconds: 200));
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].reverse();
        await Future.delayed(const Duration(milliseconds: 120));
      }
      await Future.delayed(const Duration(milliseconds: 400));
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
              child: Transform.translate(
                offset: Offset(0, -6 * _animations[i].value),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFA94A).withValues(
                          alpha: 0.5 + (0.5 * _animations[i].value),
                        ),
                        const Color(0xFFFF6B6B).withValues(
                          alpha: 0.5 + (0.5 * _animations[i].value),
                        ),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFA94A).withValues(
                          alpha: 0.3 * _animations[i].value,
                        ),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Reaction bar with emoji buttons
class _ReactionBar extends StatelessWidget {
  final String? selectedReaction;
  final Function(String) onReactionTap;

  const _ReactionBar({
    required this.selectedReaction,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final reactions = ['👍', '💪', '🔥', '❤️', '😊'];

    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.asMap().entries.map((entry) {
          final emoji = entry.value;
          final isSelected = selectedReaction == emoji;

          return GestureDetector(
            onTap: () => onReactionTap(emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFA94A).withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: isSelected ? 18 : 14,
                ),
              ),
            ),
          )
              .animate(delay: (50 * entry.key).ms)
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.8, 0.8));
        }).toList(),
      ),
    );
  }
}

/// Quick reply chips with staggered animation
class _QuickReplyChips extends StatelessWidget {
  final List<String> replies;
  final Function(String)? onTap;
  final bool isDark;

  const _QuickReplyChips({
    required this.replies,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: replies.asMap().entries.map((entry) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap?.call(entry.value);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF2A2A3E),
                          const Color(0xFF1E1E2E),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF8F9FF),
                        ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFFA94A).withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFA94A).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          )
              .animate(delay: (100 * entry.key).ms)
              .fadeIn(duration: 250.ms)
              .slideX(begin: -0.1, end: 0, curve: Curves.easeOut);
        }).toList(),
      ),
    );
  }
}

/// Regular coach message bubble with glassmorphism
class _CoachMessageBubbleContent extends StatelessWidget {
  final CoachMessage message;
  final ThemeData theme;
  final bool isDark;

  const _CoachMessageBubbleContent({
    required this.message,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(6),
        bottomRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF2A2A3E).withValues(alpha: 0.9),
                      const Color(0xFF1E1E2E).withValues(alpha: 0.85),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      const Color(0xFFF8F9FF).withValues(alpha: 0.9),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFFFA94A).withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFFFFA94A).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.95)
                  : const Color(0xFF1A1A1A),
              height: 1.55,
              letterSpacing: -0.1,
            ),
          )
              .animate()
              .custom(
                duration: 600.ms,
                builder: (context, value, child) {
                  final chars = message.text.characters;
                  final textLen = chars.length;
                  final currentLen = (textLen * value).round();
                  return Text(
                    chars.take(currentLen).toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? Colors.white.withOpacity(0.95)
                          : const Color(0xFF1A1A1A),
                      height: 1.55,
                      letterSpacing: -0.1,
                    ),
                  );
                },
              )
              .fadeIn(duration: 200.ms),
        ),
      ),
    );
  }
}

/// Tip card with gradient background
class _TipCard extends StatelessWidget {
  final CoachMessage message;
  final ThemeData theme;
  final bool isDark;

  const _TipCard({
    required this.message,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E3A5F),
                  const Color(0xFF2A4A6F),
                ]
              : [
                  const Color(0xFFE8F4FD),
                  const Color(0xFFF0F8FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('💡', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              const Text(
                'Pro Tip',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A90E2),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Celebration card with confetti trigger
class _CelebrationCard extends StatelessWidget {
  final CoachMessage message;
  final ThemeData theme;
  final bool isDark;

  const _CelebrationCard({
    required this.message,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF3D2914),
                  const Color(0xFF4A3520),
                ]
              : [
                  const Color(0xFFFFF8E7),
                  const Color(0xFFFFFBF0),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Awesome!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB800),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().shimmer(
        duration: 1500.ms,
        color: const Color(0xFFFFD700).withValues(alpha: 0.3));
  }
}

/// User message bubble - clean gradient design
class _UserMessageBubble extends StatelessWidget {
  final CoachMessage message;
  final ThemeData theme;
  final bool isDark;

  const _UserMessageBubble({
    required this.message,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA94A), Color(0xFFFFBB6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA94A).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
