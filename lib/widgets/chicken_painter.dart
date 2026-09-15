import 'dart:math';
import 'package:flutter/material.dart';

import '../models/streakoo_pet.dart';

/// Realistic emoji-quality chicken painter
/// Draws polished, smooth chicken at different life stages
/// Supports hatching animation with cracks and shell split
/// Features gradual in-stage evolution (size, color, features)
class ChickenPainter extends CustomPainter {
  final PetStage stage;
  final PetMood mood;
  final double blinkValue; // 0-1, 1 = fully open, 0 = closed
  final double happinessLevel; // 0-100
  final double stageProgress; // 0-1, progress within current stage

  // Hatching animation parameters
  final double crackProgress; // 0-1, how visible/grown the cracks are
  final double shellSplitProgress; // 0-1, how far apart the shell pieces are
  final double chickEmergenceProgress; // 0-1, chick scale/visibility

  ChickenPainter({
    required this.stage,
    required this.mood,
    this.blinkValue = 1.0,
    this.happinessLevel = 50,
    this.stageProgress = 0.0,
    this.crackProgress = 0.0,
    this.shellSplitProgress = 0.0,
    this.chickEmergenceProgress = 0.0,
  });

  /// Get size scale multiplier based on stage progress (grows 10% within each stage)
  double get sizeScale => 1.0 + (stageProgress * 0.1);

  /// Check if close to evolution (shows hint features)
  bool get isCloseToEvolution => stageProgress >= 0.85;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Apply gradual size scaling
    final scaledSize = Size(size.width * sizeScale, size.height * sizeScale);

