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
  final double _sleepQuality = 3.0; // 1-5 scale
  double _stressLevel = 3.0; // 1-5 scale
  String _workoutLocation = 'Both';
  final double _dailyMinutes = 30.0; // 15-120 range
  double _waterLitres = 2.0; // 1-4 litres
  int _exerciseDays = 3; // 0-6+ days
  int _sleepHours = 7; // 5-9 hours
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
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        Text(
          'Help us create a safe and effective plan',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
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
            initialValue: _fitnessLevel,
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
            initialValue: _activityLevel,
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
                    ?.copyWith(fontWeight: FontWeight.bold))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        Text('Help us personalize your plan',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7)))
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 24),

        // Medical Conditions
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
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),

        // Dietary Preferences
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
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 500.ms)
            .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),

        // Water Intake & Exercise
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Water Intake',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('How many litres per day?',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              _buildWaterLitreSelector(theme),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child:
                    Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              Text('Weekly Exercise',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Days you exercise per week',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              _buildExerciseDaysSelector(theme),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms)
            .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),

        // Workout Location
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Workout Location',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Where do you prefer to exercise?',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildLocationCard(
                      theme,
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: _workoutLocation == 'Home',
                      onTap: () => setState(() => _workoutLocation = 'Home'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLocationCard(
                      theme,
                      icon: Icons.fitness_center_rounded,
                      label: 'Gym',
                      selected: _workoutLocation == 'Gym',
                      onTap: () => setState(() => _workoutLocation = 'Gym'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLocationCard(
                      theme,
                      icon: Icons.sync_alt_rounded,
                      label: 'Both',
                      selected: _workoutLocation == 'Both',
                      onTap: () => setState(() => _workoutLocation = 'Both'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 500.ms)
            .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),

        // Sleep Hours
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Average Sleep',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('How many hours do you sleep?',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              _buildSleepHoursSelector(theme),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 500.ms)
            .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),

        // Stress Level
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        )
            .animate()
            .fadeIn(delay: 700.ms, duration: 500.ms)
            .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
      ],
    );
  }

  Widget _buildWaterLitreSelector(ThemeData theme) {
    final litreOptions = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: litreOptions.map((litres) {
        final isSelected = _waterLitres == litres;
        return GestureDetector(
          onTap: () => setState(() => _waterLitres = litres),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.cyan.withValues(alpha: 0.2)
                  : theme.colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.cyan : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  size: 20,
                  color: isSelected ? Colors.cyan : Colors.grey,
                ),
                Text(
                  litres == litres.toInt()
                      ? '${litres.toInt()}L'
                      : '${litres}L',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.cyan : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSleepHoursSelector(ThemeData theme) {
    final sleepLabels = {
      5: ('😴', 'Poor'),
      6: ('😐', 'Low'),
      7: ('😊', 'Good'),
      8: ('😁', 'Great'),
      9: ('🌟', 'Optimal'),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: sleepLabels.entries.map((entry) {
        final hours = entry.key;
        final emoji = entry.value.$1;
        final label = entry.value.$2;
        final isSelected = _sleepHours == hours;
        return GestureDetector(
          onTap: () => setState(() => _sleepHours = hours),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.indigo.withValues(alpha: 0.2)
                  : theme.colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.indigo : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  '${hours}h',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.indigo : Colors.grey,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected
                        ? Colors.indigo
                        : Colors.grey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExerciseDaysSelector(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final days = index;
        final isSelected = _exerciseDays == days;
        final labels = ['0', '1', '2', '3', '4', '5', '6+'];
        return GestureDetector(
          onTap: () => setState(() => _exerciseDays = days),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.surface.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : Colors.grey,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLocationCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
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
          'Help the AI customize your ${_getChallengeTitle(_selectedType!)} plan.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // Challenge-specific visual inputs
        _buildChallengeSpecificInputs(theme),

        const SizedBox(height: 24),

        // Motivation (optional text)
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Motivation (Optional)',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _motivationCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'What drives you to start this challenge?',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
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

  Widget _buildChallengeSpecificInputs(ThemeData theme) {
    switch (_selectedType!) {
      case ChallengeType.weightManagement:
        return _buildWeightManagementInputs(theme);
      case ChallengeType.heartHealth:
        return _buildHeartHealthInputs(theme);
      case ChallengeType.nutritionWellness:
        return _buildNutritionInputs(theme);
      case ChallengeType.activityStrength:
        return _buildActivityInputs(theme);
    }
  }

  Widget _buildWeightManagementInputs(ThemeData theme) {
    return Column(
      children: [
        // Goal Type
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What is your goal?',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildGoalCard(
                      theme,
                      icon: Icons.trending_down,
                      label: 'Lose',
                      color: Colors.red,
                      selected: _specificAnswers['goal'] == 'Lose',
                      onTap: () =>
                          setState(() => _specificAnswers['goal'] = 'Lose'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGoalCard(
                      theme,
                      icon: Icons.balance,
                      label: 'Maintain',
                      color: Colors.green,
                      selected: _specificAnswers['goal'] == 'Maintain',
                      onTap: () =>
                          setState(() => _specificAnswers['goal'] = 'Maintain'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGoalCard(
                      theme,
                      icon: Icons.trending_up,
                      label: 'Gain',
                      color: Colors.blue,
                      selected: _specificAnswers['goal'] == 'Gain',
                      onTap: () =>
                          setState(() => _specificAnswers['goal'] = 'Gain'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Target Weight
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Target Weight',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildNumberSelector(
                theme,
                value: (_specificAnswers['targetWeight'] as int?) ?? 70,
                min: 40,
                max: 150,
                unit: 'kg',
                onChanged: (v) =>
                    setState(() => _specificAnswers['targetWeight'] = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Timeline
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Timeline',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final weeks in [4, 8, 12])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: weeks < 12 ? 12 : 0),
                        child: _buildTimelineCard(
                          theme,
                          weeks: weeks,
                          selected: _specificAnswers['timeline'] == weeks,
                          onTap: () => setState(
                              () => _specificAnswers['timeline'] = weeks),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeartHealthInputs(ThemeData theme) {
    return Column(
      children: [
        // Cardio Level
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Cardio Level',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final level in [
                    {'label': 'Low', 'emoji': '😮‍💨', 'value': 'low'},
                    {'label': 'Moderate', 'emoji': '🙂', 'value': 'moderate'},
                    {'label': 'Good', 'emoji': '💪', 'value': 'good'},
                  ])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: level['value'] != 'good' ? 12 : 0),
                        child: _buildEmojiCard(
                          theme,
                          emoji: level['emoji']!,
                          label: level['label']!,
                          selected:
                              _specificAnswers['cardioLevel'] == level['value'],
                          onTap: () => setState(() =>
                              _specificAnswers['cardioLevel'] = level['value']),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Cardio Goal
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Focus',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Endurance', 'Stamina', 'General Health', 'Recovery']
                    .map((goal) => _buildGlassChip(
                          label: goal,
                          selected: _specificAnswers['cardioGoal'] == goal,
                          onSelected: (_) => setState(
                              () => _specificAnswers['cardioGoal'] = goal),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionInputs(ThemeData theme) {
    return Column(
      children: [
        // Daily Water Target
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Water Target',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [6, 8, 10, 12].map((glasses) {
                  final isSelected = _specificAnswers['waterTarget'] == glasses;
                  return GestureDetector(
                    onTap: () => setState(
                        () => _specificAnswers['waterTarget'] = glasses),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('🥤', style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text('$glasses',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? Colors.blue : Colors.grey,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Nutrition Focus
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nutrition Focus',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  'Energy',
                  'Immunity',
                  'Gut Health',
                  'Weight',
                  'Muscle'
                ]
                    .map((focus) => _buildGlassChip(
                          label: focus,
                          selected: _specificAnswers['nutritionFocus'] == focus,
                          onSelected: (_) => setState(
                              () => _specificAnswers['nutritionFocus'] = focus),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityInputs(ThemeData theme) {
    return Column(
      children: [
        // Workout Days
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Workout Days Per Week',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [2, 3, 4, 5, 6].map((days) {
                  final isSelected = _specificAnswers['workoutDays'] == days;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _specificAnswers['workoutDays'] = days),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text('$days',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Equipment Access
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Equipment Access',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final eq in [
                    {'label': 'None', 'icon': Icons.block, 'value': 'none'},
                    {
                      'label': 'Basic',
                      'icon': Icons.fitness_center,
                      'value': 'basic'
                    },
                    {
                      'label': 'Full Gym',
                      'icon': Icons.sports_gymnastics,
                      'value': 'full'
                    },
                  ])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: eq['value'] != 'full' ? 12 : 0),
                        child: _buildLocationCard(
                          theme,
                          icon: eq['icon'] as IconData,
                          label: eq['label'] as String,
                          selected:
                              _specificAnswers['equipment'] == eq['value'],
                          onTap: () => setState(() =>
                              _specificAnswers['equipment'] = eq['value']),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Focus Area
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Focus Area',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  'Upper Body',
                  'Lower Body',
                  'Core',
                  'Full Body',
                  'Flexibility'
                ]
                    .map((area) => _buildGlassChip(
                          label: area,
                          selected: _specificAnswers['focusArea'] == area,
                          onSelected: (_) => setState(
                              () => _specificAnswers['focusArea'] = area),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: selected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? color : Colors.grey,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiCard(
    ThemeData theme, {
    required String emoji,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 2),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? theme.colorScheme.primary : Colors.grey,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(
    ThemeData theme, {
    required int weeks,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 2),
        ),
        child: Column(
          children: [
            Text('$weeks',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: selected ? theme.colorScheme.primary : Colors.grey,
                )),
            Text('weeks',
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? theme.colorScheme.primary : Colors.grey,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberSelector(
    ThemeData theme, {
    required int value,
    required int min,
    required int max,
    required String unit,
    required Function(int) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 32,
        ),
        const SizedBox(width: 16),
        Text(
          '$value $unit',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 32,
        ),
      ],
    );
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
      if (mounted && _loadingText != "Done!") {
        setState(() => _loadingText = "Structuring your challenge...");
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _loadingText != "Done!") {
        setState(() => _loadingText = "Finalizing habits...");
      }
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
