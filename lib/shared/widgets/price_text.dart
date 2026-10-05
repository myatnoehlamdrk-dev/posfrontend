import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';

String formatPrice(double value) => value.asCurrency('MMK');

/// A money amount that shrinks to fit rather than truncating.
///
/// The full string is always rendered; a [FittedBox] scales it down to whatever
/// width the parent grants. Truncating instead would turn `MMK 1,250,000` into
/// `MMK 1,250,0...`, which is worse than no number at all at a till.
///
/// Scaling only takes effect inside a bounded parent — a [SizedBox], [Expanded]
/// or [Flexible], or a column with a bounded width. In an unbounded [Row] the
/// text lays out at its natural size and the row is responsible for its own
/// overflow.
class PriceText extends StatelessWidget {
  final double price;
  final TextStyle? style;

  const PriceText(this.price, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final full = formatPrice(price);

    return GestureDetector(
      onTap: () => _showFullPrice(context, full),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(full, style: style, maxLines: 1, softWrap: false),
      ),
    );
  }

  /// Fallback for the one case scaling cannot solve: an amount so long that even
  /// scaled down it is unreadable at its rendered size.
  void _showFullPrice(BuildContext context, String full) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(
          full,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: AppTypography.titleMediumSize, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
