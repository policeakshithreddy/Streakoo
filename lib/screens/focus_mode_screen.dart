import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'dart:io';

import 'package:live_activities/live_activities.dart';

import '../models/habit.dart';

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
    setState(() {
      _isRunning = false;
      _isCompleted = true;

      if (_isPomodoroMode) {
        _pomodoroRound++;
      }
    });
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

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = _selectedDuration * 60;
    return 1 - (_remainingSeconds / total);
  }

  Color get _primaryGradientColor {
    if (_isCompleted) return const Color(0xFF4CAF50);
    if (_progress < 0.5) return const Color(0xFF667EEA);
    return const Color(0xFFFF6B9D);
  }

  Color get _secondaryGradientColor {
    if (_isCompleted) return const Color(0xFF66BB6A);
    if (_progress < 0.5) return const Color(0xFF764BA2);
    return const Color(0xFFFFC371);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background with particles
            _buildAnimatedBackground(),
            _buildParticles(),

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
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.6),
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
                icon: const Icon(Icons.close, color: Colors.white54, size: 28),
              ),
            ),

            // Pomodoro mode toggle
            Positioned(
              top: 16,
              left: 16,
              child: _buildPomodoroToggle(),
            ),
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
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                Colors.black,
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
          painter: _ParticlePainter(_particleController.value),
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
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, child) {
        final scale = _isRunning ? 1.0 + (_pulseController.value * 0.02) : 1.0;
        final glowIntensity = 0.4 + (_glowController.value * 0.3);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 300,
            height: 300,
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
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),

                // Premium gradient progress arc
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CustomPaint(
                    painter: _GradientArcPainter(
                      progress: _progress,
                      primaryColor: _primaryGradientColor,
                      secondaryColor: _secondaryGradientColor,
                    ),
                  ),
                ),

                // Time display
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isCompleted ? '✓' : _formattedTime,
                      style: TextStyle(
                        fontSize: _isCompleted ? 90 : 64,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (!_isCompleted) const SizedBox(height: 8),
                    if (!_isCompleted)
                      Text(
                        _isRunning ? 'Stay focused' : 'Ready to begin?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
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
            color: Colors.white.withValues(alpha: 0.5),
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
                    color:
                        isSelected ? null : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
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
        const Text(
          '🎉 Excellent Focus!',
          style: TextStyle(
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Focus Mode?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your progress will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Stay', style: TextStyle(color: Color(0xFF667EEA))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close focus mode
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
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

  _ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 30; i++) {
      final x = (size.width * (i * 0.1 + animationValue * 0.3)) % size.width;
      final y = (size.height * (i * 0.07 + animationValue * 0.2)) % size.height;
      final radius = 1.0 + (i % 3);

      paint.color = Colors.white.withValues(alpha: 0.1 + (i % 5) * 0.05);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
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
              durationMinutes: defaultDuration,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.3),
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
