import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/streakoo_pet.dart';
import '../state/app_state.dart';
import 'chicken_painter.dart';

/// Animated chicken character widget with blink, wobble, and hatching
class AnimatedChickenWidget extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  final bool enableHatching; // Only true on Pet Screen

  const AnimatedChickenWidget({
    super.key,
    this.size = 200,
    this.onTap,
    this.enableHatching = false,
  });

  @override
  State<AnimatedChickenWidget> createState() => _AnimatedChickenWidgetState();
}

class _AnimatedChickenWidgetState extends State<AnimatedChickenWidget>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _wobbleController;
  late AnimationController _hatchingController;

  late Animation<double> _blinkAnimation;
  late Animation<double> _wobbleAnimation;

  // Hatching animation stages
  late Animation<double> _shakeIntensity;
  late Animation<double> _crackGrowth;
  late Animation<double> _shellSplit;
  late Animation<double> _chickEmergence;

  bool _isHatching = false;
  bool _hatchingTriggered = false;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startRandomBlink();

    // Check if should trigger hatching
    if (widget.enableHatching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndTriggerHatching();
      });
    }
  }

  void _setupAnimations() {
    // Blink animation
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _blinkController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _blinkController.reverse();
      } else if (status == AnimationStatus.dismissed && !_isHatching) {
        Future.delayed(Duration(milliseconds: 2500 + _random.nextInt(4000)),
            () {
          if (mounted && !_isHatching) {
            _blinkController.forward();
          }
        });
      }
    });

    // Wobble animation (for egg only)
    _wobbleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _wobbleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
    );

    // Hatching animation (4 seconds total)
    _hatchingController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Phase 1: Intense shaking (0-1s)
    _shakeIntensity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _hatchingController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Phase 2: Cracks appear and grow (1-1.5s, 0.25-0.375)
    _crackGrowth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _hatchingController,
        curve: const Interval(0.25, 0.625, curve: Curves.easeOut),
      ),
    );

    // Phase 3: Shell splits (1.5-2.5s, 0.375-0.625)
    _shellSplit = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _hatchingController,
        curve: const Interval(0.375, 0.75, curve: Curves.easeOut),
      ),
    );

    // Phase 4: Chick emerges (2-4s, 0.5-1.0)
    _chickEmergence = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _hatchingController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _hatchingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isHatching = false);
        StreakooPetService.instance.markHatchingAsSeen();
      }
    });
  }

  Future<void> _checkAndTriggerHatching() async {
    if (_hatchingTriggered) return;

    final appState = context.read<AppState>();
    final level = appState.userLevel.level;

    // Only hatch if level 2+ and haven't seen it yet
    if (level >= 2) {
      final hasSeenHatching =
          await StreakooPetService.instance.hasSeenHatching();
      if (!hasSeenHatching && mounted) {
        _hatchingTriggered = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _triggerHatching();
          }
        });
      }
    }
  }

  void _triggerHatching() {
    HapticFeedback.mediumImpact();
    setState(() => _isHatching = true);
    _hatchingController.forward();

    // Haptic feedback at key moments
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) HapticFeedback.lightImpact();
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  void _startRandomBlink() {
    Future.delayed(Duration(milliseconds: 1500 + _random.nextInt(2000)), () {
      if (mounted && !_isHatching) {
        _blinkController.forward();
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _wobbleController.dispose();
    _hatchingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final pet = _buildPet(appState);
        final isEgg = pet.stage == PetStage.egg;
        final level = appState.userLevel.level;
        final stageProgress = _calculateStageProgress(level, pet.stage);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap?.call();
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _blinkAnimation,
                _wobbleAnimation,
                _hatchingController,
              ]),
              builder: (context, child) {
                // Calculate wobble rotation (only for egg)
                double wobbleRotation = 0.0;
                if (isEgg && !_isHatching) {
                  wobbleRotation =
                      sin(_wobbleAnimation.value * 2 * pi) * 0.05; // ±3 degrees
                }

                // Calculate shaking (during hatching)
                double shakeRotation = 0.0;
                if (_isHatching) {
                  final shakeAmount =
                      _shakeIntensity.value * 0.15; // ±8.6 degrees max
                  shakeRotation =
                      sin(_hatchingController.value * 50 * pi) * shakeAmount;
                }

                final totalRotation = wobbleRotation + shakeRotation;

                // Determine whether to show egg or chick
                final showChick = _chickEmergence.value > 0.1;
                final chickScale = _chickEmergence.value.clamp(0.0, 1.0);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Egg (with potential cracks and split shells)
                    if (!showChick || _shellSplit.value < 1.0)
                      Transform.rotate(
                        angle: totalRotation,
                        child: Opacity(
                          opacity: showChick
                              ? (1.0 - _chickEmergence.value).clamp(0.0, 1.0)
                              : 1.0,
                          child: CustomPaint(
                            size: Size(widget.size, widget.size),
                            painter: ChickenPainter(
                              stage: PetStage.egg,
                              mood: pet.mood,
                              blinkValue: 1.0,
                              happinessLevel: pet.happinessLevel.toDouble(),
                              stageProgress: stageProgress,
                              crackProgress: _crackGrowth.value,
                              shellSplitProgress: _shellSplit.value,
                              chickEmergenceProgress: 0.0,
                            ),
                          ),
                        ),
                      ),

                    // Emerging chick
                    if (showChick)
                      Transform.scale(
                        scale: chickScale,
                        child: Opacity(
                          opacity: _chickEmergence.value.clamp(0.0, 1.0),
                          child: CustomPaint(
                            size: Size(widget.size, widget.size),
                            painter: ChickenPainter(
                              stage: pet.stage,
                              mood: pet.mood,
                              blinkValue: _blinkAnimation.value,
                              happinessLevel: pet.happinessLevel.toDouble(),
                              stageProgress: stageProgress,
                            ),
                          ),
                        ),
                      ),

                    // Normal display (no hatching)
                    if (!_isHatching && !isEgg)
                      CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: ChickenPainter(
                          stage: pet.stage,
                          mood: pet.mood,
                          blinkValue: _blinkAnimation.value,
                          happinessLevel: pet.happinessLevel.toDouble(),
                          stageProgress: stageProgress,
                        ),
                      ),
                  ],
                );
              },
            ),
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

  /// Calculate progress within current stage (0-1)
  double _calculateStageProgress(int currentLevel, PetStage stage) {
    final levelInStage = currentLevel - stage.requiredLevel;
    final nextStage = stage.nextStage;

    if (nextStage == null) return 0.5; // Legendary stays at mid-point

    final levelsInStage = nextStage.requiredLevel - stage.requiredLevel;
    if (levelsInStage <= 0) return 0.0;

    return (levelInStage / levelsInStage).clamp(0.0, 1.0);
  }
}

