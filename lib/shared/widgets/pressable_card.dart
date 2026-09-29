import 'package:flutter/material.dart';

/// Press physics for the few controls in a sale where a missed or doubled tap
/// actually costs something.
///
/// This is deliberately not a general replacement for [GestureDetector]. A till
/// is worked all day, and animating every tappable row teaches the hand to stop
/// reading the motion. So it is applied to the quantity steppers, the product
/// tile, and the two actions that commit a transaction: the taps that repeat
/// hundreds of times a shift, and the taps that move money.
///
/// Press-in is faster than press-out. That asymmetry is what makes a control
/// feel like it is answering rather than reporting: the shrink commits to the
/// touch before the finger has finished travelling, and the release is then
/// allowed to settle.
///
/// Haptics are opt-in per call site via [haptic], because a POS runs on tablets
/// and terminals where vibration is either absent, welcome, or actively
/// irritating depending on the counter, and the caller is the only thing that
/// knows which. Fire it on tap completion rather than press-down: it confirms
/// the action was accepted, and it stays silent when the gesture is cancelled by
/// a scroll.
///
/// Hit testing is opaque, so the full bounds of [child] are live even where it
/// is transparent. That is what lets this wrap a 24dp stepper button and still
/// give it a usable target.
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Called once the tap is accepted. Leave null for silent controls.
  final VoidCallback? haptic;

  /// How far in to shrink. Small controls need a larger relative dip to read.
  final double pressedScale;

  final Duration pressDuration;
  final Duration releaseDuration;

  /// Where the scale happens from, so a tall card can dip from its top edge.
  final Alignment alignment;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic,
    this.pressedScale = 0.97,
    this.pressDuration = const Duration(milliseconds: 80),
    this.releaseDuration = const Duration(milliseconds: 160),
    this.alignment = Alignment.center,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _fire(VoidCallback? action) {
    _setPressed(false);
    if (action == null) return;
    widget.haptic?.call();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final engaged = _enabled && _pressed;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null ? null : () => _fire(widget.onTap),
      onLongPress: widget.onLongPress == null
          ? null
          : () => _fire(widget.onLongPress),
      onTapDown: _enabled ? (_) => _setPressed(true) : null,
      onTapUp: _enabled ? (_) => _setPressed(false) : null,
      onTapCancel: _enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: engaged ? widget.pressedScale : 1.0,
        // Read at the moment the animation starts, which is what makes the
        // in-stroke quick and the out-stroke unhurried.
        duration: engaged ? widget.pressDuration : widget.releaseDuration,
        curve: Curves.easeOut,
        alignment: widget.alignment,
        child: widget.child,
      ),
    );
  }
}
