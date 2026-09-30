import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/customer/domain/entities/customer.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class CustomersTab extends StatefulWidget {
  final CustomerAnalyticsEntity analytics;

  const CustomersTab({super.key, required this.analytics});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color purple = Color(0xFF6D28D9);

  List<CustomerSummaryItemEntity> get _filtered {
    if (_searchQuery.isEmpty) return widget.analytics.customerSummary;
    final q = _searchQuery.toLowerCase();
    return widget.analytics.customerSummary
        .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.l10n.t('Search customers...'),
              prefixIcon: Icon(Icons.search, color: p.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: p.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: p.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: p.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: purple),
              ),
              filled: true,
              fillColor: p.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.analytics.customerSummary.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                context.l10n.t('No customer data yet.'),
                style: TextStyle(color: p.textSecondary, fontSize: 14),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _filtered.length,
              itemBuilder: (context, index) => _customerCard(_filtered[index]),
            ),
          ),
      ],
    );
  }

  Widget _customerCard(CustomerSummaryItemEntity c) {
    final p = context.palette;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: purple,
            ),
          ),
        ),
      ),
      title: Text(
        c.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
      ),
      subtitle: Text(
        context.l10n
            .t('{v1} orders · MMK {v2}')
            .replaceAll('{v1}', (c.totalOrders).toString())
            .replaceAll('{v2}', (c.totalSpending).toString()),
        style: TextStyle(fontSize: 12, color: p.textSecondary),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _detailRow('Phone', c.phone.isEmpty ? '-' : c.phone),
              _detailRow('Location', c.location.isEmpty ? '-' : c.location),
              _detailRow('Total Quantity', '${c.totalQuantity}'),
              _detailRow('Avg. Order', 'MMK ${c.avgOrderValue}'),
              _detailRow('Last Purchase', c.lastPurchaseDate ?? '-'),
              if (c.topProducts.isNotEmpty) ...[
                Divider(height: 16, color: p.border),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.l10n.t('Top Products'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ...c.topProducts.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 14,
                          color: p.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          context.l10n
                              .t('x{v1}')
                              .replaceAll('{v1}', (item.count).toString()),
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: p.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
