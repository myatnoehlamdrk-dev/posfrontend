import 'package:flutter/material.dart';

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
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF2D1B69),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: child,
      ),
    );
  }
}
