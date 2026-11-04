import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Section heading used by every Sale Analysis detail page.
class AnalysisSectionTitle extends StatelessWidget {
  const AnalysisSectionTitle(this.title, {super.key});

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

/// Small metric card at the top of a detail page.
class AnalysisKpiCard extends StatelessWidget {
  const AnalysisKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Direction decides the hue, not the copy: a green "↑" on a
              // falling figure is the mistake this avoids.
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
      ),
    );
  }
}

/// Muted explanatory line under a chart or table.
class AnalysisNote extends StatelessWidget {
  const AnalysisNote(this.text, {super.key, this.italic = false});

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

/// Simple bordered table shared by the detail pages.
class AnalysisTable extends StatelessWidget {
  const AnalysisTable({
    super.key,
    required this.headers,
    required this.rows,
    this.minTableWidth = 0,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final double minTableWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final table = Table(
      // Palette tokens, not `Colors.grey.shade*`: the old header was a fixed
      // light grey while the text came from the theme, so in dark mode white
      // sat on near-white. It was also the only table in lib/ built this way.
      border: TableBorder.all(color: p.border),
      children: [
        TableRow(
          decoration: BoxDecoration(color: p.surfaceAlt),
          children: headers
              .map(
                (h) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    h,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: p.textSecondary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (r) => TableRow(
            children: r
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      c,
                      style: TextStyle(fontSize: 12, color: p.textPrimary),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
    if (minTableWidth <= 0) return table;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < minTableWidth
            ? minTableWidth
            : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: width, child: table),
        );
      },
    );
  }
}

/// Horizontal chip filter with a leading label.
class AnalysisFilterRow extends StatelessWidget {
  const AnalysisFilterRow({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options
                  .map(
                    (o) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ChoiceChip(
                        label: Text(o, style: const TextStyle(fontSize: 11)),
                        selected: selected == o,
                        onSelected: (_) => onSelect(o),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Calendar-backed range button used by the Period Comparison controls.
///
/// Two of these plus a swap button let a page compare any range with any other
/// range instead of hard-coding "this month" and "last month".
class AnalysisRangePickerButton extends StatelessWidget {
  const AnalysisRangePickerButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 16, color: p.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: p.textMuted)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Axis label for the money charts. The demo series are in millions, and a
/// bare "1.5" next to a page quoting 15M gives the reader no unit at all.
String analysisMoneyAxisLabel(double v) =>
    v == v.roundToDouble() ? '${v.toInt()}M' : '${v.toStringAsFixed(1)}M';
