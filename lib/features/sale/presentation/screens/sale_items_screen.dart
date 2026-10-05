import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/sale_history_view_model.dart';
import 'package:posfrontend/features/sale/presentation/screens/sale_detail_screen.dart';
import 'package:posfrontend/features/sale/presentation/widgets/sale_items_skeleton.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/filter_tabs.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class SaleItemScreen extends StatefulWidget {
  const SaleItemScreen({super.key});

  @override
  State<SaleItemScreen> createState() => _SaleItemScreenState();
}

class _SaleItemScreenState extends State<SaleItemScreen> {
  late final SaleHistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SaleHistoryViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadAll(refresh: true);
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
    return AppShell(
      active: DrawerDestination.saleItem,
      backgroundColor: p.scaffoldBg,
      wrap: (_, shell) => shell,
      body: (context, isWide) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t('Sales Items'),
              // No hamburger on a wide window: the sidebar is already on screen.
              showMenuButton: !isWide,
            ),
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
    final p = context.palette;
    if (_viewModel.isLoading && _viewModel.filteredOrders.isEmpty) {
      return const SaleItemsSkeleton();
    }
    if (_viewModel.errorMessage != null && _viewModel.filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _viewModel.errorMessage!,
              style: TextStyle(color: p.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _viewModel.loadAll(refresh: true),
              child: Text(context.l10n.t('Retry')),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _viewModel.loadAll(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
            _viewModel.loadMore();
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
                context.l10n.t(
                  'Products that are already sale and will be sale (Order)',
                ),
                style: TextStyle(fontSize: 13, color: p.textSecondary),
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
              ..._viewModel.filteredOrders.asMap().entries.map(
                (entry) => KeyedSubtree(
                  key: ValueKey('${entry.value.orderId}_${entry.key}'),
                  child: _buildOrderCard(entry.value),
                ),
              ),
              if (_viewModel.isLoading && _viewModel.filteredOrders.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brandPurple),
                  ),
                ),
              if (!_viewModel.hasMore && _viewModel.filteredOrders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      context.l10n.t('No more items'),
                      style: TextStyle(color: p.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
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
    final p = context.palette;
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
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: p.cardShadow,
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
                color: p.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fastfood_outlined,
                color: p.textSecondary,
                size: 28,
              ),
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
                          order.voucherNo.isNotEmpty
                              ? order.voucherNo
                              : 'Order #${order.orderId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isAlreadySale ? p.successBg : p.warningBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAlreadySale ? 'Already Sale' : 'Will Be Sale',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAlreadySale ? p.successFg : p.warningFg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _confirmDelete(order),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.productName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  if (order.customerName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      order.customerName,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (order.createdBy.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      context.l10n
                          .t('by {v1}')
                          .replaceAll('{v1}', (order.createdBy).toString()),
                      style: TextStyle(
                        fontSize: 11,
                        color: p.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        context.l10n
                            .t('x{v1}')
                            .replaceAll('{v1}', (order.quantity).toString()),
                        style: TextStyle(
                          fontSize: 12,
                          color: p.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: p.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(order.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                      Flexible(
                        child: PriceText(
                          order.amount.toDouble(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPurple,
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
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.l10n.t('Delete Item'),
          style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary),
        ),
        content: Text(
          context.l10n
              .t('Are you sure you want to delete "{v1}"?')
              .replaceAll('{v1}', (order.productName).toString()),
          style: TextStyle(color: p.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.l10n.t('Cancel'),
              style: TextStyle(color: p.textSecondary),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.l10n.t('Delete')),
          ),
        ],
      ),
    );
  }
}
