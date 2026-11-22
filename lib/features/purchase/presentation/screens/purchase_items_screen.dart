import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/purchase/presentation/screens/add_purchase_sheet.dart';
import 'package:posfrontend/features/purchase/presentation/screens/add_supplier_sheet.dart';
import 'package:posfrontend/features/purchase/presentation/screens/purchase_detail_screen.dart';
import 'package:posfrontend/features/purchase/presentation/widgets/purchase_items_skeleton.dart';
import 'package:posfrontend/features/purchase/presentation/viewmodels/purchase_item_view_model.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_empty_state.dart';
import 'package:posfrontend/shared/widgets/app_page_transitions.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/error_retry_view.dart';
import 'package:posfrontend/shared/widgets/filter_tabs.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class PurchaseItemsScreen extends StatefulWidget {
  const PurchaseItemsScreen({super.key});

  @override
  State<PurchaseItemsScreen> createState() => _PurchaseItemsScreenState();
}

class _PurchaseItemsScreenState extends State<PurchaseItemsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late final PurchaseItemViewModel _viewModel;

  /// Drives the breathing opacity of the live-record dot in the header badge,
  /// mirroring the `animate-ping` pulse in the mockup.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _viewModel = PurchaseItemViewModel();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.35,
      upperBound: 1,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadPurchaseItems(refresh: true);
      _viewModel.loadSuppliers();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      active: DrawerDestination.purchaseItem,
      backgroundColor: Colors.transparent,
      wrap: (_, shell) => shell,
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPurchaseSheet,
        backgroundColor: AppColors.brandPurple,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: (context, isWide) => SafeArea(
        // One listener for the whole body: the app bar (badge + tabs) and the
        // list both read state, and both must rebuild on a tab change — the
        // pill lives in the bar, the rows live in the list.
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => Column(
            children: [
              AppScreenTopBar(
                title: context.l10n.t('Purchase Items'),
                // No hamburger on a wide window: the sidebar is already on screen.
                showMenuButton: !isWide,
                badge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.palette.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: context.palette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, child) =>
                            Opacity(opacity: _pulse.value, child: child),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: context.palette.successFg,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_viewModel.purchaseItems.length} Total Record${_viewModel.purchaseItems.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: AppTypography.labelSmallSize,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: FilterTabs(
                        tabs: [
                          ('All', _viewModel.purchaseItems.length),
                          (
                            'Shop',
                            _viewModel.purchaseItems
                                .where((o) => o.status == PurchaseStatus.completed)
                                .length,
                          ),
                          (
                            'Inventory',
                            _viewModel.purchaseItems
                                .where((o) => o.status == PurchaseStatus.pending)
                                .length,
                          ),
                        ],
                        selectedIndex: _selectedTab,
                        onTabChanged: (i) => setState(() => _selectedTab = i),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(context),
              ),
            ],
          ),
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
      return ErrorRetryView(
        message: _viewModel.errorMessage,
        onRetry: () => _viewModel.loadPurchaseItems(refresh: true),
      );
    }
    if (_filteredOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _viewModel.loadPurchaseItems(refresh: true),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: AppEmptyState(
                icon: Icons.search_off_rounded,
                title: context.l10n.t('No matching transactions found'),
                subtitle: context.l10n.t(
                  'Try clearing your filter or switching between All, Shop, and Inventory tabs.',
                ),
                actionLabel: context.l10n.t('Reset Filters'),
                onAction: () => setState(() => _selectedTab = 0),
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _viewModel.loadPurchaseItems(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200 &&
              _viewModel.hasMore) {
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
              ..._filteredOrders.asMap().entries.map(
                (entry) => KeyedSubtree(
                  key: ValueKey('${entry.value.orderId}_${entry.key}'),
                  child: _OrderCard(
                    order: entry.value,
                    onTap: () {
                      Navigator.of(context).push(
                        AppPageTransitions.fadeSlide<void>(
                          PurchaseDetailScreen(order: entry.value),
                        ),
                      );
                    },
                    onMarkCompleted: entry.value.status ==
                            PurchaseStatus.pending
                        ? () => _viewModel.updateStatus(
                              entry.value.orderId,
                              'completed',
                            )
                        : null,
                  ),
                ),
              ),
              if (_viewModel.isLoading && _viewModel.purchaseItems.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brandPurple),
                  ),
                ),
              if (!_viewModel.hasMore && _viewModel.purchaseItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      context.l10n.t('No more items'),
                      style: TextStyle(color: p.textSecondary, fontSize: AppTypography.labelMediumSize),
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

/// One purchase row, restyled to match the sales screen: a glass card that
/// lifts under the cursor with a violet spotlight tracking it, a copyable
/// order-number pill, and the status / amount block pinned to the right
/// (dropped below the details with a divider when the card is too narrow).
class _OrderCard extends StatefulWidget {
  final PurchaseOrder order;
  final VoidCallback onTap;
  final VoidCallback? onMarkCompleted;

  const _OrderCard({
    required this.order,
    required this.onTap,
    this.onMarkCompleted,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  /// Cursor position inside the card, or null when the pointer is out.
  /// Drives the radial spotlight that follows the mouse in the mockup.
  Offset? _mouse;

  bool get _hovered => _mouse != null;

  PurchaseOrder get order => widget.order;

  String get _voucher => 'Order #${order.orderId}';

  void _copyVoucher() {
    Clipboard.setData(ClipboardData(text: _voucher));
    showSuccessMessage(
      context,
      context.l10n.t('Copied {v1}').replaceAll('{v1}', _voucher),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isCompleted = order.status == PurchaseStatus.completed;

    final statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted ? p.successBg : p.warningBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isCompleted ? p.successFg : p.warningFg).withValues(
            alpha: 0.3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? p.successFg : p.warningFg).withValues(
              alpha: 0.25,
            ),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isCompleted ? p.successFg : p.warningFg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isCompleted
                ? context.l10n.t('Shop')
                : context.l10n.t('Inventory'),
            style: TextStyle(
              fontSize: AppTypography.labelSmallSize,
              fontWeight: FontWeight.w600,
              color: isCompleted ? p.successFg : p.warningFg,
            ),
          ),
        ],
      ),
    );

    final markButton = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onMarkCompleted,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: p.successBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: p.successFg.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 14, color: p.successFg),
            const SizedBox(width: 4),
            Text(
              context.l10n.t('Mark as Shop'),
              style: TextStyle(
                fontSize: AppTypography.labelSmallSize,
                fontWeight: FontWeight.w600,
                color: p.successFg,
              ),
            ),
          ],
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order-number pill — one tap copies the id, as in the mockup.
        GestureDetector(
          onTap: _copyVoucher,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: p.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _voucher,
                  style: TextStyle(
                    fontSize: AppTypography.labelSmallSize,
                    color: p.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.copy_rounded,
                  size: 12,
                  color: p.textSecondary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          order.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppTypography.bodyLargeSize,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        if (order.supplierName.isNotEmpty || order.createdBy.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              if (order.supplierName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(
                    order.supplierName,
                    style: TextStyle(
                      fontSize: AppTypography.labelSmallSize,
                      color: p.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (order.supplierName.isNotEmpty && order.createdBy.isNotEmpty)
                const SizedBox(width: 6),
              if (order.createdBy.isNotEmpty)
                Expanded(
                  child: Text(
                    context.l10n
                        .t('by {v1}')
                        .replaceAll('{v1}', (order.createdBy).toString()),
                    style: TextStyle(
                      fontSize: AppTypography.labelSmallSize,
                      color: p.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.violet400.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.violet400.withValues(alpha: 0.2)),
              ),
              child: Text(
                context.l10n
                    .t('x{v1}')
                    .replaceAll('{v1}', (order.quantity).toString()),
                style: TextStyle(
                  fontSize: AppTypography.labelSmallSize,
                  color: AppColors.violet300,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '@',
              style: TextStyle(
                fontSize: AppTypography.labelSmallSize,
                color: p.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            PriceText(
              order.unitPrice.toDouble(),
              style: TextStyle(
                fontSize: AppTypography.labelSmallSize,
                color: p.textSecondary,
                fontFamily: 'monospace',
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
                  fontSize: AppTypography.labelSmallSize,
                  color: p.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (e) => setState(() => _mouse = e.localPosition),
        onHover: (e) {
          if (_mouse != e.localPosition) {
            setState(() => _mouse = e.localPosition);
          }
        },
        onExit: (_) => setState(() => _mouse = null),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Side-by-side status column only when there is room for it;
            // otherwise the mockup's stacked arrangement takes over.
            final wide = constraints.maxWidth >= 480;

            final amount = PriceText(
              order.totalAmount.toDouble(),
              style: TextStyle(
                fontSize: wide
                    ? AppTypography.titleSmallSize
                    : AppTypography.bodyLargeSize,
                fontWeight: FontWeight.w700,
                color: _hovered ? Colors.white : AppColors.violet300,
                fontFamily: 'monospace',
              ),
            );

            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                statusBadge,
                if (widget.onMarkCompleted != null) ...[
                  const SizedBox(width: 6),
                  markButton,
                ],
                if (wide) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: p.surface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.border),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ],
            );

            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              // The mockup's -2px lift on hover.
              transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    p.surface.withValues(alpha: 0.78),
                    p.surface.withValues(alpha: 0.90),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hovered
                      ? AppColors.violet400.withValues(alpha: 0.28)
                      : p.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _hovered ? 0.65 : 0.45,
                    ),
                    blurRadius: _hovered ? 40 : 18,
                    spreadRadius: _hovered ? -15 : 0,
                    offset: Offset(0, _hovered ? 18 : 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Cursor spotlight: a soft violet radial that tracks the
                  // pointer, the signature effect of the mockup's cards.
                  if (_hovered)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final w =
                              c.maxWidth.isFinite && c.maxWidth > 0
                                  ? c.maxWidth
                                  : 1.0;
                          final h =
                              c.maxHeight.isFinite && c.maxHeight > 0
                                  ? c.maxHeight
                                  : 1.0;
                          final cx =
                              ((_mouse!.dx / w) * 2 - 1).clamp(-1.0, 1.0);
                          final cy =
                              ((_mouse!.dy / h) * 2 - 1).clamp(-1.0, 1.0);
                          return IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: RadialGradient(
                                  center: Alignment(cx, cy),
                                  radius: 0.55,
                                  colors: const [
                                    Color(0x167C3AED),
                                    Color(0x007C3AED),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _iconBox(p, isCompleted),
                        const SizedBox(width: 14),
                        Expanded(child: details),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            actions,
                            const SizedBox(height: 10),
                            amount,
                          ],
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _iconBox(p, isCompleted),
                            const SizedBox(width: 14),
                            Expanded(child: details),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: p.border,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              amount,
                              const SizedBox(width: 6),
                              actions,
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _iconBox(AppPalette p, bool isCompleted) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? [const Color(0x268B5CF6), const Color(0x141E1A2E)]
              : [const Color(0x26F59E0B), const Color(0x141E1A2E)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0x408B5CF6)
              : const Color(0x40F59E0B),
        ),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: isCompleted ? AppColors.violet300 : p.warningFg,
        size: 22,
      ),
    );
  }
}

/// `Nov 21, 2026 7:36 PM` — the mockup's timestamp format, parsed as local
/// time so a purchase made here is not printed in the server's clock.
String _formatDate(String dateStr) {
  try {
    final dt = DateTime.parse(dateStr).toLocal();
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${_monthName(dt.month)} ${dt.day}, ${dt.year} $hour12:$minute $ampm';
  } catch (_) {
    return dateStr;
  }
}

String _monthName(int m) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[m - 1];
}
