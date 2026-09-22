import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';

class CategoryTile extends StatelessWidget {
  final CatalogProductView product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CategoryTile({
    super.key,
    required this.product,
    this.onTap,
    this.onLongPress,
  });

  static const Color _titleColor = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF3F4F6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallback(),
                        )
                      : _fallback(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _titleColor,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            product.color.withValues(alpha: 0.85),
            product.color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(product.icon, color: Colors.white, size: 28),
      ),
    );
  }
}
