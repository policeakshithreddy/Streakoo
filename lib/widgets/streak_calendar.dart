import 'package:flutter/material.dart';

class StreakCalendar extends StatelessWidget {
  final List<bool> weekData;

  const StreakCalendar({super.key, required this.weekData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final done = weekData[index];

        // Label color (adaptive)
        final labelColor = color.onSurface.withValues(alpha: 0.8);

        // Circle background
        final circleColor = done
            ? Colors.orangeAccent.withValues(alpha: 0.9)
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08));

        // Icon color (onPrimary or onSurface)
        final iconColor =
            done ? color.onPrimary : color.onSurface.withValues(alpha: 0.6);

        return Column(
          children: [
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
              ),
              child: done
                  ? Icon(
                      Icons.local_fire_department,
                      size: 18,
                      color: iconColor,
                    )
                  : null,
            ),
          ],
        );
      }),
    );
  }
}
