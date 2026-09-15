import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/loot_box.dart';
import '../services/loot_box_service.dart';

/// Animated loot box opening screen
class LootBoxScreen extends StatefulWidget {
  final LootBox lootBox;
  final VoidCallback? onClaimed;

  const LootBoxScreen({
    super.key,
    required this.lootBox,
    this.onClaimed,
  });

  @override
  State<LootBoxScreen> createState() => _LootBoxScreenState();
}

class _LootBoxScreenState extends State<LootBoxScreen>
    with TickerProviderStateMixin {
  bool _isOpening = false;
  bool _isRevealed = false;
  LootBoxReward? _reward;
  late AnimationController _shakeController;
  late AnimationController _glowController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shakeAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _openBox() async {
    if (_isOpening) return;

    setState(() => _isOpening = true);
    HapticFeedback.heavyImpact();

    // Shake animation
    for (int i = 0; i < 5; i++) {
      await _shakeController.forward();
      await _shakeController.reverse();
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Open and get reward
    _reward = await LootBoxService.instance.openBox(widget.lootBox);

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() => _isRevealed = true);
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background with particles
          _buildBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      if (!_isRevealed)
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      const Spacer(),
                      Text(
                        widget.lootBox.trigger.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Loot box
                if (!_isRevealed) _buildClosedBox() else _buildRevealedReward(),

                const Spacer(),

                // Action button
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: _buildActionButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Gradient
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                _isRevealed
                    ? Color(_reward?.rarity.colorValue ?? 0xFFFFA94A)
                        .withValues(alpha: 0.3)
                    : const Color(0xFFFFA94A).withValues(alpha: 0.2),
                Colors.black,
              ],
            ),
          ),
        ),

        // Particles
        ...List.generate(20, (i) {
          final random = Random(i);
          return Positioned(
            left: random.nextDouble() * MediaQuery.of(context).size.width,
            top: random.nextDouble() * MediaQuery.of(context).size.height,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(delay: (i * 100).ms)
                .then()
                .fadeOut()
                .moveY(
                  begin: 0,
                  end: -50,
                  duration: Duration(milliseconds: 2000 + random.nextInt(2000)),
                ),
          );
        }),
      ],
    );
  }

  Widget _buildClosedBox() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_isOpening ? _shakeAnimation.value : 0, 0),
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA94A)
                      .withValues(alpha: 0.3 + _glowController.value * 0.3),
                  blurRadius: 30 + _glowController.value * 20,
                  spreadRadius: 5 + _glowController.value * 10,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Box
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFA94A),
                    Color(0xFFFF8A00),
                    Color(0xFFFF6B00),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🎁',
                    style: TextStyle(fontSize: 60),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mystery Box',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Question marks
            ...List.generate(4, (i) {
              return Positioned(
                left: i % 2 == 0 ? 20 : null,
                right: i % 2 == 1 ? 20 : null,
                top: i < 2 ? 20 : null,
                bottom: i >= 2 ? 20 : null,
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      delay: (i * 200).ms,
                    ),
              );
            }),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildRevealedReward() {
    if (_reward == null) return const SizedBox.shrink();

    final color = Color(_reward!.rarity.colorValue);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rarity badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_reward!.rarity.emoji),
              const SizedBox(width: 8),
              Text(
                _reward!.rarity.name.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.5),

        const SizedBox(height: 32),

        // Reward icon
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _reward!.emoji,
              style: const TextStyle(fontSize: 70),
            ),
          ),
        ).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 32),

        // Reward name
        Text(
          _reward!.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),

        const SizedBox(height: 8),

        // Reward description
        Text(
          _reward!.description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_isRevealed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            widget.onClaimed?.call();
            Navigator.pop(context, _reward);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(_reward?.rarity.colorValue ?? 0xFFFFA94A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'CLAIM REWARD',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isOpening ? null : _openBox,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA94A),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFFFFA94A).withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _isOpening ? 'OPENING...' : 'OPEN BOX',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
