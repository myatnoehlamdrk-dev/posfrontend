import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/screens/category_products_screen.dart'
    show VariantPick, VariantPickDialog;
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_products_skeleton.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_product_repository_impl.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_repository_impl.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/quick_sale_view_model.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/sale_view_model.dart';
import 'package:posfrontend/features/sale/presentation/widgets/quick_sale_cart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/cached_product_image.dart';
import 'package:posfrontend/shared/widgets/error_retry_view.dart';
import 'package:posfrontend/shared/widgets/pressable_card.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

/// Sell straight off the shelf: filter by category, scroll the products that
/// belong to it, and check out from a cart that lives beside the grid.
///
/// This is the product catalog's ability — browse, search, open a product —
/// pointed at a different outcome. The catalog exists to *manage* stock, so it
/// drills into detail screens; this one exists to *move* stock, so a tap puts a
/// line in the sale and the detail screen is a secondary action. The layout
/// follows from that: the categories are a filter row rather than a showcase,
/// the grid loads a page at a time as the cashier scrolls, and the cart is the
/// one thing that never leaves the screen.
///
/// Two presentations of the same cart, chosen by how many columns the grid can
/// keep beside the container:
///
///  * **more than two columns still fit once the container's 340 is taken out**
///    — the cart is a container *beside* the grid, on screen from the first
///    frame, so adding and checking out happen without leaving the page.
///    Closing it is a real close: it stays out of the way until the next
///    category pick or product add.
///  * **anything narrower** — there is no room to put anything beside a grid
///    that has to stay tappable, so the same cart lives behind a bar at the
///    bottom that rises as a sheet, revealed when the cashier picks a category
///    or adds a product.
class QuickSaleScreen extends StatefulWidget {
  /// The product feed and the cart to drive. Both default to the production
  /// pair; a test passes its own so nothing reaches for `ApiClient.instance`,
  /// whose base URL is a compile-time define the test runner does not set.
  ///
  /// The screen owns whatever it is handed and disposes it — pass an object
  /// built for that one screen, not one shared with anything else.
  const QuickSaleScreen({super.key, this.catalog, this.sale});

  final QuickSaleViewModel? catalog;
  final SaleViewModel? sale;

