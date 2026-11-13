import 'package:flutter/material.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/operation_fee_models.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/operation_fee_style.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/add_fee_dialog.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/cost_allocation_card.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/fee_rules_card.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/financial_insight_banner.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/summary_cards.dart';
import 'package:posfrontend/features/sale_analysis/presentation/viewmodels/finance_view_model.dart';
import 'package:posfrontend/features/sale_analysis/presentation/viewmodels/operation_fee_view_model.dart';
import 'package:posfrontend/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/month_filter_button.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class OperationFeeControllerPage extends StatefulWidget {
  const OperationFeeControllerPage({super.key});

  @override
  State<OperationFeeControllerPage> createState() =>
      _OperationFeeControllerPageState();
}

class _OperationFeeControllerPageState
    extends State<OperationFeeControllerPage> {
  static const double _marginBeforeFees = 39.8;

  late final OperationFeeViewModel _feeVm;
  late final FinanceViewModel _financeVm;

  late List<OperationFee> _fees;
  final Map<String, TextEditingController> _rateControllers = {};

  AllocationMethod _allocation = AllocationMethod.revenue;

  DateTime _month = DateTime(2026, 11);
  static final DateTime _firstMonth = DateTime(2026, 1, 1);
  static final DateTime _lastMonth = DateTime(2026, 12, 31);

  @override
  void initState() {
    super.initState();
    _feeVm = OperationFeeViewModel();
    _financeVm = FinanceViewModel(repository: DashboardRepositoryImpl());
    _fees = [];
    _feeVm.load(year: _month.year, month: _month.month);
    _financeVm.load(year: _month.year);
  }

  @override
  void dispose() {
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    _feeVm.dispose();
    _financeVm.dispose();
    super.dispose();
  }

  double get _monthlyRevenue => _financeVm.monthFor(_month)?.inflow ?? 0;
  int get _totalOrders => _financeVm.txnsFor(_month.month);
  double get _operatingCosts => _fees.fold(
        0,
        (sum, fee) => sum +
            fee.monthlyCost(revenue: _monthlyRevenue, orders: _totalOrders, month: _month.month, year: _month.year),
      );
  double get _operatingRatio =>
      _monthlyRevenue == 0 ? 0 : _operatingCosts / _monthlyRevenue * 100;
  double get _costPerOrder =>
      _totalOrders == 0 ? 0 : _operatingCosts / _totalOrders;
  double get _trueMargin => _marginBeforeFees - _operatingRatio;
  int get _activeCount => _fees.where((f) => f.isActive).length;

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
    _feeVm.deleteFee(fee.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller?.dispose();
    });
    showSuccessMessage(context, 'Operation fee deleted');
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
      final newMonth = DateTime(picked.year, picked.month);
      setState(() => _month = newMonth);
      _feeVm.load(year: newMonth.year, month: newMonth.month);
      if (newMonth.year != _financeVm.selectedYear) {
        _financeVm.load(year: newMonth.year);
      }
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
    _feeVm.addFee(fee);
    showSuccessMessage(context, 'Operation fee added');
  }

  Future<void> _downloadReport(BuildContext context) async {
    showSuccessMessage(context, 'Downloading report for ${_month.month}/${_month.year}...');
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_feeVm, _financeVm]),
      builder: (context, _) {
        if (_feeVm.fees.isNotEmpty) {
          final existingIds = _fees.map((f) => f.id).toSet();
          for (final fee in _feeVm.fees) {
            if (!existingIds.contains(fee.id)) {
              _fees.add(fee);
              _rateControllers.putIfAbsent(
                fee.id,
                () => TextEditingController(text: ofRate(fee.rate)),
              );
            }
          }
        }
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
                              Expanded(flex: 7, child: _feeRulesCard(useTable: true)),
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
      },
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
          'Track the running costs that sit outside the buy/sell price of a product.',
          style: ofText(size: 13, color: p.textSecondary),
        ),
      ],
    );

    final monthButton = MonthFilterButton(
      month: _month,
      onPressed: _pickMonth,
    );

    final downloadButton = _DownloadButton(
      onPressed: () => _downloadReport(context),
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
              downloadButton,
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
              downloadButton,
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
        downloadButton,
      ],
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
      month: _month.month,
      year: _month.year,
      onAddFee: () => _openAddFee(asSheet: !useTable),
      onActiveChanged: _onActiveChanged,
      onCalculationChanged: _onCalculationChanged,
      onRateChanged: _onRateChanged,
      onDelete: _deleteFee,
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DownloadButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FilledButton.icon(
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
      icon: const Icon(Icons.download, size: 16),
      label: Text(
        'Download',
        style: ofText(
          size: 12.5,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
