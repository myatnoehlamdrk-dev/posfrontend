import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';

String formatPrice(double value) => value.asCurrency('MMK');

class PriceText extends StatelessWidget {
  final double price;
  final TextStyle? style;
  final int maxLength;

  const PriceText(
    this.price, {
    super.key,
    this.style,
    this.maxLength = 12,
  });

  @override
  Widget build(BuildContext context) {
    final full = formatPrice(price);
    final display =
        full.length > maxLength ? '${full.substring(0, maxLength)}...' : full;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Text(
              full,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
      child: Text(display, style: style),
    );
  }
}
