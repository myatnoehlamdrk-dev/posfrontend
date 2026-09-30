import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class QuantityControl extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final double width;
  final double height;
  final double iconSize;

  const QuantityControl({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.width = 32,
    this.height = 32,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(context, Icons.remove, () => onChanged(quantity - 1)),
          SizedBox(
            width: width,
            child: Center(
              child: Text(
                context.l10n
                    .t('{v1}')
                    .replaceAll('{v1}', (quantity).toString()),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _qtyBtn(context, Icons.add, () => onChanged(quantity + 1)),
        ],
      ),
    );
  }

  Widget _qtyBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Icon(icon, size: iconSize, color: p.textSecondary),
      ),
    );
  }
}
