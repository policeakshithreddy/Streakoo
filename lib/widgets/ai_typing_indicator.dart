import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Typing indicator for AI coach
class TypingIndicator extends StatefulWidget {
  final bool isDark;
  final double size;

  const TypingIndicator({
    super.key,
    this.isDark = false,
    this.size = 8.0,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (2 * value - 1).abs()));

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.25),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.white60 : Colors.black54,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Suggested prompt chip
class PromptSuggestionChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDark;

  const PromptSuggestionChip({
    super.key,
    required this.text,
    this.icon,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space2,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: DesignTokens.borderRadiusLG,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: DesignTokens.space2),
            ],
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSM,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Container for suggested prompts
class SuggestedPrompts extends StatelessWidget {
  final List<String> prompts;
  final Function(String) onPromptTap;
  final bool isDark;

  const SuggestedPrompts({
    super.key,
    required this.prompts,
    required this.onPromptTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DesignTokens.space2,
      runSpacing: DesignTokens.space2,
      children: prompts
          .map((prompt) => PromptSuggestionChip(
                text: prompt,
                onTap: () => onPromptTap(prompt),
                isDark: isDark,
              ))
          .toList(),
    );
  }

  /// Default suggested prompts
  static const List<String> defaults = [
    'How can I improve my streak?',
    'Tips for building better habits',
    'Why did I break my streak?',
    'Set up a morning routine',
    'Help me stay motivated',
  ];
}
