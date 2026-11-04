import 'package:flutter/material.dart';
import 'package:posfrontend/features/money_flow/presentation/data/money_flow_demo_data.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Section heading used by the Money Flow Analysis dashboard.
class MoneyFlowSectionTitle extends StatelessWidget {
  const MoneyFlowSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.palette.textPrimary,
        ),
      ),
    );
  }
}

/// Muted explanatory line under a chart or list.
class MoneyFlowNote extends StatelessWidget {
  const MoneyFlowNote(this.text, {super.key, this.italic = false});

  final String text;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: context.palette.textMuted,
        fontStyle: italic ? FontStyle.italic : null,
      ),
    );
  }
}

/// Which colour family a summary card belongs to.
///
/// The hue follows the *meaning* of the figure, not its copy: money arriving is
/// green, money leaving is red, and the balance — which is neither — stays
/// neutral so the row does not read as four alarms.
enum MoneyFlowTone { inflow, outflow, net, neutral }

/// One of the four Financial Summary cards.
class MoneyFlowSummaryCard extends StatelessWidget {
  const MoneyFlowSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    this.tone = MoneyFlowTone.neutral,
    this.positive = true,
  });

  final String label;
  final String value;

  /// Period-over-period change, e.g. `↑ 12.7%`.
  final String sub;

  final IconData icon;
  final MoneyFlowTone tone;

  /// Only read for [MoneyFlowTone.net]: a negative cash flow is red.
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (accent, tint) = switch ((tone, positive)) {
      (MoneyFlowTone.inflow, _) => (p.successFg, p.successBg),
      (MoneyFlowTone.outflow, _) => (p.dangerFg, p.dangerBg),
      (MoneyFlowTone.net, true) => (p.successFg, p.successBg),
      (MoneyFlowTone.net, false) => (p.dangerFg, p.dangerBg),
      _ => (p.textSecondary, p.chipBg),
    };
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tone == MoneyFlowTone.neutral
                            ? p.textPrimary
                            : accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Direction decides the hue, never the copy: a green "↑" on
                    // a falling figure is exactly the mistake this avoids.
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 11,
                        color: sub.startsWith('↑')
                            ? p.successFg
                            : sub.startsWith('↓')
                            ? p.dangerFg
                            : p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Period presets plus the calendar button that replaces them with a range.
class MoneyFlowPeriodFilter extends StatelessWidget {
  const MoneyFlowPeriodFilter({
    super.key,
    required this.presets,
    required this.selected,
    required this.onSelect,
    required this.rangeLabel,
    required this.onPickRange,
  });

  final List<String> presets;
  final String selected;
  final ValueChanged<String> onSelect;

  /// Formatted active range, e.g. `Nov 2026`.
  final String rangeLabel;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Period: ',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final preset in presets)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ChoiceChip(
                          label: Text(
                            preset,
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: selected == preset,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => onSelect(preset),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.date_range, size: 20),
              tooltip: 'Pick date range',
              onPressed: onPickRange,
            ),
          ],
        ),
        Text(
          rangeLabel,
          style: TextStyle(fontSize: 11, color: p.textMuted),
        ),
      ],
    );
  }
}

/// One source of money: name, amount and its share of the total, drawn as a
/// horizontal bar so sources can be compared without reading the numbers.
class MoneyFlowBreakdown extends StatelessWidget {
  const MoneyFlowBreakdown({
    super.key,
    required this.title,
    required this.totalLabel,
    required this.items,
    required this.color,
  });

  final String title;
  final String totalLabel;

  /// Name, formatted amount, share of the total (0–1).
  final List<(String, String, double)> items;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                Text(
                  totalLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < items.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      items[i].$1,
                      style: TextStyle(fontSize: 12, color: p.textPrimary),
                    ),
                  ),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: items[i].$3.clamp(0.0, 1.0),
                  minHeight: 6,
                  color: color,
                  backgroundColor: p.chipBg,
                ),
              ),
              if (i != items.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// One line of the financial ledger.
class MoneyFlowTransactionTile extends StatelessWidget {
  const MoneyFlowTransactionTile({super.key, required this.tx});

  final MoneyFlowTransaction tx;

  @override
  Widget build(BuildContext context) {
    const data = MoneyFlowDemoData();
    final p = context.palette;
    final incoming = tx.isInflow;
    final accent = incoming ? p.successFg : p.dangerFg;
    final tint = incoming ? p.successBg : p.dangerBg;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
        child: Icon(
          incoming ? Icons.arrow_downward : Icons.arrow_upward,
          size: 18,
          color: accent,
        ),
      ),
      title: Text(
        tx.description,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tx.category} · ${tx.account}',
              style: TextStyle(fontSize: 11, color: p.textSecondary),
            ),
            Text(
              data.dateTimeLabel(tx.when),
              style: TextStyle(fontSize: 10, color: p.textMuted),
            ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            tx.signed,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          Text(
            incoming ? 'Inflow' : 'Outflow',
            style: TextStyle(fontSize: 10, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Recent movements with an optional `View All` hand-off to the full ledger.
class MoneyFlowTransactionList extends StatelessWidget {
  const MoneyFlowTransactionList({
    super.key,
    required this.transactions,
    this.onViewAll,
  });

  final List<MoneyFlowTransaction> transactions;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No financial movements in this period.',
          style: TextStyle(fontSize: 12, color: p.textMuted),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 12, endIndent: 12, color: p.border),
            MoneyFlowTransactionTile(tx: transactions[i]),
          ],
          if (onViewAll != null) ...[
            Divider(height: 1, indent: 12, endIndent: 12, color: p.border),
            TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text('View All'),
            ),
          ],
        ],
      ),
    );
  }
}
