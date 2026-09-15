import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/shared_chain_challenge.dart';

/// Widget to display shared chain challenges in the partner profile
class SharedChallengesSection extends StatelessWidget {
  final String partnerId;
  final String partnerName;
  final VoidCallback onCreateChallenge;

  const SharedChallengesSection({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.onCreateChallenge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final challenges = SharedChainChallengeService.instance
        .getChallengesWithPartner(partnerId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⛓️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Shared Chain Challenges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCreateChallenge,
                icon: Icon(
                  Icons.add_circle,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: 'Create Challenge',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Compete with $partnerName on habit chains!',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          if (challenges.isEmpty)
            _buildEmptyState(context, isDark)
          else
            ...challenges.map((c) => _buildChallengeCard(context, c, isDark)),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1);
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No challenges yet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a shared chain to challenge your partner!',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCreateChallenge,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(
      BuildContext context, SharedChainChallenge challenge, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFA94A).withValues(alpha: isDark ? 0.15 : 0.1),
            const Color(0xFFFF6B6B).withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFA94A).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔗', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.chainName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: challenge.isActive
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  challenge.isActive ? 'Active' : 'Paused',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: challenge.isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (challenge.description != null) ...[
            const SizedBox(height: 8),
            Text(
              challenge.description!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Progress comparison
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  label: 'You',
                  progress: challenge.myProgress,
                  total: challenge.totalHabits,
                  streak: challenge.myStreak,
                  color: const Color(0xFFFFA94A),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              const Text('vs', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressBar(
                  label: partnerName.split(' ').first,
                  progress: challenge.partnerProgress,
                  total: challenge.totalHabits,
                  streak: challenge.partnerStreak,
                  color: const Color(0xFF6B7AFF),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Habit chain icons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: challenge.habitNames.asMap().entries.map((entry) {
              final index = entry.key;
              final name = entry.value;
              final isCompletedByMe = index < challenge.myProgress;

              return Tooltip(
                message: name,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompletedByMe
                        ? const Color(0xFFFFA94A).withValues(alpha: 0.3)
                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                    shape: BoxShape.circle,
                    border: isCompletedByMe
                        ? Border.all(color: const Color(0xFFFFA94A), width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompletedByMe
                            ? const Color(0xFFFFA94A)
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int progress,
    required int total,
    required int streak,
    required Color color,
    required bool isDark,
  }) {
    final percent = total > 0 ? progress / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (streak > 0)
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 10)),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: isDark ? Colors.white10 : Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$progress/$total',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet to create a new shared chain challenge
class CreateSharedChallengeSheet extends StatefulWidget {
  final String partnerId;
  final String partnerName;

  const CreateSharedChallengeSheet({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<CreateSharedChallengeSheet> createState() =>
      _CreateSharedChallengeSheetState();
}

class _CreateSharedChallengeSheetState
    extends State<CreateSharedChallengeSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<TextEditingController> _habitControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final c in _habitControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addHabit() {
    setState(() {
      _habitControllers.add(TextEditingController());
    });
  }

  void _removeHabit(int index) {
    if (_habitControllers.length > 2) {
      setState(() {
        _habitControllers[index].dispose();
        _habitControllers.removeAt(index);
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final habits = _habitControllers
        .map((c) => c.text.trim())
        .where((h) => h.isNotEmpty)
        .toList();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a chain name')),
      );
      return;
    }

    if (habits.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 habits')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await SharedChainChallengeService.instance.createChallenge(
        chainName: name,
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        habitNames: habits,
        partnerId: widget.partnerId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Challenge created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text('⛓️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Chain Challenge',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'with ${widget.partnerName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chain name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Chain Name',
                hintText: 'e.g. Morning Routine',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Description (optional)
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this chain about?',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Habits
            Text(
              'Habits in the Chain',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete them in order. Add at least 2.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(_habitControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA94A).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFA94A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _habitControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Habit ${index + 1}',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    if (_habitControllers.length > 2) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removeHabit(index),
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                      ),
                    ],
                  ],
                ),
              );
            }),

            TextButton.icon(
              onPressed: _addHabit,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Habit'),
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA94A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Create Challenge',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
