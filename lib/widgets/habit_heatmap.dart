import 'package:flutter/material.dart';

class HabitHeatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final List<DateTime> frozenDates;
  final DateTime startDate;
  final DateTime endDate;

  const HabitHeatmap({
    super.key,
    required this.datasets,
    required this.frozenDates,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final days = endDate.difference(startDate).inDays + 1;

    // Weekday labels
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Define colors for better visibility
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.08) // Visible in dark mode
        : Colors.grey[200]!; // Light grey in light mode

    final lowColor = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.4)
        : theme.colorScheme.primary.withValues(alpha: 0.35);

    final highColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A1A) // Slightly lighter than pure black
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consistency Map',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              // Legend
              Row(
                children: [
                  _LegendItem(color: emptyColor, label: '0', isDark: isDark),
                  const SizedBox(width: 6),
                  _LegendItem(color: lowColor, label: '1-2', isDark: isDark),
                  const SizedBox(width: 6),
                  _LegendItem(color: highColor, label: '3+', isDark: isDark),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('❄️', style: TextStyle(fontSize: 10)),
                        SizedBox(width: 2),
                        Text('Frozen',
                            style: TextStyle(fontSize: 10, color: Colors.blue)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekday labels column
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: weekdayLabels.map((label) {
                  return Container(
                    height: 14,
                    margin: const EdgeInsets.only(bottom: 4),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 8),
              // Heat map grid
              Expanded(
                child: SizedBox(
                  height: 140,
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: days,
                    itemBuilder: (context, index) {
                      final date = startDate.add(Duration(days: index));
                      final dateKey = DateTime(date.year, date.month, date.day);

                      // Check if frozen
                      final isFrozen = frozenDates.any((d) =>
                          d.year == date.year &&
                          d.month == date.month &&
                          d.day == date.day);

                      // Get intensity
                      final intensity = datasets[dateKey] ?? 0;

                      return Tooltip(
                        message:
                            '${date.day}/${date.month}: $intensity habits${isFrozen ? " (Frozen)" : ""}',
                        child: Container(
                          decoration: BoxDecoration(
                            color: isFrozen
                                ? Colors.blue.withValues(alpha: 0.25)
                                : _getColor(
                                    intensity, emptyColor, lowColor, highColor),
                            borderRadius: BorderRadius.circular(4),
                            border: isFrozen
                                ? Border.all(
                                    color: Colors.blue.withValues(alpha: 0.5),
                                    width: 1,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: isFrozen
                              ? const Text('❄️', style: TextStyle(fontSize: 10))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColor(
      int intensity, Color emptyColor, Color lowColor, Color highColor) {
    if (intensity <= 0) return emptyColor;
    if (intensity <= 2) return lowColor;
    return highColor;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
