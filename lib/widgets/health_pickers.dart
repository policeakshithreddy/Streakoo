import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS-style number picker for age, height, weight, etc.
class HealthPickerBottomSheet extends StatefulWidget {
  final String title;
  final int initialValue;
  final int minValue;
  final int maxValue;
  final String unit;
  final String? subtitle;

  const HealthPickerBottomSheet({
    super.key,
    required this.title,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    this.subtitle,
  });

  @override
  State<HealthPickerBottomSheet> createState() =>
      _HealthPickerBottomSheetState();
}

class _HealthPickerBottomSheetState extends State<HealthPickerBottomSheet> {
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                Column(
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selectedValue),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Picker
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Number picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _selectedValue - widget.minValue,
                    ),
                    itemExtent: 44,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedValue = widget.minValue + index;
                      });
                    },
                    children: List.generate(
                      widget.maxValue - widget.minValue + 1,
                      (index) {
                        final value = widget.minValue + index;
                        return Center(
                          child: Text(
                            value.toString(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Unit label
                Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    widget.unit,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Height picker with feet/inches or cm toggle
class HeightPickerBottomSheet extends StatefulWidget {
  final double initialHeightCm;

  const HeightPickerBottomSheet({
    super.key,
    required this.initialHeightCm,
  });

  @override
  State<HeightPickerBottomSheet> createState() =>
      _HeightPickerBottomSheetState();
}

class _HeightPickerBottomSheetState extends State<HeightPickerBottomSheet> {
  bool _isMetric = true;
  late int _cm;
  late int _feet;
  late int _inches;

  @override
  void initState() {
    super.initState();
    _cm = widget.initialHeightCm.round();
    _updateImperialFromMetric();
  }

  void _updateImperialFromMetric() {
    final totalInches = (_cm / 2.54).round();
    _feet = totalInches ~/ 12;
    _inches = totalInches % 12;
  }

  void _updateMetricFromImperial() {
    final totalInches = (_feet * 12) + _inches;
    _cm = (totalInches * 2.54).round();
  }

  double get _heightInCm => _isMetric ? _cm.toDouble() : _cm.toDouble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Text(
                  'Height',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _heightInCm),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Unit Toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('cm')),
                ButtonSegment(value: false, label: Text('ft/in')),
              ],
              selected: {_isMetric},
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _isMetric = selection.first;
                  if (_isMetric) {
                    _updateMetricFromImperial();
                  } else {
                    _updateImperialFromMetric();
                  }
                });
              },
            ),
          ),

          // Picker
          Expanded(
            child: _isMetric
                ? _buildMetricPicker(theme)
                : _buildImperialPicker(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPicker(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: _cm - 100,
            ),
            itemExtent: 44,
            onSelectedItemChanged: (index) {
              setState(() => _cm = 100 + index);
            },
            children: List.generate(
              121, // 100-220cm
              (index) => Center(
                child: Text(
                  (100 + index).toString(),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 40),
          child: Text(
            'cm',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImperialPicker(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Feet
        Expanded(
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: _feet - 3,
            ),
            itemExtent: 44,
            onSelectedItemChanged: (index) {
              setState(() {
                _feet = 3 + index;
                _updateMetricFromImperial();
              });
            },
            children: List.generate(
              6, // 3-8 feet
              (index) => Center(
                child: Text(
                  (3 + index).toString(),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
          ),
        ),
        Text(
          'ft',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 20),

        // Inches
        Expanded(
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: _inches,
            ),
            itemExtent: 44,
            onSelectedItemChanged: (index) {
              setState(() {
                _inches = index;
                _updateMetricFromImperial();
              });
            },
            children: List.generate(
              12, // 0-11 inches
              (index) => Center(
                child: Text(
                  index.toString(),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 40),
          child: Text(
            'in',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Weight picker with lbs/kg toggle
class WeightPickerBottomSheet extends StatefulWidget {
  final double initialWeightKg;

  const WeightPickerBottomSheet({
    super.key,
    required this.initialWeightKg,
  });

  @override
  State<WeightPickerBottomSheet> createState() =>
      _WeightPickerBottomSheetState();
}

class _WeightPickerBottomSheetState extends State<WeightPickerBottomSheet> {
  bool _isMetric = true;
  late double _weight;

  @override
  void initState() {
    super.initState();
    _weight = widget.initialWeightKg;
  }

  double get _displayWeight => _isMetric ? _weight : _weight * 2.20462;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Text(
                  'Weight',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _weight),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Unit Toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('kg')),
                ButtonSegment(value: false, label: Text('lbs')),
              ],
              selected: {_isMetric},
              onSelectionChanged: (Set<bool> selection) {
                setState(() => _isMetric = selection.first);
              },
            ),
          ),

          // Picker
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _isMetric
                          ? (_weight - 30).round()
                          : (_displayWeight - 66).round(),
                    ),
                    itemExtent: 44,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        if (_isMetric) {
                          _weight = 30.0 + index;
                        } else {
                          _weight = (66 + index) / 2.20462;
                        }
                      });
                    },
                    children: List.generate(
                      _isMetric ? 171 : 375, // 30-200kg or 66-440lbs
                      (index) {
                        final value = _isMetric ? 30 + index : 66 + index;
                        return Center(
                          child: Text(
                            value.toString(),
                            style: theme.textTheme.headlineSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    _isMetric ? 'kg' : 'lbs',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
