import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'dart:io';

import 'package:provider/provider.dart';
import 'package:live_activities/live_activities.dart';

import '../models/habit.dart';
import '../state/app_state.dart';

/// Full-screen Focus Mode for distraction-free habit completion
class FocusModeScreen extends StatefulWidget {
  final Habit habit;
  final int durationMinutes;
  final VoidCallback? onComplete;

  const FocusModeScreen({
    super.key,
    required this.habit,
    this.durationMinutes = 25,
    this.onComplete,
  });

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  late int _selectedDuration;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;
  bool _isPomodoroMode = false;
  int _pomodoroRound = 0;

  // Auto-complete logic
  Timer? _autoCompleteTimer;
  int _autoCompleteSeconds = 5;
  bool _showAutoCompleteCountdown = false;
  bool _autoMarkedComplete = false;

  final _liveActivities = LiveActivities();
  String? _activityId;
  int _lastActivityUpdate = 0;

  late AnimationController _pulseController;
  late AnimationController _breathController;
  late AnimationController _particleController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.durationMinutes;
    _remainingSeconds = _selectedDuration * 60;

    // Initialize Live Activities
    if (Platform.isIOS) {
      _liveActivities.init(appGroupId: 'group.com.streakoo.app');
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _endLiveActivity();
    _timer?.cancel();
    _autoCompleteTimer?.cancel();
    _pulseController.dispose();
    _breathController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _startTimer() {
    HapticFeedback.mediumImpact();
    setState(() => _isRunning = true);

    _createLiveActivity();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        _updateLiveActivity();

        // Halfway point notification
        if (_remainingSeconds == (_selectedDuration * 60) ~/ 2) {
          HapticFeedback.mediumImpact();
        }
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() => _isRunning = false);
    _updateLiveActivity(force: true);
  }

