import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/streakoo_pet.dart';
import '../state/app_state.dart';

/// Clean emoji-based pet widget with smooth animations
class EmojiPetWidget extends StatefulWidget {
  final double size;
  final bool enableHatching;
  final VoidCallback? onTap;

  const EmojiPetWidget({
    super.key,
    this.size = 120,
    this.enableHatching = false,
    this.onTap,
  });

  @override
  State<EmojiPetWidget> createState() => EmojiPetWidgetState();
}

class EmojiPetWidgetState extends State<EmojiPetWidget>
    with TickerProviderStateMixin {
  late AnimationController _wobbleController;
  late AnimationController _hopController;
  late AnimationController _bounceController; // Continuous idle bounce
  late Animation<double> _wobbleAnimation;
  late Animation<double> _hopAnimation;
  late Animation<double> _bounceAnimation;

  bool _isHatching = false;
  bool _isEvolving = false;
  bool _showSparkle = false; // Random expression sparkle
  bool _showSpeechBubble = false;
  bool _isCelebrating = false;
  bool _isSleeping = false;
  bool _isFeeding = false;
  int _feedingPhase =
      0; // 0=none, 1=notices, 2=excited, 3=chomping, 4=satisfied
  double _foodY = -50;

  String _currentQuote = '';
  PetStage? _previousStage;
  PetStage? _currentStage;
  final Random _random = Random();
  final List<_FloatingEmoji> _floatingEmojis = [];

  // Dynamic expression system
  String _currentExpression = ''; // Current expression overlay
  bool _isBlinking = false;
  int _lookDirection = 0; // -1 left, 0 center, 1 right
  String _thoughtBubble = ''; // What pet is "thinking"

  // Expression emojis that overlay on pet
  static const Map<String, String> _expressions = {
    'happy': '😊',
    'excited': '🤩',
    'love': '😍',
    'sleepy': '😴',
    'hungry': '🤤',
    'bored': '😐',
    'curious': '🧐',
    'proud': '😤',
    'surprised': '😲',
    'wink': '😉',
    'cool': '😎',
    'thinking': '🤔',
  };

  // Motivational quotes for speech bubbles
  static const List<String> _quotes = [
    "You're doing great! 💪",
    "Keep going! 🔥",
    "I believe in you! ⭐",
    "One step at a time! 👣",
    "You've got this! 🌟",
    "Stay consistent! 📈",
    "Almost there! 🎯",
    "Great progress! 🏆",
  ];

  // Context-aware thoughts

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkSleepMode();

    // Start single coordinated idle loop
    if (widget.enableHatching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAnimations().then((_) => _startIdleBehavior());
      });
    } else {
      _startIdleBehavior();
    }
  }

  void _checkSleepMode() {
    final hour = DateTime.now().hour;
    // Pet sleeps between 10 PM and 6 AM
    _isSleeping = hour >= 22 || hour < 6;
  }

  /// Single coordinated "brain" for the pet
  /// Decides ONE action to take every few seconds to avoid overlapping/stuttering
  void _startIdleBehavior() {
    // Random interval between 3-6 seconds
    final nextActionDelay =
        Duration(milliseconds: 3000 + _random.nextInt(3000));

    Future.delayed(nextActionDelay, () {
      if (!mounted) return;

      // Don't interrupt active animations or sleep
      if (_isHatching ||
          _isEvolving ||
          _isFeeding ||
          _isCelebrating ||
          _isSleeping) {
        _startIdleBehavior(); // Check again later
        return;
      }

      // Decide what to do based on probabilities
      final actionRoll = _random.nextDouble();

      // 30% chance to just blink (low impact)
      if (actionRoll < 0.3) {
        _triggerBlink();
      }
      // 15% chance to change look direction
      else if (actionRoll < 0.45) {
        _changeLookDirection();
      }
      // 10% chance to show an emote/expression
      else if (actionRoll < 0.55) {
        _showRandomExpression();
      }
      // 5% chance to sparkle
      else if (actionRoll < 0.6) {
        _triggerRandomSparkle();
      }
      // 5% chance to show a thought
      else if (actionRoll < 0.65) {
        _triggerThought();
      }
      // 5% chance to show a quote
      else if (actionRoll < 0.70) {
        _showRandomQuote();
      }
      // 30% chance to do nothing (just breathe/bounce)

      // Schedule next cycle
      _startIdleBehavior();
    });
  }

  void _triggerBlink() {
    setState(() => _isBlinking = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isBlinking = false);
    });
  }

  void _showRandomExpression() {
    if (_currentExpression.isNotEmpty) return;

    final expressionKeys = _expressions.keys.toList();
    _currentExpression = expressionKeys[_random.nextInt(expressionKeys.length)];
    setState(() {});

    // Clear expression after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _currentExpression = '');
    });
  }

  void _changeLookDirection() {
    setState(() {
      _lookDirection = _random.nextInt(3) - 1; // -1, 0, or 1
    });

    // Reset to center after a bit
    Future.delayed(Duration(seconds: 1 + _random.nextInt(2)), () {
      if (mounted) setState(() => _lookDirection = 0);
    });
  }

  Future<void> _triggerThought() async {
    if (_thoughtBubble.isNotEmpty || _showSpeechBubble) return;

    final appState = context.read<AppState>();
    final thought =
        await StreakooPetService.instance.generatePetThought(appState);

    if (mounted) {
      setState(() => _thoughtBubble = thought);
    }

    // Clear thought after 5 seconds (slightly longer for reading)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _thoughtBubble = '');
    });
  }

  void _triggerRandomSparkle() {
    setState(() => _showSparkle = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showSparkle = false);
    });
  }

  // Not strictly part of idle loop but can be triggered randomly or externally
  void _showRandomQuote() {
    if (_showSpeechBubble) return;
    _currentQuote = _quotes[_random.nextInt(_quotes.length)];
    setState(() => _showSpeechBubble = true);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showSpeechBubble = false);
      }
    });
  }

  /// Trigger feeding animation with inline overlay (no popup)
  void feed() {
    if (_isFeeding || _isHatching || _isEvolving || _isSleeping) return;

    setState(() {
      _isFeeding = true;
      _feedingPhase = 0; // Food entering
      _foodY = -1.5; // Start above head (normalized)
    });
    HapticFeedback.mediumImpact();

    // Phase schedule
    // 0 -> 1: Food drops (600ms)
    // 1: Notices (Ooh!)
    // 1 -> 2: Excited (500ms)
    // 2: Excited (Yay!)
    // 2 -> 3: Eating (600ms)
    // 3: Chomping (Repeat 3x)
    // 4: Satisfied (Yummy!)

    _runFeedingSequence();
  }

  void _runFeedingSequence() async {
    // Drop food
    setState(() => _foodY = 0); // Drop to mouth level

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _feedingPhase = 1); // Notices
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _feedingPhase = 2); // Excited
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _feedingPhase = 3); // Eating
    HapticFeedback.mediumImpact();

    // Chomping
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      HapticFeedback.selectionClick();
    }

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _feedingPhase = 4); // Satisfied
    HapticFeedback.mediumImpact();
    // Celebrate with sparkles
    _spawnFloatingEmojis(['✨', '⭐', '💕']);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _isFeeding = false);
  }

  /// Trigger celebration dance (called externally when habit completed)
  void celebrate() {
    if (_isCelebrating) return;
    setState(() => _isCelebrating = true);
    HapticFeedback.heavyImpact();
    _spawnFloatingEmojis(['🎉', '🎊', '✨', '⭐', '🌟']);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCelebrating = false);
    });
  }

  void _setupAnimations() {
    // Wobble for egg (continuous gentle rocking)
    _wobbleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _wobbleAnimation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
    );

    // Continuous bounce/breathing animation (makes pet feel alive)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Hop animation on tap
    _hopController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _hopAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -20), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -20, end: 0), weight: 60),
    ]).animate(CurvedAnimation(parent: _hopController, curve: Curves.easeOut));
  }

  Future<void> _checkAnimations() async {
    final appState = context.read<AppState>();
    final level = appState.userLevel.level;
    final service = StreakooPetService.instance;

    // Check for pending evolution first
    await service.checkEvolution(level);
    if (service.hasPendingEvolution) {
      _previousStage = await service.getPreviousStage();
      _currentStage = service.pendingEvolution;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _triggerEvolution();
      });
      return;
    }

    // Check for hatching (level 2 first time)
    if (level >= 2) {
      final hasSeenHatching = await service.hasSeenHatching();
      if (!hasSeenHatching && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _triggerHatching();
        });
      }
    }
  }

  void _triggerEvolution() {
    if (_previousStage == null || _currentStage == null) return;

    setState(() => _isEvolving = true);
    HapticFeedback.heavyImpact();

    // Spawn celebration emojis
    _spawnFloatingEmojis(['🌟', '✨', '🎉', '⭐', '💫']);

    // After animation, mark as seen
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _isEvolving = false);
        StreakooPetService.instance.markEvolutionSeen(_currentStage!);
      }
    });
  }

  void _triggerHatching() {
    setState(() => _isHatching = true);
    HapticFeedback.heavyImpact();

    // After animation, mark as seen
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _isHatching = false);
        StreakooPetService.instance.markHatchingAsSeen();
      }
    });
  }

  void _onTap() {
    HapticFeedback.lightImpact();

    // Trigger hop
    _hopController.forward().then((_) => _hopController.reset());

    // Show floating hearts
    _spawnFloatingEmojis(['💕', '💖', '❤️']);

    widget.onTap?.call();
  }

  void _spawnFloatingEmojis(List<String> emojis) {
    setState(() {
      for (final emoji in emojis) {
        _floatingEmojis.add(_FloatingEmoji(
          emoji: emoji,
          x: _random.nextDouble() * 60 - 30,
          delay: _random.nextInt(200),
        ));
      }
    });

    // Clean up after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          if (_floatingEmojis.length > 3) {
            _floatingEmojis.removeRange(0, 3);
          } else {
            _floatingEmojis.clear();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _hopController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  String _getEmoji(PetStage stage) {
    switch (stage) {
      case PetStage.egg:
        return '🥚';
      case PetStage.hatchling:
        return '🐣';
      case PetStage.baby:
        return '🐥';
      case PetStage.teen:
        return '🐤';
      case PetStage.adult:
        return '🐔';
      case PetStage.master:
        return '🐓';
      case PetStage.legendary:
        return '🦅';
    }
  }

  String _getMoodEmoji(PetMood mood) {
    switch (mood) {
      case PetMood.excited:
        return '✨';
      case PetMood.happy:
        return '😊';
      case PetMood.content:
        return '';
      case PetMood.neutral:
        return '';
      case PetMood.worried:
        return '😰';
      case PetMood.sleepy:
        return '💤';
      case PetMood.disappointed:
        return '💔';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final pet = _buildPet(appState);
        final emoji = _getEmoji(pet.stage);
        final moodEmoji = _getMoodEmoji(pet.mood);
        final isEgg = pet.stage == PetStage.egg;

        return GestureDetector(
          onTap: _onTap,
          child: SizedBox(
            width: widget.size + 60,
            height: widget.size + 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Floating emojis (hearts, sparkles)
                ..._floatingEmojis.map((f) => _buildFloatingEmoji(f)),

                // Evolution animation (Telegram-style morph)
                if (_isEvolving &&
                    _previousStage != null &&
                    _currentStage != null)
                  _buildEvolutionSequence()
                // Hatching animation
                else if (_isHatching)
                  _buildHatchingSequence()
                else
                  // Main pet emoji
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_wobbleController, _hopController, _bounceController]),
                    builder: (context, child) {
                      final wobble =
                          isEgg ? sin(_wobbleAnimation.value * pi) * 0.08 : 0.0;
                      // Combine hop with continuous bounce
                      final verticalOffset =
                          _hopAnimation.value + _bounceAnimation.value;

                      return Transform.translate(
                        offset: Offset(0, verticalOffset),
                        child: Transform.rotate(
                          angle: wobble,
                          child: Text(
                            emoji,
                            style: TextStyle(fontSize: widget.size),
                          ),
                        ),
                      );
                    },
                  ),

                // Mood emoji (top right)
                if (moodEmoji.isNotEmpty && !_isHatching)
                  Positioned(
                    top: 0,
                    right: 10,
                    child: Text(
                      moodEmoji,
                      style: const TextStyle(fontSize: 24),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .fadeIn()
                        .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                            duration: 1000.ms)
                        .then()
                        .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(0.8, 0.8),
                            duration: 1000.ms),
                  ),

                // Random sparkle effect
                if (_showSparkle && !_isHatching && !_isEvolving)
                  Positioned(
                    top: 5,
                    left: 15,
                    child: const Text('✨', style: TextStyle(fontSize: 20))
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.2, 1.2))
                        .then()
                        .fadeOut(delay: 800.ms, duration: 300.ms),
                  ),

                // Food item during feeding
                if (_isFeeding)
                  Positioned(
                    top: widget.size * (isEgg ? -0.5 : 0.0) +
                        (_foodY * (widget.size * 0.8)),
                    child: Text(
                      '🍖', // Replace with dynamic food if needed
                      style: TextStyle(
                        fontSize: widget.size * 0.4,
                      ),
                    )
                        .animate(target: _feedingPhase == 3 ? 1 : 0) // Chomping
                        .shake(hz: 4, duration: 200.ms)
                        .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(0.8, 0.8)),
                  ),

                // Expression emoji overlay (feeding overrides random)
                if ((_currentExpression.isNotEmpty || _isFeeding) &&
                    !_isHatching &&
                    !_isEvolving &&
                    !_isSleeping)
                  Positioned(
                    top: -15,
                    left: 20,
                    child: Text(
                      _isFeeding
                          ? (_feedingPhase == 1
                              ? '😲'
                              : (_feedingPhase == 2
                                  ? '🤩'
                                  : (_feedingPhase == 3
                                      ? '😋'
                                      : (_feedingPhase == 4 ? '😊' : ''))))
                          : (_expressions[_currentExpression] ?? ''),
                      style: const TextStyle(fontSize: 24),
                    )
                        .animate(key: ValueKey('expr_$_feedingPhase'))
                        .fadeIn(duration: 200.ms)
                        .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.2, 1.2))
                        .then()
                        .scale(
                            begin: const Offset(1.2, 1.2),
                            end: const Offset(1.0, 1.0)),
                  ),

                // Blink effect (dims the pet momentarily)
                if (_isBlinking && !_isHatching && !_isEvolving)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                    )
                        .animate()
                        .fadeIn(duration: 50.ms)
                        .fadeOut(delay: 50.ms, duration: 50.ms),
                  ),

                // Look direction indicator (eyes look left/right)
                if (_lookDirection != 0 &&
                    !_isHatching &&
                    !_isEvolving &&
                    !_isSleeping)
                  Positioned(
                    top: widget.size * 0.35,
                    left: _lookDirection < 0 ? 10 : null,
                    right: _lookDirection > 0 ? 10 : null,
                    child: Text(
                      _lookDirection < 0 ? '👀' : '👀',
                      style: const TextStyle(fontSize: 14),
                    ).animate().fadeIn(duration: 200.ms),
                  ),

                // Thought bubble (what pet is thinking)
                if (_thoughtBubble.isNotEmpty &&
                    !_showSpeechBubble &&
                    !_isHatching &&
                    !_isEvolving &&
                    !_isSleeping)
                  Positioned(
                    top: -35,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            _thoughtBubble,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        // Thought bubble tail
                        Transform.translate(
                          offset: const Offset(0, -3),
                          child:
                              const Text('💭', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, end: 0),
                  ),

                // Sleep mode overlay
                if (_isSleeping && !_isHatching && !_isEvolving)
                  Positioned(
                    top: -10,
                    right: 0,
                    child: const Text('💤', style: TextStyle(fontSize: 18))
                        .animate(onPlay: (c) => c.repeat())
                        .slideY(begin: 0, end: -0.3, duration: 1500.ms)
                        .then()
                        .slideY(begin: -0.3, end: 0, duration: 1500.ms),
                  ),

                // Speech bubble with quote
                if (_showSpeechBubble &&
                    !_isHatching &&
                    !_isEvolving &&
                    !_isSleeping)
                  Positioned(
                    top: -25,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _currentQuote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.3, end: 0)
                        .then(delay: 3000.ms)
                        .fadeOut(duration: 300.ms),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Telegram-style evolution animation - old emoji morphs into new one
  Widget _buildEvolutionSequence() {
    final oldEmoji = _getEmoji(_previousStage!);
    final newEmoji = _getEmoji(_currentStage!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "EVOLVED!" text
        const Text(
          '✨ EVOLVED! ✨',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.5, end: 0),

        const SizedBox(height: 8),

        // Emoji transition: old → sparkle burst → new
        Text(oldEmoji, style: TextStyle(fontSize: widget.size * 0.8))
            .animate()
            .scale(end: const Offset(1.2, 1.2), duration: 300.ms)
            .shake(hz: 8, duration: 500.ms)
            .then()
            .scale(end: const Offset(0.1, 0.1), duration: 200.ms)
            .fadeOut(duration: 200.ms)
            .swap(builder: (_, __) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // New emoji appears with bounce
              Text(newEmoji, style: TextStyle(fontSize: widget.size))
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),

              // Stage name
              const SizedBox(height: 8),
              Text(
                _currentStage!.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA94A),
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.5, end: 0),
            ],
          );
        }),

        // Celebration emojis
        const SizedBox(height: 8),
        const Text('🎉🌟🎊', style: TextStyle(fontSize: 24))
            .animate(delay: 600.ms)
            .fadeIn()
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0)),
      ],
    );
  }

  Widget _buildHatchingSequence() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Egg cracking then chick appearing
        const Text('🥚', style: TextStyle(fontSize: 80))
            .animate()
            .shake(duration: 500.ms, hz: 10)
            .then()
            .scale(end: const Offset(1.3, 1.3), duration: 200.ms)
            .then()
            .fadeOut(duration: 100.ms)
            .swap(builder: (_, __) {
          return const Text('🐣', style: TextStyle(fontSize: 100))
              .animate()
              .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 300.ms,
                  curve: Curves.elasticOut)
              .fadeIn(duration: 200.ms);
        }),

        // Celebration emojis
        const SizedBox(height: 8),
        const Text('🎉✨🎊', style: TextStyle(fontSize: 24))
            .animate(delay: 800.ms)
            .fadeIn()
            .slideY(begin: 0.5, end: 0),
      ],
    );
  }

  Widget _buildFloatingEmoji(_FloatingEmoji floating) {
    return Positioned(
      top: 0,
      left: widget.size / 2 + floating.x,
      child: Text(
        floating.emoji,
        style: const TextStyle(fontSize: 24),
      )
          .animate(delay: Duration(milliseconds: floating.delay))
          .fadeIn(duration: 200.ms)
          .slideY(begin: 0, end: -1.5, duration: 1000.ms)
          .fadeOut(delay: 800.ms, duration: 200.ms),
    );
  }

  StreakooPet _buildPet(AppState appState) {
    final completionsToday =
        appState.habits.where((h) => h.completedToday).length;
    final streaksAtRisk =
        appState.habits.where((h) => h.streak > 0 && !h.completedToday).length;

    return StreakooPet.fromUserState(
      userLevel: appState.userLevel.level,
      completionsToday: completionsToday,
      totalHabits: appState.habits.length,
      streaksAtRisk: streaksAtRisk,
      lastCompletion: DateTime.now(),
    );
  }
}

