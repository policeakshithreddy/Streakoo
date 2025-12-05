import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/ai_health_coach_service.dart';
import '../models/habit.dart';
import '../services/health_service.dart';

class HealthIntakeScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const HealthIntakeScreen({super.key, this.onComplete});

  @override
  State<HealthIntakeScreen> createState() => _HealthIntakeScreenState();
}

class _HealthIntakeScreenState extends State<HealthIntakeScreen> {
  int _currentStep = 0;
  bool _isGenerating = false;

  // Data
  String? _selectedGoal;
  String? _activityLevel;
  int _workoutDays = 3;

  // Controllers
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  final List<String> _goals = [
    'Lose Weight',
    'Build Muscle',
    'Improve Stamina',
    'Reduce Stress',
    'Better Sleep',
  ];

  final List<String> _activityLevels = [
    'Sedentary (Office job)',
    'Lightly Active (1-2 days/week)',
    'Moderately Active (3-5 days/week)',
    'Very Active (6-7 days/week)',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
      } else {
        _generatePlan();
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  Future<void> _generatePlan() async {
    setState(() => _isGenerating = true);

    try {
      final plan = await AIHealthCoachService.instance.generateHealthPlan(
        goal: _selectedGoal!,
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        activityLevel: _activityLevel!,
        workoutDays: _workoutDays,
      );

      if (!mounted) return;

      final appState = context.read<AppState>();
      final habits = plan['habits'] as List;

      // Add generated habits
      for (var h in habits) {
        final habit = Habit(
          id: DateTime.now().millisecondsSinceEpoch.toString() + h['name'],
          name: h['name'],
          emoji: h['emoji'],
          frequencyDays: [1, 2, 3, 4, 5, 6, 7], // Default to daily for now
          isHealthTracked: h['healthMetric'] != 'none',
          healthMetric: _parseMetric(h['healthMetric']),
          healthGoalValue: (h['targetValue'] as num?)?.toDouble(),
        );
        appState.addHabit(habit);
      }

      // Show welcome tip
      final welcomeTip = plan['welcomeTip'] as String?;
      if (welcomeTip != null) {
        // TODO: Store this tip to show in Profile or Home
        debugPrint('Welcome Tip: $welcomeTip');
      }

      setState(() => _isGenerating = false);
      widget.onComplete?.call();
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Your personalized plan is ready!'),
          backgroundColor: Color(0xFF58CC02),
        ),
      );
    } catch (e) {
      debugPrint('Error generating plan: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  HealthMetricType? _parseMetric(String? metric) {
    switch (metric) {
      case 'steps':
        return HealthMetricType.steps;
      case 'sleep':
        return HealthMetricType.sleep;
      case 'distance':
        return HealthMetricType.distance;
      case 'calories':
        return HealthMetricType.calories;
      case 'heartRate':
        return HealthMetricType.heartRate;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize Your Plan'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF58CC02)),
            ),

            Expanded(
              child: _isGenerating
                  ? _buildLoadingState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildCurrentStep(),
                    ),
            ),

            // Bottom Navigation
            if (!_isGenerating)
              Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton(
                  onPressed: _canProceed() ? _nextStep : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentStep == 2 ? 'Generate Plan ✨' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(Color(0xFF58CC02)),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Designing Your Plan...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            'Analyzing your goals and baseline...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildGoalStep();
      case 1:
        return _buildBaselineStep();
      case 2:
        return _buildCommitmentStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is your main focus?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'We will tailor your daily tips and habits to this goal.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        ..._goals.map((goal) => _buildOptionTile(
              title: goal,
              isSelected: _selectedGoal == goal,
              onTap: () => setState(() => _selectedGoal = goal),
            )),
      ],
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }

  Widget _buildBaselineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tell us about you',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'This helps us calculate realistic targets.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),

        // Inputs
        Row(
          children: [
            Expanded(
              child: _buildInput(
                controller: _ageController,
                label: 'Age',
                suffix: 'years',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInput(
                controller: _weightController,
                label: 'Weight',
                suffix: 'kg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInput(
          controller: _heightController,
          label: 'Height',
          suffix: 'cm',
        ),

        const SizedBox(height: 32),
        const Text(
          'Activity Level',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._activityLevels.map((level) => _buildOptionTile(
              title: level,
              isSelected: _activityLevel == level,
              onTap: () => setState(() => _activityLevel = level),
              compact: true,
            )),
      ],
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }

  Widget _buildCommitmentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Commitment',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'How many days a week can you dedicate to workouts?',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 48),
        Center(
          child: Column(
            children: [
              Text(
                '$_workoutDays Days',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF58CC02),
                ),
              ),
              const SizedBox(height: 24),
              Slider(
                value: _workoutDays.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                activeColor: const Color(0xFF58CC02),
                onChanged: (value) =>
                    setState(() => _workoutDays = value.round()),
              ),
              const SizedBox(height: 8),
              Text(
                _workoutDays < 3
                    ? 'Gentle Start'
                    : _workoutDays < 5
                        ? 'Balanced'
                        : 'Intense',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF58CC02).withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF58CC02) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF58CC02)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF58CC02)),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedGoal != null;
      case 1:
        return _ageController.text.isNotEmpty &&
            _weightController.text.isNotEmpty &&
            _heightController.text.isNotEmpty &&
            _activityLevel != null;
      case 2:
        return true;
      default:
        return false;
    }
  }
}
