import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/habit.dart';

/// Service to create and share beautiful milestone cards
class SocialSharingService {
  static final SocialSharingService _instance = SocialSharingService._();
  static SocialSharingService get instance => _instance;
  SocialSharingService._();

  /// Generate and share a streak milestone card
  Future<void> shareStreakMilestone({
    required BuildContext context,
    required Habit habit,
    required int streakDays,
  }) async {
    final imageBytes = await _generateMilestoneImage(
      habit: habit,
      streakDays: streakDays,
      context: context,
    );

    if (imageBytes == null) return;

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/streak_milestone.png');
    await file.writeAsBytes(imageBytes);

    // Share
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'I just hit a $streakDays day streak on "${habit.name}"! 🔥\n\n#Streakoo #HabitTracking #${streakDays}DayStreak',
    );
  }

  Future<Uint8List?> _generateMilestoneImage({
    required Habit habit,
    required int streakDays,
    required BuildContext context,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      const width = 1080.0;
      const height = 1350.0;

      // Background gradient
      const bgGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF667eea),
          Color(0xFF764ba2),
        ],
      );

      final bgPaint = Paint()
        ..shader = bgGradient.createShader(
          const Rect.fromLTWH(0, 0, width, height),
        );
      canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

      // Pattern overlay
      final patternPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 20; i++) {
        for (int j = 0; j < 25; j++) {
          if ((i + j) % 3 == 0) {
            canvas.drawCircle(
              Offset(i * 60.0, j * 60.0),
              3,
              patternPaint,
            );
          }
        }
      }

      // Main card
      final cardRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(60, 200, width - 120, height - 400),
        const Radius.circular(40),
      );
      canvas.drawRRect(
        cardRect,
        Paint()..color = Colors.white,
      );

      // Draw streak number
      final streakPainter = TextPainter(
        text: TextSpan(
          text: '$streakDays',
          style: TextStyle(
            fontSize: 200,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ).createShader(const Rect.fromLTWH(0, 0, 300, 200)),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      streakPainter.layout();
      streakPainter.paint(
        canvas,
        Offset((width - streakPainter.width) / 2, 350),
      );

      // "Day Streak" text
      final dayTextPainter = TextPainter(
        text: const TextSpan(
          text: 'DAY STREAK',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
            letterSpacing: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      dayTextPainter.layout();
      dayTextPainter.paint(
        canvas,
        Offset((width - dayTextPainter.width) / 2, 570),
      );

      // Habit name
      final habitPainter = TextPainter(
        text: TextSpan(
          text: '${habit.emoji} ${habit.name}',
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      habitPainter.layout(maxWidth: width - 160);
      habitPainter.paint(
        canvas,
        Offset((width - habitPainter.width) / 2, 680),
      );

      // Decorative fire emojis
      final firePainter = TextPainter(
        text: const TextSpan(
          text: '🔥🔥🔥',
          style: TextStyle(fontSize: 80),
        ),
        textDirection: TextDirection.ltr,
      );
      firePainter.layout();
      firePainter.paint(
        canvas,
        Offset((width - firePainter.width) / 2, 780),
      );

      // App branding at bottom
      final brandPainter = TextPainter(
        text: const TextSpan(
          text: 'streakoo',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      brandPainter.layout();
      brandPainter.paint(
        canvas,
        Offset((width - brandPainter.width) / 2, height - 120),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      return pngBytes?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating milestone image: $e');
      return null;
    }
  }
}

/// Widget button to trigger social sharing
class ShareMilestoneButton extends StatelessWidget {
  final Habit habit;
  final int streakDays;

  const ShareMilestoneButton({
    super.key,
    required this.habit,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        SocialSharingService.instance.shareStreakMilestone(
          context: context,
          habit: habit,
          streakDays: streakDays,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.share_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Share',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
