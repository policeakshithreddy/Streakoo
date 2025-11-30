import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/health_challenge.dart';
import '../services/ai_health_coach_service.dart';
import '../services/local_notification_service.dart';
import '../services/health_service.dart';
import '../state/app_state.dart';
import 'challenge_habit_approval_screen.dart';

class HealthChallengeIntakeScreen extends StatefulWidget {
  const HealthChallengeIntakeScreen({super.key});

  @override
  State<HealthChallengeIntakeScreen> createState() =>
      _HealthChallengeIntakeScreenState();
}

class _HealthChallengeIntakeScreenState
    extends State<HealthChallengeIntakeScreen> {
  int _currentStep = 0;
  ChallengeType? _selectedType;
  bool _isGenerating = false;

  // Controllers
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _activityLevel = 'Moderately Active';
  final Map<String, dynamic> _specificAnswers = {};

  @override
  void dispose() {
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isGenerating
            ? 'Creating Plan...'
            : 'Step ${_currentStep + 1} of 3'),
        centerTitle: true,
      ),
      body: _isGenerating
          ? _buildLoadingState(theme)
          : Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildCurrentStep(theme),
                  ),
                ),
                _buildBottomBar(theme),
              ],
            ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildChallengeSelection(theme);
      case 1:
        return _buildBasicInfo(theme);
      case 2:
        return _buildSpecificQuestions(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChallengeSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your focus',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the area you want to improve over the next 4 weeks.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        _buildChallengeCard(
          theme,
          type: ChallengeType.weightManagement,
          title: 'Weight Management',
          icon: Icons.monitor_weight_outlined,
          color: Colors.orange,
          description: 'Focus on sustainable weight goals and nutrition.',
        ),
        _buildChallengeCard(
          theme,
          type: ChallengeType.heartHealth,
          title: 'Heart Health',
          icon: Icons.favorite_border,
          color: Colors.red,
          description: 'Improve cardiovascular fitness and stamina.',
        ),
        _buildChallengeCard(
          theme,
          type: ChallengeType.nutritionWellness,
          title: 'Nutrition & Wellness',
          icon: Icons.restaurant_menu,
          color: Colors.green,
          description: 'Build better eating habits and hydration.',
        ),
        _buildChallengeCard(
          theme,
          type: ChallengeType.activityStrength,
          title: 'Activity & Strength',
          icon: Icons.fitness_center,
          color: Colors.blue,
          description: 'Increase muscle tone and daily activity.',
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
    ThemeData theme, {
    required ChallengeType type,
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainer,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about you',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.cake),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.monitor_weight),
          ),
        ),
        const SizedBox(height: 24),
        Text('Activity Level', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _activityLevel,
          items: [
            'Sedentary',
            'Lightly Active',
            'Moderately Active',
            'Very Active'
          ].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: (v) => setState(() => _activityLevel = v!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildSpecificQuestions(ThemeData theme) {
    // Dynamic questions based on type
    final questions = _getQuestionsForType(_selectedType!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Final Details',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Help the AI customize your plan.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        ...questions.map((q) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              decoration: InputDecoration(
                labelText: q,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => _specificAnswers[q] = v,
            ),
          );
        }),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This plan is for wellness only. Consult a doctor for medical issues.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getQuestionsForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.weightManagement:
        return ['What is your target weight?', 'Do you track calories?'];
      case ChallengeType.heartHealth:
        return [
          'Do you know your resting heart rate?',
          'Any dietary restrictions?'
        ];
      case ChallengeType.nutritionWellness:
        return ['How much water do you drink?', 'Main nutritional goal?'];
      case ChallengeType.activityStrength:
        return ['How many days can you workout?', 'Access to gym equipment?'];
    }
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back'),
            ),
          const Spacer(),
          FilledButton(
            onPressed: _handleNext,
            child: Text(_currentStep == 2 ? 'Generate Plan' : 'Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Analyzing your profile...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'AI is crafting your 4-week challenge.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep == 0 && _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a challenge')),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      return;
    }

    // Generate Plan
    setState(() => _isGenerating = true);

    try {
      final planData =
          await AIHealthCoachService.instance.generateChallengePlan(
        challengeType: _selectedType!.name,
        age: int.tryParse(_ageCtrl.text) ?? 30,
        weight: double.tryParse(_weightCtrl.text) ?? 70,
        activityLevel: _activityLevel,
        specificAnswers: _specificAnswers,
      );

      // Capture baseline metrics
      final healthService = HealthService.instance;
      final now = DateTime.now();

      // Get average steps from last week
      int totalSteps = 0;
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: i));
        totalSteps += await healthService.getStepCount(day);
      }
      final avgSteps = (totalSteps / 7).round();

      final challenge = HealthChallenge(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType!,
        title: _getChallengeTitle(_selectedType!),
        description: planData['weeklyFocus'] ?? 'Your personalized plan',
        startDate: DateTime.now(),
        durationWeeks: 4,
        goals: _specificAnswers,
        aiPlan: planData,
        recommendedHabits: (planData['recommendedHabits'] as List)
            .map((h) => ChallengeHabit.fromJson(h))
            .toList(),
        baselineMetrics: {
          'weight': _specificAnswers['currentWeight'] as num?,
          'height': _specificAnswers['height'] as num?,
          'age': _specificAnswers['age'] as int?,
          'avgSteps': avgSteps,
          'activityLevel': _specificAnswers['activityLevel'],
          'capturedAt': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;

      // Navigate to habit approval screen
      final approved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ChallengeHabitApprovalScreen(challenge: challenge),
        ),
      );

      if (!mounted) return;

      // Only start challenge if user approved habits (or skipped)
      if (approved != null) {
        context.read<AppState>().startChallenge(challenge);

        // Schedule daily reminder
        await LocalNotificationService.scheduleDailyNotification(
          id: challenge.id.hashCode,
          title: 'Health Challenge Update',
          body: 'Check your daily progress for ${challenge.title}!',
          time: const TimeOfDay(hour: 9, minute: 0),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Challenge Started! Check your dashboard.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isGenerating = false);
      }
    }
  }

  String _getChallengeTitle(ChallengeType type) {
    switch (type) {
      case ChallengeType.weightManagement:
        return 'Weight Management';
      case ChallengeType.heartHealth:
        return 'Heart Health';
      case ChallengeType.nutritionWellness:
        return 'Nutrition & Wellness';
      case ChallengeType.activityStrength:
        return 'Activity & Strength';
    }
  }
}
