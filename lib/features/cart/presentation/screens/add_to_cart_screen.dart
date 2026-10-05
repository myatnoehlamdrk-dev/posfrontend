import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/cart/data/cart_card_mapper.dart';
import 'package:posfrontend/features/cart/data/cart_store.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_card_entity.dart';
import 'package:posfrontend/features/cart/presentation/screens/cart_card_screen.dart';
import 'package:posfrontend/features/cart/presentation/widgets/cart_item_row.dart';
import 'package:posfrontend/features/cart/presentation/widgets/add_to_cart_skeleton.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_repository_impl.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

class AddToCartScreen extends StatefulWidget {
  const AddToCartScreen({super.key});

  @override
  State<AddToCartScreen> createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  static const int _perPage = 20;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollCtrl = ScrollController();

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  /// The signed-in user's identity, used to drop other shops' orders. Resolved
  /// once because the orders endpoint returns every shop's drafts and nothing
  /// else on the page distinguishes them.
  ///
  /// Not `late final`: it is read in [didChangeDependencies] rather than
  /// `initState`, because `AuthScope.userOf` goes through
  /// `dependOnInheritedWidgetOfExactType` and Flutter forbids establishing an
  /// inherited-widget dependency before `initState` has finished.
  Set<String> _ownerKeys = const {};

  /// Order ids confirmed to belong to this user, and whether that confirmation
  /// has happened at all. Before the first successful fetch the store is shown
  /// unfiltered — otherwise a failed request would look like an empty cart, and
  /// the cached cards on the device would be unreachable.
  final Set<String> _allowedOrderIds = {};
  bool _ownershipChecked = false;

