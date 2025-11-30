import 'package:flutter/material.dart';
import '../utils/slide_route.dart';
import 'ai_analyzing_screen.dart';

class ChallengeSelectionScreen extends StatefulWidget {
  final String displayName;
  final int age;
  final List<String> goals;
  final List<String> struggles;
  final String timeOfDay;

  const ChallengeSelectionScreen({
    super.key,
    required this.displayName,
    required this.age,
    required this.goals,
    required this.struggles,
    required this.timeOfDay,
  });

  @override
  State<ChallengeSelectionScreen> createState() =>
      _ChallengeSelectionScreenState();
}

class _ChallengeSelectionScreenState extends State<ChallengeSelectionScreen> {
  int _selectedDays = 7;

  void _continue() {
    Navigator.of(context).push(
      slideFromRight(
        AiAnalyzingScreen(
          displayName: widget.displayName,
          goals: widget.goals,
          struggles: widget.struggles,
          timeOfDay: widget.timeOfDay,
          age: widget.age,
          challengeTargetDays: _selectedDays,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Challenge'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick your challenge duration',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your habits daily to earn badges!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 7,
                    label: Text('7 days'),
                    icon: Text('🥉'),
                  ),
                  ButtonSegment(
                    value: 15,
                    label: Text('15 days'),
                    icon: Text('🥈'),
                  ),
                  ButtonSegment(
                    value: 30,
                    label: Text('30 days'),
                    icon: Text('🥇'),
                  ),
                ],
                selected: {_selectedDays},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedDays = set.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedDays == 7
                              ? '🥉'
                              : _selectedDays == 15
                                  ? '🥈'
                                  : '🥇',
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDays == 7
                                    ? 'Bronze Badge'
                                    : _selectedDays == 15
                                        ? 'Silver Badge'
                                        : 'Gold Badge',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedDays == 7
                                    ? 'Perfect for beginners'
                                    : _selectedDays == 15
                                        ? 'Build real momentum'
                                        : 'Transform into a habit',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Complete $_selectedDays days in a row without missing to earn this achievement!',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
