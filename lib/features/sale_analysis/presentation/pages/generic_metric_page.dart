import 'package:flutter/material.dart';

/// Fallback list for a metric that has no dedicated detail page.
class GenericMetricPage extends StatelessWidget {
  const GenericMetricPage({super.key, required this.metric});

  final String metric;

  @override
  Widget build(BuildContext context) {
    final rows = _demoRows(metric);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = rows[i];
        return ListTile(title: Text(r.$1), trailing: Text(r.$2));
      },
    );
  }

  List<(String, String)> _demoRows(String m) {
    switch (m) {
      case 'cogs':
        return const [
          ('2026-10-01', '720,000'),
          ('2026-10-02', '810,000'),
          ('2026-10-03', '660,000'),
          ('2026-10-04', '870,000'),
          ('2026-10-05', '960,000'),
        ];
      case 'grossProfit':
        return const [
          ('2026-10-01', '480,000'),
          ('2026-10-02', '540,000'),
          ('2026-10-03', '440,000'),
          ('2026-10-04', '580,000'),
          ('2026-10-05', '640,000'),
        ];
      case 'units':
        return const [
          ('Product A', '120'),
          ('Product B', '95'),
          ('Product C', '80'),
          ('Product D', '75'),
          ('Product E', '80'),
        ];
      case 'transactions':
        return const [
          ('2026-10-01', '32'),
          ('2026-10-02', '36'),
          ('2026-10-03', '30'),
          ('2026-10-04', '40'),
          ('2026-10-05', '42'),
        ];
      default:
        return const [('Detail', 'Demo value')];
    }
  }
}
