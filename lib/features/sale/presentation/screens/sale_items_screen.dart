import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';

import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/sale_history_view_model.dart';
import 'package:posfrontend/features/sale/presentation/screens/sale_detail_screen.dart';
import 'package:posfrontend/features/sale/presentation/widgets/sale_items_skeleton.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_empty_state.dart';
import 'package:posfrontend/shared/widgets/app_page_transitions.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/error_retry_view.dart';
import 'package:posfrontend/shared/widgets/filter_tabs.dart';
import 'package:posfrontend/shared/widgets/filter_transition.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class SaleItemScreen extends StatefulWidget {
  const SaleItemScreen({super.key});

  @override
  State<SaleItemScreen> createState() => _SaleItemScreenState();
}

class _SaleItemScreenState extends State<SaleItemScreen>
    with SingleTickerProviderStateMixin {
  late final SaleHistoryViewModel _viewModel;

  /// Drives the breathing opacity of the live-record dot in the header badge,
  /// mirroring the `animate-ping` pulse in the mockup.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _viewModel = SaleHistoryViewModel();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.35,
      upperBound: 1,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadAll(refresh: true);
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
      active: DrawerDestination.saleItem,
      backgroundColor: Colors.transparent,
      wrap: (_, shell) => shell,
      body: (context, isWide) => SafeArea(
        // One listener for the whole body: the app bar (badge + tabs) and the
        // list both read view-model state, and both must rebuild on a tab
        // change — the pill lives in the bar, the rows live in the list.
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => Column(
            children: [
              AppScreenTopBar(
                title: context.l10n.t('Sale Items'),
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
                        '${_viewModel.filteredOrders.length} Total Record${_viewModel.filteredOrders.length == 1 ? '' : 's'}',
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
                          ('All', _viewModel.filteredOrders.length),
                          ('Sold', _viewModel.totalSalesCount),
                          ('Order', _viewModel.totalOrdersCount),
                        ],
                        selectedIndex: _selectedTabIndex,
                        onTabChanged: (i) {
                          _viewModel.setTab(['All', 'Sold', 'Order'][i]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FilterTransition(
                  filterKey: '${_viewModel.selectedTab}_${_viewModel.selectedYear}',
                  child: _buildBody(),
                ),
              ),
            ],
          ),
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
      return ErrorRetryView(
        message: _viewModel.errorMessage,
        onRetry: () => _viewModel.loadAll(refresh: true),
      );
    }
    if (_localOrders().isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _viewModel.loadAll(refresh: true),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: AppEmptyState(
                icon: Icons.search_off_rounded,
                title: context.l10n.t('No matching transactions found'),
                subtitle: context.l10n.t(
                  'Try clearing your search filter or switching between All, Sold, and Order tabs.',
                ),
                actionLabel: context.l10n.t('Reset Filters'),
                onAction: _resetFilters,
              ),
            ),
          ),
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
              ..._localOrders().asMap().entries.map(
                (entry) => KeyedSubtree(
                  key: ValueKey('${entry.value.orderId}_${entry.key}'),
                  child: _OrderCard(
                    order: entry.value,
                    onTap: () {
                      Navigator.of(context).push(
                        AppPageTransitions.fadeSlide<void>(
                          SaleDetailScreen(order: entry.value),
                        ),
                      );
                    },
                    onDelete: () => _confirmDelete(entry.value),
                  ),
                ),
              ),
              if (_viewModel.isLoading && _viewModel.filteredOrders.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandPurple,
                    ),
                  ),
                ),
              if (!_viewModel.hasMore && _viewModel.filteredOrders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      context.l10n.t('No more items'),
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: AppTypography.labelMediumSize,
                      ),
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

  List<SaleOrderEntity> _localOrders() => _viewModel.filteredOrders;

  /// Clears the year and tab in one pass — the empty state's reset action.
  void _resetFilters() {
    _viewModel.setYear(null);
    _viewModel.setTab('All');
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

  void _confirmDelete(SaleOrderEntity order) {
    final p = context.palette;
    bool deleting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
              onPressed: deleting ? null : () => Navigator.pop(ctx),
              child: Text(
                context.l10n.t('Cancel'),
                style: TextStyle(color: p.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: deleting
                  ? null
                  : () async {
                      setDialogState(() => deleting = true);
                      bool success;
                      if (order.status == OrderStatus.alreadySale) {
                        success = await _viewModel.deleteSale(order.orderId);
                      } else {
                        success = await _viewModel.deleteOrder(order.orderId);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        if (success) {
                          showSuccessMessage(context, 'Item deleted');
                        } else {
                          showErrorMessage(context, 'Failed to delete');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.red.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(context.l10n.t('Delete')),
            ),
          ],
        ),
      ),
    );
  }
}

/// One transaction row, restyled to the sales mockup: a glass card that lifts
/// under the cursor with a violet spotlight tracking it, a copyable invoice
/// pill, and the status / amount block pinned to the right (dropped below the
/// details with a divider when the card is too narrow for a side column).
class _OrderCard extends StatefulWidget {
  final SaleOrderEntity order;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  /// Cursor position inside the card, or null when the pointer is out.
  /// Drives the radial spotlight that follows the mouse in the mockup.
  Offset? _mouse;

  bool get _hovered => _mouse != null;

  SaleOrderEntity get order => widget.order;

  String get _voucher =>
      order.voucherNo.isNotEmpty ? order.voucherNo : 'Order #${order.orderId}';

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
    final isAlreadySale = order.status == OrderStatus.alreadySale;

    final statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAlreadySale ? p.successBg : p.warningBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isAlreadySale ? p.successFg : p.warningFg).withValues(
            alpha: 0.3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: (isAlreadySale ? p.successFg : p.warningFg).withValues(
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
              color: isAlreadySale ? p.successFg : p.warningFg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isAlreadySale
                ? context.l10n.t('Already Sale')
                : context.l10n.t('Order'),
            style: TextStyle(
              fontSize: AppTypography.labelSmallSize,
              fontWeight: FontWeight.w600,
              color: isAlreadySale ? p.successFg : p.warningFg,
            ),
          ),
        ],
      ),
    );

    final deleteButton = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onDelete,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.18)),
        ),
        child: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invoice pill — one tap copies the id, as in the mockup.
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
        if (order.customerName.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: p.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  order.customerName,
                  style: TextStyle(
                    fontSize: AppTypography.labelSmallSize,
                    color: p.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
              order.amount.toDouble(),
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
                const SizedBox(width: 6),
                deleteButton,
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
                        _iconBox(p, isAlreadySale),
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
                            _iconBox(p, isAlreadySale),
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
                          child: Row(
                            children: [
                              amount,
                              const Spacer(),
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

  Widget _iconBox(AppPalette p, bool isAlreadySale) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAlreadySale
              ? [const Color(0x268B5CF6), const Color(0x141E1A2E)]
              : [const Color(0x26F59E0B), const Color(0x141E1A2E)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlreadySale
              ? const Color(0x408B5CF6)
              : const Color(0x40F59E0B),
        ),
      ),
      child: Icon(
        Icons.fastfood_outlined,
        color: isAlreadySale ? AppColors.violet300 : p.warningFg,
        size: 22,
      ),
    );
  }
}

/// `Nov 21, 2026 7:36 PM` — the mockup's timestamp format, parsed as local
/// time so a sale made here is not printed in the server's clock.
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
