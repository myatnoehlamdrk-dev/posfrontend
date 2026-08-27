import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:posfrontend/modules/dashboard/model/dashboard_models.dart';
import 'package:posfrontend/modules/dashboard/repository/dashboard_repository_impl.dart';
import 'package:posfrontend/modules/dashboard/view/dashboard_drawer.dart';
import 'package:posfrontend/modules/dashboard/viewmodel/dashboard_view_model.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';

class DashboardScreen extends StatefulWidget {
  final LoginResponse? user;

  const DashboardScreen({super.key, this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final DashboardViewModel _viewModel;

  static const Color bg = Color(0xFFF8F9FC);
  static const Color titleColor = Color(0xFF0F172A);
  static const Color labelColor = Color(0xFF111827);
  static const Color grayText = Color(0xFF6B7280);
  static const Color primaryLight = Color(0xFF9D4EDD);
  static const Color purpleAction = Color(0xFF6D28D9);
  static const Color cardBorder = Color(0xFFE5E7EB);

  String get _userName =>
      widget.user != null && widget.user!.fullName.trim().isNotEmpty
          ? widget.user!.fullName
          : 'John Doe';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(repository: DashboardRepositoryImpl());
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(_userName);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: DashboardDrawer(user: widget.user),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.isLoading || _viewModel.data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = _viewModel.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(initials),
                  const SizedBox(height: 24),
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryGrid(data.metrics),
                  const SizedBox(height: 24),
                  _buildTrendSection(data.trendSeries),
                  const SizedBox(height: 24),
                  const Text(
                    'Product Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProductTrendSection(data.mostBought, data.leastBought),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String initials) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: const Icon(Icons.menu, color: titleColor),
          ),
        ),
        const SizedBox(width: 12),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: grayText),
              const SizedBox(width: 8),
              Text(
                _formatDate(DateTime.now()),
                style: const TextStyle(fontSize: 13, color: titleColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 22,
          backgroundColor: primaryLight,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _summaryCard(Metric m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: m.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(m.icon, color: m.iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            m.label,
            style: const TextStyle(fontSize: 13, color: grayText),
          ),
          const SizedBox(height: 6),
          Text(
            m.value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {},
            child: const Row(
              children: [
                Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: purpleAction,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 14, color: purpleAction),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(List<Metric> metrics) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cards = metrics.map(_summaryCard).toList();
        if (constraints.maxWidth < 360) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
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

  Widget _buildTrendSection(List<TrendSeries> series) {
    final chartH = (MediaQuery.of(context).size.height * 0.32).clamp(200.0, 300.0);

    final lineBars = series.asMap().entries.map((entry) {
      final s = entry.value;
      return LineChartBarData(
        spots: s.values
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList(),
        isCurved: true,
        color: s.color,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: s.color.withValues(alpha: 0.08),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'User Buying Trend by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            _PeriodDropdown(),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: chartH,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: cardBorder,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 20,
                          getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: grayText),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: lineBars,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: series
                    .map((s) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.name,
                              style: const TextStyle(fontSize: 12, color: grayText),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductTrendSection(
    List<ProductItem> most,
    List<ProductItem> least,
  ) {
    final mostCard = _ProductListCard(
      title: 'Most Bought',
      titleColor: const Color(0xFF16A34A),
      items: most,
    );
    final leastCard = _ProductListCard(
      title: 'Least Bought',
      titleColor: const Color(0xFFEF4444),
      items: least,
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              mostCard,
              const SizedBox(height: 12),
              leastCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: mostCard),
            const SizedBox(width: 12),
            Expanded(child: leastCard),
          ],
        );
      },
    );
  }
}

class _ProductListCard extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<ProductItem> items;

  const _ProductListCard({
    required this.title,
    required this.titleColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2)),
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(p.icon, color: const Color(0xFF6B7280)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.sold,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PeriodDropdown extends StatefulWidget {
  @override
  State<_PeriodDropdown> createState() => _PeriodDropdownState();
}

class _PeriodDropdownState extends State<_PeriodDropdown> {
  String _value = 'This Year';
  final List<String> _options = ['This Week', 'This Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          items: _options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _value = v!),
        ),
      ),
    );
  }
}