  @override
  State<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends State<QuickSaleScreen> {
  /// The cart container's width. The side-by-side layout is offered only while
  /// the grid can keep more than two columns after this much is taken out of
  /// its row — see [_sideBySide].
  static const double _sidePanelWidth = 340;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _search = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late final QuickSaleViewModel _catalog;
  late final SaleViewModel _sale;

  /// Built once: a fresh `Listenable.merge` per build would make the listener
  /// tear itself down and re-subscribe on every repaint.
  late final Listenable _changes;

  /// The cart surface has been engaged: a category was picked, a product went
  /// in, the container was reopened from the bar. It is what raises the bottom
  /// bar on a layout too narrow for the container, and what a dismissed
  /// container falls back to carrying.
  bool _cartOpen = false;

  /// The cashier closed the side container. Only an act of engagement —
  /// picking a category, adding a product, opening the cart from the bar —
  /// clears it, so the close holds instead of flapping open on the next
  /// rebuild.
  bool _cartDismissed = false;

  /// The bottom sheet is on screen. Only mutated from callbacks, never from
  /// build, so it needs no setState.
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog ?? QuickSaleViewModel();
    // The same cart the new-sale screen drives: one submission path (draft
    // order, idempotency key, offline outbox) for every way of making a sale.
    _sale =
        widget.sale ??
        SaleViewModel(
          productRepository: SaleProductRepositoryImpl(),
          saleRepository: SaleRepositoryImpl(),
          orderRepository: OrderRepositoryImpl(),
          customerRepository: CustomerRepositoryImpl(),
        );
    _sale.init();
    _changes = Listenable.merge([_catalog, _sale]);
    _scrollCtrl.addListener(_onScroll);
    _catalog.load();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _search.dispose();
    _catalog.dispose();
    _sale.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent -
            QuickSaleViewModel.prefetchDistance) {
      _catalog.loadMore();
    }
  }

  /// The width of the row the grid and the cart container share: the window
  /// minus the sidebar [AppShell] puts beside the body from its wide
  /// breakpoint up.
  double get _rowWidth {
    final window = MediaQuery.sizeOf(context).width;
    return window >= AppShell.wideBreakpoint
        ? window - AppShell.sidebarWidth
        : window;
  }

  /// Whether the cart can live beside the grid: true when the grid still lays
  /// out more than two columns *after* the container claims its
  /// [_sidePanelWidth].
  ///
  /// The test runs against the row's full width, never the grid's own: the
  /// grid's width is exactly what shrinks when the container opens, so a rule
  /// keyed on it would open the container, lose a column, close it again —
  /// each way forever. The row's width does not depend on the container, so
  /// the answer cannot flap.
  bool get _sideBySide => _crossAxisFor(_rowWidth - _sidePanelWidth) > 2;

  /// The container beside the grid. On a layout with room for it, it is simply
  /// there from the first frame — no category has to be picked first. What
  /// keeps it out of the way afterwards is [_cartDismissed], the cashier's
  /// own close.
  bool get _showSidePanel => _sideBySide && !_cartDismissed;

  /// The bar stands in for the container wherever the container cannot go, and
  /// also carries a dismissed container's cart on a layout that has room for
  /// one.
  bool get _showCartBar => !_showSidePanel && (_cartOpen || _sale.hasItems);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _changes,
      builder: (context, _) {
        return AppShell(
          active: DrawerDestination.quickSale,
          scaffoldKey: _scaffoldKey,
          backgroundColor: context.palette.scaffoldBg,
          wrap: (_, shell) => shell,
          body: _content,
        );
      },
    );
  }

  Widget _content(BuildContext context, bool isWide) {
    return SafeArea(
      child: Column(
        children: [
          AppScreenTopBar(
            title: context.l10n.t('Quick Sale'),
            showMenuButton: !isWide,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          _searchBar(),
          _categoryStrip(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _productArea()),
                _sidePanel(),
              ],
            ),
          ),
          if (_showCartBar) _cartBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- search

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ListenableBuilder(
        listenable: _search,
        builder: (context, _) {
          final p = context.palette;
          return TextField(
            controller: _search,
            onChanged: _catalog.setSearchQuery,
            style: TextStyle(fontSize: 14, color: p.textPrimary),
            decoration: InputDecoration(
              hintText: context.l10n.t('Search products...'),
              hintStyle: TextStyle(fontSize: 14, color: p.textMuted),
              prefixIcon: Icon(Icons.search, color: p.accentText, size: 20),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        _catalog.setSearchQuery('');
                        setState(() {});
                      },
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: p.textSecondary,
                      ),
                    ),
              isDense: true,
              filled: true,
              fillColor: p.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: p.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: p.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: p.primary),
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------- categories

  Widget _categoryStrip() {
    final selected = _catalog.selected;
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        children: [
          _chip(
            label: context.l10n.t('All'),
            selected: selected == null,
            onTap: () => _onSelectCategory(null),
          ),
          for (final category in _catalog.categories)
            _chip(
              label: category.name,
              selected: selected?.id == category.id,
              onTap: () => _onSelectCategory(category),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressableCard(
        onTap: onTap,
        haptic: HapticFeedback.selectionClick,
        pressedScale: 0.94,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandPurple : p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.brandPurple : p.border,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : p.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSelectCategory(SaleCategoryChip? category) async {
    // Engaged first: picking a filter is the moment the cashier commits to
    // building a sale, which is when a dismissed container is wanted back (and
    // what raises the bar where there is no container).
    _revealCart();
    await _catalog.selectCategory(category);
  }

  // --------------------------------------------------------------- products

  /// The grid is its own scroll viewport rather than a `shrinkWrap` grid
  /// inside a `SingleChildScrollView`. That is the difference between lazy
  /// and not: the outer scroll view lays out — and so builds — every card it
  /// holds, page after page, while a viewport grid builds only the cards that
  /// come on screen. Same page-at-a-time fetch as before; now the widgets
  /// match it.
  Widget _productArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _crossAxisFor(constraints.maxWidth);

        // Nothing to scroll yet: the placeholder states keep the pull-to-
        // refresh shell, which stretches them so they can centre themselves.
        if (_catalog.isLoading && _catalog.products.isEmpty) {
          return _refreshable(
            fill: true,
            child: CategoryProductsSkeleton(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 20,
            ),
          );
        }
        if (_catalog.hasError && _catalog.products.isEmpty) {
          return _refreshable(
            fill: true,
            child: ErrorRetryView(
              message: _catalog.errorMessage,
              onRetry: _catalog.reload,
              accentColor: context.palette.primary,
            ),
          );
        }
        if (_catalog.products.isEmpty) {
          return _refreshable(fill: true, child: _emptyState());
        }

        // The trailing cell is the loading status: it exists only while a page
        // is actually in flight, so it appears when the finger nears the end
        // and disappears with the items it fetched. Nothing after the last
        // page — [QuickSaleViewModel.hasMore] is what the server's last page
        // settled on.
        final itemCount = _catalog.products.length + (_catalog.isLoadingMore ? 1 : 0);

        final grid = GridView.builder(
          controller: _scrollCtrl,
          // Always scrollable so pull-to-refresh works even on a short page.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            // Rows breathe farther apart than the category grid's 12: the
            // cards are taller than they are wide, so a tight row gap reads
            // as one continuous wall of stock.
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            // Same aspect ratio as the category grid, so the shared skeleton
            // lands where the real cards will.
            childAspectRatio: 0.72,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == _catalog.products.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: context.palette.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }
            final product = _catalog.products[index];
            return _QuickSaleCard(
              product: product,
              qtyInCart: _qtyInCart(product.id),
              onAdd: () => _addToSale(product),
              onOpen: () => _openProduct(product),
            );
          },
        );

        // A page that failed while the grid already has content: keep the
        // products and say what went wrong, rather than replacing the page
        // with an error.
        if (_catalog.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _inlineError(),
              Expanded(child: _refreshable(child: grid)),
            ],
          );
        }
        return _refreshable(child: grid);
      },
    );
  }

  Widget _refreshable({required Widget child, bool fill = false}) {
    // The placeholder states get the shared stretch-to-viewport shell so they
    // can centre themselves; the grid case below is the one that cannot go
    // through [RefreshableBody].
    if (fill) {
      return RefreshableBody(onRefresh: _catalog.refresh, fill: true, child: child);
    }
    final p = context.palette;
    return RefreshIndicator(
      onRefresh: _catalog.refresh,
      color: p.accentText,
      backgroundColor: p.surface,
      child: child,
    );
  }

  int _crossAxisFor(double width) {
    if (width >= 1100) return 5;
    if (width >= 820) return 4;
    if (width >= 500) return 3;
    return 2;
  }

  Widget _emptyState() {
    final p = context.palette;
    final searching = _catalog.isSearching;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            searching ? Icons.search_off : Icons.inventory_2_outlined,
            size: 64,
            color: p.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            searching
                ? context.l10n
                      .t('No products found for "{v1}"')
                      .replaceAll('{v1}', _catalog.searchQuery.trim())
                : context.l10n.t('No products in this category'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: p.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.t('Try a different keyword or category'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  /// A page that failed while the grid already has content: keep the products
  /// and say what went wrong, rather than replacing the page with an error.
  Widget _inlineError() {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.dangerBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 17, color: p.dangerFg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _catalog.errorMessage ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: p.dangerFg),
            ),
          ),
          TextButton(
            onPressed: _catalog.reload,
            style: TextButton.styleFrom(
              foregroundColor: p.dangerFg,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(44, 32),
            ),
            child: Text(
              context.l10n.t('Retry'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openProduct(CatalogProductView product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.id),
      ),
    );
  }

  // ------------------------------------------------------------ cart surface

  /// What the cashier has of this product, across every line of it in the
  /// sale. The card shows it so "tap to add" reads as a count going up.
  int _qtyInCart(String productId) {
    var total = 0;
    for (final item in _sale.items) {
      if (item.productId == productId) total += item.quantity;
    }
    return total;
  }

  /// Engagement: the surface the cashier wants up — the container on a layout
  /// roomy enough for one, the bar otherwise — is brought up, clearing any
  /// dismissal. A no-op when it is already there.
  void _revealCart() {
    final shown = _sideBySide ? !_cartDismissed : _cartOpen;
    if (shown) return;
    setState(() {
      _cartOpen = true;
      _cartDismissed = false;
    });
  }

  Future<void> _addToSale(CatalogProductView product) async {
    if (product.variants.isNotEmpty) {
      final picks = await showDialog<List<VariantPick>>(
        context: context,
        builder: (_) => VariantPickDialog(
          product: product,
          onConfirm: (picks) => Navigator.of(context).pop(picks),
        ),
      );
      if (!mounted || picks == null || picks.isEmpty) return;
      var added = false;
      for (final pick in picks) {
        added =
            _addLine(
              productId: product.id,
              name: product.name,
              category: product.category,
              imageUrl: product.imageUrl,
              unitPrice: pick.variant.price,
              size: pick.variant.size.isEmpty ? null : pick.variant.size,
              color: pick.variant.color.isEmpty ? null : pick.variant.color,
              quantity: pick.qty,
              available: pick.variant.quantity,
            ) ||
            added;
      }
      if (!added) return;
    } else {
      final added = _addLine(
        productId: product.id,
        name: product.name,
        category: product.category,
        imageUrl: product.imageUrl,
        unitPrice: product.price,
        quantity: 1,
        available: product.stock,
      );
      if (!added) return;
    }
    _revealCart();
  }

  /// Adds [quantity] of a line, or increments the line already there. Returns
  /// false — after saying why — when stock will not cover it, so a caller can
  /// stop instead of revealing a cart that did not change.
  bool _addLine({
    required String productId,
    required String name,
    required String category,
    required String? imageUrl,
    required double unitPrice,
    String? size,
    String? color,
    required int quantity,
    required int available,
  }) {
    if (available <= 0) {
      showErrorMessage(
        context,
        context.l10n
            .t('{v1} is out of stock')
            .replaceAll('{v1}', name),
      );
      return false;
    }
    final items = _sale.items;
    final index = items.indexWhere(
      (e) => e.productId == productId && e.size == size && e.color == color,
    );
    final inCart = index >= 0 ? items[index].quantity : 0;
    if (inCart + quantity > available) {
      showErrorMessage(
        context,
        context.l10n
            .t('{v1} has only {v2} in stock')
            .replaceAll('{v1}', name)
            .replaceAll('{v2}', available.toString()),
      );
      return false;
    }
    if (index >= 0) {
      _sale.updateItemQuantity(index, quantity);
    } else {
      _sale.addItem(
        SaleItemEntity(
          productId: productId,
          productName: name,
          imageUrl: imageUrl,
          unitPrice: unitPrice,
          quantity: quantity,
          size: size,
          color: color,
          category: category,
        ),
      );
    }
    return true;
  }

  /// The container beside the grid. Always present so it can animate its width
  /// to nothing when closed instead of popping in and out of the [Row].
  Widget _sidePanel() {
    final p = context.palette;
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      child: _showSidePanel
          ? SizedBox(
              width: _sidePanelWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border(left: BorderSide(color: p.border)),
                ),
                child: QuickSaleCartPanel(
                  sale: _sale,
                  onClose: () => setState(() {
                    _cartOpen = false;
                    _cartDismissed = true;
                  }),
                  onSaleCompleted: () => _catalog.refresh(),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _cartBar() {
    final p = context.palette;
    final count = _sale.totalItems;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Badge(
              isLabelVisible: count > 0,
              label: Text(count.toString()),
              backgroundColor: AppColors.brandPurple,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.selectionTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  color: p.accentText,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count > 0
                        ? context.l10n
                              .t('{v1} items')
                              .replaceAll('{v1}', count.toString())
                        : context.l10n.t('No items added yet.'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PriceText(
                    _sale.totalPayable,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.accentText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PressableSaleButton(
              enabled: true,
              submitting: false,
              label: context.l10n.t('View Cart'),
              icon: Icons.shopping_cart_outlined,
              onTap: _onOpenCartTap,
            ),
          ],
        ),
      ),
    );
  }

  void _onOpenCartTap() {
    if (_sideBySide) {
      // Back from the bar to the container: a dismissed one is reopened.
      setState(() {
        _cartOpen = true;
        _cartDismissed = false;
      });
    } else {
      _openCartSheet();
    }
  }

  void _openCartSheet() {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.86;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final p = sheetContext.palette;
        return Container(
          height: sheetHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: p.border),
          ),
          child: QuickSaleCartPanel(
            sale: _sale,
            onClose: () => Navigator.of(sheetContext).pop(),
            onSaleCompleted: () => _catalog.refresh(),
          ),
        );
      },
    ).whenComplete(() => _sheetOpen = false);
  }
}

