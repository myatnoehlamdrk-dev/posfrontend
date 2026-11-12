import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee_models.dart';
import '../operation_fee_style.dart';

/// Right-hand card: allocation strategy plus a worked product example.
class CostAllocationCard extends StatelessWidget {
  final AllocationMethod selected;
  final ValueChanged<AllocationMethod> onChanged;

  const CostAllocationCard({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ofCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost allocation',
                      style: ofText(
                        size: 16,
                        weight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Choose how fees affect products',
                      style: ofText(
                        size: 11.5,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OfIconChip(
                icon: Icons.tune,
                background: p.chipBg,
                foreground: p.textSecondary,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final method in AllocationMethod.values) ...[
            _AllocationOption(
              method: method,
              selected: method == selected,
              onTap: () => onChanged(method),
            ),
            if (method != AllocationMethod.values.last)
              const SizedBox(height: 8),
          ],
          const SizedBox(height: 20),
          const ProductImpactPreview(),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: p.textPrimary,
              side: BorderSide(color: p.border),
              backgroundColor: p.surface,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View product profitability',
                  style: ofText(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationOption extends StatelessWidget {
  final AllocationMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _AllocationOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? p.selectionTint : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? p.primary.withValues(alpha: 0.45)
                : p.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.surface,
                border: Border.all(
                  color: selected ? p.primary : p.borderStrong,
                  width: selected ? 4.5 : 1.3,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: ofText(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.description,
                    style: ofText(
                      size: 11,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductImpactPreview extends StatelessWidget {
  const ProductImpactPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const buyPrice = 38.0;
    const allocatedFee = 8.74;
    const sellingPrice = 89.0;
    const trueCost = buyPrice + allocatedFee;
    const trueMargin = (sellingPrice - trueCost) / sellingPrice * 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'PRODUCT IMPACT PREVIEW',
                style: ofText(
                  size: 10,
                  weight: FontWeight.w600,
                  color: p.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 4),
              const OfInfoDot(size: 12),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.chipBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 20,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Canvas Weekender',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ofText(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU: BAG-204',
                      style: ofText(
                        size: 10.5,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ofMoney(sellingPrice, digits: 0),
                style: ofText(
                  size: 13,
                  weight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BreakdownRow(label: 'Buy price', value: ofMoney(buyPrice)),
          const SizedBox(height: 6),
          _BreakdownRow(
            label: 'Allocated operation fee',
            value: '+ ${ofMoney(allocatedFee)}',
            valueColor: p.accentText,
          ),
          const SizedBox(height: 10),
          const _DashedDivider(),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: 'True cost',
            value: ofMoney(trueCost),
            bold: true,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.successBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'True profit margin',
                  style: ofText(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: p.successFg,
                  ),
                ),
                const Spacer(),
                Text(
                  '${trueMargin.toStringAsFixed(1)}%',
                  style: ofText(
                    size: 13,
                    weight: FontWeight.w700,
                    color: p.successFg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _BreakdownRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ofText(
              size: 11.5,
              color: p.textSecondary,
              weight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: ofText(
            size: 12,
            weight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? p.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 7).floor().clamp(1, 400);
        return Row(
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: 4,
                height: 1,
                margin: const EdgeInsets.only(right: 3),
                color: p.border,
              ),
          ],
        );
      },
    );
  }
}
