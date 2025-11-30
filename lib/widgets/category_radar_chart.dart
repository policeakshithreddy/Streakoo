import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/habit.dart';

class CategoryRadarChart extends StatelessWidget {
  final List<Habit> habits;

  const CategoryRadarChart({
    super.key,
    required this.habits,
  });

  Map<String, double> _getCategoryScores() {
    final scores = <String, double>{};
    final counts = <String, int>{};

    for (final habit in habits) {
      final category = habit.category;
      scores[category] = (scores[category] ?? 0) + habit.streak.toDouble();
      counts[category] = (counts[category] ?? 0) + 1;
    }

    // Average scores
    final averaged = <String, double>{};
    scores.forEach((category, total) {
      averaged[category] = total / counts[category]!;
    });

    return averaged;
  }

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Center(
        child: Text('No habits to display'),
      );
    }

    final categoryScores = _getCategoryScores();

    // Ensure we always have these standard categories to maintain shape
    final standardCategories = [
      'Health',
      'Sports',
      'Social Media',
      'Lifestyle'
    ];
    for (final cat in standardCategories) {
      if (!categoryScores.containsKey(cat)) {
        categoryScores[cat] = 0;
      }
    }

    final categories = categoryScores.keys.toList()..sort();

    if (categories.isEmpty) {
      return const Center(
        child: Text('No categories to display'),
      );
    }

    // Find max score for normalization
    var maxScore =
        categoryScores.values.reduce((a, b) => a > b ? a : b).toDouble();

    // Prevent division by zero
    if (maxScore == 0) maxScore = 1.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🕸️ Category Balance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  tickCount: 4,
                  ticksTextStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                  radarBorderData: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  gridBorderData: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  tickBorderData: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  getTitle: (index, angle) {
                    if (index >= categories.length) {
                      return const RadarChartTitle(text: '');
                    }
                    return RadarChartTitle(
                      text: categories[index],
                      angle: 0,
                    );
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                      borderColor: const Color(0xFF4ECDC4),
                      borderWidth: 3,
                      entryRadius: 4,
                      dataEntries: categories
                          .map((cat) => RadarEntry(
                                value: (categoryScores[cat]! / maxScore) * 100,
                              ))
                          .toList(),
                    ),
                  ],
                  titleTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  titlePositionPercentageOffset: 0.15,
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutCubic,
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: categories.map((category) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ECDC4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$category: ${categoryScores[category]!.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
