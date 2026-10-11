import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/customer/domain/entities/customer.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class OverviewTab extends StatelessWidget {
  final CustomerAnalyticsEntity analytics;

  const OverviewTab({super.key, required this.analytics});

  static const Color teal = Color(0xFF4FD1D9);
  static const Color green = Color(0xFF10B981);
  static const Color orange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ov = analytics.overview;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statCard(
                context,
                'Total Customers',
                '${ov.totalCustomers}',
                Icons.people,
                AppColors.brandPurpleDark,
              ),
              const SizedBox(width: 12),
              _statCard(
                context,
                'New This Month',
                '${ov.newThisMonth}',
                Icons.person_add,
                teal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                context,
                'Returning',
                '${ov.returningCustomers}',
                Icons.replay,
                green,
              ),
              const SizedBox(width: 12),
              _statCard(
                context,
                'Walk-in',
                '${ov.walkInCount}',
                Icons.store,
                orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _newVsReturningCard(context),
          const SizedBox(height: 24),
          if (analytics.topCustomers.isNotEmpty) ...[
            Text(
              context.l10n.t('Top 3 Customers'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...analytics.topCustomers.take(3).toList().asMap().entries.map((
              entry,
            ) {
              final i = entry.key;
              final c = entry.value;
              return _topCustomerRow(context, i, c);
            }),
            const SizedBox(height: 24),
          ],
          _behaviorCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
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
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, color: p.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _newVsReturningCard(BuildContext context) {
    final p = context.palette;
    final nvr = analytics.newVsReturning;
    final total = nvr.newCount + nvr.returningCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('New vs Returning Customers'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _nvrStat(context, 'New', nvr.newCount, nvr.newPct, teal),
              const SizedBox(width: 16),
              _nvrStat(
                context,
                'Returning',
                nvr.returningCount,
                nvr.returningPct,
                AppColors.brandPurpleDark,
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: nvr.newPct / 100,
                backgroundColor: AppColors.brandPurpleDark.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(teal),
                minHeight: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _nvrStat(
    BuildContext context,
    String label,
    int count,
    int pct,
    Color color,
  ) {
    final p = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: p.textSecondary)),
          const SizedBox(height: 4),
          Text(
            context.l10n.t('{v1}').replaceAll('{v1}', (count).toString()),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            context.l10n.t('{v1}%').replaceAll('{v1}', (pct).toString()),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topCustomerRow(BuildContext context, int rank, TopCustomerEntity c) {
    final p = context.palette;
    final medals = ['🥇', '🥈', '🥉'];
    final medal = rank < 3 ? medals[rank] : '#${rank + 1}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank == 0 ? p.warningBg : p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: rank == 0 ? const Color(0xFFF59E0B) : p.border,
        ),
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  context.l10n
                      .t('{v1} orders')
                      .replaceAll('{v1}', (c.totalOrders).toString()),
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            context.l10n
                .t('MMK {v1}')
                .replaceAll('{v1}', (c.totalSpending).toString()),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: rank == 0 ? const Color(0xFFF59E0B) : AppColors.brandPurpleDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _behaviorCard(BuildContext context) {
    final p = context.palette;
    final b = analytics.purchaseBehavior;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('Purchase Behavior'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _behaviorRow(
            context,
            Icons.attach_money,
            'Avg. Spending',
            'MMK ${b.avgSpendingPerCustomer}',
          ),
          const SizedBox(height: 8),
          _behaviorRow(
            context,
            Icons.calendar_today,
            'Most Frequent Day',
            b.mostFrequentDay.isEmpty ? '-' : b.mostFrequentDay,
          ),
          const SizedBox(height: 8),
          _behaviorRow(
            context,
            Icons.access_time,
            'Most Frequent Hour',
            b.mostFrequentHour.isEmpty ? '-' : b.mostFrequentHour,
          ),
        ],
      ),
    );
  }

  Widget _behaviorRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final p = context.palette;
    return Row(
      children: [
        Icon(icon, size: 18, color: p.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: p.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
        ),
      ],
    );
  }
}
