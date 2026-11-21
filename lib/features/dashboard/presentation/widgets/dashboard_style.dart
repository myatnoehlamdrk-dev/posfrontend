import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_text.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// The dashboard's visual language, kept in one place.
///
/// The screen had picked up three card treatments — token-based panels, a
/// `#12151E` dark KPI island that ignored the theme, and hand-rolled
/// `BoxDecoration`s — so the same page read as three different products
/// stitched together. These tokens give every card one surface, one radius and
/// one elevation, in both brightnesses.
abstract final class DashboardStyle {
  const DashboardStyle._();

  /// Cards and the hero container.
  static const double cardRadius = 20;

  /// Buttons, dropdowns, small controls.
  static const double controlRadius = AppRadius.md;

  /// The gap between cards and sections.
  static const double gap = 20;

  /// Keeps the bento from stretching across an ultrawide monitor.
  static const double maxContentWidth = 1560;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// The page wash: one soft violet bloom behind the top-right of the content,
  /// so the page has depth without turning into a gradient poster.
  static Gradient pageGlow(BuildContext context) {
    final p = context.palette;
    return RadialGradient(
      center: const Alignment(0.9, -1.1),
      radius: 1.35,
      colors: [
        p.primary.withValues(alpha: isDark(context) ? 0.14 : 0.06),
        p.scaffoldBg.withValues(alpha: 0),
      ],
      stops: const [0, 0.72],
    );
  }

  /// The hero card's violet wash. Dark mode keeps the deep plum it had; light
  /// mode uses a tint of the brand accent so the card still reads as the loud
  /// one on the page without painting a dark island on a white sheet.
  static Gradient heroGradient(BuildContext context) {
    final p = context.palette;
    if (isDark(context)) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF2E1065), p.surface],
        stops: const [0, 0.78],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.lerp(p.surface, p.primary, 0.14)!, p.surface],
      stops: const [0, 0.78],
    );
  }

  /// Resting card elevation. Dark mode relies on the border instead of a
  /// shadow, which is what `AppPalette.cardShadow` already encodes.
  static List<BoxShadow> cardShadow(BuildContext context) {
    final p = context.palette;
    if (isDark(context)) return const [];
    return [
      BoxShadow(
        color: p.cardShadow,
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ];
  }

  /// The lift a clickable card gets under the pointer.
  static List<BoxShadow> hoverShadow(BuildContext context) {
    final p = context.palette;
    if (isDark(context)) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];
    }
    return [
      BoxShadow(
        color: p.primary.withValues(alpha: 0.16),
        blurRadius: 26,
        offset: const Offset(0, 12),
      ),
    ];
  }
}

/// Lifts a card a few pixels under the pointer and deepens its shadow.
///
/// Only meaningful on desktop/web; on touch the pointer never enters, so the
/// card simply keeps its resting state. [enabled] lets a caller opt out for
/// static cards that should not invite a click.
class HoverLift extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final VoidCallback? onTap;

  const HoverLift({
    super.key,
    required this.child,
    this.enabled = true,
    this.onTap,
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && _hovered;

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      // The transform is what actually moves the card; the decoration only
      // contributes the shadow, so the card's own fill is not repainted.
      transform: Matrix4.translationValues(0, active ? -3 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DashboardStyle.cardRadius),
        boxShadow: active
            ? DashboardStyle.hoverShadow(context)
            : const <BoxShadow>[],
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: card,
        ),
      );
    }

    if (!widget.enabled) return card;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: card,
    );
  }
}

/// Fades and lifts a dashboard section in public, one beat after the section
/// above it.
///
/// The delay is folded into a single [Interval] over one animation instead of
/// a timer per section, so nothing has to be cancelled on dispose and a
/// rebuild in the middle of the reveal keeps the current value.
class DashboardReveal extends StatelessWidget {
  final Widget child;
  final int index;

  const DashboardReveal({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.06).clamp(0.0, 0.5);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: Transform.scale(
            scale: 0.92 + 0.08 * t,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Reveals a chart. Pass [grow] for charts that should rise from their baseline
/// (bars, area fills) and leave it false for rings and donuts, which scale in.
class ChartReveal extends StatelessWidget {
  final Widget child;
  final bool grow;
  final Duration duration;

  const ChartReveal({
    super.key,
    required this.child,
    this.grow = false,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        if (grow) {
          return ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: t.clamp(0.0, 1.0),
              child: child,
            ),
          );
        }
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
        );
      },
      child: child,
    );
  }
}

/// A quiet overline that groups the bento into readable chapters
/// ("Performance", "Inventory", …) instead of one undifferentiated stack.
class DashboardSectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const DashboardSectionLabel({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: appText(
            size: 11,
            weight: FontWeight.w700,
            color: p.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(child: Divider(height: 1, color: p.border)),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.s12),
          trailing!,
        ],
      ],
    );
  }
}

/// A square toolbar control that matches the dashboard's card treatment.
class DashboardIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const DashboardIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardStyle.controlRadius),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(DashboardStyle.controlRadius),
            border: Border.all(color: p.border),
          ),
          child: Icon(icon, size: AppIconSize.md, color: p.textSecondary),
        ),
      ),
    );
  }
}
