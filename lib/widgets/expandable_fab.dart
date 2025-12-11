import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/design_tokens.dart';
import '../utils/haptic_service.dart';

/// Expandable Floating Action Button with speed dial actions
class ExpandableFAB extends StatefulWidget {
  final List<FABAction> actions;
  final VoidCallback? onMainTap;
  final IconData mainIcon;
  final Gradient? gradient;

  const ExpandableFAB({
    super.key,
    required this.actions,
    this.onMainTap,
    this.mainIcon = Icons.add,
    this.gradient,
  });

  @override
  State<ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<ExpandableFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
        HapticService.instance.medium();
      } else {
        _controller.reverse();
        HapticService.instance.light();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Backdrop overlay
        if (_isOpen)
          GestureDetector(
            onTap: _toggle,
            child: AnimatedOpacity(
              duration: DesignTokens.durationNormal,
              opacity: _isOpen ? 1.0 : 0.0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),

        // Action buttons
        ..._buildActionButtons(),

        // Main FAB
        FloatingActionButton(
          onPressed: widget.onMainTap ?? _toggle,
          elevation: 6,
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _expandAnimation.value * math.pi / 4, // 45 degrees
                child: Icon(
                  _isOpen ? Icons.close : widget.mainIcon,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons() {
    final children = <Widget>[];
    final count = widget.actions.length;

    for (var i = 0; i < count; i++) {
      final action = widget.actions[i];
      final offset = (i + 1) * 70.0; // Spacing between buttons

      children.add(
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: offset * _expandAnimation.value,
              right: 0,
              child: Transform.scale(
                scale: _expandAnimation.value,
                child: Opacity(
                  opacity: _expandAnimation.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label
                      if (action.label != null)
                        Container(
                          margin:
                              const EdgeInsets.only(right: DesignTokens.space2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space3,
                            vertical: DesignTokens.space2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: DesignTokens.borderRadiusMD,
                            boxShadow: DesignTokens.shadowSM(Colors.black),
                          ),
                          child: Text(
                            action.label!,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeSM,
                              fontWeight: DesignTokens.fontWeightMedium,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),

                      // Button
                      FloatingActionButton.small(
                        onPressed: () {
                          HapticService.instance.light();
                          _toggle();
                          action.onTap();
                        },
                        backgroundColor: action.color,
                        elevation: 4,
                        child: Icon(
                          action.icon,
                          color: Colors.white,
                          size: DesignTokens.iconLG,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return children;
  }
}

/// FAB Action configuration
class FABAction {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color color;

  const FABAction({
    required this.icon,
    this.label,
    required this.onTap,
    this.color = const Color(0xFFFFA94A),
  });
}
