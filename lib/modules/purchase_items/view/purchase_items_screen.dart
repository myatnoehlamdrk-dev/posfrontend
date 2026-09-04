import 'package:flutter/material.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/purchase_items/model/purchase_models.dart';
import 'package:posfrontend/modules/purchase_items/view/add_purchase_sheet.dart';
import 'package:posfrontend/modules/purchase_items/view/add_supplier_sheet.dart';
import 'package:posfrontend/modules/purchase_items/viewmodel/purchase_item_view_model.dart';
import 'package:posfrontend/modules/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/filter_tabs.dart';
import 'package:posfrontend/shared/widgets/search_input_bar.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

class PurchaseItemsScreen extends StatefulWidget {
  final LoginResponse? user;

  const PurchaseItemsScreen({super.key, this.user});

  @override
  State<PurchaseItemsScreen> createState() => _PurchaseItemsScreenState();
}

class _PurchaseItemsScreenState extends State<PurchaseItemsScreen> {
  int _selectedTab = 0;
  final _searchController = TextEditingController();
  late final PurchaseItemViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PurchaseItemViewModel();
    _viewModel.addListener(_onViewModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadPurchaseItems(refresh: true);
      _viewModel.loadSuppliers();
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
      drawer: AppDrawer(user: widget.user, activeItem: 'Purchase Item'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPurchaseSheet,
        backgroundColor: AppColors.teal,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(title: 'Purchase Items', user: widget.user),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading && _viewModel.purchaseItems.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }
    if (_viewModel.error != null && _viewModel.purchaseItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_viewModel.error!, style: const TextStyle(color: AppColors.gray)),
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Manage purchase orders from your suppliers',
              style: TextStyle(fontSize: 13, color: AppColors.gray),
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
            SearchInputBar(
              controller: _searchController,
              hintText: 'Search item, order ID, supplier...',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            ..._filteredOrders.map((order) => _buildOrderCard(order)),
            const SizedBox(height: 80),
          ],
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
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((o) =>
          o.orderId.toLowerCase().contains(query) ||
          o.productName.toLowerCase().contains(query) ||
          o.supplierName.toLowerCase().contains(query)).toList();
    }
    return list;
  }

  Widget _buildOrderCard(PurchaseOrder order) {
    final isCompleted = order.status == PurchaseStatus.completed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
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
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.gray, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId}',
                      style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.productName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.titleColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.greenBg : AppColors.orangeBg,
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
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.business_outlined, size: 14, color: AppColors.gray),
              const SizedBox(width: 4),
              Text(order.supplierName, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
              const Spacer(),
              Text(
                'x${order.quantity}',
                style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              const Text('@', style: TextStyle(fontSize: 12, color: AppColors.gray)),
              const SizedBox(width: 4),
              PriceText(order.unitPrice.toDouble(), maxLength: 12, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.gray),
              const SizedBox(width: 4),
              Text(order.date, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
              const Spacer(),
              if (!isCompleted)
                GestureDetector(
                  onTap: () => _viewModel.updateStatus(order.orderId, 'completed'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Mark Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green)),
                  ),
                ),
              if (isCompleted) const SizedBox(width: 8),
              PriceText(order.totalAmount.toDouble(), maxLength: 14, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.tealDark)),
            ],
          ),
        ],
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
