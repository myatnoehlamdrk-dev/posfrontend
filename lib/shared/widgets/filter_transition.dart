import 'package:flutter/material.dart';

/// Short fade + sideways slide whenever a list's filter changes.
///
/// Filter strips swap their whole body (All / Sold / Order, System / Alert /
/// News, …). Without a transition that swap is a hard cut, which reads as a
/// flicker on desktop. Keying the child by the active filter lets
/// [AnimatedSwitcher] cross-fade the two lists while the old one slides out and
/// the new one settles in.
class FilterTransition extends StatelessWidget {
  /// Changing this value starts the transition.
  final Object filterKey;

  final Widget child;

  const FilterTransition({
    super.key,
    required this.filterKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        // Scroll views need the switcher's full height; StackFit.loose (the
        // default) hands them loose constraints and collapses the list.
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          ...previousChildren,
          ?currentChild,
        ],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.035, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(filterKey), child: child),
    );
  }
}
