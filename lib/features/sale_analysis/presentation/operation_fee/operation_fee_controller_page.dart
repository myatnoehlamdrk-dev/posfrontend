import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

import '../widgets/month_filter_button.dart';
import 'operation_fee_models.dart';
import 'operation_fee_style.dart';
import 'widgets/add_fee_dialog.dart';
import 'widgets/cost_allocation_card.dart';
import 'widgets/fee_rules_card.dart';
import 'widgets/financial_insight_banner.dart';
import 'widgets/summary_cards.dart';

/// Operation Fee Controller — tracks the running costs that sit outside the
/// buy/sell price of a product so the shop can see its true margin.
///
/// Content only: no drawer, app bar, or bottom navigation. The sale-analysis
/// screen hosts this page inside its "Operation Fee" tab.
class OperationFeeControllerPage extends StatefulWidget {
  const OperationFeeControllerPage({super.key});

  @override
  State<OperationFeeControllerPage> createState() =>
      _OperationFeeControllerPageState();
}

class _OperationFeeControllerPageState
    extends State<OperationFeeControllerPage> {
  static const double _monthlyRevenue = 48240;
  static const int _totalOrders = 1264;
  static const double _marginBeforeFees = 39.8;

  late List<OperationFee> _fees;
  final Map<String, TextEditingController> _rateControllers = {};

  AllocationMethod _allocation = AllocationMethod.revenue;

  /// The fee rules are the same every month, so the picker only scopes the
  /// period being reviewed. It opens on November 2026, like the sibling tabs.
  DateTime _month = DateTime(2026, 11);
  static final DateTime _firstMonth = DateTime(2026, 1, 1);
  static final DateTime _lastMonth = DateTime(2026, 12, 31);
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _fees = List<OperationFee>.of(defaultOperationFees);
    for (final fee in _fees) {
      _rateControllers[fee.id] = TextEditingController(text: ofRate(fee.rate));
    }
  }

  @override
  void dispose() {
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- totals

  double get _operatingCosts => _fees.fold(
        0,
        (sum, fee) => sum +
            fee.monthlyCost(revenue: _monthlyRevenue, orders: _totalOrders),
      );

  double get _operatingRatio => _operatingCosts / _monthlyRevenue * 100;

  double get _costPerOrder => _operatingCosts / _totalOrders;

  double get _trueMargin => _marginBeforeFees - _operatingRatio;

  int get _activeCount => _fees.where((f) => f.isActive).length;

  // ---------------------------------------------------------------- edits

  void _replaceFee(OperationFee updated) {
    setState(() {
      final index = _fees.indexWhere((f) => f.id == updated.id);
      if (index != -1) _fees[index] = updated;
    });
  }

  void _onActiveChanged(OperationFee fee, bool active) {
    _replaceFee(fee.copyWith(isActive: active));
  }

  void _onCalculationChanged(OperationFee fee, FeeCalculation method) {
    _replaceFee(fee.copyWith(calculation: method));
  }

  void _onRateChanged(OperationFee fee, String text) {
    final parsed = double.tryParse(text.replaceAll(',', '')) ?? 0;
    _replaceFee(fee.copyWith(rate: parsed));
  }

  void _deleteFee(OperationFee fee) {
    final controller = _rateControllers.remove(fee.id);
    setState(() => _fees.removeWhere((f) => f.id == fee.id));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller?.dispose();
    });
    showSuccessMessage(context, 'Operation fee deleted');
  }

  // ---------------------------------------------------------------- actions

  void _handleSave() {
    showSuccessMessage(context, 'Fee rules saved successfully');
    setState(() => _saved = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: _firstMonth,
      lastDate: _lastMonth,
      helpText: 'Select a month',
    );
    if (picked != null && mounted) {
      setState(() => _month = DateTime(picked.year, picked.month));
    }
  }

  Future<void> _openAddFee({required bool asSheet}) async {
    final OperationFee? created;
    if (asSheet) {
      created = await showModalBottomSheet<OperationFee>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: const SafeArea(
            top: false,
            child: AddFeeDialog(asSheet: true),
          ),
        ),
      );
    } else {
      created = await showDialog<OperationFee>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(24),
          child: AddFeeDialog(),
        ),
      );
    }

    if (created == null || !mounted) return;
    final OperationFee fee = created;
    _rateControllers[fee.id] =
        TextEditingController(text: ofRate(fee.rate));
    setState(() => _fees.add(fee));
    showSuccessMessage(context, 'Operation fee added');
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      color: p.scaffoldBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 1100;
          final isTablet = width >= 700;
          final pagePadding = isDesktop
              ? 32.0
              : isTablet
                  ? 24.0
                  : 16.0;
          final summaryColumns = isDesktop
              ? 4
              : isTablet
                  ? 2
                  : 1;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              pagePadding,
              pagePadding,
              pagePadding,
              pagePadding + 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _pageHeading(
                      p: p,
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    const SizedBox(height: 20),
                    SummaryCardsGrid(
                      columns: summaryColumns,
                      revenue: _monthlyRevenue,
                      operatingCosts: _operatingCosts,
                      operatingRatio: _operatingRatio,
                      costPerOrder: _costPerOrder,
                      totalOrders: _totalOrders,
                      marginBeforeFees: _marginBeforeFees,
                      trueMargin: _trueMargin,
                    ),
                    const SizedBox(height: 16),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: _feeRulesCard(
                            useTable: true,
                          )),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: CostAllocationCard(
                              selected: _allocation,
                              onChanged: (method) =>
                                  setState(() => _allocation = method),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _feeRulesCard(useTable: isTablet),
                          const SizedBox(height: 16),
                          CostAllocationCard(
                            selected: _allocation,
                            onChanged: (method) =>
                                setState(() => _allocation = method),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    FinancialInsightBanner(compact: !isTablet),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _feeRulesCard({required bool useTable}) {
    return FeeRulesCard(
      fees: _fees,
      rateControllers: _rateControllers,
      useTable: useTable,
      activeCount: _activeCount,
      total: _operatingCosts,
      revenue: _monthlyRevenue,
      orders: _totalOrders,
      onAddFee: () => _openAddFee(asSheet: !useTable),
      onActiveChanged: _onActiveChanged,
      onCalculationChanged: _onCalculationChanged,
      onRateChanged: _onRateChanged,
      onDelete: _deleteFee,
    );
  }

  Widget _pageHeading({
    required AppPalette p,
    required bool isDesktop,
    required bool isTablet,
  }) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operation fee controller',
          style: ofText(
            size: 27,
            weight: FontWeight.w700,
            color: p.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Track the costs beyond buying and selling, and see your real margin.',
          style: ofText(
            size: 13,
            color: p.textSecondary,
          ),
        ),
      ],
    );

    final monthButton = MonthFilterButton(
      month: _month,
      onPressed: _pickMonth,
    );

    final saveButton = _SaveButton(
      saved: _saved,
      onPressed: _handleSave,
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titleBlock),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              monthButton,
              const SizedBox(width: 10),
              saveButton,
            ],
          ),
        ],
      );
    }

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: titleBlock),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              monthButton,
              const SizedBox(height: 8),
              saveButton,
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        titleBlock,
        const SizedBox(height: 16),
        monthButton,
        const SizedBox(height: 10),
        saveButton,
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onPressed;

  const _SaveButton({required this.saved, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (saved) ...[
            const Icon(Icons.check, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            saved ? 'Saved' : 'Save changes',
            style: ofText(
              size: 12.5,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
