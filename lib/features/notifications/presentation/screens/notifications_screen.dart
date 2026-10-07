import 'package:flutter/material.dart';
import 'package:posfrontend/features/category/data/repositories/category_repository_impl.dart';
import 'package:posfrontend/features/notifications/data/notification_store.dart';
import 'package:posfrontend/features/notifications/domain/entities/app_notification.dart';
import 'package:posfrontend/features/package/data/repositories/package_repository_impl.dart';
import 'package:posfrontend/features/package/presentation/screens/package_details_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/features/notifications/presentation/screens/stock_report_detail_screen.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

/// In-app history of pushed notifications, reached from the bell in the
/// app bars. The store only ever contains what the Dart side actually saw
/// (foreground arrivals and taps on tray entries), so this is the durable
/// copy — the system tray entry itself is gone once dismissed.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationStore _store = NotificationStore.instance;
  late final TabController _tabController;

  /// Which tab is showing: `system` | `alert` | `news`. Opens on Alert —
  /// it is the only category that receives pushes today, so a fresh
  /// install should not land on an empty System tab.
  String _category = 'alert';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppNotification.categories.length,
      vsync: this,
      initialIndex: AppNotification.categories.indexOf('alert'),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _store.refresh();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.notifications,
              showBackButton: true,
              showMenuButton: false,
              showNotificationsButton: false,
            ),
            _buildCategoryBar(context),
            Expanded(
              child: ListenableBuilder(
                listenable: _store,
                builder: (context, _) {
                  final items = _store.value
                      .where((n) => n.category == _category)
                      .toList();
                  if (items.isEmpty) return _buildEmpty(context);
                  return _buildList(context, items);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Segmented System / Alert / News selector, styled after the tab bar on
  /// the customer page (chip surface, solid purple indicator).
  Widget _buildCategoryBar(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        0,
      ),
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(
          () => _category = AppNotification.categories[index],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: p.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.brandPurpleDark,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(text: context.l10n.t('System')),
          Tab(text: context.l10n.t('Alert')),
          Tab(text: context.l10n.t('News')),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final p = context.palette;
    return RefreshableBody(
      onRefresh: _refresh,
      fill: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 56,
              color: p.textMuted,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              context.l10n.noNotificationsYet,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: AppTypography.bodyMediumSize,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            if (_category == 'alert')
              Text(
                context.l10n.t('Stock alerts will appear here.'),
                style: TextStyle(
                  color: p.textMuted,
                  fontSize: AppTypography.bodySmallSize,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<AppNotification> items) {
    final p = context.palette;
    final unread = _store.unreadCount;
    // Mark-all and clear-all stay global (they act on the whole store), so
    // they key off the store totals, not just the visible tab.
    final total = _store.value.length;
    return Column(
      children: [
        if (unread > 0 || total > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s8,
              0,
            ),
            child: Row(
              children: [
                if (unread > 0)
                  TextButton(
                    onPressed: _store.markAllRead,
                    child: Text(
                      context.l10n.markAllRead,
                      style: TextStyle(
                        color: p.accentText,
                        fontSize: AppTypography.bodySmallSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                if (total > 1)
                  TextButton(
                    onPressed: () => _confirmClear(context),
                    child: Text(
                      context.l10n.clearAll,
                      style: TextStyle(
                        color: p.dangerFg,
                        fontSize: AppTypography.bodySmallSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: p.accentText,
            backgroundColor: p.surface,
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) =>
                  _NotificationTile(notification: items[index]),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.l10n.t('Clear all notifications?')),
          content: Text(
            context.l10n.t('This removes the saved notification history.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.t('Cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _store.clear();
              },
              child: Text(
                context.l10n.clearAll,
                style: TextStyle(color: context.palette.dangerFg),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  ({IconData icon, Color background, Color foreground}) get _style {
    switch (notification.type) {
      case 'stock_out':
      case 'out_of_stock':
        return (
          icon: Icons.remove_shopping_cart_outlined,
          background: const Color(0xFFFEE2E2),
          foreground: const Color(0xFFB91C1C),
        );
      case 'low_stock':
        return (
          icon: Icons.warning_amber_rounded,
          background: const Color(0xFFFEF3C7),
          foreground: const Color(0xFFB45309),
        );
      case 'stock_restored':
        return (
          icon: Icons.add_shopping_cart_outlined,
          background: const Color(0xFFDCFCE7),
          foreground: const Color(0xFF15803D),
        );
      case 'package_out':
        return (
          icon: Icons.inventory_2_outlined,
          background: const Color(0xFFFEE2E2),
          foreground: const Color(0xFFB91C1C),
        );
      case 'stock_report':
        return (
          icon: Icons.assignment_outlined,
          background: const Color(0xFFDBEAFE),
          foreground: const Color(0xFF1D4ED8),
        );
      default:
        return (
          icon: Icons.notifications_none_outlined,
          background: const Color(0xFFF3F4F6),
          foreground: const Color(0xFF5A6373),
        );
    }
  }

  /// The status pairs are constant-accent on purpose (same reasoning as
  /// `AppPalette.primary`): they carry the alert kind, not the theme, and
  /// the dark palette's softer variants would wash out against a dark card.
  ({Color background, Color foreground}) _statusColors(bool isDark) {
    if (!isDark) return (background: _style.background, foreground: _style.foreground);
    switch (notification.type) {
      case 'stock_out':
      case 'out_of_stock':
        return (background: const Color(0xFF35191B), foreground: const Color(0xFFFCA5A5));
      case 'low_stock':
        return (background: const Color(0xFF302710), foreground: const Color(0xFFFCD34D));
      case 'stock_restored':
        return (background: const Color(0xFF13301F), foreground: const Color(0xFF6EE7A8));
      case 'package_out':
        return (background: const Color(0xFF35191B), foreground: const Color(0xFFFCA5A5));
      case 'stock_report':
        return (background: const Color(0xFF17233A), foreground: const Color(0xFF93C5FD));
      default:
        return (background: const Color(0xFF354253), foreground: const Color(0xFFA2AAB8));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _statusColors(isDark);
    final n = notification;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: p.cardElevation,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: status.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(_style.icon, color: status.foreground, size: 20),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: AppTypography.bodyMediumSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        n.body,
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: AppTypography.bodySmallSize,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      _timeLabel(context, n.receivedAt),
                      style: TextStyle(
                        color: p.textMuted,
                        fontSize: AppTypography.labelSmallSize,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: p.textMuted,
                ),
                tooltip: context.l10n.t('Delete'),
                onPressed: () => NotificationStore.instance.remove(n.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    await NotificationStore.instance.markRead(notification.id);
    if (!context.mounted) return;

    // The daily summary is one message covering many products — its list
    // of products lives on a dedicated detail page.
    if (notification.type == 'stock_report') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              StockReportDetailScreen(notification: notification),
        ),
      );
      return;
    }

    final productId = notification.productId;
    if (productId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        ),
      );
      return;
    }

    final packageId = notification.packageId;
    if (packageId != null) {
      await _openPackage(context, packageId);
    }
  }

  /// Package-out alerts carry a package id instead of a product id; the
  /// detail screen wants the package plus its category, both fetched by id.
  /// A failure (offline, record deleted) just leaves the list open — the
  /// row is already marked read.
  Future<void> _openPackage(BuildContext context, String packageId) async {
    try {
      final package = await PackageRepositoryImpl().getPackageById(packageId);
      final category = await CategoryRepositoryImpl().getCategoryById(
        package.categoryId,
      );
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PackageDetailsScreen(
            package: package,
            category: category,
          ),
        ),
      );
    } catch (_) {
      debugPrint('Package notification navigation failed: $packageId');
    }
  }

  String _timeLabel(BuildContext context, DateTime time) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return l10n.t('Just now');
    if (diff.inMinutes < 60) {
      return l10n
          .t('{v1} min ago')
          .replaceFirst('{v1}', '${diff.inMinutes}');
    }
    if (diff.inHours < 24) {
      return l10n
          .t('{v1} hr ago')
          .replaceFirst('{v1}', '${diff.inHours}');
    }
    if (diff.inDays == 1) return l10n.t('Yesterday');
    return time.toFormattedDateTime();
  }
}
