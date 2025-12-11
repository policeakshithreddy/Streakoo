import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Enhanced bottom sheet with draggable handle and custom styling
class EnhancedBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final double? initialChildSize;
  final double? minChildSize;
  final double? maxChildSize;
  final bool isDark;
  final List<Widget>? actions;

  const EnhancedBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.95,
    this.isDark = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize!,
      minChildSize: minChildSize!,
      maxChildSize: maxChildSize!,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radius2XL),
            ),
            boxShadow: DesignTokens.shadow2XL(Colors.black),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: DesignTokens.space3),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              if (title != null || actions != null)
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  child: Row(
                    children: [
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSize2XL,
                              fontWeight: DesignTokens.fontWeightBold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),

              // Divider
              if (title != null || actions != null)
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  children: [child],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show modal bottom sheet with enhanced styling
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.95,
    bool isDismissible = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: isDismissible,
      builder: (context) => EnhancedBottomSheet(
        title: title,
        actions: actions,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        isDark: isDark,
        child: child,
      ),
    );
  }
}

/// Simple bottom sheet for quick actions
class SimpleBottomSheet extends StatelessWidget {
  final String title;
  final List<BottomSheetAction> actions;
  final bool isDark;

  const SimpleBottomSheet({
    super.key,
    required this.title,
    required this.actions,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius2XL),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: DesignTokens.space4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white30 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeLG,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.space3),

          // Actions
          ...actions.map((action) => ListTile(
                leading: Icon(
                  action.icon,
                  color: action.isDestructive
                      ? Colors.red
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
                title: Text(
                  action.label,
                  style: TextStyle(
                    color: action.isDestructive
                        ? Colors.red
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  action.onTap();
                },
              )),
        ],
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<BottomSheetAction> actions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SimpleBottomSheet(
        title: title,
        actions: actions,
        isDark: isDark,
      ),
    );
  }
}

class BottomSheetAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const BottomSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}