  @override
  void initState() {
    super.initState();
    CartStore.instance.addListener(_onCartChanged);
    CartStore.instance.init();
    _scrollCtrl.addListener(_onScroll);
    _loadBackendCards();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = AuthScope.userOf(context);
    final keys = cartOwnerKeys(
      userId: user?.id,
      fullName: user?.fullName,
      email: user?.email,
    );
    // Re-filtering only matters if the signed-in user actually changed, which
    // also stops the order fetch from being re-run on every unrelated rebuild.
    if (setEquals(keys, _ownerKeys)) return;
    _ownerKeys = keys;
    _allowedOrderIds.clear();
    _ownershipChecked = false;
    _page = 1;
    _hasMore = true;
    _loadBackendCards();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    CartStore.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_loadingMore || !_hasMore) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadBackendCards();
    }
  }

  Future<void> _loadBackendCards() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    try {
      final result = await SaleHistoryRepositoryImpl().getOrders(
        page: _page,
        perPage: _perPage,
      );
      final data = result['data'];
      final meta = result['meta'];
      if (data is! List) {
        _hasMore = false;
        return;
      }
      final cards = <CartCardEntity>[];
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        // Another shop's draft is not ours to show, let alone to merge into.
        if (!cartOrderBelongsTo(item, _ownerKeys)) continue;
        final card = cartCardFromOrder(item);
        if (card != null) cards.add(card);
      }
      await CartStore.instance.mergeCards(cards);
      if (mounted) {
        setState(() {
          _allowedOrderIds.addAll(cards.map((c) => c.orderId));
          _ownershipChecked = true;
        });
      }
      final lastPage = meta is Map<String, dynamic> ? meta['last_page'] : null;
      _hasMore = lastPage is num
          ? _page < lastPage.toInt()
          : data.length >= _perPage;
      _page++;
    } catch (_) {
      _hasMore = false;
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _reload() async {
    if (_loadingMore) return;
    _loadingMore = true;
    _page = 1;
    _hasMore = true;
    try {
      final localOnly = CartStore.instance.value
          .where((c) => c.orderId.isEmpty)
          .toList();
      final fresh = <CartCardEntity>[];
      var page = 1;
      while (true) {
        final result = await SaleHistoryRepositoryImpl().getOrders(
          page: page,
          perPage: _perPage,
        );
        final data = result['data'];
        final meta = result['meta'];
        if (data is! List) break;
        for (final item in data) {
          if (item is! Map<String, dynamic>) continue;
          if (!cartOrderBelongsTo(item, _ownerKeys)) continue;
          final card = cartCardFromOrder(item);
          if (card != null) fresh.add(card);
        }
        final lastPage = meta is Map<String, dynamic>
            ? meta['last_page']
            : null;
        if (lastPage is num && page >= lastPage.toInt()) break;
        if (lastPage is! num && data.length < _perPage) break;
        if (page >= 100) break;
        page++;
      }
      await CartStore.instance.replaceAll([...localOnly, ...fresh]);
      if (mounted) {
        setState(() {
          _allowedOrderIds
            ..clear()
            ..addAll(fresh.map((c) => c.orderId));
          _ownershipChecked = true;
        });
      }
    } catch (_) {
      // Keep the current list if the reload fails
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  // The order-row mapping now lives in `cartCardFromOrder` so this screen and
  // the products screen agree on what an existing card is.

  @override
  Widget build(BuildContext context) {
    // Filtered here as well as at fetch time. Cards persisted by an earlier
    // session — or by whoever used this device last — are still in the store,
    // and the store has no notion of ownership, so the list is the last place
    // another shop's card can be kept off the screen.
    final cards = CartStore.instance.value
        .where(
          (card) =>
              card.orderId.isEmpty ||
              !_ownershipChecked ||
              _allowedOrderIds.contains(card.orderId),
        )
        .toList();
    return AppShell(
      active: DrawerDestination.addToCart,
      scaffoldKey: _scaffoldKey,
      backgroundColor: context.palette.scaffoldBg,
      wrap: (_, shell) => shell,
      body: (context, isWide) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t('Add to Cart'),
              // No hamburger on a wide window: the sidebar is already on screen.
              showMenuButton: !isWide,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(
              child: cards.isEmpty
                  ? RefreshableBody(
                      onRefresh: _reload,
                      // The empty state is a `Center`, and without a viewport
                      // floor the scroll view would collapse it to the top.
                      fill: true,
                      child: _loadingMore ? _loadingState() : _emptyState(),
                    )
                  : RefreshIndicator(
                      onRefresh: _reload,
                      color: const Color(0xFF2D1B69),
                      backgroundColor: context.palette.surface,
                      child: _cardsList(cards),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const AddToCartSkeleton();
  }

  Widget _emptyState() {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: p.textMuted),
          const SizedBox(height: 20),
          Text(
            context.l10n.t('Cart is empty'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.t('Add products to your cart'),
            style: TextStyle(fontSize: 14, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _cardsList(List<CartCardEntity> cards) {
    final showFooter = _loadingMore || !_hasMore;
    return ListView.separated(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: cards.length + (showFooter ? 1 : 0),
      separatorBuilder: (ctx, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        if (index == cards.length) return _footer();
        return _CardTile(card: cards[index]);
      },
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _loadingMore
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.teal,
                  strokeWidth: 2,
                ),
              )
            : Text(
                context.l10n.t('No more items'),
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final CartCardEntity card;

  const _CardTile({required this.card});

  // Brightness-dependent tokens, resolved from the active theme.
  AppPalette _tokens(BuildContext context) => context.palette;

  @override
  Widget build(BuildContext context) {
    final p = _tokens(context);
    final titleColor = p.textPrimary;
    final mutedColor = p.textSecondary;
    final accentColor = p.primary;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => CartCardScreen(card: card)));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
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
                      color: p.chipBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // Two keys rather than a `{v1}` in one template:
                          // "1 item" and "5 items" are different words, and
                          // collapsing them would force one of them to be
                          // wrong. The other three languages have no plural
                          // distinction, so they simply ignore the second.
                          context.l10n
                              .t(
                                card.totalQuantity == 1
                                    ? '1 item'
                                    : '{v1} items',
                              )
                              .replaceAll(
                                '{v1}',
                                card.totalQuantity.toString(),
                              ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(card.createdAt),
                          style: TextStyle(fontSize: 11, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  PriceText(
                    card.total,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.isDark
                          ? const Color(0xFF5EEAD4)
                          : AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showDeleteDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: p.dangerFg,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 20, color: p.border),
              for (final item in card.items.take(2)) ...[
                CartItemRow(item: item, dense: true),
                if (item != card.items.take(2).last) const SizedBox(height: 8),
              ],
              if (card.items.length > 2) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n
                      .t('+{v1} more')
                      .replaceAll('{v1}', (card.items.length - 2).toString()),
                  style: TextStyle(
                    fontSize: 11,
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final dangerFg = context.palette.dangerFg;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.l10n.t('Delete Cart')),
          content: Text(
            context.l10n
                .t('Are you sure you want to delete this cart "{v1} items"?')
                .replaceAll('{v1}', (card.totalQuantity).toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.t('Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                context.l10n.t('Delete'),
                style: TextStyle(color: dangerFg),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    if (card.orderId.isNotEmpty) {
      try {
        await OrderRepositoryImpl().deleteOrder(card.orderId);
      } catch (_) {
        // Backend order deletion failure is non-critical; card still removed
      }
    }
    if (!context.mounted) return;
    await CartStore.instance.removeCard(card.id);
  }
}
