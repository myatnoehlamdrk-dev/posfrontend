import 'package:flutter/material.dart';

class RefreshableBody extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const RefreshableBody({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF2D1B69),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: child,
      ),
    );
  }
}
