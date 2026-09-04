import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(Icons.remove, () => onChanged(quantity - 1)),
          SizedBox(
            width: width,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          _qtyBtn(Icons.add, () => onChanged(quantity + 1)),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Icon(icon, size: iconSize, color: AppColors.gray),
      ),
    );
  }
}
