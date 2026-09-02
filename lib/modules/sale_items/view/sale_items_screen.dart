import 'package:flutter/material.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/sale_items/model/sale_item_models.dart';
import 'package:posfrontend/modules/sale_items/view/sale_detail_screen.dart';
import 'package:posfrontend/modules/sale_items/viewmodel/sale_item_view_model.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';

class SaleItemScreen extends StatefulWidget {
  final LoginResponse? user;

  const SaleItemScreen({super.key, this.user});

  @override
  State<SaleItemScreen> createState() => _SaleItemScreenState();
}

class _SaleItemScreenState extends State<SaleItemScreen> {
  int _selectedTab = 0;
  final _searchController = TextEditingController();
  late final SaleItemViewModel _viewModel;

  static const Color teal = Color(0xFF14B8A6);
  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color green = Color(0xFF16A34A);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color orange = Color(0xFFD97706);
  static const Color orangeBg = Color(0xFFFEF3C7);

  @override
  void initState() {
    super.initState();
    _viewModel = SaleItemViewModel();
    _viewModel.addListener(_onViewModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadSales(refresh: true);
    });
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      drawer: AppDrawer(user: widget.user, activeItem: 'Sale Item'),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading && _viewModel.sales.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: teal));
    }
    if (_viewModel.error != null && _viewModel.sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_viewModel.error!, style: const TextStyle(color: gray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _viewModel.loadSales(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _viewModel.loadSales(refresh: true),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Products that are already sale and will be sale (Order)',
              style: TextStyle(fontSize: 13, color: gray),
            ),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            ..._filteredOrders.map((order) => _buildOrderCard(order)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<SaleOrder> get _filteredOrders {
    var list = _viewModel.sales;
    if (_selectedTab == 1) {
      list = list.where((o) => o.status == OrderStatus.alreadySale).toList();
    } else if (_selectedTab == 2) {
      list = list.where((o) => o.status == OrderStatus.willBeSale).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((o) =>
          o.orderId.toLowerCase().contains(query) ||
          o.productName.toLowerCase().contains(query) ||
          o.customerName.toLowerCase().contains(query)).toList();
    }
    return list;
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: const Icon(Icons.menu, color: titleColor),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Sales Items',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, color: titleColor),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 18,
            backgroundColor: teal,
            child: Text(
              widget.user != null && widget.user!.fullName.trim().isNotEmpty
                  ? widget.user!.fullName.trim()[0].toUpperCase()
                  : 'A',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final allCount = _viewModel.sales.length;
    final alreadySaleCount = _viewModel.sales.where((o) => o.status == OrderStatus.alreadySale).length;
    final willBeSaleCount = _viewModel.sales.where((o) => o.status == OrderStatus.willBeSale).length;
    final tabs = [
      ('All', allCount),
      ('Sold', alreadySaleCount),
      ('Order', willBeSaleCount),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? teal : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${tabs[i].$1} (${tabs[i].$2})',
                    style: TextStyle(
                      color: active ? Colors.white : gray,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search products, order ID, customer...',
          hintStyle: TextStyle(color: gray, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: gray, size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildOrderCard(SaleOrder order) {
    final isAlreadySale = order.status == OrderStatus.alreadySale;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SaleDetailScreen(order: order, user: widget.user)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fastfood_outlined, color: gray, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.voucherNo.isNotEmpty ? order.voucherNo : 'Order #${order.orderId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: gray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAlreadySale ? greenBg : orangeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAlreadySale ? 'Already Sale' : 'Will Be Sale',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAlreadySale ? green : orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  if (order.customerName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      order.customerName,
                      style: const TextStyle(fontSize: 12, color: gray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'x${order.quantity}',
                        style: const TextStyle(fontSize: 12, color: gray, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today_outlined, size: 12, color: gray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(order.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: gray),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'MMK ${_formatAmount(order.amount)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
