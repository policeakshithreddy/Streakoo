import 'package:flutter/material.dart';

class FreezeCounterWidget extends StatelessWidget {
  final int freezeCount;
  final VoidCallback onTap;

  const FreezeCounterWidget({
    super.key,
    required this.freezeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Hide when no freezes
    if (freezeCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lightBlue.shade100,
              Colors.blue.shade200,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ice/frost effect background (subtle pattern)
            Center(
              child: Icon(
                Icons.ac_unit,
                color: Colors.white.withOpacity(0.3),
                size: 28,
              ),
            ),
            // Count in center
            Center(
              child: Text(
                '$freezeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.blue,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