  void _completeSession() {
    HapticFeedback.heavyImpact();
    _endLiveActivity();
    _timer?.cancel();

    // Start auto-complete countdown
    setState(() {
      _isRunning = false;
      _showAutoCompleteCountdown = true;
      _autoCompleteSeconds = 5;
    });

    _autoCompleteTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_autoCompleteSeconds > 1) {
        setState(() => _autoCompleteSeconds--);
        HapticFeedback.lightImpact();
      } else {
        _confirmAutoComplete();
      }
    });
  }

  void _confirmAutoComplete() {
    _autoCompleteTimer?.cancel();

    // Mark habit as complete in AppState
    // Use isAiTriggered: true because Focus Mode completion is verified (user completed timer)
    // This bypasses manual completion restrictions for health-tracked habits
    if (mounted) {
      context.read<AppState>().completeHabit(widget.habit, isAiTriggered: true);
    }

    setState(() {
      _showAutoCompleteCountdown = false;
      _isCompleted = true;
      _autoMarkedComplete = true;

      if (_isPomodoroMode) {
        _pomodoroRound++;
      }
    });

    HapticFeedback.heavyImpact();
    widget.onComplete?.call();
  }

  void _cancelAutoComplete() {
    _autoCompleteTimer?.cancel();
    setState(() {
      _showAutoCompleteCountdown = false;
      _isCompleted = true; // Show completed state but don't mark as done
      _autoMarkedComplete = false;

      if (_isPomodoroMode) {
        _pomodoroRound++;
      }
    });
    HapticFeedback.selectionClick();
    widget.onComplete?.call();
  }

  void _setDuration(int minutes) {
    if (!_isRunning) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedDuration = minutes;
        _remainingSeconds = minutes * 60;
      });
    }
  }

  void _togglePomodoroMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isPomodoroMode = !_isPomodoroMode;
      if (_isPomodoroMode) {
        _selectedDuration = 25;
        _remainingSeconds = 25 * 60;
      }
    });
  }

  double get _progress {
    final total = _selectedDuration * 60;
    return 1 - (_remainingSeconds / total);
  }

  Color get _primaryGradientColor {
    if (_isCompleted) return const Color(0xFF4CAF50); // Keep green for success
    if (_progress < 0.5) return const Color(0xFFFFA94A); // Orange - app primary
    return const Color(0xFFFF6B6B); // Coral for second half
  }

  Color get _secondaryGradientColor {
    if (_isCompleted) return const Color(0xFF66BB6A);
    if (_progress < 0.5) return const Color(0xFF1FD1A5); // Teal - app secondary
    return const Color(0xFFFFA94A); // Orange for second half
  }

  // Theme helper getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bgColor => _isDark ? Colors.black : const Color(0xFFF8F9FA);
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get _subtextColor =>
      _isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background with particles
            _buildAnimatedBackground(),
            _buildParticles(), // Show particles in both themes

            // Main content
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // Habit emoji with glow
                      _buildHabitEmoji(),

                      const SizedBox(height: 16),

                      // Habit name
                      Text(
                        widget.habit.name,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 8),

                      Text(
                        _isPomodoroMode
                            ? 'Pomodoro Round ${_pomodoroRound + 1}'
                            : 'Focus Time',
                        style: TextStyle(
                          fontSize: 14,
                          color: _subtextColor,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Premium Timer Circle with gradient
                      _buildPremiumTimerCircle(),

                      const SizedBox(height: 48),

                      // Duration Presets (when not running)
                      if (!_isRunning && !_isCompleted) _buildDurationPresets(),

                      const SizedBox(height: 24),

                      // Controls
                      if (_isCompleted)
                        _buildCompletedState()
                      else
                        _buildControls(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => _showExitConfirmation(),
                icon: Icon(
                  Icons.close,
                  color: _isDark ? Colors.white54 : Colors.black45,
                  size: 28,
                ),
              ),
            ),

            // Pomodoro mode toggle
            Positioned(
              top: 16,
              left: 16,
              child: _buildPomodoroToggle(),
            ),

            // Auto-complete Countdown Overlay
            if (_showAutoCompleteCountdown) _buildAutoCompleteOverlay(),
          ],
        ),
      ),
    );
  }

  // LIVE ACTIVITIES INTEGRATION

  Future<void> _createLiveActivity() async {
    if (!Platform.isIOS) return;

    // Don't create if already exists
    if (_activityId != null) {
      _updateLiveActivity(force: true);
      return;
    }

    final activityId = 'focus_mode_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _liveActivities.createActivity(
        activityId,
        {
          'habitName': widget.habit.name,
          'habitEmoji': widget.habit.emoji,
          'remainingSeconds': _remainingSeconds,
          'totalDurationSeconds': _selectedDuration * 60,
          'progress': 1 - (_remainingSeconds / (_selectedDuration * 60)),
          'isPaused': false,
        },
      );
      setState(() => _activityId = activityId);
    } catch (e) {
      debugPrint('Error creating live activity: $e');
    }
  }

  Future<void> _updateLiveActivity({bool force = false}) async {
    if (!Platform.isIOS || _activityId == null) return;

    // Throttle updates to every 5 seconds unless forced (e.g. pause/resume)
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _lastActivityUpdate < 5000) return;

    _lastActivityUpdate = now;

    try {
      await _liveActivities.updateActivity(
        _activityId!,
        {
          'remainingSeconds': _remainingSeconds,
          'totalDurationSeconds': _selectedDuration * 60,
          'progress': 1 - (_remainingSeconds / (_selectedDuration * 60)),
          'isPaused': !_isRunning,
        },
      );
    } catch (e) {
      debugPrint('Error updating live activity: $e');
    }
  }

  Future<void> _endLiveActivity() async {
    if (!Platform.isIOS || _activityId == null) return;

    try {
      await _liveActivities.endActivity(_activityId!);
      setState(() => _activityId = null);
    } catch (e) {
      debugPrint('Error ending live activity: $e');
    }
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5 + (_breathController.value * 0.3),
              colors: _isDark
                  ? [
                      const Color(0xFF1A1A1A),
                      const Color(0xFF0D0D0D).withValues(alpha: 0.95),
                      Colors.black,
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF0F0F0),
                      const Color(0xFFE8E8E8),
                    ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particleController.value, _isDark),
          child: Container(),
        );
      },
    );
  }

  Widget _buildHabitEmoji() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryGradientColor.withValues(
                    alpha: 0.3 + (_glowController.value * 0.2)),
                blurRadius: 40 + (_glowController.value * 20),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Text(
            widget.habit.emoji,
            style: const TextStyle(fontSize: 80),
          ),
        );
      },
    ).animate().fadeIn().scale(
          delay: 200.ms,
          duration: 600.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildPremiumTimerCircle() {
    // Calculate responsive size based on screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final minDimension = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;
    // Use 70% of min dimension, but cap between 250-400px
    final timerSize = (minDimension * 0.65).clamp(250.0, 400.0);
    final arcSize = timerSize - 20; // Arc slightly smaller than container

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, child) {
        final scale = _isRunning ? 1.0 + (_pulseController.value * 0.02) : 1.0;
        final glowIntensity = 0.4 + (_glowController.value * 0.3);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: timerSize,
            height: timerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryGradientColor.withValues(alpha: glowIntensity),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle with gradient
                Container(
                  width: timerSize,
                  height: timerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (_isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.05),
                        (_isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),

                // Premium gradient progress arc
                SizedBox(
                  width: arcSize,
                  height: arcSize,
                  child: CustomPaint(
                    painter: _GradientArcPainter(
                      progress: _progress,
                      primaryColor: _primaryGradientColor,
                      secondaryColor: _secondaryGradientColor,
                    ),
                  ),
                ),

                // Apple-style time display with individual digit animations
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isCompleted)
                      Text(
                        '✓',
                        style: TextStyle(
                          fontSize: timerSize * 0.3,
                          fontWeight: FontWeight.w200,
                          color: _textColor,
                        ),
                      ).animate().scale(curve: Curves.elasticOut)
                    else
                      _buildAppleStyleTimer(),
                    if (!_isCompleted) const SizedBox(height: 8),
                    if (!_isCompleted)
                      Text(
                        _isRunning ? 'Stay focused' : 'Ready to begin?',
                        style: TextStyle(
                          fontSize: 14,
                          color: _subtextColor,
                          fontWeight: FontWeight.w500,
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

  /// Build Apple-style animated timer with individual digit animations
  Widget _buildAppleStyleTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    // Split into individual digits
    final minTens = minutes ~/ 10;
    final minOnes = minutes % 10;
    final secTens = seconds ~/ 10;
    final secOnes = seconds % 10;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Minutes tens digit
        _buildAnimatedDigit(minTens, 'min_tens'),
        // Minutes ones digit
        _buildAnimatedDigit(minOnes, 'min_ones'),
        // Colon separator
        Text(
          ':',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w200,
            color: _textColor.withValues(alpha: 0.8),
          ),
        ),
        // Seconds tens digit
        _buildAnimatedDigit(secTens, 'sec_tens'),
        // Seconds ones digit
        _buildAnimatedDigit(secOnes, 'sec_ones'),
      ],
    );
  }

  /// Build an individual animated digit with smooth scale + fade transition
  Widget _buildAnimatedDigit(int digit, String keyPrefix) {
    return SizedBox(
      width: 40, // Fixed width for consistent spacing
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Smoother scale + fade animation (Apple-style)
          return ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: Text(
          digit.toString(),
          key: ValueKey('${keyPrefix}_$digit'),
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w200,
            color: _textColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationPresets() {
    final presets = [
      {'minutes': 5, 'label': '5m'},
      {'minutes': 15, 'label': '15m'},
      {'minutes': 25, 'label': '25m'},
      {'minutes': 45, 'label': '45m'},
    ];

    return Column(
      children: [
        Text(
          'Quick Presets',
          style: TextStyle(
            fontSize: 12,
            color: _subtextColor,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: presets.map((preset) {
            final minutes = preset['minutes'] as int;
            final label = preset['label'] as String;
            final isSelected = _selectedDuration == minutes;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => _setDuration(minutes),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              _primaryGradientColor,
                              _secondaryGradientColor
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (_isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (_isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _textColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildControls() {
    return GestureDetector(
      onTap: _isRunning ? _pauseTimer : _startTimer,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryGradientColor, _secondaryGradientColor],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primaryGradientColor.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 45,
        ),
      ),
    )
        .animate()
        .scale(delay: 500.ms, duration: 400.ms, curve: Curves.elasticOut);
  }

  Widget _buildCompletedState() {
    return Column(
      children: [
        Text(
          _autoMarkedComplete ? '🎉 Marked Complete!' : '🎉 Session Finished',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 16),
        Text(
          'You completed $_selectedDuration minutes',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              'Another Round',
              Icons.refresh_rounded,
              () {
                setState(() {
                  _remainingSeconds = _selectedDuration * 60;
                  _isCompleted = false;
                });
              },
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              'Done',
              Icons.check_rounded,
              () => Navigator.pop(context),
              isPrimary: true,
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                )
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroToggle() {
    return GestureDetector(
      onTap: _isRunning ? null : _togglePomodoroMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isPomodoroMode
              ? const Color(0xFFFF6B6B).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isPomodoroMode
                ? const Color(0xFFFF6B6B).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer,
              size: 16,
              color: _isPomodoroMode ? const Color(0xFFFF6B6B) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              'Pomodoro',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    _isPomodoroMode ? const Color(0xFFFF6B6B) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    if (!_isRunning && _remainingSeconds == _selectedDuration * 60) {
      Navigator.pop(context);
      return;
    }

    // If countdown is showing, just cancel it and exit
    if (_showAutoCompleteCountdown) {
      _autoCompleteTimer?.cancel();
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF191919) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Exit Focus Mode?',
          style: TextStyle(color: _textColor),
        ),
        content: Text(
          'Your progress will be lost.',
          style: TextStyle(color: _subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Stay',
              style: TextStyle(color: Color(0xFFFFA94A)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child:
                const Text('Exit', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoCompleteOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Marking Complete In',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 30),
            // Animated countdown circle with progress ring
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress ring background
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 6,
                      ),
                    ),
                  ),
                  // Animated progress ring
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (5 - _autoCompleteSeconds) / 5),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOutCubic,
                    builder: (context, value, child) {
                      return SizedBox(
                        width: 160,
                        height: 160,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color.lerp(
                              const Color(0xFF4CAF50),
                              const Color(0xFF81C784),
                              value,
                            )!,
                          ),
                        ),
                      );
                    },
                  ),
                  // Inner glow circle
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Countdown number with enhanced animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut,
                        ),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      '$_autoCompleteSeconds',
                      key: ValueKey(_autoCompleteSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.03, 1.03),
                  duration: 800.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  'Cancel',
                  Icons.close_rounded,
                  _cancelAutoComplete,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                const SizedBox(width: 20),
                _buildActionButton(
                  'Complete Now',
                  Icons.check_rounded,
                  _confirmAutoComplete,
                  isPrimary: true,
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for gradient arc
class _GradientArcPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _GradientArcPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      bgPaint,
    );

    // Gradient progress arc
    if (progress > 0) {
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
        colors: [primaryColor, secondaryColor, primaryColor],
        stops: const [0.0, 0.5, 1.0],
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GradientArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

// Custom painter for particle effect
class _ParticlePainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _ParticlePainter(this.animationValue, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isDark
        ? Colors.white
        : const Color(0xFF191919); // Dark particles for light theme
    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 30; i++) {
      final x = (size.width * (i * 0.1 + animationValue * 0.3)) % size.width;
      final y = (size.height * (i * 0.07 + animationValue * 0.2)) % size.height;
      final radius = 1.0 + (i % 3);

      paint.color = baseColor.withValues(alpha: 0.1 + (i % 5) * 0.05);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}

/// Button to launch focus mode for a habit
class FocusModeButton extends StatelessWidget {
  final Habit habit;
  final int defaultDuration;

  const FocusModeButton({
    super.key,
    required this.habit,
    this.defaultDuration = 25,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FocusModeScreen(
              habit: habit,
              durationMinutes: habit.focusModeDuration ?? defaultDuration,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA94A), Color(0xFF1FD1A5)], // App theme colors
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_rounded, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Focus',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
