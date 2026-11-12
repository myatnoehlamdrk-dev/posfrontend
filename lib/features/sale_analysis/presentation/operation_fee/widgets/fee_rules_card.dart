import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee_models.dart';
import '../operation_fee_style.dart';

/// White card holding the fee-rule table (wide) or stacked rule cards (narrow).
class FeeRulesCard extends StatelessWidget {
  final List<OperationFee> fees;
  final Map<String, TextEditingController> rateControllers;
  final bool useTable;
  final int activeCount;
  final double total;
  final double revenue;
  final int orders;
  final VoidCallback onAddFee;
  final void Function(OperationFee fee, bool active) onActiveChanged;
  final void Function(OperationFee fee, FeeCalculation method)
      onCalculationChanged;
  final void Function(OperationFee fee, String text) onRateChanged;
  final void Function(OperationFee fee) onDelete;

  const FeeRulesCard({
    super.key,
    required this.fees,
    required this.rateControllers,
    required this.useTable,
    required this.activeCount,
    required this.total,
    required this.revenue,
    required this.orders,
    required this.onAddFee,
    required this.onActiveChanged,
    required this.onCalculationChanged,
    required this.onRateChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: ofCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fee rules',
                        style: ofText(
                          size: 16,
                          weight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$activeCount active ${activeCount == 1 ? 'fee' : 'fees'} applied this month',
                        style: ofText(
                          size: 11.5,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onAddFee,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    'Add fee',
                    style: ofText(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.textPrimary,
                    side: BorderSide(color: p.border),
                    backgroundColor: p.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (useTable) ...[
            const _TableHeader(),
            for (final fee in fees) _FeeRuleRow(
              fee: fee,
              rateController: rateControllers[fee.id],
              revenue: revenue,
              orders: orders,
              onActiveChanged: onActiveChanged,
              onCalculationChanged: onCalculationChanged,
              onRateChanged: onRateChanged,
              onDelete: onDelete,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  for (final fee in fees)
                    FeeRuleMobileCard(
                      fee: fee,
                      rateController: rateControllers[fee.id],
                      revenue: revenue,
                      orders: orders,
                      onActiveChanged: onActiveChanged,
                      onCalculationChanged: onCalculationChanged,
                      onRateChanged: onRateChanged,
                      onDelete: onDelete,
                    ),
                ],
              ),
            ),
          _FeeFooter(total: total),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = ofText(
      size: 10.5,
      weight: FontWeight.w600,
      color: p.textMuted,
      letterSpacing: 0.3,
    );
    return Container(
      color: p.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 44),
          const SizedBox(width: 44),
          Expanded(flex: 3, child: Text('FEE NAME', style: style)),
          SizedBox(width: 150, child: Text('CALCULATION', style: style)),
          SizedBox(
            width: 112,
            child: Text('RATE', style: style),
          ),
          SizedBox(
            width: 108,
            child: Text(
              'MONTHLY COST',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _FeeRuleRow extends StatelessWidget {
  final OperationFee fee;
  final TextEditingController? rateController;
  final double revenue;
  final int orders;
  final void Function(OperationFee fee, bool active) onActiveChanged;
  final void Function(OperationFee fee, FeeCalculation method)
      onCalculationChanged;
  final void Function(OperationFee fee, String text) onRateChanged;
  final void Function(OperationFee fee) onDelete;

  const _FeeRuleRow({
    required this.fee,
    required this.rateController,
    required this.revenue,
    required this.orders,
    required this.onActiveChanged,
    required this.onCalculationChanged,
    required this.onRateChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cost = fee.monthlyCost(revenue: revenue, orders: orders);
    final tint = feeTintFor(context, fee.tint);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Opacity(
        opacity: fee.isActive ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  child: Switch(
                    value: fee.isActive,
                    onChanged: (v) => onActiveChanged(fee, v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: p.primary,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: p.chipBg,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OfIconChip(
                    icon: feeIconFor(fee.icon),
                    background: tint.$1,
                    foreground: tint.$2,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ofText(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fee.category.label,
                      style: ofText(size: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: _CalculationDropdown(
                  value: fee.calculation,
                  onChanged: (m) => onCalculationChanged(fee, m),
                ),
              ),
              SizedBox(
                width: 112,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _RateField(
                    controller: rateController,
                    calculation: fee.calculation,
                    onChanged: (v) => onRateChanged(fee, v),
                  ),
                ),
              ),
              SizedBox(
                width: 108,
                child: Text(
                  ofMoney(cost),
                  textAlign: TextAlign.right,
                  style: ofText(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: _FeeMenu(
                  color: p.textMuted,
                  onDelete: () => onDelete(fee),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Narrow-screen version of a rule: same controls, stacked.
class FeeRuleMobileCard extends StatelessWidget {
  final OperationFee fee;
  final TextEditingController? rateController;
  final double revenue;
  final int orders;
  final void Function(OperationFee fee, bool active) onActiveChanged;
  final void Function(OperationFee fee, FeeCalculation method)
      onCalculationChanged;
  final void Function(OperationFee fee, String text) onRateChanged;
  final void Function(OperationFee fee) onDelete;

  const FeeRuleMobileCard({
    super.key,
    required this.fee,
    required this.rateController,
    required this.revenue,
    required this.orders,
    required this.onActiveChanged,
    required this.onCalculationChanged,
    required this.onRateChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cost = fee.monthlyCost(revenue: revenue, orders: orders);
    final tint = feeTintFor(context, fee.tint);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Opacity(
        opacity: fee.isActive ? 1 : 0.45,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 42,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Switch(
                      value: fee.isActive,
                      onChanged: (v) => onActiveChanged(fee, v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: p.primary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: p.chipBg,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                OfIconChip(
                  icon: feeIconFor(fee.icon),
                  background: tint.$1,
                  foreground: tint.$2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ofText(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fee.category.label,
                        style: ofText(size: 11, color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                _FeeMenu(
                  color: p.textMuted,
                  onDelete: () => onDelete(fee),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CalculationDropdown(
                    value: fee.calculation,
                    onChanged: (m) => onCalculationChanged(fee, m),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: _RateField(
                    controller: rateController,
                    calculation: fee.calculation,
                    onChanged: (v) => onRateChanged(fee, v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Monthly cost',
                  style: ofText(size: 11.5, color: p.textMuted),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    ofMoney(cost),
                    style: ofText(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculationDropdown extends StatelessWidget {
  final FeeCalculation value;
  final ValueChanged<FeeCalculation> onChanged;

  const _CalculationDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FeeCalculation>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(8),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: p.textSecondary,
          ),
          style: ofText(size: 12.5, color: p.textPrimary),
          padding: const EdgeInsets.symmetric(vertical: 9),
          items: [
            for (final method in FeeCalculation.values)
              DropdownMenuItem(value: method, child: Text(method.label)),
          ],
          onChanged: (m) {
            if (m != null) onChanged(m);
          },
        ),
      ),
    );
  }
}

class _RateField extends StatelessWidget {
  final TextEditingController? controller;
  final FeeCalculation calculation;
  final ValueChanged<String> onChanged;

  const _RateField({
    required this.controller,
    required this.calculation,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: ofText(
          size: 12.5,
          weight: FontWeight.w500,
          color: p.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          prefixText: calculation.isPercentage ? null : 'MMK ',
          suffixText: calculation.isPercentage ? '%' : null,
          prefixStyle: ofText(size: 12, color: p.textMuted),
          suffixStyle: ofText(size: 12, color: p.textMuted),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _FeeMenu extends StatelessWidget {
  final Color color;
  final VoidCallback onDelete;

  const _FeeMenu({required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Fee options',
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert, size: 18, color: color),
      onSelected: (_) => onDelete(),
      itemBuilder: (context) {
        final p = context.palette;
        return [
          PopupMenuItem(
            value: 'delete',
            child: Text(
              'Delete fee',
              style: ofText(size: 12.5, color: p.textPrimary),
            ),
          ),
        ];
      },
    );
  }
}

class _FeeFooter extends StatelessWidget {
  final double total;
  const _FeeFooter({required this.total});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          Text(
            'Estimated monthly operation fees',
            style: ofText(size: 12, color: p.textSecondary),
          ),
          const SizedBox(width: 5),
          const OfInfoDot(size: 12),
          const Spacer(),
          Text(
            ofMoney(total),
            style: ofText(
              size: 15,
              weight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

IconData feeIconFor(FeeIcon icon) => switch (icon) {
      FeeIcon.premises => Icons.storefront_outlined,
      FeeIcon.transaction => Icons.credit_card,
      FeeIcon.fulfilment => Icons.inventory_2_outlined,
      FeeIcon.people => Icons.groups_outlined,
      FeeIcon.other => Icons.receipt_long_outlined,
    };

/// (background, foreground) pair for a fee icon chip, derived from the active
/// theme so the tints stay legible in both light and dark mode.
(Color, Color) feeTintFor(BuildContext context, FeeTint tint) {
  final p = context.palette;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final Color hue = switch (tint) {
    FeeTint.blue =>
      isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6),
    FeeTint.violet => isDark ? const Color(0xFFC4B5FD) : p.primary,
    FeeTint.orange =>
      isDark ? const Color(0xFFFDBA74) : const Color(0xFFD97706),
    FeeTint.green =>
      isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
    FeeTint.gray => p.textSecondary,
  };

  return (hue.withValues(alpha: 0.14), hue);
}
