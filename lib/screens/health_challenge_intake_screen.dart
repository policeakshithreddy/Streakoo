import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/health_challenge.dart';
import '../services/ai_health_coach_service.dart';
import '../services/local_notification_service.dart';
import '../services/health_service.dart';
import '../services/health_validation_service.dart';
import '../state/app_state.dart';
import '../widgets/health_pickers.dart';
import '../widgets/animated_validation_card.dart';
import '../widgets/emoji_sleep_slider.dart';
import '../widgets/stress_level_slider.dart';
import 'challenge_habit_approval_screen.dart';

class HealthChallengeIntakeScreen extends StatefulWidget {
  final ChallengeType? preselectedChallenge;

  const HealthChallengeIntakeScreen({super.key, this.preselectedChallenge});

  @override
  State<HealthChallengeIntakeScreen> createState() =>
      _HealthChallengeIntakeScreenState();
}

class _HealthChallengeIntakeScreenState
    extends State<HealthChallengeIntakeScreen> {
  int _currentStep = 0;
  ChallengeType? _selectedType;
  bool _isGenerating = false;

  // Basic Info Controllers
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _fitnessLevel = 'Beginner';
  String _activityLevel = 'Moderately Active';

  // Health & Lifestyle Controllers
  final List<String> _medicalConditions = [];
  final List<String> _dietaryPreferences = [];
  final List<String> _allergies = [];
  double _sleepQuality = 3.0; // 1-5 scale
  double _stressLevel = 3.0; // 1-5 scale
  String _workoutLocation = 'Both';
  double _dailyMinutes = 30.0; // 15-120 range
  final _motivationCtrl = TextEditingController();

  final Map<String, dynamic> _specificAnswers = {};

  @override
  void initState() {
    super.initState();
    // Pre-select challenge if provided
    if (widget.preselectedChallenge != null) {
      _selectedType = widget.preselectedChallenge;
    }
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _motivationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isGenerating
            ? 'Creating Plan...'
            : 'Step ${_currentStep + 1} of 4'),
        centerTitle: true,
      ),
      body: _isGenerating
          ? _buildLoadingState(theme)
          : Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
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
        return _buildHealthLifestyle(theme);
      case 3:
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
        const SizedBox(height: 8),
        Text(
          'Help us create a safe and effective plan',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),

        // Age Picker Button
        _buildPickerButton(
          theme: theme,
          label: 'Age',
          value: _ageCtrl.text.isEmpty
              ? 'Tap to select'
              : '${_ageCtrl.text} years',
          icon: Icons.cake,
          onTap: () async {
            final age = await showModalBottomSheet<int>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => HealthPickerBottomSheet(
                title: 'Age',
                initialValue: int.tryParse(_ageCtrl.text) ?? 25,
                minValue: 16,
                maxValue: 100,
                unit: 'years',
                subtitle: 'How old are you?',
              ),
            );
            if (age != null) {
              HapticFeedback.selectionClick();
              setState(() => _ageCtrl.text = age.toString());
            }
          },
        ),
        const SizedBox(height: 16),

        // Height Picker Button
        _buildPickerButton(
          theme: theme,
          label: 'Height',
          value: _heightCtrl.text.isEmpty
              ? 'Tap to select'
              : '${_heightCtrl.text} cm',
          icon: Icons.height,
          onTap: () async {
            final height = await showModalBottomSheet<double>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => HeightPickerBottomSheet(
                initialHeightCm: double.tryParse(_heightCtrl.text) ?? 170,
              ),
            );
            if (height != null) {
              HapticFeedback.selectionClick();
              setState(() => _heightCtrl.text = height.toStringAsFixed(0));
            }
          },
        ),
        const SizedBox(height: 16),

        // Weight Picker Button
        _buildPickerButton(
          theme: theme,
          label: 'Weight',
          value: _weightCtrl.text.isEmpty
              ? 'Tap to select'
              : '${_weightCtrl.text} kg',
          icon: Icons.monitor_weight,
          onTap: () async {
            final weight = await showModalBottomSheet<double>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => WeightPickerBottomSheet(
                initialWeightKg: double.tryParse(_weightCtrl.text) ?? 70,
              ),
            );
            if (weight != null) {
              HapticFeedback.selectionClick();
              setState(() => _weightCtrl.text = weight.toStringAsFixed(0));
            }
          },
        ),

        // BMI Validation (show after height & weight entered)
        if (_heightCtrl.text.isNotEmpty && _weightCtrl.text.isNotEmpty) ...{
          const SizedBox(height: 16),
          AnimatedValidationCard(
            validation: HealthValidationService.validateBMI(
              HealthValidationService.calculateBMI(
                double.parse(_heightCtrl.text),
                double.parse(_weightCtrl.text),
              ),
            ),
            label: 'BMI',
            value: HealthValidationService.calculateBMI(
              double.parse(_heightCtrl.text),
              double.parse(_weightCtrl.text),
            ).toStringAsFixed(1),
          ),
        },

        // Age Validation
        if (_ageCtrl.text.isNotEmpty) ...{
          const SizedBox(height: 16),
          AnimatedValidationCard(
            validation: HealthValidationService.validateAge(
              int.parse(_ageCtrl.text),
            ),
            label: 'Age Group',
            showValue: false,
          ),
        },
        const SizedBox(height: 24),

        // Fitness Level
        Text('Current Fitness Level', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _fitnessLevel,
          items: ['Beginner', 'Intermediate', 'Advanced', 'Athlete']
              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
              .toList(),
          onChanged: (v) => setState(() => _fitnessLevel = v!),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            helperText: 'How would you rate your current fitness?',
          ),
        ),
        const SizedBox(height: 16),

        // Activity Level
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
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            helperText: 'Your typical daily activity',
          ),
        ),
      ],
    );
  }

  Widget _buildHealthLifestyle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health & Lifestyle',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Help us personalize your plan',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 24),

        // Medical
        Text('Medical Conditions', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'None',
              'Diabetes',
              'Heart Condition',
              'Joint Issues',
              'High BP',
              'Asthma'
            ]
                .map((c) => FilterChip(
                    label: Text(c),
                    selected: _medicalConditions.contains(c),
                    onSelected: (s) => setState(() {
                          if (c == 'None') {
                            _medicalConditions.clear();
                            if (s) _medicalConditions.add('None');
                          } else {
                            _medicalConditions.remove('None');
                            s
                                ? _medicalConditions.add(c)
                                : _medicalConditions.remove(c);
                          }
                        })))
                .toList()),
        const SizedBox(height: 24),

        // Diet
        Text('Dietary Preferences', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'No Restrictions',
              'Vegetarian',
              'Vegan',
              'Keto',
              'Paleo',
              'Gluten-Free'
            ]
                .map((d) => FilterChip(
                    label: Text(d),
                    selected: _dietaryPreferences.contains(d),
                    onSelected: (s) => setState(() {
                          if (d == 'No Restrictions') {
                            _dietaryPreferences.clear();
                            if (s) _dietaryPreferences.add(d);
                          } else {
                            _dietaryPreferences.remove('No Restrictions');
                            s
                                ? _dietaryPreferences.add(d)
                                : _dietaryPreferences.remove(d);
                          }
                        })))
                .toList()),
        const SizedBox(height: 24),

        // Allergies
        Text('Common Allergies', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['None', 'Nuts', 'Dairy', 'Eggs', 'Soy', 'Shellfish']
                .map((a) => FilterChip(
                    label: Text(a),
                    selected: _allergies.contains(a),
                    onSelected: (s) => setState(() {
                          if (a == 'None') {
                            _allergies.clear();
                            if (s) _allergies.add('None');
                          } else {
                            _allergies.remove('None');
                            s ? _allergies.add(a) : _allergies.remove(a);
                          }
                        })))
                .toList()),
        const SizedBox(height: 24),

        // Sleep Quality - Enhanced with emoji selector
        Text('Sleep Quality', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        EmojiSleepSlider(
          initialValue: _sleepQuality,
          onChanged: (v) => setState(() => _sleepQuality = v),
        ),
        const SizedBox(height: 16),

        // Stress Level - Enhanced with gradient slider
        Text('Current Stress Level', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        StressLevelSlider(
          initialValue: _stressLevel,
          onChanged: (v) => setState(() => _stressLevel = v),
        ),
        const SizedBox(height: 24),

        // Location
        Text('Workout Preference', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Home', label: Text('🏠 Home')),
              ButtonSegment(value: 'Gym', label: Text('🏋️ Gym')),
              ButtonSegment(value: 'Both', label: Text('Both'))
            ],
            selected: {
              _workoutLocation
            },
            onSelectionChanged: (s) =>
                setState(() => _workoutLocation = s.first)),
        const SizedBox(height: 24),

        // Time
        Text('Daily Time Available', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Slider(
            value: _dailyMinutes,
            min: 15,
            max: 120,
            divisions: 21,
            label: '${_dailyMinutes.round()} mins',
            onChanged: (v) => setState(() => _dailyMinutes = v)),
        Text('${_dailyMinutes.round()} minutes per day',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        // Motivation
        Text('What\'s your main motivation?',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
            controller: _motivationCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
                hintText: 'e.g., "Fit into my wedding dress"',
                border: OutlineInputBorder(),
                helperText: 'Helps us provide personalized encouragement')),
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
            child: Text(_currentStep == 3 ? 'Generate Plan' : 'Next'),
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

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      return;
    }

    // Generate Plan with rich context
    setState(() => _isGenerating = true);

    try {
      // Calculate BMI
      final height = double.tryParse(_heightCtrl.text) ?? 170;
      final weight = double.tryParse(_weightCtrl.text) ?? 70;
      final bmi = weight / ((height / 100) * (height / 100));

      final planData =
          await AIHealthCoachService.instance.generateChallengePlan(
        challengeType: _selectedType!.name,
        age: int.tryParse(_ageCtrl.text) ?? 30,
        weight: weight,
        activityLevel: _activityLevel,
        specificAnswers: {
          ..._specificAnswers,
          // Enhanced context
          'height': height,
          'bmi': bmi.toStringAsFixed(1),
          'fitnessLevel': _fitnessLevel,
          'medicalConditions': _medicalConditions.isEmpty
              ? 'None'
              : _medicalConditions.join(', '),
          'dietaryPreferences': _dietaryPreferences.isEmpty
              ? 'No restrictions'
              : _dietaryPreferences.join(', '),
          'allergies': _allergies.isEmpty ? 'None' : _allergies.join(', '),
          'sleepQuality': _sleepQuality.round(),
          'stressLevel': _stressLevel.round(),
          'workoutLocation': _workoutLocation,
          'dailyMinutes': _dailyMinutes.round(),
          'motivation': _motivationCtrl.text.isEmpty
              ? 'General health improvement'
              : _motivationCtrl.text,
        },
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

  Widget _buildPickerButton({
    required ThemeData theme,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasValue = value != 'Tap to select';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasValue
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.5),
            width: hasValue ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasValue
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: hasValue
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                      fontWeight:
                          hasValue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
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