/// One product, tappable to add. The detail screen is demoted to its own
/// button: on a till, "put it in the sale" is the default verb.
class _QuickSaleCard extends StatelessWidget {
  final CatalogProductView product;
  final int qtyInCart;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  const _QuickSaleCard({
    required this.product,
    required this.qtyInCart,
    required this.onAdd,
    required this.onOpen,
  });

  double get _price => product.variants.isNotEmpty
      ? product.variants.first.price
      : product.price;

  bool get _outOfStock =>
      product.stock <= 0 &&
      (product.variants.isEmpty ||
          product.variants.every((v) => v.quantity <= 0));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressableCard(
      onTap: onAdd,
      haptic: HapticFeedback.selectionClick,
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: qtyInCart > 0 ? AppColors.brandPurple : p.border,
          ),
          boxShadow: [
            BoxShadow(
              color: p.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _image(p)),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _outOfStock
                            ? context.l10n.t('Out of Stock')
                            : context.l10n
                                  .t('Stock: {v1}')
                                  .replaceAll('{v1}', product.stock.toString()),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      onPressed: onOpen,
                      tooltip: context.l10n.t('View Details'),
                      icon: Icon(
                        Icons.visibility_outlined,
                        size: 17,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  if (qtyInCart > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          context.l10n
                              .t('×{v1}')
                              .replaceAll('{v1}', qtyInCart.toString()),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: PriceText(
                          _price,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _outOfStock ? p.chipBg : p.selectionTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _outOfStock
                              ? Icons.remove_shopping_cart_outlined
                              : Icons.add_shopping_cart_outlined,
                          size: 14,
                          color: _outOfStock
                              ? p.textSecondary
                              : p.accentText,
                        ),
                      ),
                    ],
                  ),
                  if (product.variants.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n
                          .t('{v1} variants')
                          .replaceAll('{v1}', product.variants.length.toString()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(AppPalette p) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        child: product.imageUrl != null
            ? CachedProductImage(
                url: product.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            product.color.withValues(alpha: 0.85),
            product.color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(product.icon, color: Colors.white, size: 34),
      ),
    );
  }
}
