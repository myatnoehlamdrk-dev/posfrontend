import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

/// How the running rows are separated from the grand total.
enum TotalsDividerStyle { none, solid, dashed }

typedef MoneyFormatter = String Function(double value);

/// The checkout totals block, shared by every screen that totals a bill.
///
/// This replaced one copy in the new-sale summary card and another in the
/// invoice preview. They had drifted: one showed `Total Items` and a
/// `Discount Amount` row, the other showed neither; one coloured the total blue
/// and the other purple; one truncated prices through [PriceText] and the other
/// printed raw numbers. One implementation means the arithmetic on screen can no
/// longer disagree with itself.
///
/// The grand total is the hero: the supporting rows are quiet, and the amount
/// sits in its own tinted block at a size nothing else on the panel reaches.
/// That is deliberate — the number the cashier is asked to read out loud should
/// be the thing the eye lands on.
///
/// Deliberately draws no card of its own. The new-sale screen wraps it in a
/// card, the preview wraps it in the invoice sheet, and the cart bottom bar
/// wraps it in a bar; the panel supplies the rows, the caller supplies the
/// surface.
class TotalsPanel extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final double totalPayable;
  final double discountPercent;

  /// Renders a `Total Items` row when non-null.
  final int? itemCount;

  /// Replaces the read-only discount value with a control, such as the
  /// percentage field on the new-sale screen.
  ///
  /// Passing one switches the panel into edit mode: the percentage label is
  /// left bare (the control shows the number) and the discount amount gets its
  /// own row, because it no longer shares a line with anything.
  final Widget? discountEditor;

  /// Rendered below the grand total, e.g. a payment-method chip.
  final Widget? footer;

  /// Hide when the caller only wants the grand total.
  final bool showSubtotal;

  final TotalsDividerStyle divider;

  /// Roboto Mono, to match the invoice look. Off for the app UI.
  final bool mono;

  /// Set to [withCommas] to drop the currency prefix, as the invoice does.
  final MoneyFormatter format;

  final EdgeInsets padding;

  static const double _editorWidth = 96;

  const TotalsPanel({
    super.key,
    required this.subtotal,
    required this.discountAmount,
    required this.totalPayable,
    this.discountPercent = 0,
    this.itemCount,
    this.discountEditor,
    this.footer,
    this.showSubtotal = true,
    this.divider = TotalsDividerStyle.solid,
    this.mono = false,
    this.format = formatPrice,
    this.padding = const EdgeInsets.all(16),
  });

  bool get _isEditing => discountEditor != null;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (itemCount != null) ...[
            _row(context, 'Total Items', '${itemCount!}'),
            const SizedBox(height: 12),
          ],
          if (showSubtotal) ...[
            _row(context, 'Subtotal', format(subtotal)),
            const SizedBox(height: 12),
          ],
          if (_isEditing)
            _rowWith(
              context,
              'Discount',
              SizedBox(width: _editorWidth, child: discountEditor),
            )
          else if (discountPercent > 0)
            _row(
              context,
              'Discount (${discountPercent.asPercent()}%)',
              '-${format(discountAmount)}',
              valueColor: p.dangerFg,
            ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            _row(context, 'Discount Amount', format(discountAmount)),
          ],
          _divider(context),
          _hero(context),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }

  /// The grand total, set apart from the rows that produced it.
  Widget _hero(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p.selectionTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TOTAL PAYABLE',
            style: _type(11, FontWeight.w700, p.textSecondary).copyWith(
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          _amount(
            format(totalPayable),
            color: p.primary,
            size: 28,
            weight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final color = context.palette.border;

    switch (divider) {
      case TotalsDividerStyle.none:
        return const SizedBox.shrink();
      case TotalsDividerStyle.solid:
        return Divider(height: 33, thickness: 1, color: color);
      case TotalsDividerStyle.dashed:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _DashedDivider(color: color),
        );
    }
  }

  /// Label left, value right. The label takes the leftover width and the value
  /// keeps its natural width unless the two together would overflow, in which
  /// case [Flexible] lets the amount scale down instead of the label wrapping.
  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return _rowWith(
      context,
      label,
      _amount(value, color: valueColor ?? context.palette.textPrimary),
    );
  }

  Widget _rowWith(BuildContext context, String label, Widget value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _type(14, FontWeight.w400, context.palette.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(child: value),
      ],
    );
  }

  /// Money, sized to fit its slot instead of being cut off.
  Widget _amount(
    String text, {
    required Color color,
    double size = 14,
    FontWeight weight = FontWeight.w600,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: _type(size, weight, color),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }

  TextStyle _type(double size, FontWeight weight, Color color) => mono
      ? GoogleFonts.robotoMono(fontSize: size, fontWeight: weight, color: color)
      : TextStyle(fontSize: size, fontWeight: weight, color: color);
}

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: ColoredBox(color: color),
            ),
          ),
        );
      },
    );
  }
}
