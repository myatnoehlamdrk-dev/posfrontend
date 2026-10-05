import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// The grey blocks that make up a loading placeholder.
///
/// Split from [SkeletonSweep] on purpose. A dashboard placeholder is fifty-odd
/// blocks; giving each its own ticking controller would mean fifty animations
/// per frame for a screen that is on display for a second. So the blocks are
/// inert, and one sweep travels over the whole group from [SkeletonSweep].
///
/// Fills come from the palette instead of literals so a placeholder still reads
/// as a placeholder when the till is running in dark mode.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.chipBg,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    if (padding == null) return block;
    return Padding(padding: padding!, child: block);
  }
}

/// The card treatment the dashboard uses for every panel: surface fill, hairline
/// border, 16px radius. No shadow, because a shadow under a block that is
/// standing in for a card reads as a smudge.
class SkeletonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Overrides the hairline colour. Pass [Colors.transparent] to drop the
  /// outline entirely, for a placeholder standing in for a card that is itself
  /// borderless — a bordered placeholder would be a visible jump when the real
  /// card replaced it.
  final Color? borderColor;

  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
    this.radius = 16,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final outline = borderColor ?? p.border;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(radius),
        // Omitted rather than painted transparent so the placeholder costs no
        // paint when the card it stands in for has no outline.
        border: outline.a == 0 ? null : Border.all(color: outline),
      ),
      child: child,
    );
  }
}

/// Hairline for a screen that draws a real `Divider` between blocks. Uses the
/// `border` token rather than [SkeletonBox]'s `chipBg` so the weight matches
/// the one it stands in for.
class SkeletonDivider extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const SkeletonDivider({super.key, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(height: 1, color: context.palette.border),
    );
  }
}

/// A band of light travelling diagonally across a group of [SkeletonBox]es.
///
/// One controller for the whole group rather than one per block, and painted as
/// an overlay rather than a recolour. That distinction matters: tinting the
/// subtree with the sweep gradient would flatten every opaque pixel to the same
/// colour, so the card fill and the block inside it would stop being
/// distinguishable and the placeholder would read as a flat smear instead of a
/// layout. Overlaying leaves the geometry alone and just says "wait".
///
/// Honours the platform's reduce-motion setting by standing still, which is
/// what that setting asks for.
class SkeletonSweep extends StatefulWidget {
  final Widget child;

  const SkeletonSweep({super.key, required this.child});

  @override
  State<SkeletonSweep> createState() => _SkeletonSweepState();
}

class _SkeletonSweepState extends State<SkeletonSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Null until the first dependency read, so the initial state is never
  /// mistaken for "already configured the same way" and skipped.
  bool? _still;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (still == _still) return;
    _still = still;
    if (still) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_still!)
          Positioned.fill(
            key: const ValueKey('skeleton-sweep-overlay'),
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    // Sweeps well past both edges before wrapping, so the band
                    // never appears to pop back in at the near side.
                    final x = -2.0 + 4.0 * _controller.value;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(x - 0.3, -1),
                          end: Alignment(x + 0.3, 1),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
