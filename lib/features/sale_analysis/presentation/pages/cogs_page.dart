import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/sale_analysis/presentation/data/sale_analysis_demo_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_chart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// COGS drill-down: cost trend, category mix and product cost tables.
class CogsPage extends StatefulWidget {
  const CogsPage({super.key});

  @override
  State<CogsPage> createState() => _CogsPageState();
}

class _CogsPageState extends State<CogsPage> {
  static const SaleAnalysisDemoData _data = SaleAnalysisDemoData();

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );
  String _trendGranularity = 'Daily';
  String _chartType = 'Line';

  /// The two independent ranges behind the Period Comparison table. They are
  /// deliberately separate from the trend range so any period can be compared
  /// with any other, not just this month and last month.
  DateTimeRange _compareRangeA = DateTimeRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );
  DateTimeRange _compareRangeB = DateTimeRange(
    start: DateTime(2026, 10, 1),
    end: DateTime(2026, 10, 31),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AnalysisKpiCard(
                label: 'Total COGS',
                value: '28.5M',
                sub: '↑ 8.5% vs prev',
              ),
              AnalysisKpiCard(
                label: 'COGS Ratio',
                value: '62.2%',
                sub: 'COGS / Revenue',
              ),
              AnalysisKpiCard(
                label: 'Units Sold',
                value: '1,250',
                sub: 'Total quantities',
              ),
              AnalysisKpiCard(
                label: 'Avg Cost / Unit',
                value: '22.8K',
                sub: 'COGS / units sold',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote('Illustrative values in MMK.'),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('COGS Trend'),
          TrendChartPanel(
            dateRange: _dateRange,
            granularity: _trendGranularity,
            chartType: _chartType,
            granularities: _data.granularitiesFor(_dateRange),
            buckets: _data.cogsTrendBuckets(_dateRange, _trendGranularity),
            candleOhlc: _data.candleBuckets(
              _dateRange,
              _trendGranularity,
              _data.cogsDailyValue,
            ),
            // Cost stays red: the controls and candle view match Revenue, but
            // the series and caption remain COGS.
            lineColor: AppColors.red,
            axisLabel: (v) => _data.money(v),
            money: (v) => _data.money(v),
            metricLabel: 'COGS',
            rangeLabel: _data.rangeLabelFor(_dateRange),
            onRangePicked: _setRange,
            onGranularityChanged: (g) => setState(() => _trendGranularity = g),
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('COGS by Category'),
          _cogsPieChart(),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Category', 'COGS'],
            rows: [
              ['Electronics', '13.5M'],
              ['Accessories', '8.2M'],
              ['Computer', '4.5M'],
              ['Others', '2.3M'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('COGS by Product'),
          const AnalysisTable(
            headers: ['Product', 'Units sold', 'COGS'],
            rows: [
              ['Headphones', '300', '9M'],
              ['Keyboard', '200', '6M'],
              ['Mouse', '250', '3M'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Product Cost Analysis'),
          const AnalysisTable(
            headers: ['Product', 'Unit cost', 'Selling price'],
            rows: [
              ['Headphones', '20,000', '30,000'],
              ['Keyboard', '25,000', '35,000'],
              ['Mouse', '10,000', '15,000'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Period Comparison'),
          _periodComparison(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _setRange(DateTimeRange range) {
    final available = _data.granularitiesFor(range);
    setState(() {
      _dateRange = range;
      // The selected granularity can disappear when the range shrinks; fall
      // back to the coarsest one the new range still supports.
      if (!available.contains(_trendGranularity)) {
        _trendGranularity = available.last;
      }
    });
  }

  Widget _periodComparison() {
    final a = _data.cogsStatsFor(_compareRangeA);
    final b = _data.cogsStatsFor(_compareRangeB);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AnalysisRangePickerButton(
                label: 'Range A',
                value: _data.rangeLabelFor(_compareRangeA),
                onPressed: () => _pickComparisonRange(isRangeA: true),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20),
              tooltip: 'Swap ranges',
              onPressed: _swapComparisonRanges,
            ),
            Expanded(
              child: AnalysisRangePickerButton(
                label: 'Range B',
                value: _data.rangeLabelFor(_compareRangeB),
                onPressed: () => _pickComparisonRange(isRangeA: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnalysisTable(
          headers: [
            'Metric',
            _data.rangeLabelFor(_compareRangeA),
            _data.rangeLabelFor(_compareRangeB),
            'Change',
          ],
          // Four columns, two of them date spans: let phones scroll the table
          // sideways instead of squeezing the figures into unreadable cells.
          minTableWidth: 560,
          rows: [
            [
              'Total COGS',
              _data.money(a.cogs),
              _data.money(b.cogs),
              _data.change(a.cogs, b.cogs),
            ],
            [
              'Units sold',
              a.unitsSold.withCommas(),
              b.unitsSold.withCommas(),
              _data.change(a.unitsSold.toDouble(), b.unitsSold.toDouble()),
            ],
            [
              'Avg cost/unit',
              _data.money(a.avgCostPerUnit / 1000000),
              _data.money(b.avgCostPerUnit / 1000000),
              _data.change(a.avgCostPerUnit, b.avgCostPerUnit),
            ],
            [
              'COGS ratio',
              '${a.cogsRatio.asPercent(1)}%',
              '${b.cogsRatio.asPercent(1)}%',
              _data.change(a.cogsRatio, b.cogsRatio),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const AnalysisNote(
          'Pick any two ranges with the calendar buttons. Change compares '
          'Range A with Range B; amounts are in MMK.',
        ),
      ],
    );
  }

  Future<void> _pickComparisonRange({required bool isRangeA}) async {
    final initial = isRangeA ? _compareRangeA : _compareRangeB;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isRangeA) {
        _compareRangeA = picked;
      } else {
        _compareRangeB = picked;
      }
    });
  }

  void _swapComparisonRanges() {
    setState(() {
      final previousA = _compareRangeA;
      _compareRangeA = _compareRangeB;
      _compareRangeB = previousA;
    });
  }

  Widget _cogsPieChart() {
    const slices = [
      (label: 'Electronics', value: 13.5, color: AppColors.brandPurple),
      (label: 'Accessories', value: 8.2, color: AppColors.teal),
      (label: 'Computer', value: 4.5, color: AppColors.orange),
      (label: 'Others', value: 2.3, color: AppColors.blue),
    ];
    final p = context.palette;
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);

    final chart = SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 46,
              startDegreeOffset: -90,
              // Names live in the legend. Drawing them on the slices made the
              // short arcs unreadable and clipped the longer ones.
              sections: [
                for (final slice in slices)
                  PieChartSectionData(
                    value: slice.value,
                    color: slice.color,
                    radius: 52,
                    showTitle: false,
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${total.toStringAsFixed(1)}M',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
              Text(
                'Total COGS',
                style: TextStyle(fontSize: 11, color: p.textMuted),
              ),
            ],
          ),
        ],
      ),
    );

    final legend = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final slice in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: slice.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slice.label,
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ),
                Text(
                  '${slice.value.toStringAsFixed(1)}M',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(slice.value / total * 100).toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: p.textMuted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide layouts put the legend beside the donut; phones stack it below
        // so neither the chart nor the labels get squeezed.
        if (constraints.maxWidth >= 440) {
          return Row(
            children: [
              chart,
              const SizedBox(width: 24),
              Expanded(child: legend),
            ],
          );
        }
        return Column(children: [chart, const SizedBox(height: 12), legend]);
      },
    );
  }
}
