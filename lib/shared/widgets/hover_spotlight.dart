import 'package:flutter/material.dart';

/// Mockup-style hover: a violet radial spotlight tracking the cursor, a -2px
/// lift, a violet border and a deeper glow. Wraps any card; on touch the
/// pointer never enters so the card keeps its resting state.
class HoverSpotlight extends StatefulWidget {
  final Widget child;
  final BorderRadius radius;
  final VoidCallback? onTap;

  const HoverSpotlight({
    super.key,
    required this.child,
    required this.radius,
    this.onTap,
  });

  @override
  State<HoverSpotlight> createState() => _HoverSpotlightState();
}

class _HoverSpotlightState extends State<HoverSpotlight> {
  Offset? _mouse;

  bool get _hovered => _mouse != null;

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: widget.radius,
        boxShadow: [
          BoxShadow(
            color: _hovered
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.transparent,
            blurRadius: _hovered ? 36 : 0,
            spreadRadius: _hovered ? -12 : 0,
            offset: Offset(0, _hovered ? 16 : 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          widget.child,
          // Border painted inside the stack so it never adds layout width —
          // a decoration border made each grid card 2px too wide and pushed
          // the finance/overview grids from two rows into three.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: widget.radius,
                  border: Border.all(
                    color: _hovered
                        ? const Color(0x478B5CF6)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          if (_hovered)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth.isFinite && c.maxWidth > 0
                      ? c.maxWidth
                      : 1.0;
                  final h = c.maxHeight.isFinite && c.maxHeight > 0
                      ? c.maxHeight
                      : 1.0;
                  final cx = ((_mouse!.dx / w) * 2 - 1).clamp(-1.0, 1.0);
                  final cy = ((_mouse!.dy / h) * 2 - 1).clamp(-1.0, 1.0);
                  return IgnorePointer(
                    child: ClipRRect(
                      borderRadius: widget.radius,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(cx, cy),
                            radius: 0.55,
                            colors: const [
                              Color(0x167C3AED),
                              Color(0x007C3AED),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );

    card = MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (e) => setState(() => _mouse = e.localPosition),
      onHover: (e) {
        if (_mouse != e.localPosition) {
          setState(() => _mouse = e.localPosition);
        }
      },
      onExit: (_) => setState(() => _mouse = null),
      child: card,
    );

    if (widget.onTap != null) {
      card = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: card,
      );
    }
    return card;
  }
}
