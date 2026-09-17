import 'package:flutter/material.dart';
import 'package:posfrontend/features/customer/domain/entities/customer.dart';

class CustomersTab extends StatefulWidget {
  final CustomerAnalyticsEntity analytics;

  const CustomersTab({super.key, required this.analytics});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color title = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);
  static const Color border = Color(0xFFE5E7EB);

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: const Icon(Icons.search, color: gray),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: gray),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: purple)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.analytics.customerSummary.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No customer data yet.', style: TextStyle(color: gray, fontSize: 14)),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: purple),
          ),
        ),
      ),
      title: Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: title)),
      subtitle: Text(
        '${c.totalOrders} orders · MMK ${c.totalSpending}',
        style: const TextStyle(fontSize: 12, color: gray),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
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
                const Divider(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Top Products', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: title)),
                ),
                const SizedBox(height: 6),
                ...c.topProducts.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 14, color: gray),
                      const SizedBox(width: 6),
                      Expanded(child: Text(p.name, style: const TextStyle(fontSize: 12, color: title))),
                      Text('x${p.count}', style: const TextStyle(fontSize: 12, color: gray)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: gray)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: title)),
        ],
      ),
    );
  }
}
