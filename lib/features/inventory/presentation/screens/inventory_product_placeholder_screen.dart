import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Placeholder screen shown from the inventory row's "View details" action.
/// Real product detail wiring will replace this later.
class InventoryProductPlaceholderScreen extends StatelessWidget {
  final String productId;
  const InventoryProductPlaceholderScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffoldBg,
      appBar: AppBar(
        title: Text(context.l10n.t('Product details')),
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 56, color: p.textMuted),
              const SizedBox(height: 16),
              Text(
                context.l10n.t('Product details coming soon.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: p.textSecondary),
              ),
              if (productId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  productId,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: p.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}