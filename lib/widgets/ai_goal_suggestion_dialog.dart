import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/groq_ai_service.dart';

/// Result of the AI Goal Suggestion dialog
class GoalSuggestionResult {
  final bool accepted;
  final String? goal;
  final bool skipped;

  const GoalSuggestionResult({
    required this.accepted,
    this.goal,
    this.skipped = false,
  });

  factory GoalSuggestionResult.accepted(String goal) =>
      GoalSuggestionResult(accepted: true, goal: goal);

  factory GoalSuggestionResult.skipped() =>
      const GoalSuggestionResult(accepted: false, skipped: true);

  factory GoalSuggestionResult.cancelled() =>
      const GoalSuggestionResult(accepted: false);
}

/// Beautiful dialog for AI-suggested habit goals
class AiGoalSuggestionDialog extends StatefulWidget {
  final String habitName;
  final String habitEmoji;
  final String category;
  final String? existingDescription;
  final String? preloadedSuggestion;

  const AiGoalSuggestionDialog({
    super.key,
    required this.habitName,
    required this.habitEmoji,
    required this.category,
    this.existingDescription,
    this.preloadedSuggestion,
  });

  /// Show the dialog and return the result
  static Future<GoalSuggestionResult?> show({
    required BuildContext context,
    required String habitName,
    required String habitEmoji,
    required String category,
    String? existingDescription,
    String? preloadedSuggestion,
  }) async {
    return showDialog<GoalSuggestionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AiGoalSuggestionDialog(
        habitName: habitName,
        habitEmoji: habitEmoji,
        category: category,
        existingDescription: existingDescription,
        preloadedSuggestion: preloadedSuggestion,
      ),
    );
  }

  @override
  State<AiGoalSuggestionDialog> createState() => _AiGoalSuggestionDialogState();
}

class _AiGoalSuggestionDialogState extends State<AiGoalSuggestionDialog> {
  final TextEditingController _goalController = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;
  String? _suggestedGoal;
  String? _error;

  // Theme colors
  static const _primaryGradient = [Color(0xFF8B5CF6), Color(0xFFEC4899)];
  static const _accentColor = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    if (widget.preloadedSuggestion != null) {
      _suggestedGoal = widget.preloadedSuggestion;
      _goalController.text = _suggestedGoal!;
      _isLoading = false;
    } else {
      _fetchAiSuggestion();
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _fetchAiSuggestion() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suggestion =
          await GroqAIService.instance.generateHabitGoalSuggestion(
        habitName: widget.habitName,
        category: widget.category,
        existingDescription: widget.existingDescription,
      );

      if (mounted) {
        setState(() {
          _suggestedGoal = suggestion;
          _goalController.text = suggestion ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not generate suggestion';
          _isLoading = false;
        });
      }
    }
  }

  void _acceptGoal() {
    HapticFeedback.mediumImpact();
    final goal = _goalController.text.trim();
    if (goal.isNotEmpty) {
      Navigator.of(context).pop(GoalSuggestionResult.accepted(goal));
    }
  }

  void _skipGoal() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(GoalSuggestionResult.skipped());
  }

  void _cancel() {
    Navigator.of(context).pop(GoalSuggestionResult.cancelled());
  }

  void _toggleEdit() {
    HapticFeedback.selectionClick();
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[900]!.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Habit emoji with glow
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.habitEmoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          )
                              .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.05, 1.05),
                                duration: 1500.ms,
                              ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'AI Goal Suggestion',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.habitName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _cancel,
                            icon:
                                const Icon(Icons.close, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading) ...[
                        _buildLoadingState(isDark),
                      ] else if (_error != null) ...[
                        _buildErrorState(isDark),
                      ] else ...[
                        _buildSuggestionContent(isDark),
                      ],

                      const SizedBox(height: 24),

                      // Action buttons
                      if (!_isLoading) _buildActionButtons(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(_accentColor),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: _primaryGradient[1]),
        const SizedBox(height: 20),
        Text(
          'Generating personalized goal...',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Colors.orange[400],
        ),
        const SizedBox(height: 12),
        Text(
          _error!,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _fetchAiSuggestion,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildSuggestionContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: _accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Suggested Goal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const Spacer(),
            if (!_isEditing)
              TextButton.icon(
                onPressed: _toggleEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Goal display/edit
        AnimatedSwitcher(
          duration: 200.ms,
          child: _isEditing
              ? TextField(
                  key: const ValueKey('editing'),
                  controller: _goalController,
                  maxLines: 3,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your custom goal...',
                    filled: true,
                    fillColor: isDark
                        ? Colors.grey[800]!.withValues(alpha: 0.5)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _accentColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onSubmitted: (_) => _toggleEdit(),
                )
              : Container(
                  key: const ValueKey('display'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryGradient[0].withValues(alpha: 0.1),
                        _primaryGradient[1].withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _goalController.text.isNotEmpty
                        ? _goalController.text
                        : 'No goal suggested',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn().shimmer(
                  duration: 2.seconds,
                  color: _accentColor.withValues(alpha: 0.1)),
        ),

        if (_isEditing) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _goalController.text = _suggestedGoal ?? '';
                  _toggleEdit();
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _toggleEdit,
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // Regenerate button
        Center(
          child: TextButton.icon(
            onPressed: _fetchAiSuggestion,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Regenerate'),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        // Skip button
        Expanded(
          child: OutlinedButton(
            onPressed: _skipGoal,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
              side: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Accept button
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _primaryGradient),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _primaryGradient[0].withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed:
                  _goalController.text.trim().isNotEmpty ? _acceptGoal : null,
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'Accept Goal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
