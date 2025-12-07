import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../widgets/glass_card.dart';
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
  String _loadingText = "Analyzing your profile...";

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_isGenerating
            ? 'Creating Plan...'
            : 'Step ${_currentStep + 1} of 4'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor,
                  theme.colorScheme.secondary.withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
          // Decorative background shapes
          Positioned(
            top: -50,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SafeArea(
            child: _isGenerating
                ? _buildLoadingState(theme)
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_currentStep + 1) / 4,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            minHeight: 6,
                          ),
                        ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_currentStep),
        child: _buildStepContent(theme),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
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
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          'Select the area you want to improve over the next 4 weeks.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 24),
        _buildChallengeCard(
          theme,
          type: ChallengeType.weightManagement,
          title: 'Weight Management',
          icon: Icons.monitor_weight_outlined,
          color: Colors.orange,
          description: 'Focus on sustainable weight goals and nutrition.',
          index: 0,
        ),
        _buildChallengeCard(
          theme,
          type: ChallengeType.heartHealth,
          title: 'Heart Health',
          icon: Icons.favorite_border,
          color: Colors.red,
          description: 'Improve cardiovascular fitness and stamina.',
          index: 1,
        ),
        _buildChallengeCard(
          theme,
          type: ChallengeType.nutritionWellness,
          title: 'Nutrition & Wellness',
          icon: Icons.restaurant_menu,
          color: Colors.green,
          description: 'Build better eating habits and hydration.',
          index: 2,
        ),
        _buildChallengeCard(
          theme,
          type: ChallengeType.activityStrength,
          title: 'Activity & Strength',
          icon: Icons.fitness_center,
          color: Colors.blue,
          description: 'Increase muscle tone and daily activity.',
          index: 3,
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
    required int index,
  }) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          opacity: isSelected ? 0.15 : 0.05,
          color: isSelected ? color : null,
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
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
              ).animate(target: isSelected ? 1 : 0).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 200.ms,
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
              if (isSelected)
                Icon(Icons.check_circle, color: color)
                    .animate()
                    .fadeIn()
                    .scale(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
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

        // Improved Tile-based Pickers
        Row(
          children: [
            Expanded(
              child: _buildGlassPickerTile(
                theme,
                label: 'Age',
                value: _ageCtrl.text.isEmpty ? '--' : _ageCtrl.text,
                unit: 'years',
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
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGlassPickerTile(
                theme,
                label: 'Height',
                value: _heightCtrl.text.isEmpty ? '--' : _heightCtrl.text,
                unit: 'cm',
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
                    setState(
                        () => _heightCtrl.text = height.toStringAsFixed(0));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGlassPickerTile(
          theme,
          label: 'Weight',
          value: _weightCtrl.text.isEmpty ? '--' : _weightCtrl.text,
          unit: 'kg',
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

        // BMI Validation
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
            showValue: false, // Don't show numeric value, just category/color
          ),
        },

        const SizedBox(height: 24),

        // Fitness Level
        Text('Current Fitness Level', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: DropdownButtonFormField<String>(
            dropdownColor: theme.colorScheme.surfaceContainer,
            value: _fitnessLevel,
            items: ['Beginner', 'Intermediate', 'Advanced', 'Athlete']
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) => setState(() => _fitnessLevel = v!),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              helperText: null,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Activity Level
        Text('Activity Level', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: DropdownButtonFormField<String>(
            dropdownColor: theme.colorScheme.surfaceContainer,
            value: _activityLevel,
            items: [
              'Sedentary',
              'Lightly Active',
              'Moderately Active',
              'Very Active'
            ].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => _activityLevel = v!),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              helperText: null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPickerTile(
    ThemeData theme, {
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Medical Conditions',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
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
                    .map((c) => _buildGlassChip(
                        label: c,
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
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Diet
        GlassCard(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dietary Preferences',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
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
                  .map((d) => _buildGlassChip(
                      label: d,
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
                  .toList(),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Sleep & Stress
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sleep Quality',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('How refreshed do you feel?',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              EmojiSleepSlider(
                initialValue: _sleepQuality,
                onChanged: (v) => setState(() => _sleepQuality = v),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child:
                    Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              Text('Current Stress Level',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Daily stress impact', style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              StressLevelSlider(
                initialValue: _stressLevel,
                onChanged: (v) => setState(() => _stressLevel = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificQuestions(ThemeData theme) {
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
                filled: true,
                fillColor: theme.colorScheme.surface.withValues(alpha: 0.3),
                labelText: q,
                labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
                prefixIcon: Icon(Icons.question_answer_outlined,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5)),
              ),
              onChanged: (v) => _specificAnswers[q] = v,
            ),
          );
        }),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This plan is for wellness only. Consult a doctor for medical issues.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber[800],
                    height: 1.3,
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  side: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _handleNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 56),
                backgroundColor: theme.colorScheme.primary,
                elevation: 4,
                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              child: Text(
                _currentStep == 3 ? 'Generate Plan' : 'Next',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    final isSuccess = _loadingText == "Done!";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI Pulse Animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isSuccess
                  ? Colors.green.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_rounded : Icons.auto_awesome,
              size: 40,
              color: isSuccess ? Colors.green : theme.colorScheme.primary,
            ),
          )
              .animate(
                  target: isSuccess ? 1 : 0) // Stop looping pulse if success
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  duration: 1.5.seconds,
                  curve: Curves.easeInOut)
              .fadeOut(delay: 0.5.seconds, duration: 1.seconds)
          // We want the pulse to stop when isSuccess is true.
          // We can control the "onPlay" or similar. But simplistic is:
          // If we change target, the previous animation might persist or reset.
          // Let's rely on standard implicit animation for color/icon,
          // and the flutter_animate pulse effect will just fade out or continue.
          // Ideally we'd rebuild the widget or use a controller, but this is okay for now.
          ,

          const SizedBox(height: 40),

          Text(
            _loadingText,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )
              .animate(key: ValueKey(_loadingText))
              .fadeIn(), // Animate text change

          if (!isSuccess)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Refining habits based on your goal...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
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
    setState(() {
      _isGenerating = true;
      _loadingText = "Analyzing your profile...";
    });

    // Simulate loading steps text change
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _loadingText != "Done!")
        setState(() => _loadingText = "Structuring your challenge...");
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _loadingText != "Done!")
        setState(() => _loadingText = "Finalizing habits...");
    });

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

      // SUCCESS ANIMATION PHASE
      if (mounted) {
        setState(() => _loadingText = "Done!");
        // Haptic feedback
        HapticFeedback.mediumImpact();
        await Future.delayed(
            const Duration(milliseconds: 1000)); // Show success for 1s
      }

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

        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Challenge Started! Check your dashboard.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // User cancelled, reset loading state
        if (mounted) setState(() => _isGenerating = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getChallengeTitle(ChallengeType type) {
    switch (type) {
      case ChallengeType.weightManagement:
        return 'Weight Management Challenge';
      case ChallengeType.heartHealth:
        return 'Heart Health Challenge';
      case ChallengeType.nutritionWellness:
        return 'Nutrition Wellness Challenge';
      case ChallengeType.activityStrength:
        return 'Activity & Strength Challenge';
    }
  }
}
