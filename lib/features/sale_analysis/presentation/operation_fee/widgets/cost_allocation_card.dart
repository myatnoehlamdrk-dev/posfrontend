import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee_models.dart';
import '../operation_fee_style.dart';

/// Right-hand card: allocation strategy plus a worked product example.
class CostAllocationCard extends StatelessWidget {
  final AllocationMethod selected;
  final ValueChanged<AllocationMethod> onChanged;

  /// Real preview data for the selected month and allocation method.
  final OperationFeeProductImpact? impact;
  final bool impactLoading;
  final String? impactError;

  /// Opens the product picker so the preview can follow any product.
  final VoidCallback? onChooseProduct;

  const CostAllocationCard({
    super.key,
    required this.selected,
    required this.onChanged,
    this.impact,
    this.impactLoading = false,
    this.impactError,
    this.onChooseProduct,
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
                      style: ofText(size: 11.5, color: p.textSecondary),
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
          ProductImpactPreview(
            selected: selected,
            impact: impact,
            isLoading: impactLoading,
            error: impactError,
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onChooseProduct,
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
                  'Choose product',
                  style: ofText(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.search, size: 16),
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
            color: selected ? p.primary.withValues(alpha: 0.45) : p.border,
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
                    style: ofText(size: 11, color: p.textSecondary),
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
  /// The basis the preview is currently showing: revenue, units sold or gross
  /// profit. The month's total fee does not change with it; only this
  /// product's allocated share and the figures on show do.
  final AllocationMethod selected;

  /// Real figures from the backend; null means no product was sold in the
  /// selected month (or the request has not finished yet).
  final OperationFeeProductImpact? impact;
  final bool isLoading;
  final String? error;

  const ProductImpactPreview({
    super.key,
    required this.selected,
    this.impact,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: p.chipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  selected.label,
                  style: ofText(
                    size: 9.5,
                    weight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _body(context),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final p = context.palette;

    if (isLoading && impact == null) {
      return _message(p, 'Calculating from this month\'s sales…');
    }

    if (error != null) {
      return _message(p, error!, isError: true);
    }

    final data = impact;

    if (data == null) {
      return _message(
        p,
        'No product sales in this month yet, so there is nothing to allocate.',
      );
    }

    final keptPercent = switch (selected) {
      AllocationMethod.revenue => _percentOf(data.revenue, data.allocatedFee),
      AllocationMethod.grossProfit => _percentOf(
        data.grossProfit,
        data.allocatedFee,
      ),
      AllocationMethod.unitsSold => data.trueMargin,
    };

    final chipLabel = switch (selected) {
      AllocationMethod.revenue => 'Revenue kept after fee',
      AllocationMethod.grossProfit => 'Profit kept after fee',
      AllocationMethod.unitsSold => 'True profit margin',
    };

    // A negative "kept" figure is a loss. Showing it in the success palette
    // would read as "profitable" at a glance, so the chip flips to danger.
    final isLoss = keptPercent < 0;
    final chipBg = isLoss ? p.dangerBg : p.successBg;
    final chipFg = isLoss ? p.dangerFg : p.successFg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                    data.name,
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
                    data.sku.isEmpty
                        ? _unitsLabel(data)
                        : 'SKU: ${data.sku} · ${_unitsLabel(data)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ofText(size: 10.5, color: p.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._figures(p, data),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                chipLabel,
                style: ofText(
                  size: 11.5,
                  weight: FontWeight.w500,
                  color: chipFg,
                ),
              ),
              const Spacer(),
              Text(
                '${keptPercent.toStringAsFixed(1)}%',
                style: ofText(size: 13, weight: FontWeight.w700, color: chipFg),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Month operation fee ${ofMoney(data.monthlyFee)}. The total is the '
          'same for every basis; this product carries '
          '${ofMoney(data.allocatedFee)} under '
          '${selected.label.toLowerCase()}.',
          style: ofText(size: 10.5, color: p.textMuted, height: 1.35),
        ),
        if (!data.hasSales) ...[
          const SizedBox(height: 10),
          Text(
            'No sales this month, so no operation fee is allocated to this '
            'product. The figures show price and cost only.',
            style: ofText(size: 10.5, color: p.textMuted, height: 1.35),
          ),
        ],
      ],
    );
  }

  /// The rows that change with the selected allocation basis.
  List<Widget> _figures(AppPalette p, OperationFeeProductImpact data) {
    switch (selected) {
      case AllocationMethod.revenue:
        return [
          _BreakdownRow(label: 'Product revenue', value: ofMoney(data.revenue)),
          const SizedBox(height: 6),
          _BreakdownRow(
            label: 'Operation fee cost',
            value: '- ${ofMoney(data.allocatedFee)}',
            valueColor: p.accentText,
          ),
          const SizedBox(height: 10),
          const _DashedDivider(),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: 'Revenue after fee',
            value: ofMoney(data.revenue - data.allocatedFee),
            valueColor: data.revenue - data.allocatedFee < 0
                ? p.dangerFg
                : null,
            bold: true,
          ),
        ];
      case AllocationMethod.grossProfit:
        return [
          _BreakdownRow(
            label: 'Product gross profit',
            value: ofMoney(data.grossProfit),
          ),
          const SizedBox(height: 6),
          _BreakdownRow(
            label: 'Operation fee cost',
            value: '- ${ofMoney(data.allocatedFee)}',
            valueColor: p.accentText,
          ),
          const SizedBox(height: 10),
          const _DashedDivider(),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: 'Profit after fee',
            value: ofMoney(data.grossProfit - data.allocatedFee),
            valueColor: data.grossProfit - data.allocatedFee < 0
                ? p.dangerFg
                : null,
            bold: true,
          ),
        ];
      case AllocationMethod.unitsSold:
        return [
          _BreakdownRow(
            label: 'Sell price / unit',
            value: ofMoney(data.unitSellingPrice),
          ),
          const SizedBox(height: 6),
          _BreakdownRow(
            label: 'Buy price / unit',
            value: ofMoney(data.unitCost),
          ),
          const SizedBox(height: 6),
          _BreakdownRow(
            label: 'Fee / unit',
            value: '+ ${ofMoney(data.unitAllocatedFee)}',
            valueColor: p.accentText,
          ),
          const SizedBox(height: 10),
          const _DashedDivider(),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: 'True cost / unit',
            value: ofMoney(data.trueUnitCost),
            valueColor: data.trueUnitCost > data.unitSellingPrice
                ? p.dangerFg
                : null,
            bold: true,
          ),
        ];
    }
  }

  /// Share of [base] left after [fee], as a percentage. A non-positive base
  /// has nothing to keep, so it reports zero rather than dividing by it.
  double _percentOf(double base, double fee) {
    if (base <= 0) return 0;
    return (base - fee) / base * 100;
  }

  String _unitsLabel(OperationFeeProductImpact data) {
    return data.hasSales
        ? '${ofCount(data.units)} units sold'
        : 'No sales this month';
  }

  Widget _message(AppPalette p, String text, {bool isError = false}) {
    final color = isError ? p.dangerFg : p.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: ofText(size: 11.5, color: color, height: 1.35),
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
