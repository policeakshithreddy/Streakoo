import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet_customization.dart';
import '../state/app_state.dart';

/// Bottom sheet for pet customization (Edit Mode)
class PetCustomizationSheet extends StatelessWidget {
  const PetCustomizationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customize Pet 🎨',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scrollable content in case of overflow
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Accessories', isDark),
                  const SizedBox(height: 12),
                  _buildAccessoriesGrid(context, isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Pet Theme', isDark),
                  const SizedBox(height: 12),
                  _buildThemeSelector(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }

  Widget _buildAccessoriesGrid(BuildContext context, bool isDark) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final service = PetCustomizationService.instance;
        final userLevel = appState.userLevel.level;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: PetCustomizationService.accessories.map((item) {
            final isUnlocked = userLevel >= item.requiredLevel;
            final isEquipped = service.equippedAccessoryId == item.id;

            return GestureDetector(
              onTap: isUnlocked
                  ? () {
                      service.equipAccessory(isEquipped ? null : item.id);
                      // The Consumer will rebuild when AppState notifies listeners,
                      // which should happen after equipAccessory updates the state.
                      // No need for setState() in a StatelessWidget.
                    }
                  : null,
              child: Stack(
                children: [
                  Container(
                    width: 70,
                    height: 80,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isEquipped
                          ? const Color(0xFFFFA94A).withValues(alpha: 0.2)
                          : (isDark ? Colors.grey[800] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEquipped
                            ? const Color(0xFFFFA94A)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white70 : Colors.black87,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isUnlocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock, color: Colors.white70),
                        ),
                      ),
                    ),
                  if (isEquipped)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Color(0xFFFFA94A), shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final service = PetCustomizationService.instance;
        final userLevel = appState.userLevel.level;

        return SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: PetCustomizationService.themes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final theme = PetCustomizationService.themes[index];

              final isUnlocked = userLevel >= theme.requiredLevel;
              final isSelected = service.currentThemeId == theme.id;

              return GestureDetector(
                onTap: isUnlocked
                    ? () async {
                        await service.setTheme(theme.id);
                        (context as Element).markNeedsBuild();
                      }
                    : null,
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.5,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFA94A).withValues(alpha: 0.2)
                              : (isDark ? Colors.black26 : Colors.grey[100]),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFA94A)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                              theme.name == 'Default'
                                  ? '🐥'
                                  : '🐉', // Just examples, should use theme icon if available
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.name,
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
