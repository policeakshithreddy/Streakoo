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
    final days = endDate.difference(startDate).inDays + 1;

    // Weekday labels
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Consistency Map',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                _LegendItem(
                    color: theme.colorScheme.surfaceContainerHighest,
                    label: '0'),
                const SizedBox(width: 4),
                _LegendItem(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    label: '1-2'),
                const SizedBox(width: 4),
                _LegendItem(color: theme.colorScheme.primary, label: '3+'),
                const SizedBox(width: 4),
                const Text('❄️', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 2),
                const Text('Frozen',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekday labels column
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: weekdayLabels.map((label) {
                return Container(
                  height: 14, // Match the cell size
                  margin: const EdgeInsets.only(
                      bottom: 4), // Match crossAxisSpacing
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
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
                height: 140, // 7 rows * (14 size + 4 margin) approx
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, // 7 days a week (rows)
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
                              ? Colors.blue.withValues(alpha: 0.2)
                              : _getColor(theme, intensity),
                          borderRadius: BorderRadius.circular(4),
                          border: isFrozen
                              ? Border.all(
                                  color: Colors.blue.withValues(alpha: 0.5))
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
    );
  }

  Color _getColor(ThemeData theme, int intensity) {
    if (intensity <= 0) return theme.colorScheme.surfaceContainerHighest;
    if (intensity <= 2) return theme.colorScheme.primary.withValues(alpha: 0.4);
    return theme.colorScheme.primary;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
