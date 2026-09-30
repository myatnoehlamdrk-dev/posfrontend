import 'package:dio/dio.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_tables.dart';
import 'package:posfrontend/features/dashboard/presentation/screens/dashboard_table_screen.dart';
import 'package:posfrontend/features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'package:posfrontend/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final DashboardViewModel _viewModel;
  final CancelToken _cancelToken = CancelToken();

  static const Color purpleAction = Color(0xFF6D28D9);

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(repository: DashboardRepositoryImpl());
    _viewModel.load();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get(
        '/api/auth/profile',
        cancelToken: _cancelToken,
      );
      final data = resp.data;
      final image = (data is Map<String, dynamic>) ? (data['image'] ?? '') : '';
      if (image is String && image.isNotEmpty && mounted) {
        ProfileImageNotifier.instance.update(image);
      }
    } catch (_) {
      // Profile image fetch failure is non-critical
    }
  }

  @override
  void dispose() {
    if (!_cancelToken.isCancelled) _cancelToken.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: p.scaffoldBg,
      drawer: const AppDrawer(active: DrawerDestination.dashboard),
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t('Dashboard'),
              showMenuButton: true,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return RefreshableBody(
                    onRefresh: () => _viewModel.load(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_viewModel.isLoading && _viewModel.data == null)
                            const DashboardSkeleton()
                          else if (_viewModel.hasError)
                            SizedBox(
                              height: 300,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Color(0xFFEF4444),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _viewModel.errorMessage ??
                                          'Something went wrong',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: p.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => _viewModel.load(),
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: Text(context.l10n.t('Retry')),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: purpleAction,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_viewModel.data == null)
                            const DashboardSkeleton()
                          else ...[
                            Text(
                              context.l10n.t('Summary'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryGrid(_viewModel.data!.metrics),
                            const SizedBox(height: 24),
                            _buildCategoryDistributionSection(
                              _viewModel.data!.categoryDistribution,
                            ),
                            const SizedBox(height: 24),
                            _buildCategoryQuantitySection(
                              _viewModel.data!.categoryQuantity,
                            ),
                            const SizedBox(height: 24),
                            _buildMonthlySalesSection(),
                            const SizedBox(height: 24),
                            Text(
                              context.l10n.t('Product Trend'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildProductTrendSection(
                              _viewModel.data!.mostBought,
                              _viewModel.data!.leastBought,
                              _viewModel.data!.noBought,
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(MetricEntity m) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(m.iconBgValue),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              IconData(
                int.parse(m.iconCodePoint),
                fontFamily: m.iconFontFamily,
              ),
              color: Color(m.iconColorValue),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.t(m.label),
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          const SizedBox(height: 6),
          // Both the number and "View all" open the same table. The number used
          // to open a dialog that just repeated it, which is a dead end: the
          // card is a summary, and the rows behind it are somewhere else.
          GestureDetector(
            onTap: () => _openSummaryTable(m.tableKey),
            child: Text(
              m.value.length > 12 ? '${m.value.substring(0, 12)}...' : m.value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openSummaryTable(m.tableKey),
            child: Row(
              children: [
                Text(
                  context.l10n.t('View all'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: purpleAction,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 14, color: purpleAction),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Maps a summary card to the table of rows behind it. Total Sales is the
  /// only card whose value is money rather than a count, but it has a table
  /// too, so the mapping is on the label for all four.
  void _openSummaryTable(DashboardTableKey? key) {
    final route = switch (key) {
      DashboardTableKey.products => DashboardTableScreen.route(
        spec: DashboardTables.products,
      ),
      DashboardTableKey.inStock => DashboardTableScreen.route(
        spec: DashboardTables.inStock,
      ),
      DashboardTableKey.lowStock => DashboardTableScreen.route(
        spec: DashboardTables.lowStock,
        query: const {'low': 1},
      ),
      DashboardTableKey.sales => DashboardTableScreen.route(
        spec: DashboardTables.sales,
      ),
      null => null,
    };

    if (route == null) return;
    Navigator.of(context).push(route);
  }

  Widget _buildSummaryGrid(List<MetricEntity> metrics) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cards = metrics.map(_summaryCard).toList();
        if (constraints.maxWidth < 360) {
          return Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: c,
                  ),
                )
                .toList(),
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 12),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryDistributionSection(
    List<CategoryDistributionEntity> items,
  ) {
    final p = context.palette;
    Widget buildPie() {
      return SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
                sections: items.asMap().entries.map((entry) {
                  final item = entry.value;
                  return PieChartSectionData(
                    value: item.productCount.toDouble(),
                    color: Color(item.colorValue),
                    radius: 60,
                    showTitle: false,
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            ),
            SizedBox(
              width: 80,
              child: Text(
                ShopScope.shopOf(context)?.name ?? 'Shop',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildLegend() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(item.colorValue),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.category,
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.t('Product Distribution by Category'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                color: p.cardShadow,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: items.isEmpty
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(context.l10n.t('No category data')),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 560;
                    if (wide) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          buildPie(),
                          const SizedBox(width: 32),
                          Expanded(child: buildLegend()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        buildPie(),
                        const SizedBox(height: 16),
                        buildLegend(),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryQuantitySection(List<CategoryQuantityEntity> items) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.t('Quantity Sold by Category'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                color: p.cardShadow,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: items.isEmpty
              ? SizedBox(
                  height: 200,
                  child: Center(child: Text(context.l10n.t('No sales data'))),
                )
              : _HorizontalCategoryChart(items: items, palette: p),
        ),
      ],
    );
  }

  Widget _buildMonthlySalesSection() {
    final p = context.palette;
    var years = _viewModel.years.isEmpty
        ? [DateTime.now().year]
        : _viewModel.years;
    if (!years.contains(_viewModel.selectedYear)) {
      years = [_viewModel.selectedYear, ...years];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.t('Monthly Sales'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
            _YearDropdown(
              years: years,
              value: _viewModel.selectedYear,
              onChanged: (year) => _viewModel.loadMonthlySales(year: year),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                color: p.cardShadow,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _viewModel.isLoadingMonthly
              ? const MonthlySalesChartSkeleton()
              : _viewModel.monthlySales.isEmpty
              ? SizedBox(
                  height: 260,
                  child: Center(child: Text(context.l10n.t('No sales data'))),
                )
              : _HorizontalBarChart(items: _viewModel.monthlySales, palette: p),
        ),
      ],
    );
  }

  Widget _buildProductTrendSection(
    List<ProductItemEntity> most,
    List<ProductItemEntity> least,
    List<ProductItemEntity> noBought,
  ) {
    final p = context.palette;
    final mostCard = _ProductListCard(
      title: context.l10n.t('Most Bought'),
      titleColor: const Color(0xFF16A34A),
      items: most,
      onViewAll: () => Navigator.of(context).push(
        DashboardTableScreen.route(
          spec: DashboardTables.bought,
          showDirectionToggle: true,
        ),
      ),
    );
    final leastCard = _ProductListCard(
      title: context.l10n.t('Least Bought'),
      titleColor: const Color(0xFFEF4444),
      items: least,
      onViewAll: () => Navigator.of(context).push(
        DashboardTableScreen.route(
          spec: DashboardTables.leastBought,
          showDirectionToggle: true,
          initialDirection: 'asc',
        ),
      ),
    );
    final noBoughtCard = _ProductListCard(
      title: context.l10n.t('No Bought'),
      titleColor: p.textSecondary,
      items: noBought,
      onViewAll: () => Navigator.of(
        context,
      ).push(DashboardTableScreen.route(spec: DashboardTables.noBought)),
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              mostCard,
              const SizedBox(height: 12),
              leastCard,
              const SizedBox(height: 12),
              noBoughtCard,
            ],
          );
        }
        if (constraints.maxWidth < 880) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: mostCard),
                  const SizedBox(width: 12),
                  Expanded(child: leastCard),
                ],
              ),
              const SizedBox(height: 12),
              noBoughtCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: mostCard),
            const SizedBox(width: 12),
            Expanded(child: leastCard),
            const SizedBox(width: 12),
            Expanded(child: noBoughtCard),
          ],
        );
      },
    );
  }
}

class _ProductListCard extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<ProductItemEntity> items;

  /// Opens the full table of rows for this list. The card only holds three rows,
  /// so without a way out the list is a dead end.
  final VoidCallback onViewAll;

  const _ProductListCard({
    required this.title,
    required this.titleColor,
    required this.items,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pal.border),
        boxShadow: [
          BoxShadow(
            color: pal.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: items
                .map(
                  (p) => Padding(
                    key: ValueKey(p.name),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: pal.chipBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: p.image.isNotEmpty
                              ? Image.network(
                                  p.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        IconData(
                                          p.iconCodePoint,
                                          fontFamily: p.iconFontFamily,
                                        ),
                                        color: pal.textSecondary,
                                      ),
                                )
                              : Icon(
                                  IconData(
                                    p.iconCodePoint,
                                    fontFamily: p.iconFontFamily,
                                  ),
                                  color: pal.textSecondary,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: pal.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.sold,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: pal.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.t('View all'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _DashboardScreenState.purpleAction,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: _DashboardScreenState.purpleAction,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalCategoryChart extends StatelessWidget {
  final List<CategoryQuantityEntity> items;
  final AppPalette palette;

  const _HorizontalCategoryChart({required this.items, required this.palette});

  @override
  Widget build(BuildContext context) {
    final chartH = (items.length * 36.0 + 40.0).clamp(240.0, 520.0);
    return SizedBox(
      height: chartH,
      width: double.infinity,
      child: CustomPaint(
        painter: _HorizontalCategoryChartPainter(items, palette),
      ),
    );
  }
}

class _HorizontalCategoryChartPainter extends CustomPainter {
  final List<CategoryQuantityEntity> items;
  final AppPalette palette;

  _HorizontalCategoryChartPainter(this.items, this.palette);

  static const Color _barColor = Color(0xFF6D28D9);

  @override
  void paint(Canvas canvas, Size size) {
    final sorted = [...items]
      ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    if (sorted.isEmpty) return;

    const rightPad = 16.0;
    const topPad = 16.0;
    const bottomPad = 32.0;

    var leftPad = 64.0;
    for (final e in sorted) {
      final tp = TextPainter(
        text: TextSpan(
          text: e.category,
          style: TextStyle(fontSize: 11, color: palette.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tp.width + 12 > leftPad) leftPad = tp.width + 12;
    }
    leftPad = leftPad.clamp(56.0, 180.0).toDouble();

    final plot = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );

    final values = sorted.map((e) => e.totalQuantity.toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final chartMax = maxVal <= 0 ? 1.0 : maxVal * 1.1;

    final gridPaint = Paint()
      ..color = palette.border
      ..strokeWidth = 1;

    const ticks = 4;
    for (var t = 0; t <= ticks; t++) {
      final x = plot.left + (t / ticks) * plot.width;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), gridPaint);
      final value = chartMax * (t / ticks);
      final tp = TextPainter(
        text: TextSpan(
          text: _formatQuantity(value),
          style: TextStyle(fontSize: 10, color: palette.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, plot.bottom + 8));
    }

    final n = sorted.length;
    final rowH = plot.height / n;
    final barH = (rowH * 0.6).clamp(6.0, 22.0);
    final barPaint = Paint()..color = _barColor;

    for (var i = 0; i < n; i++) {
      final e = sorted[i];
      final cy = plot.top + rowH * (i + 0.5);
      final barW = (e.totalQuantity / chartMax) * plot.width;

      final lp = TextPainter(
        text: TextSpan(
          text: e.category,
          style: TextStyle(fontSize: 11, color: palette.textSecondary),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPad - 8);
      lp.paint(canvas, Offset(plot.left - lp.width - 8, cy - lp.height / 2));

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(plot.left, cy - barH / 2, barW, barH),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, barPaint);

      final vp = TextPainter(
        text: TextSpan(
          text: _formatQuantity(e.totalQuantity.toDouble()),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final vx = (plot.left + barW + 6).clamp(plot.left, plot.right - vp.width);
      if (vx >= plot.left) {
        vp.paint(canvas, Offset(vx, cy - vp.height / 2));
      }
    }
  }

  String _formatQuantity(double value) {
    if (value >= 1000000) {
      return '${_trim(value / 1000000)}M';
    }
    if (value >= 1000) {
      return '${_trim(value / 1000)}k';
    }
    return value.round().toString();
  }

  String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  bool shouldRepaint(covariant _HorizontalCategoryChartPainter oldDelegate) =>
      oldDelegate.items != items || oldDelegate.palette != palette;
}

class _YearDropdown extends StatelessWidget {
  final List<int> years;
  final int value;
  final ValueChanged<int> onChanged;

  const _YearDropdown({
    required this.years,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: years.contains(value) ? value : years.first,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: TextStyle(fontSize: 13, color: p.textSecondary),
          items: years
              .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
              .toList(),
          onChanged: (v) {
            if (v != null && v != value) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _HorizontalBarChart extends StatelessWidget {
  final List<MonthlySalesEntity> items;
  final AppPalette palette;

  const _HorizontalBarChart({required this.items, required this.palette});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: CustomPaint(painter: _HorizontalBarChartPainter(items, palette)),
    );
  }
}

class _HorizontalBarChartPainter extends CustomPainter {
  final List<MonthlySalesEntity> items;
  final AppPalette palette;

  _HorizontalBarChartPainter(this.items, this.palette);

  static const List<String> _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const Color _barColor = Color(0xFF6D28D9);

  @override
  void paint(Canvas canvas, Size size) {
    final sorted = [...items]..sort((a, b) => a.month.compareTo(b.month));
    if (sorted.isEmpty) return;

    const leftPad = 52.0;
    const rightPad = 16.0;
    const topPad = 16.0;
    const bottomPad = 32.0;
    final plot = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );

    final values = sorted.map((e) => e.total.toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final chartMax = maxVal <= 0 ? 1.0 : maxVal * 1.1;

    final gridPaint = Paint()
      ..color = palette.border
      ..strokeWidth = 1;

    const ticks = 4;
    for (var t = 0; t <= ticks; t++) {
      final x = plot.left + (t / ticks) * plot.width;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), gridPaint);
      final value = chartMax * (t / ticks);
      final label = _formatAxisValue(value);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 10, color: palette.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, plot.bottom + 8));
    }

    final n = sorted.length;
    final rowH = plot.height / n;
    final barH = (rowH * 0.62).clamp(6.0, 18.0);
    final barPaint = Paint()..color = _barColor;

    for (var i = 0; i < n; i++) {
      final entry = sorted[i];
      final cy = plot.top + rowH * (i + 0.5);
      final barW = (entry.total / chartMax) * plot.width;

      final label = _monthLabels[(entry.month - 1) % 12];
      final lp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 11, color: palette.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lp.paint(canvas, Offset(plot.left - lp.width - 8, cy - lp.height / 2));

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(plot.left, cy - barH / 2, barW, barH),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${_trimDouble(value / 1000000)}M';
    }
    if (value >= 1000) {
      return '${_trimDouble(value / 1000)}k';
    }
    return value.round().toString();
  }

  String _trimDouble(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  bool shouldRepaint(covariant _HorizontalBarChartPainter oldDelegate) =>
      oldDelegate.items != items || oldDelegate.palette != palette;
}
