import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/inventory/domain/entities/inventory_store_item.dart';
import 'package:posfrontend/shared/widgets/app_message.dart';
import 'package:posfrontend/features/inventory/presentation/screens/add_inventory_store_screen.dart';
import 'package:posfrontend/features/inventory/presentation/screens/adjust_stock_screen.dart';
import 'package:posfrontend/features/inventory/presentation/screens/edit_inventory_store_screen.dart';
import 'package:posfrontend/features/inventory/presentation/screens/inventory_product_placeholder_screen.dart';
import 'package:posfrontend/features/inventory/presentation/viewmodels/inventory_overview_view_model.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/error_retry_view.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

/// Stock Overview — the sidebar's Inventory destination.
class InventoryOverviewScreen extends StatefulWidget {
  const InventoryOverviewScreen({super.key});

  @override
  State<InventoryOverviewScreen> createState() =>
      _InventoryOverviewScreenState();
}

class _InventoryOverviewScreenState extends State<InventoryOverviewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  late final InventoryOverviewViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = InventoryOverviewViewModel();
    _vm.load();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      _vm.loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigateToDashboard(context);
      },
      child: AppShell(
        active: DrawerDestination.inventoryOverview,
        scaffoldKey: _scaffoldKey,
        backgroundColor: p.scaffoldBg,
        wrap: (_, shell) => shell,
        body: (context, isWide) => SafeArea(
          child: Column(
            children: [
              AppScreenTopBar(
                title: context.l10n.t('Inventory'),
                showMenuButton: !isWide,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _vm,
                  builder: (context, _) {
                    return RefreshableBody(
                      onRefresh: _vm.refresh,
                      scrollController: _scroll,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildHeading(context, p),
                            const SizedBox(height: 22),
                            _buildKpis(context, p),
                            const SizedBox(height: 22),
                            _buildTableContainer(context, p),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- heading ----

  Widget _buildHeading(BuildContext context, AppPalette p) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 640;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('INVENTORY MANAGEMENT'),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: const Color.fromARGB(255, 90, 61, 164),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.t('Inventory overview'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.t(
                  "Track quantities, update stock levels, and manage your product catalog."),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: p.textSecondary,
              ),
            ),
          ],
        );
        final buttons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _outlineButton(
              p: p,
              icon: Icons.upload_outlined,
              label: context.l10n.t('Export to shop'),
              onTap: () => _showExportDialog(context),
            ),
            const SizedBox(width: 8),
            _primaryButton(
              p: p,
              icon: Icons.add,
              label: context.l10n.t('Add product'),
              onTap: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                      builder: (_) => const AddInventoryStoreScreen()),
                );
                if (ok == true) _vm.refresh();
              },
            ),
          ],
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleBlock, const SizedBox(height: 12), buttons],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            buttons,
          ],
        );
      },
    );
  }

  Widget _outlineButton({
    required AppPalette p,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: Color(0xFFDFE7E2)),
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required AppPalette p,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.surface,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  // ---- KPIs ----

  Widget _buildKpis(BuildContext context, AppPalette p) {
    final rows = _vm.rows;
    final totalProducts = _vm.total > 0 ? _vm.total : rows.length;
    final unitsInStock = rows.fold<int>(0, (s, r) => s + r.quantityOnHand);
    final lowStock = rows.where((r) => r.status == 'Low Stock').length;
    final outStock = rows.where((r) => r.status == 'Out of Stock').length;
    final cards = <Widget>[
      _kpiCard(
        p: p,
        icon: Icons.inventory_2_outlined,
        iconBg: const Color(0xFFE8F0FF),
        iconColor: const Color(0xFF4779D9),
        label: context.l10n.t('Total products'),
        value: totalProducts.withCommas(),
        support: context.l10n.t('Across all categories'),
        onTap: () => _vm.setStatusFilter('all'),
      ),
      _kpiCard(
        p: p,
        icon: Icons.all_inbox_outlined,
        iconBg: const Color(0xFFE1F6ED),
        iconColor: const Color(0xFF15966B),
        label: context.l10n.t('Units in stock'),
        value: unitsInStock.withCommas(),
        support: context.l10n.t('Across all items'),
        onTap: () => _vm.setStatusFilter('all'),
      ),
      _kpiCard(
        p: p,
        icon: Icons.warning_amber_rounded,
        iconBg: const Color(0xFFFFF0DB),
        iconColor: const Color(0xFFD97706),
        label: context.l10n.t('Low stock'),
        value: lowStock.withCommas(),
        support: context.l10n.t('Needs attention'),
        onTap: () => _vm.setStatusFilter('low'),
      ),
      _kpiCard(
        p: p,
        icon: Icons.store_outlined,
        iconBg: const Color(0xFFFCE8E5),
        iconColor: const Color(0xFFD94B3D),
        label: context.l10n.t('Out of stock'),
        value: outStock.withCommas(),
        support: context.l10n.t('Needs restock'),
        onTap: () => _vm.setStatusFilter('out'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 4 : 2;
        final rows = <Widget>[];
        for (var i = 0; i < cards.length; i += cols) {
          final end = (i + cols).clamp(0, cards.length);
          final slice = cards.sublist(i, end);
          rows.add(Row(
            children: [
              for (var j = 0; j < slice.length; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(child: slice[j]),
              ],
              for (var k = slice.length; k < cols; k++) ...[
                const SizedBox(width: 12),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ));
          if (end < cards.length) rows.add(const SizedBox(height: 12));
        }
        return Column(children: rows);
      },
    );
  }

  Widget _kpiCard({
    required AppPalette p,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String support,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
          boxShadow: p.cardElevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const Spacer(),
                Icon(Icons.more_horiz, size: 16, color: const Color(0xFF87938E)),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w400, color: p.textSecondary)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary)),
            const Spacer(),
            Text(support,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 8, fontWeight: FontWeight.w400, color: p.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ---- table container ----

  Widget _buildTableContainer(BuildContext context, AppPalette p) {
    if (_vm.isLoading && _vm.rows.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: p.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_vm.hasError && _vm.rows.isEmpty) {
      return ErrorRetryView(
        message: _vm.errorMessage,
        onRetry: _vm.load,
        fill: false,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(context, p),
          LayoutBuilder(
            builder: (context, tc) {
              final scale = tc.maxWidth > 868 ? tc.maxWidth / 868 : 1.0;
              final total = 868.0 * scale;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: total,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderRow(context, p, scale),
                      for (final r in _vm.filteredRows) _buildRow(context, p, r, scale),
                      if (_vm.filteredRows.isEmpty && !_vm.isLoading)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(context.l10n.t('No products found.'),
                                style: TextStyle(color: p.textSecondary)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_vm.loadingMore)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 720;
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.t('All inventory'),
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              Text(
                context.l10n
                    .t('{v1} products shown')
                    .replaceAll('{v1}', _vm.filteredRows.length.toString()),
                style: TextStyle(fontSize: 9, color: p.textSecondary),
              ),
            ],
          );
          final right = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 216,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.chipBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _vm.setSearch,
                    style: TextStyle(fontSize: 10),
                    decoration: InputDecoration(
                      hintText: context.l10n.t('Search product, SKU, supplier...'),
                      hintStyle: TextStyle(
                          fontSize: 10, color: p.textSecondary),
                      prefixIcon: Icon(Icons.search,
                          size: 16, color: p.textSecondary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 114,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _vm.statusFilter,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    style: TextStyle(
                        fontSize: 10, color: p.textPrimary),
                    items: [
                      DropdownMenuItem(
                          value: 'all',
                          child: Text(context.l10n.t('All'))),
                      DropdownMenuItem(
                          value: 'in',
                          child: Text(context.l10n.t('In stock'))),
                      DropdownMenuItem(
                          value: 'low',
                          child: Text(context.l10n.t('Low stock'))),
                      DropdownMenuItem(
                          value: 'out',
                          child: Text(context.l10n.t('Out of stock'))),
                    ],
                    onChanged: (v) {
                      if (v != null) _vm.setStatusFilter(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: p.border),
                ),
                child: Icon(Icons.tune, size: 16, color: p.textSecondary),
              ),
            ],
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 8), right],
            );
          }
          return Row(
            children: [
              Expanded(child: left),
              right,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, AppPalette p, double scale) {
    final w = [230.0, 90.0, 80.0, 130.0, 90.0, 120.0, 40.0].map((x) => x * scale).toList();
    return Container(
      height: 32,
      color: p.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: w[0], child: const _H('Product')),
          SizedBox(width: w[1], child: const _H('Category')),
          SizedBox(width: w[2], child: const _H('Status')),
          SizedBox(width: 20 * scale),
          SizedBox(width: w[3], child: const _H('Stock Level')),
          SizedBox(width: 20 * scale),
          SizedBox(width: w[4], child: const _H('Value')),
          SizedBox(width: w[5], child: const _H('Updated')),
          SizedBox(width: w[6], child: const _H('')),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppPalette p, InventoryStoreItem item, double scale) {
    final w = [230.0, 90.0, 80.0, 130.0, 90.0, 120.0, 40.0].map((x) => x * scale).toList();
    return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            // Product
            SizedBox(
              width: w[0],
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: p.chipBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.inventory_2_outlined, size: 18, color: p.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.textPrimary)),
                        Text(
                          item.sku,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 7.5, color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Category
            SizedBox(
              width: w[1],
              child: Text(
                item.category.isEmpty ? '—' : item.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9.5, color: p.textPrimary),
              ),
            ),
            // Status
            SizedBox(
              width: w[2],
              child: _statusBadge(p, item.status),
            ),
            SizedBox(width: 20 * scale),
            // Stock level
            SizedBox(
              width: w[3],
              child: _stockLevel(p, item),
            ),
            SizedBox(width: 20 * scale),
            // Value
            SizedBox(
              width: w[4],
              child: Text(
                item.value.asCurrency(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary),
              ),
            ),
            // Updated
            SizedBox(
              width: w[5],
              child: Text(
                _relativeTime(context, item.updatedAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 8.5, color: p.textSecondary),
              ),
            ),
            // Actions
            SizedBox(
              width: w[6],
              child: Center(
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      size: 15, color: Color(0xFF5A6373)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'view',
                        child: Text(context.l10n.t('View details'))),
                    PopupMenuItem(
                        value: 'edit',
                        child: Text(context.l10n.t('Edit product'))),
                    PopupMenuItem(
                        value: 'adjust',
                        child: Text(context.l10n.t('Adjust stock'))),
                    PopupMenuItem(
                        value: 'archive',
                        child: Text(context.l10n.t('Archive product'))),
                  ],
                  onSelected: (v) async {
                    if (v == 'view') {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => InventoryProductPlaceholderScreen(
                              productId: item.id)));
                    } else if (v == 'edit') {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) =>
                                EditInventoryStoreScreen(item: item)),
                      );
                      if (ok == true) _vm.refresh();
                    } else if (v == 'archive') {
                      try {
                        await ApiClient.instance.put(
                          '/inventory-stores/${item.id}',
                          data: {'active': false},
                        );
                        if (mounted) _vm.refresh();
                      } catch (e) {
                        if (mounted) showErrorMessage(context, e);
                      }
                    } else if (v == 'adjust') {
                      final ok = await showGeneralDialog<bool>(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'Adjust stock',
                        barrierColor: Colors.black54,
                        transitionDuration:
                            const Duration(milliseconds: 250),
                        transitionBuilder: (ctx, anim, _, child) =>
                            SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                        pageBuilder: (ctx, _, secondary) => Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: MediaQuery.of(ctx).size.width * 0.425,
                            child: AdjustStockScreen(item: item),
                          ),
                        ),
                      );
                      if (ok == true) _vm.refresh();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _statusBadge(AppPalette p, String status) {
    Color bg, fg;
    switch (status) {
      case 'Low Stock':
        bg = p.warningBg;
        fg = p.warningFg;
        break;
      case 'Out of Stock':
        bg = p.dangerBg;
        fg = p.dangerFg;
        break;
      default:
        bg = p.successBg;
        fg = p.successFg;
    }
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status == 'In Stock'
                ? context.l10n.t('In stock')
                : status == 'Low Stock'
                    ? context.l10n.t('Low stock')
                    : context.l10n.t('Out of stock'),
            style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _stockLevel(AppPalette p, InventoryStoreItem item) {
    const capacity = 40.0; // defined healthy-stock reference level
    final frac = (item.quantityOnHand / capacity).clamp(0.0, 1.0);
    Color fill;
    if (item.quantityOnHand <= 0) {
      fill = const Color(0xFFE05B50);
    } else if (item.quantityOnHand <= InventoryStoreItem.lowStockThreshold) {
      fill = const Color(0xFFF4A340);
    } else {
      fill = const Color(0xFF35C98A);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(item.quantityOnHand.withCommas(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary)),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: frac == 0 ? 0.02 : frac,
                  child: Container(
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          context.l10n
              .t('At {v1}')
              .replaceAll('{v1}', InventoryStoreItem.lowStockThreshold.toString()),
          style: TextStyle(fontSize: 7, color: p.textSecondary),
        ),
      ],
    );
  }

  String _relativeTime(BuildContext context, DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return context.l10n.t('just now');
    if (diff.inMinutes < 60) {
      return context.l10n
          .t('{v1} min ago')
          .replaceAll('{v1}', diff.inMinutes.toString());
    }
    if (diff.inHours < 24) {
      return context.l10n
          .t('{v1} hr ago')
          .replaceAll('{v1}', diff.inHours.toString());
    }
    final days = diff.inDays;
    return context.l10n
        .t('{v1} days ago')
        .replaceAll('{v1}', days.toString());
  }

  void _showExportDialog(BuildContext context) {
    String? selectedShop;
    String selectedType = 'Self';
    String recipientName = '';
    final shops = ['Shop A', 'Shop B', 'Shop C'];
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final p = context.palette;
            return AlertDialog(
              title: Text(context.l10n.t('Export to shop')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.t('Select shop'),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: recipientName.isEmpty ? null : recipientName,
                    decoration: InputDecoration(
                      labelText: context.l10n.t('Recipient name'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const ['John Doe', 'Jane Smith', 'Acme Corp']
                        .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => recipientName = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedShop,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: shops
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedShop = v),
                  ),
                  const SizedBox(height: 12),
                  Text(context.l10n.t('Type'),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedType = 'Self'),
                          child: Container(
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedType == 'Self'
                                  ? const Color(0xFFE8F7F0)
                                  : p.surface,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: selectedType == 'Self'
                                    ? const Color(0xFF15966B)
                                    : p.border,
                              ),
                            ),
                            child: Text(
                              context.l10n.t('Self'),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: selectedType == 'Self'
                                    ? const Color(0xFF087A50)
                                    : p.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedType = 'Public'),
                          child: Container(
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedType == 'Public'
                                  ? const Color(0xFFE8F7F0)
                                  : p.surface,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: selectedType == 'Public'
                                    ? const Color(0xFF15966B)
                                    : p.border,
                              ),
                            ),
                            child: Text(
                              context.l10n.t('Public'),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: selectedType == 'Public'
                                    ? const Color(0xFF087A50)
                                    : p.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.l10n.t('Cancel')),
                ),
                ElevatedButton(
                  onPressed: selectedShop == null
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.t(
                                  'Export to {shop} ({type}) for {name} — demo.')
                                  .replaceAll('{shop}', selectedShop!)
                                  .replaceAll('{type}', selectedType)
                                  .replaceAll('{name}', recipientName)),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14241E),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(context.l10n.t('Export')),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

class _H extends StatelessWidget {
  final String text;
  const _H(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF788681),
        letterSpacing: 0.7,
      ),
    );
  }
}