    switch (stage) {
      case PetStage.egg:
        _drawEgg(canvas, scaledSize, center);
        break;
      case PetStage.hatchling:
        _drawHatchling(canvas, scaledSize, center);
        break;
      case PetStage.baby:
        _drawBabyChick(canvas, scaledSize, center);
        break;
      case PetStage.teen:
        _drawTeenChick(canvas, scaledSize, center);
        break;
      case PetStage.adult:
        _drawAdultChicken(canvas, scaledSize, center);
        break;
      case PetStage.master:
        _drawMasterRooster(canvas, scaledSize, center);
        break;
      case PetStage.legendary:
        _drawPhoenix(canvas, scaledSize, center);
        break;
    }
  }

  // ============ EGG STAGE ============
  void _drawEgg(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Shadow
    _drawShadow(canvas, center.translate(0, h * 0.35), w * 0.35, h * 0.08);

    // If hatching, draw split shells separately
    if (shellSplitProgress > 0) {
      _drawSplitEggShells(canvas, size, center);
    } else {
      // Draw normal egg
      _drawCompleteEgg(canvas, size, center);

      // Draw cracks if hatching has started
      if (crackProgress > 0) {
        _drawHatchingCracks(canvas, center, w, h, crackProgress);
      } else if (happinessLevel > 60) {
        // Static cracks if almost ready (old behavior)
        _drawCracks(canvas, center, w, h);
      }
    }
  }

  void _drawCompleteEgg(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Main egg shape with gradient
    final eggRect = Rect.fromCenter(
      center: center.translate(0, h * 0.05),
      width: w * 0.55,
      height: h * 0.75,
    );

    final eggPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 1.2,
        colors: [
          Color(0xFFFFFDF5),
          Color(0xFFFFF8E7),
          Color(0xFFEED9B6),
        ],
      ).createShader(eggRect);

    // Egg path (oval with wider bottom)
    final eggPath = Path();
    final eggCenter = center.translate(0, h * 0.05);
    for (double angle = 0; angle <= 2 * pi; angle += 0.1) {
      final radiusX = w * 0.275;
      final radiusY = h * 0.375 * (1 + 0.15 * sin(angle)); // Wider at bottom
      final x = eggCenter.dx + radiusX * cos(angle);
      final y = eggCenter.dy + radiusY * sin(angle);
      if (angle == 0) {
        eggPath.moveTo(x, y);
      } else {
        eggPath.lineTo(x, y);
      }
    }
    eggPath.close();
    canvas.drawPath(eggPath, eggPaint);

    // Highlight shine
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-w * 0.1, -h * 0.15),
        width: w * 0.12,
        height: h * 0.08,
      ),
      shinePaint,
    );
  }

  void _drawSplitEggShells(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;
    final splitDistance = w * 0.3 * shellSplitProgress;
    final fadeOut = 1.0 - (shellSplitProgress * 0.7); // Fade as they split

    // Left shell half
    _drawHalfShell(
        canvas,
        size,
        center.translate(-splitDistance, h * 0.1 * shellSplitProgress),
        true,
        fadeOut);

    // Right shell half
    _drawHalfShell(
        canvas,
        size,
        center.translate(splitDistance, h * 0.1 * shellSplitProgress),
        false,
        fadeOut);
  }

  void _drawHalfShell(
      Canvas canvas, Size size, Offset center, bool isLeft, double opacity) {
    final w = size.width;
    final h = size.height;

    final shellPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFFDF5).withValues(alpha: opacity),
          const Color(0xFFEED9B6).withValues(alpha: opacity),
        ],
      ).createShader(
          Rect.fromCenter(center: center, width: w * 0.3, height: h * 0.4));

    final shellPath = Path();
    final eggCenter = center.translate(0, h * 0.05);

    // Draw jagged half shell
    if (isLeft) {
      shellPath.moveTo(eggCenter.dx, eggCenter.dy - h * 0.3);
      shellPath.lineTo(eggCenter.dx - w * 0.05, eggCenter.dy - h * 0.2);
      shellPath.lineTo(eggCenter.dx, eggCenter.dy - h * 0.1);
      shellPath.lineTo(eggCenter.dx - w * 0.08, eggCenter.dy);
      shellPath.lineTo(eggCenter.dx, eggCenter.dy + h * 0.1);
      shellPath.lineTo(eggCenter.dx - w * 0.1, eggCenter.dy + h * 0.2);
      shellPath.lineTo(eggCenter.dx, eggCenter.dy + h * 0.3);
      shellPath.lineTo(eggCenter.dx - w * 0.3, eggCenter.dy + h * 0.35);
      shellPath.lineTo(eggCenter.dx - w * 0.3, eggCenter.dy - h * 0.35);
      shellPath.close();
    } else {
      shellPath.moveTo(eggCenter.dx, eggCenter.dy - h * 0.3);
      shellPath.lineTo(eggCenter.dx + w * 0.05, eggCenter.dy - h * 0.2);
      shellPath.lineTo(eggCenter.dx, eggCenter.dy - h * 0.1);
      shellPath.lineTo(eggCenter.dx + w * 0.08, eggCenter.dy);
      shellPath.lineTo(eggCenter.dx, eggCenter.dy + h * 0.1);
      shellPath.lineTo(eggCenter.dx + w * 0.1, eggCenter.dy + h * 0.2);
      shellPath.lineTo(eggCenter.dx, eggCenter.dy + h * 0.3);
      shellPath.lineTo(eggCenter.dx + w * 0.3, eggCenter.dy + h * 0.35);
      shellPath.lineTo(eggCenter.dx + w * 0.3, eggCenter.dy - h * 0.35);
      shellPath.close();
    }

    canvas.drawPath(shellPath, shellPaint);
  }

  void _drawHatchingCracks(
      Canvas canvas, Offset center, double w, double h, double progress) {
    final crackPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Main vertical crack growing from top to bottom
    final crackPath = Path();
    final crackLength = progress;

    crackPath.moveTo(center.dx, center.dy - h * 0.25 * crackLength);
    crackPath.lineTo(center.dx, center.dy + h * 0.25 * crackLength);

    // Branch cracks appear as progress increases
    if (progress > 0.3) {
      final branchProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);

      // Upper branch
      crackPath.moveTo(center.dx, center.dy - h * 0.1);
      crackPath.lineTo(
          center.dx + w * 0.08 * branchProgress, center.dy - h * 0.15);

      // Middle branch left
      crackPath.moveTo(center.dx, center.dy);
      crackPath.lineTo(
          center.dx - w * 0.1 * branchProgress, center.dy - h * 0.05);

      // Middle branch right
      crackPath.moveTo(center.dx, center.dy + h * 0.05);
      crackPath.lineTo(
          center.dx + w * 0.09 * branchProgress, center.dy + h * 0.08);

      // Lower branch
      crackPath.moveTo(center.dx, center.dy + h * 0.15);
      crackPath.lineTo(
          center.dx - w * 0.07 * branchProgress, center.dy + h * 0.2);
    }

    canvas.drawPath(crackPath, crackPaint);
  }

  void _drawCracks(Canvas canvas, Offset center, double w, double h) {
    final crackPaint = Paint()
      ..color = const Color(0xFFBB9966)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Main crack
    final crackPath = Path();
    crackPath.moveTo(center.dx - w * 0.05, center.dy - h * 0.08);
    crackPath.lineTo(center.dx + w * 0.02, center.dy);
    crackPath.lineTo(center.dx - w * 0.03, center.dy + h * 0.05);
    crackPath.lineTo(center.dx + w * 0.05, center.dy + h * 0.1);
    canvas.drawPath(crackPath, crackPaint);

    // Side cracks
    canvas.drawLine(
      Offset(center.dx + w * 0.02, center.dy),
      Offset(center.dx + w * 0.08, center.dy - h * 0.02),
      crackPaint,
    );
  }

  // ============ HATCHLING STAGE ============
  void _drawHatchling(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Shadow
    _drawShadow(canvas, center.translate(0, h * 0.32), w * 0.4, h * 0.08);

    // Broken eggshell bottom
    _drawBrokenShell(canvas, center.translate(0, h * 0.15), w * 0.5, h * 0.25);

    // Baby body (small fluffy ball)
    _drawFluffyBody(
      canvas,
      center.translate(0, h * 0.02),
      w * 0.35,
      const Color(0xFFFFE566),
      const Color(0xFFFFCC00),
    );

    // Head
    _drawFluffyBody(
      canvas,
      center.translate(0, -h * 0.15),
      w * 0.28,
      const Color(0xFFFFE566),
      const Color(0xFFFFCC00),
    );

    // Eyes (cute, big)
    _drawCuteEyes(canvas, center.translate(0, -h * 0.16), w * 0.18,
        small: true);

    // Tiny beak
    _drawBeak(canvas, center.translate(0, -h * 0.08), w * 0.06, small: true);
  }

  void _drawBrokenShell(Canvas canvas, Offset center, double w, double h) {
    final shellPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF8E7),
          Color(0xFFEED9B6),
        ],
      ).createShader(Rect.fromCenter(center: center, width: w, height: h));

    // Jagged shell edge
    final shellPath = Path();
    shellPath.moveTo(center.dx - w * 0.5, center.dy + h * 0.5);
    shellPath.lineTo(center.dx - w * 0.45, center.dy - h * 0.1);
    shellPath.lineTo(center.dx - w * 0.3, center.dy + h * 0.05);
    shellPath.lineTo(center.dx - w * 0.15, center.dy - h * 0.15);
    shellPath.lineTo(center.dx, center.dy + h * 0.1);
    shellPath.lineTo(center.dx + w * 0.15, center.dy - h * 0.2);
    shellPath.lineTo(center.dx + w * 0.3, center.dy);
    shellPath.lineTo(center.dx + w * 0.45, center.dy - h * 0.05);
    shellPath.lineTo(center.dx + w * 0.5, center.dy + h * 0.5);
    shellPath.close();

    canvas.drawPath(shellPath, shellPaint);
  }

  // ============ BABY CHICK STAGE ============
  void _drawBabyChick(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Shadow
    _drawShadow(canvas, center.translate(0, h * 0.35), w * 0.35, h * 0.07);

    // Body (fluffy round)
    _drawFluffyBody(
      canvas,
      center.translate(0, h * 0.1),
      w * 0.4,
      const Color(0xFFFFE082),
      const Color(0xFFFFB300),
    );

    // Head
    _drawFluffyBody(
      canvas,
      center.translate(0, -h * 0.1),
      w * 0.32,
      const Color(0xFFFFE082),
      const Color(0xFFFFB300),
    );

    // Small wing hints
    _drawSmallWing(
        canvas, center.translate(-w * 0.22, h * 0.08), w * 0.15, true);
    _drawSmallWing(
        canvas, center.translate(w * 0.22, h * 0.08), w * 0.15, false);

    // Cute eyes
    _drawCuteEyes(canvas, center.translate(0, -h * 0.12), w * 0.2);

    // Beak
    _drawBeak(canvas, center.translate(0, -h * 0.02), w * 0.08, small: true);

    // Tiny feet
    _drawFeet(canvas, center.translate(0, h * 0.32), w * 0.08, small: true);
  }

  // ============ TEEN CHICK STAGE ============
  void _drawTeenChick(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Shadow
    _drawShadow(canvas, center.translate(0, h * 0.38), w * 0.4, h * 0.08);

    // Body
    final bodyRect = Rect.fromCenter(
      center: center.translate(0, h * 0.1),
      width: w * 0.5,
      height: h * 0.45,
    );
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 1.0,
        colors: [
          Color(0xFFFFD54F),
          Color(0xFFFFA000),
        ],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // Head
    _drawFluffyBody(
      canvas,
      center.translate(0, -h * 0.12),
      w * 0.35,
      const Color(0xFFFFD54F),
      const Color(0xFFFFA000),
    );

    // Wings
    _drawWing(
        canvas, center.translate(-w * 0.25, h * 0.08), w * 0.18, h * 0.2, true);
    _drawWing(
        canvas, center.translate(w * 0.25, h * 0.08), w * 0.18, h * 0.2, false);

    // Small comb starting
    _drawComb(canvas, center.translate(0, -h * 0.28), w * 0.12, small: true);

    // Eyes
    _drawCuteEyes(canvas, center.translate(0, -h * 0.14), w * 0.22);

    // Beak
    _drawBeak(canvas, center.translate(0, -h * 0.02), w * 0.1);

    // Feet
    _drawFeet(canvas, center.translate(0, h * 0.35), w * 0.1);
  }

  // ============ ADULT CHICKEN STAGE ============
  void _drawAdultChicken(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Shadow
    _drawShadow(canvas, center.translate(0, h * 0.4), w * 0.45, h * 0.08);

    // Tail feathers
    _drawTailFeathers(canvas, center.translate(-w * 0.2, h * 0.05), w, h);

    // Body
    final bodyRect = Rect.fromCenter(
      center: center.translate(0, h * 0.08),
      width: w * 0.55,
      height: h * 0.45,
    );
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 1.0,
        colors: [
          Color(0xFFFFA94A),
          Color(0xFFE65100),
        ],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // Head
    _drawFluffyBody(
      canvas,
      center.translate(0, -h * 0.15),
      w * 0.32,
      const Color(0xFFFFA94A),
      const Color(0xFFE65100),
    );

    // Wings
    _drawWing(canvas, center.translate(-w * 0.28, h * 0.06), w * 0.22, h * 0.25,
        true);
    _drawWing(canvas, center.translate(w * 0.28, h * 0.06), w * 0.22, h * 0.25,
        false);

    // Comb
    _drawComb(canvas, center.translate(0, -h * 0.3), w * 0.18);

    // Wattle
    _drawWattle(canvas, center.translate(0, h * 0.02), w * 0.06);

    // Eyes
    _drawCuteEyes(canvas, center.translate(0, -h * 0.16), w * 0.2);

    // Beak
    _drawBeak(canvas, center.translate(0, -h * 0.04), w * 0.12);

    // Feet
    _drawFeet(canvas, center.translate(0, h * 0.35), w * 0.12);
  }

  // ============ MASTER ROOSTER STAGE ============
  void _drawMasterRooster(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Shadow
    _drawShadow(canvas, center.translate(0, h * 0.42), w * 0.5, h * 0.1);

    // Magnificent tail
    _drawRoosterTail(canvas, center.translate(-w * 0.15, h * 0.05), w, h);

    // Body (proud posture)
    final bodyRect = Rect.fromCenter(
      center: center.translate(w * 0.02, h * 0.08),
      width: w * 0.52,
      height: h * 0.42,
    );
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 1.0,
        colors: [
          Color(0xFFFF7043),
          Color(0xFFBF360C),
        ],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // Head
    _drawFluffyBody(
      canvas,
      center.translate(0, -h * 0.16),
      w * 0.3,
      const Color(0xFFFF7043),
      const Color(0xFFBF360C),
    );

    // Wings
    _drawWing(canvas, center.translate(-w * 0.26, h * 0.06), w * 0.24, h * 0.28,
        true);
    _drawWing(canvas, center.translate(w * 0.26, h * 0.06), w * 0.24, h * 0.28,
        false);

    // Majestic comb
    _drawComb(canvas, center.translate(0, -h * 0.32), w * 0.22, majestic: true);

    // Wattle
    _drawWattle(canvas, center.translate(0, h * 0.0), w * 0.08);

    // Eyes (confident)
    _drawCuteEyes(canvas, center.translate(0, -h * 0.17), w * 0.18,
        confident: true);

    // Strong beak
    _drawBeak(canvas, center.translate(0, -h * 0.05), w * 0.13);

    // Feet with spurs
    _drawFeet(canvas, center.translate(0, h * 0.36), w * 0.13, withSpurs: true);
  }

  // ============ PHOENIX STAGE ============
  void _drawPhoenix(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Golden aura
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.3),
          const Color(0xFFFF6B00).withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromCenter(center: center, width: w * 1.5, height: h * 1.5));
    canvas.drawCircle(center, w * 0.6, auraPaint);

    // Shadow
    _drawShadow(canvas, center.translate(0, h * 0.4), w * 0.4, h * 0.08);

    // Magnificent plumage tail
    _drawPhoenixTail(canvas, center.translate(-w * 0.1, h * 0.05), w, h);

    // Body
    final bodyRect = Rect.fromCenter(
      center: center.translate(0, h * 0.05),
      width: w * 0.45,
      height: h * 0.38,
    );
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 1.0,
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFF6B00),
          Color(0xFFDC143C),
        ],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // Head
    final headCenter = center.translate(0, -h * 0.18);
    _drawFluffyBody(
      canvas,
      headCenter,
      w * 0.28,
      const Color(0xFFFFD700),
      const Color(0xFFFF8C00),
    );

    // Phoenix crest
    _drawPhoenixCrest(canvas, center.translate(0, -h * 0.32), w * 0.2);

    // Wings spread partially
    _drawPhoenixWing(
        canvas, center.translate(-w * 0.25, h * 0.02), w * 0.3, h * 0.3, true);
    _drawPhoenixWing(
        canvas, center.translate(w * 0.25, h * 0.02), w * 0.3, h * 0.3, false);

    // Eyes (glowing)
    _drawCuteEyes(canvas, center.translate(0, -h * 0.19), w * 0.18,
        glowing: true);

    // Sharp beak
    _drawBeak(canvas, center.translate(0, -h * 0.08), w * 0.1, sharp: true);

    // Talons
    _drawTalons(canvas, center.translate(0, h * 0.32), w * 0.12);
  }

  // ============ HELPER METHODS ============

  void _drawShadow(Canvas canvas, Offset center, double w, double h) {
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.15);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w, height: h),
      shadowPaint,
    );
  }

  void _drawFluffyBody(
      Canvas canvas, Offset center, double radius, Color light, Color dark) {
    final bodyRect = Rect.fromCircle(center: center, radius: radius);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.0,
        colors: [light, dark],
      ).createShader(bodyRect);
    canvas.drawCircle(center, radius, bodyPaint);

    // Highlight
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.25, -radius * 0.3),
        width: radius * 0.4,
        height: radius * 0.25,
      ),
      highlightPaint,
    );
  }

  void _drawCuteEyes(Canvas canvas, Offset center, double spacing,
      {bool small = false, bool confident = false, bool glowing = false}) {
    final eyeRadius = spacing * (small ? 0.28 : 0.32);
    final pupilRadius = eyeRadius * 0.55;

    for (final side in [-1.0, 1.0]) {
      final eyeCenter = center.translate(side * spacing * 0.35, 0);

      // White of eye
      canvas.drawCircle(
        eyeCenter,
        eyeRadius,
        Paint()..color = Colors.white,
      );

      // Pupil with blink
      if (blinkValue > 0.1) {
        final pupilHeight = pupilRadius * 2 * blinkValue;
        canvas.drawOval(
          Rect.fromCenter(
            center: eyeCenter,
            width: pupilRadius * 2,
            height: pupilHeight,
          ),
          Paint()..color = glowing ? const Color(0xFFFF4500) : Colors.black,
        );

        // Eye shine
        if (blinkValue > 0.5) {
          canvas.drawCircle(
            eyeCenter.translate(pupilRadius * 0.3, -pupilRadius * 0.3),
            pupilRadius * 0.35,
            Paint()..color = Colors.white,
          );
        }
      } else {
        // Closed eye line
        canvas.drawLine(
          eyeCenter.translate(-eyeRadius * 0.7, 0),
          eyeCenter.translate(eyeRadius * 0.7, 0),
          Paint()
            ..color = Colors.black
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }

      // Glowing effect
      if (glowing) {
        canvas.drawCircle(
          eyeCenter,
          eyeRadius * 1.3,
          Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.3),
        );
      }
    }

    // Eyebrows for mood
    if (mood == PetMood.worried || confident) {
      for (final side in [-1.0, 1.0]) {
        final browStart =
            center.translate(side * spacing * 0.15, -spacing * 0.35);
        final browEnd = center.translate(
            side * spacing * 0.5, -spacing * (confident ? 0.45 : 0.25));
        canvas.drawLine(
          browStart,
          browEnd,
          Paint()
            ..color = const Color(0xFF5D4037)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawBeak(Canvas canvas, Offset center, double size,
      {bool small = false, bool sharp = false}) {
    final beakPath = Path();

    if (sharp) {
      // Phoenix beak
      beakPath.moveTo(center.dx - size * 0.3, center.dy);
      beakPath.quadraticBezierTo(
          center.dx, center.dy - size * 0.1, center.dx + size * 0.3, center.dy);
      beakPath.lineTo(center.dx, center.dy + size * 0.9);
      beakPath.close();
    } else {
      // Round cute beak
      beakPath.moveTo(center.dx - size * 0.35, center.dy);
      beakPath.quadraticBezierTo(
          center.dx,
          center.dy + size * (small ? 0.5 : 0.7),
          center.dx + size * 0.35,
          center.dy);
      beakPath.close();
    }

    final beakPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF9800),
          Color(0xFFE65100),
        ],
      ).createShader(
          Rect.fromCenter(center: center, width: size, height: size));

    canvas.drawPath(beakPath, beakPaint);
  }

  void _drawComb(Canvas canvas, Offset center, double size,
      {bool small = false, bool majestic = false}) {
    final combPaint = Paint()..color = const Color(0xFFE53935);
    final numSpikes = majestic ? 4 : (small ? 2 : 3);

    final combPath = Path();
    combPath.moveTo(center.dx - size * 0.5, center.dy + size * 0.4);

    for (int i = 0; i <= numSpikes; i++) {
      final x = center.dx - size * 0.5 + (size / numSpikes) * i;
      final spikeHeight = size * (majestic ? 0.7 : 0.5);
      combPath.lineTo(x, center.dy - spikeHeight * (i % 2 == 0 ? 0.3 : 1.0));
    }

    combPath.lineTo(center.dx + size * 0.5, center.dy + size * 0.4);
    combPath.close();

    canvas.drawPath(combPath, combPaint);
  }

  void _drawWattle(Canvas canvas, Offset center, double size) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size * 0.7, height: size * 1.2),
      Paint()..color = const Color(0xFFE53935),
    );
  }

  void _drawSmallWing(Canvas canvas, Offset center, double size, bool isLeft) {
    final wingPaint = Paint()..color = const Color(0xFFFFCC80);

    final wingPath = Path();
    wingPath.addOval(Rect.fromCenter(
      center: center,
      width: size,
      height: size * 0.6,
    ));
    canvas.drawPath(wingPath, wingPaint);
  }

  void _drawWing(
      Canvas canvas, Offset center, double w, double h, bool isLeft) {
    final wingPaint = Paint()..color = const Color(0xFFFFB74D);

    final wingPath = Path();
    if (isLeft) {
      wingPath.moveTo(center.dx + w * 0.3, center.dy - h * 0.3);
      wingPath.quadraticBezierTo(center.dx - w * 0.5, center.dy,
          center.dx - w * 0.3, center.dy + h * 0.5);
      wingPath.quadraticBezierTo(center.dx, center.dy + h * 0.3,
          center.dx + w * 0.3, center.dy - h * 0.3);
    } else {
      wingPath.moveTo(center.dx - w * 0.3, center.dy - h * 0.3);
      wingPath.quadraticBezierTo(center.dx + w * 0.5, center.dy,
          center.dx + w * 0.3, center.dy + h * 0.5);
      wingPath.quadraticBezierTo(center.dx, center.dy + h * 0.3,
          center.dx - w * 0.3, center.dy - h * 0.3);
    }
    wingPath.close();
    canvas.drawPath(wingPath, wingPaint);
  }

  void _drawFeet(Canvas canvas, Offset center, double size,
      {bool small = false, bool withSpurs = false}) {
    final feetPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = small ? 2 : 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final side in [-1.0, 1.0]) {
      final footX = center.dx + side * size * 0.8;

      // Leg
      canvas.drawLine(
        Offset(footX, center.dy - size * 0.5),
        Offset(footX, center.dy + size * 0.3),
        feetPaint,
      );

      // Toes
      for (final toeAngle in [-0.4, 0, 0.4]) {
        canvas.drawLine(
          Offset(footX, center.dy + size * 0.3),
          Offset(footX + sin(toeAngle) * size * 0.6, center.dy + size * 0.6),
          feetPaint,
        );
      }

      // Spurs for rooster
      if (withSpurs && side < 0) {
        canvas.drawLine(
          Offset(footX, center.dy),
          Offset(footX - size * 0.4, center.dy - size * 0.3),
          feetPaint..color = const Color(0xFF455A64),
        );
        feetPaint.color = const Color(0xFFFF9800);
      }
    }
  }

  void _drawTalons(Canvas canvas, Offset center, double size) {
    final talonPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final side in [-1.0, 1.0]) {
      final footX = center.dx + side * size * 0.7;

      canvas.drawLine(
        Offset(footX, center.dy - size * 0.4),
        Offset(footX, center.dy + size * 0.4),
        talonPaint,
      );

      for (final toeAngle in [-0.5, 0, 0.5]) {
        canvas.drawLine(
          Offset(footX, center.dy + size * 0.4),
          Offset(footX + sin(toeAngle) * size * 0.5, center.dy + size * 0.7),
          talonPaint,
        );
      }
    }
  }

  void _drawTailFeathers(Canvas canvas, Offset center, double w, double h) {
    final featherColors = [
      const Color(0xFFFF8A65),
      const Color(0xFFFFCC80),
      const Color(0xFFFFAB91),
    ];

    for (int i = 0; i < 3; i++) {
      final featherPath = Path();

      featherPath.moveTo(center.dx, center.dy);
      featherPath.quadraticBezierTo(
        center.dx - w * 0.15,
        center.dy + h * (0.15 + i * 0.03),
        center.dx - w * 0.08,
        center.dy + h * (0.25 + i * 0.02),
      );
      featherPath.quadraticBezierTo(
        center.dx + w * 0.02,
        center.dy + h * 0.15,
        center.dx,
        center.dy,
      );

      canvas.drawPath(featherPath, Paint()..color = featherColors[i]);
    }
  }

  void _drawRoosterTail(Canvas canvas, Offset center, double w, double h) {
    final colors = [
      const Color(0xFF1B5E20),
      const Color(0xFF004D40),
      const Color(0xFF311B92),
      const Color(0xFFBF360C),
      const Color(0xFF0D47A1),
    ];

    for (int i = 0; i < 5; i++) {
      final featherPath = Path();
      final curveOffset = (i - 2) * 0.08;

      featherPath.moveTo(center.dx, center.dy);
      featherPath.cubicTo(
        center.dx - w * 0.15,
        center.dy + h * 0.1,
        center.dx - w * (0.25 + curveOffset),
        center.dy + h * (0.2 + i * 0.03),
        center.dx - w * 0.15,
        center.dy + h * (0.35 + i * 0.02),
      );
      featherPath.quadraticBezierTo(
        center.dx + w * 0.02,
        center.dy + h * 0.2,
        center.dx,
        center.dy,
      );

      canvas.drawPath(featherPath, Paint()..color = colors[i]);
    }
  }

  void _drawPhoenixTail(Canvas canvas, Offset center, double w, double h) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFFFA500),
      const Color(0xFFFF6B00),
      const Color(0xFFFF4500),
      const Color(0xFFDC143C),
    ];

    for (int i = 0; i < 7; i++) {
      final featherPath = Path();
      final angle = (i - 3) * 0.12;
      final length = h * (0.4 + (3 - (i - 3).abs()) * 0.05);

      featherPath.moveTo(center.dx, center.dy);
      featherPath.cubicTo(
        center.dx - w * (0.1 + angle * 0.3),
        center.dy + length * 0.4,
        center.dx - w * (0.15 + angle * 0.5),
        center.dy + length * 0.7,
        center.dx - w * (0.05 + angle * 0.3),
        center.dy + length,
      );
      featherPath.quadraticBezierTo(
        center.dx + w * 0.03,
        center.dy + length * 0.5,
        center.dx,
        center.dy,
      );

      final featherPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors[i % colors.length], colors[(i + 1) % colors.length]],
        ).createShader(
            Rect.fromLTWH(center.dx - w * 0.3, center.dy, w * 0.6, length));

      canvas.drawPath(featherPath, featherPaint);
    }
  }

  void _drawPhoenixCrest(Canvas canvas, Offset center, double size) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFFFA500),
      const Color(0xFFFF4500),
    ];

    for (int i = 0; i < 5; i++) {
      final angle = (i - 2) * 0.3;
      final length = size * (1.0 + (2 - (i - 2).abs()) * 0.2);

      final crestPath = Path();
      crestPath.moveTo(center.dx, center.dy + size * 0.3);
      crestPath.quadraticBezierTo(
        center.dx + sin(angle) * size * 0.3,
        center.dy - length * 0.5,
        center.dx + sin(angle) * size * 0.15,
        center.dy - length,
      );
      crestPath.quadraticBezierTo(
        center.dx,
        center.dy - length * 0.3,
        center.dx,
        center.dy + size * 0.3,
      );

      canvas.drawPath(crestPath, Paint()..color = colors[i % colors.length]);
    }
  }

  void _drawPhoenixWing(
      Canvas canvas, Offset center, double w, double h, bool isLeft) {
    final wingPaint = Paint()
      ..shader = LinearGradient(
        begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        colors: const [
          Color(0xFFFFD700),
          Color(0xFFFFA500),
          Color(0xFFFF4500),
        ],
      ).createShader(
          Rect.fromCenter(center: center, width: w * 2, height: h * 2));

    final wingPath = Path();
    final dir = isLeft ? -1.0 : 1.0;

    wingPath.moveTo(center.dx, center.dy - h * 0.2);
    wingPath.quadraticBezierTo(
      center.dx + dir * w * 0.8,
      center.dy - h * 0.3,
      center.dx + dir * w * 0.9,
      center.dy + h * 0.2,
    );
    wingPath.quadraticBezierTo(
      center.dx + dir * w * 0.5,
      center.dy + h * 0.5,
      center.dx,
      center.dy + h * 0.3,
    );
    wingPath.close();

    canvas.drawPath(wingPath, wingPaint);
  }

  @override
  bool shouldRepaint(covariant ChickenPainter oldDelegate) {
    return oldDelegate.stage != stage ||
        oldDelegate.mood != mood ||
        oldDelegate.blinkValue != blinkValue ||
        oldDelegate.happinessLevel != happinessLevel ||
        oldDelegate.stageProgress != stageProgress ||
        oldDelegate.crackProgress != crackProgress ||
        oldDelegate.shellSplitProgress != shellSplitProgress ||
        oldDelegate.chickEmergenceProgress != chickEmergenceProgress;
  }
}
