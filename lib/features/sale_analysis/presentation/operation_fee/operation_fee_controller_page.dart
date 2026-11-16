import 'dart:async';

import 'package:flutter/material.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/operation_fee_models.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/operation_fee_style.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/add_fee_dialog.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/cost_allocation_card.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/fee_rules_card.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/financial_insight_banner.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/product_picker_dialog.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/summary_cards.dart';
import 'package:posfrontend/features/sale_analysis/presentation/money_flow/money_flow_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/viewmodels/finance_view_model.dart';
import 'package:posfrontend/features/sale_analysis/presentation/viewmodels/operation_fee_view_model.dart';
import 'package:posfrontend/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/month_filter_button.dart';
import 'package:posfrontend/shared/services/report_download.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class OperationFeeControllerPage extends StatefulWidget {
  const OperationFeeControllerPage({super.key});

  @override
  State<OperationFeeControllerPage> createState() =>
      _OperationFeeControllerPageState();
}

class _OperationFeeControllerPageState
    extends State<OperationFeeControllerPage> {
  late final OperationFeeViewModel _feeVm;
  late final FinanceViewModel _financeVm;

  late List<OperationFee> _fees;
  final Map<String, TextEditingController> _rateControllers = {};
  final Map<String, Timer> _saveTimers = {};

  AllocationMethod _allocation = AllocationMethod.revenue;

  /// Null means the preview follows the month's highest-revenue product.
  int? _selectedProductId;

  /// The month on screen. Opens on the current month so the controller is
  /// never anchored to a date that was hard-coded when the screen was built.
  DateTime _month = _nowMonth();

  /// `DateTime.now()` truncated to the first of its month.
  static DateTime _nowMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Earliest month the picker can reach: January of the first year the
  /// account has data for, falling back to the selected year while the
  /// finance data is still loading.
  DateTime get _firstMonth {
    var year = _month.year;
    for (final y in _financeVm.years) {
      if (y < year) year = y;
    }
    return DateTime(year, 1);
  }

  /// Latest month the picker can reach: no month can be selected beyond the
  /// one currently in progress, since there is no data for future months.
  DateTime get _lastMonth => _nowMonth();

  @override
  void initState() {
    super.initState();
    _feeVm = OperationFeeViewModel();
    _financeVm = FinanceViewModel(repository: DashboardRepositoryImpl());
    _fees = [];
    _feeVm.load().then((_) {
      if (!mounted) return;
      setState(() {
        _allocation = allocationMethodFromName(_feeVm.allocationMethod);
      });
      _loadProductImpact();
    });
    _financeVm.load(year: _month.year);
  }

  void _loadProductImpact() {
    _feeVm.loadProductImpact(
      year: _month.year,
      month: _month.month,
      allocationMethod: _allocation.name,
      productId: _selectedProductId,
    );
  }

  Future<void> _chooseProduct() async {
    final chosen = await showDialog<OperationFeeProductOption>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ProductPickerDialog(
          search: _feeVm.searchProducts,
          selectedProductId: _selectedProductId?.toString(),
        ),
      ),
    );

    if (chosen == null || !mounted) return;

    final id = int.tryParse(chosen.id);
    if (id == null) return;

    setState(() => _selectedProductId = id);
    _loadProductImpact();
  }

  void _onAllocationChanged(AllocationMethod method) {
    if (method == _allocation) return;
    setState(() => _allocation = method);
    _feeVm.saveSettings(method.name);
    _loadProductImpact();
  }

  @override
  void dispose() {
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    for (final timer in _saveTimers.values) {
      timer.cancel();
    }
    _feeVm.dispose();
    _financeVm.dispose();
    super.dispose();
  }

  double get _monthlyRevenue => _financeVm.monthFor(_month)?.inflow ?? 0;
  int get _totalOrders => _financeVm.txnsFor(_month.month);

  /// The operation-fee cost of an arbitrary month under the current rules.
  /// Taking a month as an argument is what lets the previous-month
  /// comparison use exactly the same maths as the headline figure.
  double _operatingCostsFor(DateTime month) {
    final revenue = _financeVm.monthFor(month)?.inflow ?? 0;
    final orders = _financeVm.txnsFor(month.month);
    return _fees.fold(
      0,
      (sum, fee) =>
          sum +
          fee.monthlyCost(
            revenue: revenue,
            orders: orders,
            month: month.month,
            year: month.year,
          ),
    );
  }

  double get _operatingCosts => _operatingCostsFor(_month);

  /// Costs as a share of revenue for an arbitrary month.
  double _operatingRatioFor(DateTime month) {
    final revenue = _financeVm.monthFor(month)?.inflow ?? 0;
    if (revenue == 0) return 0;
    return _operatingCostsFor(month) / revenue * 100;
  }

  double get _operatingRatio => _operatingRatioFor(_month);
  double get _costPerOrder =>
      _totalOrders == 0 ? 0 : _operatingCosts / _totalOrders;

  /// Gross margin before any operation fee: `(revenue - COGS) / revenue`.
  /// COGS is the real per-variant cost the finance view model already loads —
  /// this used to be a hard-coded 39.8%.
  double _marginBeforeFeesFor(double revenue, int month) {
    if (revenue == 0) return 0;
    final cogs = _financeVm.cogsFor(month).toDouble();
    return (revenue - cogs) / revenue * 100;
  }

  double get _marginBeforeFees =>
      _marginBeforeFeesFor(_monthlyRevenue, _month.month);
  double get _trueMargin => _marginBeforeFees - _operatingRatio;
  int get _activeCount => _fees.where((f) => f.isActive).length;

  // ---------------------------------------------------------- previous month

  MoneyFlowMonth? get _prevMonth => _financeVm.previousMonthOf(_month);

  double? get _prevRevenue => _prevMonth?.inflow;

  double? get _prevOperatingCosts {
    final m = _prevMonth;
    return m == null ? null : _operatingCostsFor(m.month);
  }

  double? get _prevTrueMargin {
    final m = _prevMonth;
    if (m == null) return null;
    return _marginBeforeFeesFor(m.inflow, m.month.month) -
        _operatingRatioFor(m.month);
  }

  // ---------------------------------------------------------------- sparks

  /// Up to the seven months ending on the selected one, scaled to 0..1 for
  /// the card sparkbars. An all-zero series draws a flat baseline rather
  /// than nothing.
  List<double> _sparkFor(double Function(DateTime month) pick) {
    final start = _month.month > 6 ? _month.month - 6 : 1;
    final values = <double>[
      for (var m = start; m <= _month.month; m++)
        pick(DateTime(_month.year, m)),
    ];
    var max = 0.0;
    for (final v in values) {
      if (v > max) max = v;
    }
    if (max <= 0) return [for (final _ in values) 0.08];
    return [for (final v in values) (v / max).clamp(0.08, 1.0).toDouble()];
  }

  List<double> get _revenueSpark =>
      _sparkFor((m) => _financeVm.monthFor(m)?.inflow ?? 0);
  List<double> get _costSpark => _sparkFor(_operatingCostsFor);

  void _replaceFee(OperationFee updated) {
    setState(() {
      final index = _fees.indexWhere((f) => f.id == updated.id);
      if (index != -1) _fees[index] = updated;
    });
  }

  void _onActiveChanged(OperationFee fee, bool active) {
    _replaceFee(fee.copyWith(isActive: active));
    _persistFee(fee.copyWith(isActive: active), revertTo: fee);
  }

  void _onCalculationChanged(OperationFee fee, FeeCalculation method) {
    _replaceFee(fee.copyWith(calculation: method));
    _persistFee(fee.copyWith(calculation: method), revertTo: fee);
  }

  void _onRateChanged(OperationFee fee, String text) {
    final parsed = double.tryParse(text.replaceAll(',', '')) ?? 0;
    final updated = fee.copyWith(rate: parsed);
    _replaceFee(updated);

    // Typing a rate fires per keystroke; only save once the user pauses.
    _saveTimers[fee.id]?.cancel();
    _saveTimers[fee.id] = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _persistFee(updated, revertTo: fee);
    });
  }

  /// Saves an edited rule to the backend so active/inactive and rate changes
  /// survive a reload. Reverts the local edit if the request fails.
  Future<void> _persistFee(
    OperationFee fee, {
    required OperationFee revertTo,
  }) async {
    await _feeVm.updateFee(fee);
    if (!mounted) return;
    if (_feeVm.hasError) {
      _replaceFee(revertTo);
      showErrorMessage(
        context,
        _feeVm.errorMessage ?? 'Failed to update operation fee',
      );
      return;
    }

    // The page keeps its own copy, so mirror the server's saved values.
    for (final saved in _feeVm.fees) {
      if (saved.id == fee.id) {
        _replaceFee(saved);
        break;
      }
    }
  }

  void _deleteFee(OperationFee fee) {
    _saveTimers.remove(fee.id)?.cancel();
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
      _loadProductImpact();
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
          child: const SafeArea(top: false, child: AddFeeDialog(asSheet: true)),
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
    final saved = await _feeVm.addFee(created);
    if (!mounted) return;
    if (saved == null) {
      showErrorMessage(
        context,
        _feeVm.errorMessage ?? 'Failed to add operation fee',
      );
      return;
    }
    _rateControllers[saved.id] = TextEditingController(
      text: ofRate(saved.rate),
    );
    setState(() => _fees.add(saved));
    showSuccessMessage(context, 'Operation fee added');
  }

  bool _isDownloading = false;

  Future<void> _downloadReport(BuildContext context) async {
    if (_isDownloading) return;

    final year = _month.year;
    final month = _month.month;

    setState(() => _isDownloading = true);
    try {
      final bytes = await _feeVm.downloadReport(year: year, month: month);
      if (!context.mounted) return;

      if (bytes == null) {
        showErrorMessage(
          context,
          _feeVm.errorMessage ?? 'Failed to download operation fee report',
        );
        return;
      }

      final filename =
          'operation_fee_report_${year}_${month.toString().padLeft(2, '0')}.csv';
      final started = await ReportDownload.save(
        bytes,
        filename: filename,
        mimeType: 'text/csv',
      );
      if (!context.mounted) return;

      if (!started) {
        showErrorMessage(
          context,
          'The download could not be started. Try again.',
        );
        return;
      }

      showSuccessMessage(context, 'Report for $month/$year downloaded');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
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
                        if (_feeVm.hasError) ...[
                          const SizedBox(height: 16),
                          _FeeLoadError(
                            message: _feeVm.errorMessage!,
                            onRetry: _feeVm.load,
                          ),
                        ],
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
                          prevRevenue: _prevRevenue,
                          prevOperatingCosts: _prevOperatingCosts,
                          prevTrueMargin: _prevTrueMargin,
                          revenueSpark: _revenueSpark,
                          costSpark: _costSpark,
                        ),
                        const SizedBox(height: 16),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _feeRulesCard(useTable: true),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: CostAllocationCard(
                                  selected: _allocation,
                                  impact: _feeVm.productImpact,
                                  impactLoading: _feeVm.impactLoading,
                                  impactError: _feeVm.impactError,
                                  onChanged: _onAllocationChanged,
                                  onChooseProduct: _chooseProduct,
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
                                impact: _feeVm.productImpact,
                                impactLoading: _feeVm.impactLoading,
                                impactError: _feeVm.impactError,
                                onChanged: _onAllocationChanged,
                                onChooseProduct: _chooseProduct,
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        FinancialInsightBanner(
                          compact: !isTablet,
                          totalCosts: _operatingCosts,
                          revenue: _monthlyRevenue,
                          costPerOrder: _costPerOrder,
                          orders: _totalOrders,
                        ),
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

    final monthButton = MonthFilterButton(month: _month, onPressed: _pickMonth);

    final downloadButton = _DownloadButton(
      onPressed: () => _downloadReport(context),
      isLoading: _isDownloading,
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titleBlock),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [monthButton, const SizedBox(width: 10), downloadButton],
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
            children: [monthButton, const SizedBox(height: 8), downloadButton],
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

class _FeeLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FeeLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.dangerFg.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: p.dangerFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: ofText(size: 12, color: p.dangerFg)),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: p.dangerFg,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              'Retry',
              style: ofText(
                size: 12,
                weight: FontWeight.w600,
                color: p.dangerFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _DownloadButton({required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: p.primary.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.download, size: 16),
      label: Text(
        isLoading ? 'Downloading…' : 'Download',
        style: ofText(size: 12.5, weight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}
