import 'package:flutter/material.dart';

String formatPrice(double value) {
  final whole = value.round();
  final neg = whole < 0;
  final digits = whole.abs().toString();
  final withCommas = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return 'MMK ${neg ? '-' : ''}$withCommas';
}

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
