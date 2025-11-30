import 'package:flutter/material.dart';
import '../models/coach_message.dart';

class CoachMessageBubble extends StatelessWidget {
  final CoachMessage message;
  final bool isThinking;

  const CoachMessageBubble({
    super.key,
    required this.message,
    this.isThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isFromUser;

    final bubbleColor = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor =
        isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  isUser ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight:
                  isUser ? const Radius.circular(4) : const Radius.circular(18),
            ),
          ),
          child: isThinking
              ? _buildThinkingDots(textColor)
              : Text(
                  message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildThinkingDots(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(color),
        const SizedBox(width: 4),
        _dot(color),
        const SizedBox(width: 4),
        _dot(color),
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
