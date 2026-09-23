import 'package:flutter/material.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_item_entity.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

class CartItemRow extends StatelessWidget {
  final CartItemEntity item;
  final bool dense;

  const CartItemRow({
    super.key,
    required this.item,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final img = 36.0;
    final nameSize = dense ? 12.5 : 14.0;
    return Row(
      children: [
        Container(
          width: img,
          height: img,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.imageUrl != null
              ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.inventory_2, color: Colors.grey[400], size: 18),
                )
              : Icon(Icons.inventory_2, color: Colors.grey[400], size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: nameSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              if (item.variantLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.tune, size: 11, color: Color(0xFF6B7280)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        item.variantLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 2),
              Text(
                '${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        PriceText(
          item.subtotal,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F766E),
          ),
        ),
      ],
    );
  }
}