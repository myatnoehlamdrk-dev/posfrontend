import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class RefreshableBody extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final ScrollController? scrollController;

  /// Stretches [child] to at least the height of the viewport.
  ///
  /// A `SingleChildScrollView` hands its child unbounded height, so a `Center`
  /// inside one does not center on screen — it collapses to the size of its
  /// child and lands at the top. Giving the content a floor of one viewport is
  /// what makes an empty state actually appear in the middle.
  ///
  /// Off by default, because a page of real content is usually taller than the
  /// viewport and must be free to grow past it.
  final bool fill;

  const RefreshableBody({
    super.key,
    required this.onRefresh,
    required this.child,
    this.scrollController,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: p.primary,
      backgroundColor: p.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Unbounded height here would make BoxConstraints throw, and a
          // stretched child is not possible anyway, so fall back to plain.
          final content = fill && constraints.hasBoundedHeight
              ? ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: child,
                )
              : child;

          return SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: content,
          );
        },
      ),
    );
  }
}
