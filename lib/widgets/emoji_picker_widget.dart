import 'package:flutter/material.dart';

class EmojiPickerWidget extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
  });

  // Common emojis categorized
  static const Map<String, List<String>> emojiCategories = {
    'Smileys': [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '🤣',
      '😂',
      '🙂',
      '🙃',
      '😉',
      '😊',
      '😇',
      '🥰',
      '😍',
      '🤩',
      '😘',
      '😗',
      '😚',
      '😙',
      '😋',
      '😛',
      '😜',
      '🤪',
    ],
    'Activities': [
      '⚽',
      '🏀',
      '🏈',
      '⚾',
      '🎾',
      '🏐',
      '🏉',
      '🎱',
      '🏓',
      '🏸',
      '🏒',
      '🏑',
      '🥍',
      '🏏',
      '🥅',
      '⛳',
      '🏹',
      '🎣',
      '🤿',
      '🥊',
      '🥋',
      '🎽',
      '🛹',
      '🛷',
    ],
    'Objects': [
      '📚',
      '📖',
      '📝',
      '📊',
      '📈',
      '📉',
      '💻',
      '⌨️',
      '🖥️',
      '🖨️',
      '🖱️',
      '💾',
      '💿',
      '📱',
      '☎️',
      '📞',
      '📟',
      '📠',
      '📡',
      '🔋',
      '🔌',
      '💡',
      '🔦',
      '🕯️',
    ],
    'Food': [
      '🍎',
      '🍊',
      '🍋',
      '🍌',
      '🍉',
      '🍇',
      '🍓',
      '🍈',
      '🍒',
      '🍑',
      '🥭',
      '🍍',
      '🥥',
      '🥝',
      '🍅',
      '🥑',
      '🥦',
      '🥬',
      '🥒',
      '🌶️',
      '🌽',
      '🥕',
      '🥗',
      '🍕',
    ],
    'Nature': [
      '🌱',
      '🌿',
      '☘️',
      '🍀',
      '🎋',
      '🎍',
      '🌾',
      '🌵',
      '🌲',
      '🌳',
      '🌴',
      '🌻',
      '🌼',
      '🌷',
      '🌹',
      '🥀',
      '🌺',
      '🌸',
      '💐',
      '🏵️',
      '🌞',
      '🌝',
      '🌛',
      '⭐',
    ],
    'Hearts': [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '☮️',
      '✝️',
      '☪️',
      '🕉️',
      '☸️',
    ],
    'Symbols': [
      '⚡',
      '🔥',
      '💧',
      '💫',
      '⭐',
      '🌟',
      '✨',
      '⚠️',
      '🔔',
      '🎵',
      '🎶',
      '💯',
      '🔞',
      '⏰',
      '⏱️',
      '⏲️',
      '🎯',
      '🎪',
      '🎭',
      '🎨',
      '🎬',
      '🎤',
      '🎧',
      '🎼',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose an Emoji',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: emojiCategories.length,
              itemBuilder: (context, index) {
                final category = emojiCategories.keys.elementAt(index);
                final emojis = emojiCategories[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: emojis.length,
                      itemBuilder: (context, emojiIndex) {
                        final emoji = emojis[emojiIndex];
                        return InkWell(
                          onTap: () {
                            onEmojiSelected(emoji);
                            // Don't pop here - the callback already handles navigation
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
