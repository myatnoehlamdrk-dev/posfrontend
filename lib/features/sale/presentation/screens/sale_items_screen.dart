import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/sale_history_view_model.dart';
import 'package:posfrontend/features/sale/presentation/screens/sale_detail_screen.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/filter_tabs.dart';
import 'package:posfrontend/shared/widgets/search_input_bar.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

class SaleItemScreen extends StatefulWidget {
  const SaleItemScreen({super.key});

  @override
  State<SaleItemScreen> createState() => _SaleItemScreenState();
}

class _SaleItemScreenState extends State<SaleItemScreen> {
  final _searchController = TextEditingController();
  late final SaleHistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.instance<SaleHistoryViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadAll(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      drawer: const AppDrawer(activeItem: 'Sale Item'),
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenTopBar(title: 'Sales Items'),
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) => _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading && _viewModel.filteredOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }
    if (_viewModel.errorMessage != null && _viewModel.filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_viewModel.errorMessage!, style: const TextStyle(color: AppColors.gray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _viewModel.loadAll(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _viewModel.loadAll(refresh: true),
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
                ('All', _viewModel.filteredOrders.length),
                ('Sold', _viewModel.totalSalesCount),
                ('Order', _viewModel.totalOrdersCount),
              ],
              selectedIndex: _selectedTabIndex,
              onTabChanged: (i) {
                _viewModel.setTab(['All', 'Sold', 'Order'][i]);
              },
            ),
            const SizedBox(height: 16),
            SearchInputBar(
              controller: _searchController,
              hintText: 'Search products, order ID, customer...',
              onChanged: _viewModel.setSearchQuery,
            ),
            const SizedBox(height: 16),
            ..._viewModel.filteredOrders.asMap().entries.map((entry) => KeyedSubtree(
              key: ValueKey('${entry.value.orderId}_${entry.key}'),
              child: _buildOrderCard(entry.value),
            )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  int get _selectedTabIndex {
    switch (_viewModel.selectedTab) {
      case 'Sold':
        return 1;
      case 'Order':
        return 2;
      default:
        return 0;
    }
  }

  Widget _buildOrderCard(SaleOrderEntity order) {
    final isAlreadySale = order.status == OrderStatus.alreadySale;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SaleDetailScreen(order: order)),
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
                  if (order.createdBy.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'by ${order.createdBy}',
                      style: const TextStyle(fontSize: 11, color: AppColors.gray, fontStyle: FontStyle.italic),
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
      return dt.toFormattedDateTime();
    } catch (_) {
      return dateStr;
    }
  }

  void _confirmDelete(SaleOrderEntity order) {
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
              bool success;
              if (order.status == OrderStatus.alreadySale) {
                success = await _viewModel.deleteSale(order.orderId);
              } else {
                success = await _viewModel.deleteOrder(order.orderId);
              }
              if (mounted) {
                if (success) {
                  showSuccessSnackBar(context, 'Item deleted');
                } else {
                  showErrorSnackBar(context, 'Failed to delete');
                }
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
