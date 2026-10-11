import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_item_entity.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

class CartItemRow extends StatelessWidget {
  final CartItemEntity item;
  final bool dense;

  const CartItemRow({super.key, required this.item, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final img = 36.0;
    final nameSize = dense ? 12.5 : 14.0;
    // The teal price sits on a card, so it needs lifting in dark to keep
    // contrast; AppColors.teal is the light-mode value.
    final priceColor = context.isDark
        ? const Color(0xFF5EEAD4)
        : const Color(0xFF0F766E);
    return Row(
      children: [
        Container(
          width: img,
          height: img,
          decoration: BoxDecoration(
            color: p.chipBg,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.imageUrl != null
              ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.inventory_2, color: p.textMuted, size: 18),
                )
              : Icon(Icons.inventory_2, color: p.textMuted, size: 18),
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
                  color: p.textPrimary,
                ),
              ),
              if (item.variantLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.tune, size: 11, color: p.textMuted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        item.variantLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 2),
              Text(
                context.l10n
                    .t('{v1} x {v2}')
                    .replaceAll('{v1}', item.unitPrice.withCommas())
                    .replaceAll('{v2}', (item.quantity).toString()),
                style: TextStyle(fontSize: 11, color: p.textSecondary),
              ),
            ],
          ),
        ),
        PriceText(
          item.subtotal,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: priceColor,
          ),
        ),
      ],
    );
  }
}
