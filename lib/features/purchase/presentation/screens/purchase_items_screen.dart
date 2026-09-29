import 'package:flutter/material.dart';
import 'package:posfrontend/features/purchase/presentation/screens/add_purchase_sheet.dart';
import 'package:posfrontend/features/purchase/presentation/screens/add_supplier_sheet.dart';
import 'package:posfrontend/features/purchase/presentation/screens/purchase_detail_screen.dart';
import 'package:posfrontend/features/purchase/presentation/widgets/purchase_items_skeleton.dart';
import 'package:posfrontend/features/purchase/presentation/viewmodels/purchase_item_view_model.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/filter_tabs.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class PurchaseItemsScreen extends StatefulWidget {
  const PurchaseItemsScreen({super.key});

  @override
  State<PurchaseItemsScreen> createState() => _PurchaseItemsScreenState();
}

class _PurchaseItemsScreenState extends State<PurchaseItemsScreen> {
  int _selectedTab = 0;
  late final PurchaseItemViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PurchaseItemViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadPurchaseItems(refresh: true);
      _viewModel.loadSuppliers();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffoldBg,
      drawer: const AppDrawer(activeItem: 'Purchase Item'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPurchaseSheet,
        backgroundColor: AppColors.teal,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(title: 'Purchase Items'),
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) => _buildBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final p = context.palette;
    if (_viewModel.isLoading && _viewModel.purchaseItems.isEmpty) {
      return const PurchaseItemsSkeleton();
    }
    if (_viewModel.errorMessage != null && _viewModel.purchaseItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_viewModel.errorMessage!, style: TextStyle(color: p.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _viewModel.loadPurchaseItems(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _viewModel.loadPurchaseItems(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
            _viewModel.loadPurchaseItems();
          }
          return false;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Manage purchase orders from your suppliers',
                style: TextStyle(fontSize: 13, color: p.textSecondary),
              ),
              const SizedBox(height: 16),
              FilterTabs(
                tabs: [
                  ('All', _viewModel.purchaseItems.length),
                  ('Completed', _viewModel.purchaseItems.where((o) => o.status == PurchaseStatus.completed).length),
                  ('Pending', _viewModel.purchaseItems.where((o) => o.status == PurchaseStatus.pending).length),
                ],
                selectedIndex: _selectedTab,
                onTabChanged: (i) => setState(() => _selectedTab = i),
              ),
              const SizedBox(height: 16),
              ..._filteredOrders.map((order) => _buildOrderCard(context, order)),
              if (_viewModel.isLoading && _viewModel.purchaseItems.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  ),
                ),
              if (!_viewModel.hasMore && _viewModel.purchaseItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No more items',
                      style: TextStyle(color: p.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  List<PurchaseOrder> get _filteredOrders {
    var list = _viewModel.purchaseItems;
    if (_selectedTab == 1) {
      list = list.where((o) => o.status == PurchaseStatus.completed).toList();
    } else if (_selectedTab == 2) {
      list = list.where((o) => o.status == PurchaseStatus.pending).toList();
    }
    return list;
  }

  Widget _buildOrderCard(BuildContext context, PurchaseOrder order) {
    final p = context.palette;
    final isCompleted = order.status == PurchaseStatus.completed;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PurchaseDetailScreen(order: order),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: p.cardShadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.chipBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: p.textSecondary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderId}',
                        style: TextStyle(fontSize: 12, color: p.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.productName,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.textPrimary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted ? p.successBg : p.warningBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'Pending',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isCompleted ? AppColors.green : AppColors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: p.border, height: 1),
            const SizedBox(height: 10),
            if (order.createdBy.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'by ${order.createdBy}',
                  style: TextStyle(fontSize: 11, color: p.textSecondary, fontStyle: FontStyle.italic),
                ),
              ),
            Row(
              children: [
                Icon(Icons.business_outlined, size: 14, color: p.textSecondary),
                const SizedBox(width: 4),
                Text(order.supplierName, style: TextStyle(fontSize: 12, color: p.textSecondary)),
                const Spacer(),
                Text(
                  'x${order.quantity}',
                  style: TextStyle(fontSize: 12, color: p.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                Text('@', style: TextStyle(fontSize: 12, color: p.textSecondary)),
                const SizedBox(width: 4),
                PriceText(order.unitPrice.toDouble(), style: TextStyle(fontSize: 12, color: p.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: p.textSecondary),
                const SizedBox(width: 4),
                Text(order.date, style: TextStyle(fontSize: 11, color: p.textSecondary)),
                const Spacer(),
                if (!isCompleted)
                  GestureDetector(
                    onTap: () => _viewModel.updateStatus(order.orderId, 'completed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Mark Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green)),
                    ),
                  ),
                if (isCompleted) const SizedBox(width: 8),
                PriceText(order.totalAmount.toDouble(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.tealDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNewPurchaseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return AddPurchaseSheet(
          viewModel: _viewModel,
          onAddSupplier: _showAddSupplierSheet,
        );
      },
    );
  }

  void _showAddSupplierSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return AddSupplierSheet(
          viewModel: _viewModel,
          onSupplierCreated: _showNewPurchaseSheet,
        );
      },
    );
  }
}
