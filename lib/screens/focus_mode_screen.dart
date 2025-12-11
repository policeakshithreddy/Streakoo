import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;
  late AnimationController _pulseController;
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationMinutes * 60;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  void _startTimer() {
    HapticFeedback.mediumImpact();
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _completeSession() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });
    widget.onComplete?.call();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = widget.durationMinutes * 60;
    return 1 - (_remainingSeconds / total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Habit emoji
                  Text(
                    widget.habit.emoji,
                    style: const TextStyle(fontSize: 60),
                  ).animate().fadeIn().scale(
                        delay: 200.ms,
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 16),

                  // Habit name
                  Text(
                    widget.habit.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Focus Time',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 2,
                    ),
                  ),

                  const Spacer(),

                  // Timer Circle
                  _buildTimerCircle(),

                  const Spacer(),

                  // Controls
                  if (_isCompleted)
                    _buildCompletedState()
                  else
                    _buildControls(),

                  const Spacer(flex: 2),
                ],
              ),
            ),

            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => _showExitConfirmation(),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildTimerCircle() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = _isRunning ? 1.0 + (_pulseController.value * 0.02) : 1.0;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),

                // Progress arc
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isCompleted
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF667EEA),
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
                        fontSize: _isCompleted ? 80 : 56,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (!_isCompleted)
                      Text(
                        _isRunning ? 'Stay focused' : 'Ready?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
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

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Duration adjustment buttons (when paused)
        if (!_isRunning) ...[
          _buildDurationButton(-5, '-5m'),
          const SizedBox(width: 16),
        ],

        // Play/Pause button
        GestureDetector(
          onTap: _isRunning ? _pauseTimer : _startTimer,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        )
            .animate()
            .scale(delay: 400.ms, duration: 400.ms, curve: Curves.elasticOut),

        if (!_isRunning) ...[
          const SizedBox(width: 16),
          _buildDurationButton(5, '+5m'),
        ],
      ],
    );
  }

  Widget _buildDurationButton(int minutes, String label) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _remainingSeconds =
              (_remainingSeconds + (minutes * 60)).clamp(60, 120 * 60);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedState() {
    return Column(
      children: [
        const Text(
          '🎉 Great Focus Session!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              'Another Round',
              Icons.refresh_rounded,
              () {
                setState(() {
                  _remainingSeconds = widget.durationMinutes * 60;
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                )
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    if (!_isRunning && _remainingSeconds == widget.durationMinutes * 60) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Focus Mode?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
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
          color: const Color(0xFF667EEA).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_rounded, size: 16, color: Color(0xFF667EEA)),
            SizedBox(width: 6),
            Text(
              'Focus',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667EEA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