class _FloatingEmoji {
  final String emoji;
  final double x;
  final int delay;

  _FloatingEmoji({required this.emoji, required this.x, required this.delay});
}

/// Compact emoji pet for AppBar
class CompactEmojiPet extends StatefulWidget {
  final VoidCallback? onTap;

  const CompactEmojiPet({super.key, this.onTap});

  @override
  State<CompactEmojiPet> createState() => _CompactEmojiPetState();
}

class _CompactEmojiPetState extends State<CompactEmojiPet>
    with SingleTickerProviderStateMixin {
  late AnimationController _wobbleController;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    super.dispose();
  }

  String _getEmoji(PetStage stage) {
    switch (stage) {
      case PetStage.egg:
        return '🥚';
      case PetStage.hatchling:
        return '🐣';
      case PetStage.baby:
        return '🐥';
      case PetStage.teen:
        return '🐤';
      case PetStage.adult:
        return '🐔';
      case PetStage.master:
        return '🐓';
      case PetStage.legendary:
        return '🦅';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppState>(
      builder: (context, appState, _) {
        final pet = _buildPet(appState);
        final petName = StreakooPetService.instance.customName ?? 'Pet';
        final level = appState.userLevel.level;
        final emoji = _getEmoji(pet.stage);
        final isEgg = pet.stage == PetStage.egg;
        final hasPendingEvolution =
            StreakooPetService.instance.hasPendingEvolution;

        return GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFA94A)
                          .withValues(alpha: isDark ? 0.2 : 0.12),
                      const Color(0xFFFFD54F)
                          .withValues(alpha: isDark ? 0.08 : 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasPendingEvolution
                        ? const Color(0xFFFFD700)
                        : const Color(0xFFFFA94A).withValues(alpha: 0.25),
                    width: hasPendingEvolution ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mini emoji with wobble for egg
                    AnimatedBuilder(
                      animation: _wobbleController,
                      builder: (context, _) {
                        final wobble = isEgg
                            ? sin(_wobbleController.value * 2 * pi) * 0.08
                            : 0.0;

                        return Transform.rotate(
                          angle: wobble,
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 24)),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          petName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Lv.$level',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFA94A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Sparkle badge when evolution is pending
              if (hasPendingEvolution)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('✨', style: TextStyle(fontSize: 10))
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: const Duration(milliseconds: 600),
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.2, 1.2),
                          end: const Offset(0.8, 0.8),
                          duration: const Duration(milliseconds: 600),
                        ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  StreakooPet _buildPet(AppState appState) {
    final completionsToday =
        appState.habits.where((h) => h.completedToday).length;
    final streaksAtRisk =
        appState.habits.where((h) => h.streak > 0 && !h.completedToday).length;

    return StreakooPet.fromUserState(
      userLevel: appState.userLevel.level,
      completionsToday: completionsToday,
      totalHabits: appState.habits.length,
      streaksAtRisk: streaksAtRisk,
      lastCompletion: DateTime.now(),
    );
  }
}
