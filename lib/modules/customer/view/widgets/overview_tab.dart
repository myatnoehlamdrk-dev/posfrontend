import 'package:flutter/material.dart';
import '../../model/customer_models.dart';

class OverviewTab extends StatelessWidget {
  final CustomerAnalytics analytics;

  const OverviewTab({super.key, required this.analytics});

  static const Color title = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);
  static const Color border = Color(0xFFE5E7EB);
  static const Color teal = Color(0xFF4FD1D9);
  static const Color green = Color(0xFF10B981);
  static const Color orange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final ov = analytics.overview;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statCard('Total Customers', '${ov.totalCustomers}', Icons.people, purple),
              const SizedBox(width: 12),
              _statCard('New This Month', '${ov.newThisMonth}', Icons.person_add, teal),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Returning', '${ov.returningCustomers}', Icons.replay, green),
              const SizedBox(width: 12),
              _statCard('Walk-in', '${ov.walkInCount}', Icons.store, orange),
            ],
          ),
          const SizedBox(height: 24),
          _newVsReturningCard(),
          const SizedBox(height: 24),
          if (analytics.topCustomers.isNotEmpty) ...[
            const Text(
              'Top 3 Customers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: title),
            ),
            const SizedBox(height: 12),
            ...analytics.topCustomers.take(3).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              return _topCustomerRow(i, c);
            }),
            const SizedBox(height: 24),
          ],
          _behaviorCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: gray)),
          ],
        ),
      ),
    );
  }

  Widget _newVsReturningCard() {
    final nvr = analytics.newVsReturning;
    final total = nvr.newCount + nvr.returningCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New vs Returning Customers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: title)),
          const SizedBox(height: 16),
          Row(
            children: [
              _nvrStat('New', nvr.newCount, nvr.newPct, teal),
              const SizedBox(width: 16),
              _nvrStat('Returning', nvr.returningCount, nvr.returningPct, purple),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: nvr.newPct / 100,
                backgroundColor: purple.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(teal),
                minHeight: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _nvrStat(String label, int count, int pct, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: gray)),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  Widget _topCustomerRow(int rank, TopCustomer c) {
    final medals = ['🥇', '🥈', '🥉'];
    final medal = rank < 3 ? medals[rank] : '#${rank + 1}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank == 0 ? const Color(0xFFFDF6E3) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rank == 0 ? const Color(0xFFF59E0B) : border),
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: title)),
                Text('${c.totalOrders} orders', style: const TextStyle(fontSize: 12, color: gray)),
              ],
            ),
          ),
          Text('MMK ${c.totalSpending}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: rank == 0 ? const Color(0xFFF59E0B) : purple)),
        ],
      ),
    );
  }

  Widget _behaviorCard() {
    final b = analytics.purchaseBehavior;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Purchase Behavior', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: title)),
          const SizedBox(height: 12),
          _behaviorRow(Icons.attach_money, 'Avg. Spending', 'MMK ${b.avgSpendingPerCustomer}'),
          const SizedBox(height: 8),
          _behaviorRow(Icons.calendar_today, 'Most Frequent Day', b.mostFrequentDay.isEmpty ? '-' : b.mostFrequentDay),
          const SizedBox(height: 8),
          _behaviorRow(Icons.access_time, 'Most Frequent Hour', b.mostFrequentHour.isEmpty ? '-' : b.mostFrequentHour),
        ],
      ),
    );
  }

  Widget _behaviorRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: gray),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: gray)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: title)),
      ],
    );
  }
}