/// Compact version for AppBar with mini chicken
class CompactAnimatedChicken extends StatefulWidget {
  final VoidCallback? onTap;

  const CompactAnimatedChicken({super.key, this.onTap});

  @override
  State<CompactAnimatedChicken> createState() => _CompactAnimatedChickenState();
}

class _CompactAnimatedChickenState extends State<CompactAnimatedChicken>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _wobbleController;
  late Animation<double> _blinkAnimation;
  late Animation<double> _wobbleAnimation;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    _blinkAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);

    _blinkController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _blinkController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        Future.delayed(Duration(milliseconds: 3000 + _random.nextInt(4000)),
            () {
          if (mounted) _blinkController.forward();
        });
      }
    });

    // Wobble for egg
    _wobbleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _wobbleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
    );

    // Start first blink
    Future.delayed(Duration(milliseconds: 1000 + _random.nextInt(2000)), () {
      if (mounted) _blinkController.forward();
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppState>(
      builder: (context, appState, _) {
        final petName = StreakooPetService.instance.customName ?? 'Pet';
        final level = appState.userLevel.level;
        final pet = _buildPet(appState);
        final isEgg = pet.stage == PetStage.egg;

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                color: const Color(0xFFFFA94A).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini chicken with wobble for egg
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_blinkAnimation, _wobbleAnimation]),
                  builder: (context, _) {
                    final wobbleRotation = isEgg
                        ? sin(_wobbleAnimation.value * 2 * pi) * 0.05
                        : 0.0;
                    final stageProgress =
                        _calculateStageProgress(level, pet.stage);

                    return Transform.rotate(
                      angle: wobbleRotation,
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CustomPaint(
                          painter: ChickenPainter(
                            stage: pet.stage,
                            mood: pet.mood,
                            blinkValue: _blinkAnimation.value,
                            happinessLevel: pet.happinessLevel.toDouble(),
                            stageProgress: stageProgress,
                          ),
                        ),
                      ),
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

  /// Calculate progress within current stage (0-1)
  double _calculateStageProgress(int currentLevel, PetStage stage) {
    final levelInStage = currentLevel - stage.requiredLevel;
    final nextStage = stage.nextStage;

    if (nextStage == null) return 0.5; // Legendary stays at mid-point

    final levelsInStage = nextStage.requiredLevel - stage.requiredLevel;
    if (levelsInStage <= 0) return 0.0;

    return (levelInStage / levelsInStage).clamp(0.0, 1.0);
  }
}
