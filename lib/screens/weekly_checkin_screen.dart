import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/health_challenge.dart';

class WeeklyCheckInScreen extends StatefulWidget {
  const WeeklyCheckInScreen({super.key});

  @override
  State<WeeklyCheckInScreen> createState() => _WeeklyCheckInScreenState();
}

class _WeeklyCheckInScreenState extends State<WeeklyCheckInScreen> {
  int _currentStep = 0;

  // Survey responses
  double _energyLevel = 3;
  double _motivationLevel = 3;
  final _challengeController = TextEditingController();
  final _winsController = TextEditingController();
  final _painPointsController = TextEditingController();

  @override
  void dispose() {
    _challengeController.dispose();
    _winsController.dispose();
    _painPointsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _submitCheckIn();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _submitCheckIn() {
    final appState = Provider.of<AppState>(context, listen: false);
    final challenge = appState.activeHealthChallenge;

    if (challenge == null) return;

    final response = {
      'week': DateTime.now().difference(challenge.startDate).inDays ~/ 7 + 1,
      'date': DateTime.now().toIso8601String(),
      'energyLevel': _energyLevel.toInt(),
      'motivationLevel': _motivationLevel.toInt(),
      'biggestChallenge': _challengeController.text,
      'wins': _winsController.text,
      'painPoints': _painPointsController.text,
    };

    // Add response to challenge
    final updatedChallenge = HealthChallenge(
      id: challenge.id,
      type: challenge.type,
      title: challenge.title,
      description: challenge.description,
      startDate: challenge.startDate,
      durationWeeks: challenge.durationWeeks,
      goals: challenge.goals,
      aiPlan: challenge.aiPlan,
      recommendedHabits: challenge.recommendedHabits,
      baselineMetrics: challenge.baselineMetrics,
      progressSnapshots: challenge.progressSnapshots,
      surveyResponses: [...?challenge.surveyResponses, response],
    );

    appState.setActiveHealthChallenge(updatedChallenge);

    // Show success message
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Check-in completed! Keep up the great work!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final challenge = context.watch<AppState>().activeHealthChallenge;

    if (challenge == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly Check-In')),
        body: const Center(child: Text('No active challenge')),
      );
    }

    final weekNumber =
        DateTime.now().difference(challenge.startDate).inDays ~/ 7 + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Week $weekNumber Check-In'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(),
            ),
          ),

          // Navigation Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == 4 ? 'Complete Check-In' : 'Next',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEnergyLevelStep();
      case 1:
        return _buildMotivationStep();
      case 2:
        return _buildChallengeStep();
      case 3:
        return _buildWinsStep();
      case 4:
        return _buildPainPointsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEnergyLevelStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Energy Level',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'How has your energy been this week?',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 40),
        _buildSliderWithLabels(
          value: _energyLevel,
          onChanged: (val) => setState(() => _energyLevel = val),
          labels: ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
        ),
      ],
    );
  }

  Widget _buildMotivationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💪 Motivation Level',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'How motivated are you feeling?',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 40),
        _buildSliderWithLabels(
          value: _motivationLevel,
          onChanged: (val) => setState(() => _motivationLevel = val),
          labels: ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
        ),
      ],
    );
  }

  Widget _buildChallengeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🤔 Biggest Challenge',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'What was your biggest challenge this week?',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _challengeController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'e.g., Staying consistent with workouts...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWinsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎉 Wins & Achievements',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'What are you proud of this week?',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _winsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'e.g., Hit my step goal 5 days in a row!',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPainPointsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💬 Anything Else? (Optional)',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Any pain points or concerns you want to share?',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _painPointsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share your thoughts (optional)...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderWithLabels({
    required double value,
    required ValueChanged<double> onChanged,
    required List<String> labels,
  }) {
    return Column(
      children: [
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: labels[value.toInt() - 1],
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.asMap().entries.map((entry) {
            final isSelected = value.toInt() - 1 == entry.key;
            return Expanded(
              child: Text(
                entry.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
