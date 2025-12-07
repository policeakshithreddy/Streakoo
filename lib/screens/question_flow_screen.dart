import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  // App theme colors
  static const _primaryOrange = Color(0xFFFFA94A);

  // Goals with icons
  final List<_OptionItem> _goalOptions = [
    _OptionItem('Better health & fitness', Icons.fitness_center_rounded),
    _OptionItem('Better grades & study', Icons.school_rounded),
    _OptionItem('More focus & deep work', Icons.track_changes_rounded),
    _OptionItem('Better sleep & energy', Icons.bedtime_rounded),
    _OptionItem('General self-discipline', Icons.psychology_rounded),
  ];

  // Struggles with icons
  final List<_OptionItem> _struggleOptions = [
    _OptionItem('Staying consistent', Icons.calendar_today_rounded),
    _OptionItem('Getting started', Icons.play_circle_outline_rounded),
    _OptionItem('Distractions & phone', Icons.phone_android_rounded),
    _OptionItem('Low motivation', Icons.battery_1_bar_rounded),
    _OptionItem('Poor sleep & tired', Icons.nightlight_round),
  ];

  // Time preferences with icons
  final List<_OptionItem> _timeOptions = [
    _OptionItem('Morning', Icons.wb_sunny_rounded),
    _OptionItem('Afternoon', Icons.wb_cloudy_rounded),
    _OptionItem('Evening', Icons.nights_stay_rounded),
    _OptionItem('Flexible / no fixed time', Icons.schedule_rounded),
  ];

  void _next() {
    if (_step == 0 && _goals.isEmpty) {
      _showSnack('Pick at least one main goal');
      return;
    }
    if (_step == 1 && _struggles.isEmpty) {
      _showSnack('Pick at least one thing you struggle with');
      return;
    }
    if (_step == 2 && _timeOfDay == null) {
      _showSnack('Pick when you prefer doing your habits');
      return;
    }

    if (_step < 2) {
      setState(() => _step++);
    } else {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ChallengeSelectionScreen(
            displayName: widget.displayName,
            age: widget.age,
            goals: _goals.toList(),
            struggles: _struggles.toList(),
            timeOfDay: _timeOfDay!,
          ),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
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
        if (target.length >= 3) return;
        target.add(value);
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _back,
        ),
        title: Text(
          'Quick Setup',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildProgressBar(isDark),
            ),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: _buildStepContent(isDark),
              ),
            ),

            // Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _step > 0 ? 2 : 1,
                    child: GestureDetector(
                      onTap: _next,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryOrange, Color(0xFFFFBB6E)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryOrange.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _step < 2 ? 'Continue' : 'See my habits',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${_step + 1} of 3',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              '${((_step + 1) / 3 * 100).round()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _primaryOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            valueColor: const AlwaysStoppedAnimation<Color>(_primaryOrange),
            minHeight: 6,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStepContent(bool isDark) {
    final theme = Theme.of(context);

    String title;
    String subtitle;
    List<_OptionItem> options;
    Set<String>? multiSelect;
    bool isSingleSelect = false;

    if (_step == 0) {
      title = 'What are your main goals?';
      subtitle = 'Select up to 3 goals that matter most to you';
      options = _goalOptions;
      multiSelect = _goals;
    } else if (_step == 1) {
      title = 'What do you struggle with?';
      subtitle = 'Understanding your challenges helps us help you';
      options = _struggleOptions;
      multiSelect = _struggles;
    } else {
      title = 'When do you prefer habits?';
      subtitle = 'We\'ll optimize reminders for this time';
      options = _timeOptions;
      isSingleSelect = true;
    }

    return Padding(
      key: ValueKey(_step),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = isSingleSelect
                    ? _timeOfDay == option.text
                    : multiSelect!.contains(option.text);

                return _buildOptionCard(
                  option: option,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () {
                    if (isSingleSelect) {
                      setState(() => _timeOfDay = option.text);
                    } else {
                      _toggle(multiSelect!, option.text);
                    }
                  },
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required _OptionItem option,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? _primaryOrange.withValues(alpha: 0.15)
                    : _primaryOrange.withValues(alpha: 0.1))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? _primaryOrange
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryOrange.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _primaryOrange.withValues(alpha: 0.2)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  option.icon,
                  size: 22,
                  color: isSelected
                      ? _primaryOrange
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ),

              // Check indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _primaryOrange : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? _primaryOrange
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.4)),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }
}

class _OptionItem {
  final String text;
  final IconData icon;

  _OptionItem(this.text, this.icon);
}
