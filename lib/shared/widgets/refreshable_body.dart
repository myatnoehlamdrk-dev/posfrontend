import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class RefreshableBody extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final ScrollController? scrollController;

  const RefreshableBody({
    super.key,
    required this.onRefresh,
    required this.child,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: p.primary,
      backgroundColor: p.surface,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: child,
      ),
    );
  }
}
