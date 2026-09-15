import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Pet mini-game screen - Tap the Pet!
class PetMiniGameScreen extends StatefulWidget {
  const PetMiniGameScreen({super.key});

  @override
  State<PetMiniGameScreen> createState() => _PetMiniGameScreenState();
}

class _PetMiniGameScreenState extends State<PetMiniGameScreen>
    with TickerProviderStateMixin {
  int _score = 0;
  int _timeLeft = 15;
  bool _gameActive = false;
  bool _gameOver = false;
  Timer? _gameTimer;
  final Random _random = Random();

  // Target positions
  double _targetX = 0.5;
  double _targetY = 0.5;
  final List<_FloatingScore> _floatingScores = [];

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 15;
      _gameActive = true;
      _gameOver = false;
      _moveTarget();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() {
      _gameActive = false;
      _gameOver = true;
    });
    HapticFeedback.heavyImpact();
  }

  void _moveTarget() {
    setState(() {
      _targetX = 0.1 + _random.nextDouble() * 0.8;
      _targetY = 0.2 + _random.nextDouble() * 0.5;
    });
  }

  void _onTapTarget() {
    if (!_gameActive) return;

    HapticFeedback.mediumImpact();

    // Add floating score
    _floatingScores.add(_FloatingScore(
      x: _targetX,
      y: _targetY,
      points: 10,
    ));

    setState(() {
      _score += 10;
    });

    _moveTarget();

    // Remove floating score after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _floatingScores.isNotEmpty) {
        setState(() => _floatingScores.removeAt(0));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('🎮 Tap the Pet!'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Game area
          Positioned.fill(
            child: Column(
              children: [
                // Stats bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Score
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFA94A).withValues(alpha: 0.2),
                              const Color(0xFFFFD54F).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              '$_score',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _timeLeft <= 5
                                ? [
                                    Colors.red.withValues(alpha: 0.3),
                                    Colors.red.withValues(alpha: 0.1)
                                  ]
                                : [
                                    const Color(0xFF4CAF50)
                                        .withValues(alpha: 0.2),
                                    const Color(0xFF8BC34A)
                                        .withValues(alpha: 0.1)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text('⏱️', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              '$_timeLeft',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _timeLeft <= 5
                                    ? Colors.red
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Game area
                Expanded(
                  child: Stack(
                    children: [
                      // Tap target
                      if (_gameActive)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          left: _targetX * (size.width - 80),
                          top: _targetY * (size.height * 0.5),
                          child: GestureDetector(
                            onTap: _onTapTarget,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA94A)
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFA94A),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFA94A)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child:
                                    Text('🐥', style: TextStyle(fontSize: 40)),
                              ),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                duration: 500.ms,
                              )
                              .then()
                              .scale(
                                begin: const Offset(1.1, 1.1),
                                end: const Offset(1, 1),
                                duration: 500.ms,
                              ),
                        ),

                      // Floating scores
                      ..._floatingScores.map((fs) => Positioned(
                            left: fs.x * (size.width - 40),
                            top: fs.y * (size.height * 0.5),
                            child: const Text(
                              '+10',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFA94A),
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 200.ms)
                                .slideY(begin: 0, end: -1, duration: 600.ms)
                                .fadeOut(delay: 400.ms, duration: 200.ms),
                          )),

                      // Start/Game Over overlay
                      if (!_gameActive)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.8)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_gameOver) ...[
                                  const Text('🎉',
                                      style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Game Over!',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Score: $_score',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Color(0xFFFFA94A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getScoreMessage(_score),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                ] else ...[
                                  const Text('🐥',
                                      style: TextStyle(fontSize: 64)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap the Pet!',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap as fast as you can!',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _startGame,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFA94A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    _gameOver ? 'Play Again' : 'Start Game',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn()
                              .scale(begin: const Offset(0.9, 0.9)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreMessage(int score) {
    if (score >= 200) return '🌟 LEGENDARY! Your pet is impressed!';
    if (score >= 150) return '🔥 Amazing! Super fast tapper!';
    if (score >= 100) return '⭐ Great job! Keep practicing!';
    if (score >= 50) return '👍 Not bad! Try again!';
    return '💪 Keep trying! You can do better!';
  }
}

class _FloatingScore {
  final double x;
  final double y;
  final int points;

  _FloatingScore({required this.x, required this.y, required this.points});
}
