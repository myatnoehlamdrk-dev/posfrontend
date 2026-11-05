import 'package:flutter/material.dart';
import 'package:posfrontend/features/money_flow/presentation/data/money_flow_demo_data.dart';
import 'package:posfrontend/features/money_flow/presentation/widgets/money_flow_widgets.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';

/// The full ledger behind the dashboard's `Recent Financial Transactions`
/// preview: every movement in the range, filterable by direction, with the
/// inflow/outflow/net totals they add up to.
class MoneyFlowTransactionsScreen extends StatefulWidget {
  const MoneyFlowTransactionsScreen({super.key, required this.range});

  final DateTimeRange range;

  @override
  State<MoneyFlowTransactionsScreen> createState() =>
      _MoneyFlowTransactionsScreenState();
}

class _MoneyFlowTransactionsScreenState
    extends State<MoneyFlowTransactionsScreen> {
  static const MoneyFlowDemoData _data = MoneyFlowDemoData();

  String _direction = 'All';

  List<MoneyFlowTransaction> get _rows {
    final start = DateUtils.dateOnly(widget.range.start);
    final end = DateUtils.dateOnly(widget.range.end);
    return MoneyFlowDemoData.ledger.where((tx) {
      final day = DateUtils.dateOnly(tx.when);
      if (day.isBefore(start) || day.isAfter(end)) return false;
      if (_direction == 'Inflow') return tx.isInflow;
      if (_direction == 'Outflow') return !tx.isInflow;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = _rows;
    var inflow = 0.0;
    var outflow = 0.0;
    for (final tx in rows) {
      if (tx.isInflow) {
        inflow += tx.amount;
      } else {
        outflow += tx.amount;
      }
    }
    final net = inflow - outflow;
    return AppShell(
      active: DrawerDestination.saleAnalysis,
      backgroundColor: p.scaffoldBg,
      wrap: (_, shell) => shell,
      body: (context, _) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: 'Financial Transactions',
              showBackButton: true,
              showMenuButton: false,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_data.rangeLabelFor(widget.range)} · ${rows.length} '
                    'movements',
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final option in const [
                        'All',
                        'Inflow',
                        'Outflow',
                      ])
                        ChoiceChip(
                          label: Text(
                            option,
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: _direction == option,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) =>
                              setState(() => _direction = option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _totalsRow(inflow, outflow, net, p),
                ],
              ),
            ),
            Expanded(child: _list(rows)),
          ],
        ),
      ),
    );
  }

  Widget _totalsRow(double inflow, double outflow, double net, dynamic p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: _total(
                'Inflow',
                '+${formatMmk(inflow)}',
                p.successFg,
                p,
              ),
            ),
            Expanded(
              child: _total(
                'Outflow',
                '-${formatMmk(outflow)}',
                p.dangerFg,
                p,
              ),
            ),
            Expanded(
              child: _total(
                'Net',
                '${net >= 0 ? '+' : '-'}${formatMmk(net.abs())}',
                net >= 0 ? p.successFg : p.dangerFg,
                p,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _total(String label, String value, Color color, dynamic p) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      );

  Widget _list(List<MoneyFlowTransaction> rows) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No movements match this filter.',
            style: TextStyle(fontSize: 12, color: context.palette.textMuted),
          ),
        ),
      );
    }
    final p = context.palette;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, indent: 12, endIndent: 12, color: p.border),
      itemBuilder: (context, i) =>
          MoneyFlowTransactionTile(tx: rows[i]),
    );
  }
}
