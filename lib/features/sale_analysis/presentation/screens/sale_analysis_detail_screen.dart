import 'package:flutter/material.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/aov_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/avg_units_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/cogs_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/generic_metric_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/gross_profit_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/margin_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/net_profit_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/operating_expenses_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/revenue_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/transactions_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/pages/units_page.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';

/// Drill-down screen for the Sale Analysis KPIs. Each metric gets its own page
/// under `presentation/pages/`; this screen only picks the page and supplies
/// the shell and top bar.
class SaleAnalysisDetailScreen extends StatefulWidget {
  final String metric;
  const SaleAnalysisDetailScreen({super.key, required this.metric});

  @override
  State<SaleAnalysisDetailScreen> createState() =>
      _SaleAnalysisDetailScreenState();
}

class _SaleAnalysisDetailScreenState extends State<SaleAnalysisDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _title {
    switch (widget.metric) {
      case 'revenue':
        return 'Revenue Analysis';
      case 'cogs':
        return 'COGS Detail';
      case 'grossProfit':
        return 'Gross Profit Detail';
      case 'margin':
        return 'Margin Detail';
      case 'units':
        return 'Units Sold Detail';
      case 'transactions':
        return 'Transactions Detail';
      case 'aov':
        return 'Average Order Value Detail';
      case 'operatingExpenses':
        return 'Operating Expenses Detail';
      case 'netProfit':
        return 'Net Profit Detail';
      default:
        return 'Detail';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppShell(
      active: DrawerDestination.saleAnalysis,
      scaffoldKey: _scaffoldKey,
      backgroundColor: p.scaffoldBg,
      wrap: (_, shell) => shell,
      // Back, not menu: this screen is a drill-down from Sale Analysis, and
      // every other pushed detail screen in the app does the same. On a narrow
      // window it used to show the hamburger and no back button, so the only
      // way back to the overview was the drawer or the system back gesture.
      body: (context, _) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: _title,
              showBackButton: true,
              showMenuButton: false,
            ),
            Expanded(child: _pageFor(widget.metric)),
          ],
        ),
      ),
    );
  }

  Widget _pageFor(String metric) {
    switch (metric) {
      case 'revenue':
        return const RevenueAnalysisPage();
      case 'cogs':
        return const CogsPage();
      case 'grossProfit':
        return const GrossProfitPage();
      case 'margin':
        return const MarginPage();
      case 'units':
        return const UnitsPage();
      case 'transactions':
        return const TransactionsPage();
      case 'aov':
        return const AovPage();
      case 'avgUnits':
        return const AvgUnitsPage();
      case 'operatingExpenses':
        return const OperatingExpensesPage();
      case 'netProfit':
        return const NetProfitPage();
      default:
        return GenericMetricPage(metric: metric);
    }
  }
}
