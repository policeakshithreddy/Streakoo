import 'package:flutter/material.dart';
import 'challenge_selection_screen.dart';

class QuestionFlowScreen extends StatefulWidget {
  final String displayName;
  final int age;

  const QuestionFlowScreen({
    super.key,
    required this.displayName,
    required this.age,
  });

  @override
  State<QuestionFlowScreen> createState() => _QuestionFlowScreenState();
}

class _QuestionFlowScreenState extends State<QuestionFlowScreen> {
  int _step = 0;

  final Set<String> _goals = {};
  final Set<String> _struggles = {};
  String? _timeOfDay;

  void _next() {
    if (_step == 0 && _goals.isEmpty) {
      _showSnack('Pick at least one main goal.');
      return;
    }
    if (_step == 1 && _struggles.isEmpty) {
      _showSnack('Pick at least one thing you struggle with.');
      return;
    }
    if (_step == 2 && _timeOfDay == null) {
      _showSnack('Pick when you prefer doing your habits.');
      return;
    }

    if (_step < 2) {
      setState(() => _step++);
    } else {
      // Done → go to challenge selection screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChallengeSelectionScreen(
            displayName: widget.displayName,
            age: widget.age,
            goals: _goals.toList(),
            struggles: _struggles.toList(),
            timeOfDay: _timeOfDay!,
          ),
        ),
      );
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _toggle(Set<String> target, String value) {
    setState(() {
      if (target.contains(value)) {
        target.remove(value);
      } else {
        if (target.length >= 3) return; // max 3 selections
        target.add(value);
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    String title;

    if (_step == 0) {
      title = 'What are your main goals?';
      final options = [
        'Better health / fitness',
        'Better grades / study',
        'More focus & deep work',
        'Better sleep & energy',
        'General self-discipline',
      ];
      content = _MultiSelectList(
        options: options,
        selected: _goals,
        onToggle: (v) => _toggle(_goals, v),
      );
    } else if (_step == 1) {
      title = 'What do you struggle with most?';
      final options = [
        'Staying consistent',
        'Getting started',
        'Distractions / phone',
        'Low motivation',
        'Poor sleep / tired',
      ];
      content = _MultiSelectList(
        options: options,
        selected: _struggles,
        onToggle: (v) => _toggle(_struggles, v),
      );
    } else {
      title = 'When do you prefer doing your habits?';
      final options = [
        'Morning',
        'Afternoon',
        'Evening',
        'Flexible / no fixed time',
      ];
      content = Column(
        children: options.map((o) {
          final selected = _timeOfDay == o;
          return ListTile(
            title: Text(o),
            trailing: selected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.circle_outlined),
            onTap: () => setState(() => _timeOfDay = o),
          );
        }).toList(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _back,
        ),
        title: const Text('We\'ll keep it quick'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 0
                    ? 'You can pick up to 3.'
                    : _step == 1
                        ? 'Again, up to 3 options.'
                        : 'Just one is enough.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Expanded(child: SingleChildScrollView(child: content)),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(_step < 2 ? 'Continue' : 'See my habits'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiSelectList extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _MultiSelectList({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return Card(
          child: ListTile(
            title: Text(o),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.circle_outlined),
            onTap: () => onToggle(o),
          ),
        );
      }).toList(),
    );
  }
}
