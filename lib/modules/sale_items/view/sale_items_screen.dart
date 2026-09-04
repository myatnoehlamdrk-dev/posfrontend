import 'package:flutter/material.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/sale_items/model/sale_item_models.dart';
import 'package:posfrontend/modules/sale_items/view/sale_detail_screen.dart';
import 'package:posfrontend/modules/sale_items/viewmodel/sale_item_view_model.dart';
import 'package:posfrontend/modules/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/filter_tabs.dart';
import 'package:posfrontend/shared/widgets/search_input_bar.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

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
            AppScreenTopBar(title: 'Sales Items', user: widget.user),
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
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }
    if (_viewModel.error != null && _viewModel.sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_viewModel.error!, style: const TextStyle(color: AppColors.gray)),
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Products that are already sale and will be sale (Order)',
              style: TextStyle(fontSize: 13, color: AppColors.gray),
            ),
            const SizedBox(height: 16),
            FilterTabs(
              tabs: [
                ('All', _viewModel.sales.length),
                ('Sold', _viewModel.sales.where((o) => o.status == OrderStatus.alreadySale).length),
                ('Order', _viewModel.sales.where((o) => o.status == OrderStatus.willBeSale).length),
              ],
              selectedIndex: _selectedTab,
              onTabChanged: (i) => setState(() => _selectedTab = i),
            ),
            const SizedBox(height: 16),
            SearchInputBar(
              controller: _searchController,
              hintText: 'Search products, order ID, customer...',
              onChanged: (_) => setState(() {}),
            ),
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
              child: const Icon(Icons.fastfood_outlined, color: AppColors.gray, size: 28),
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
                            color: AppColors.gray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAlreadySale ? AppColors.greenBg : AppColors.orangeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAlreadySale ? 'Already Sale' : 'Will Be Sale',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAlreadySale ? AppColors.green : AppColors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _confirmDelete(order),
                        child: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.titleColor,
                    ),
                  ),
                  if (order.customerName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      order.customerName,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'x${order.quantity}',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.gray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(order.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.gray),
                        ),
                      ),
                      Flexible(
                        child: PriceText(
                          order.amount.toDouble(),
                          maxLength: 14,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
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

  void _confirmDelete(SaleOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Item', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.titleColor)),
        content: Text(
          'Are you sure you want to delete "${order.productName}"?',
          style: const TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _viewModel.deleteItem(order);
              if (mounted) {
                showSuccessSnackBar(context, success ? 'Item deleted' : 'Failed to delete');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
