import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/package/presentation/screens/package_details_screen.dart';
import 'package:posfrontend/features/package/presentation/widgets/explore_packages_section.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/category_products_screen.dart';
import 'package:posfrontend/features/product/presentation/viewmodels/products_catalog_view_model.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/error_snackbar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/features/product/presentation/widgets/catalog_footer.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_grid.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_skeleton.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class ProductsCatalogScreen extends StatefulWidget {
  const ProductsCatalogScreen({super.key});

  @override
  State<ProductsCatalogScreen> createState() => _ProductsCatalogScreenState();
}

class _ProductsCatalogScreenState extends State<ProductsCatalogScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _search = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late final ProductsCatalogViewModel _viewModel;
  late final PageController _hotPageController;
  int _hotIndex = 0;
  bool _hotPaused = false;
  bool _isSearchOpen = false;
  bool _disposed = false;

  /// Whether the back-to-top control is showing.
  ///
  /// Driven by [onScroll] rather than by a `NotificationListener` so the button
  /// appears while the list is still gliding, instead of only once the scroll has
  /// settled and the notification arrives.
  bool _showBackToTop = false;

  /// How far the page must be scrolled before the back-to-top control appears.
  ///
  /// A screenful's worth. Before that the footer itself is on screen and already
  /// offers the same action, so a floating button would be a second control for
  /// something the user can already reach.
  static const double backToTopThreshold = 400;

  /// Drives the carousel's automatic advance. See [_startAutoScroll].
  Timer? _autoScrollTimer;

  /// How long a tile sits on screen before the carousel moves on.
  ///
  /// Long enough to actually look at a banner — reading a product name and a
  /// price takes a beat or two — and short enough that a shop owner waiting at
  /// the till does not think the screen has frozen.
  static const Duration _autoScrollInterval = Duration(seconds: 4);

  AppPalette get _p => context.palette;
  Color get _accentColor => _p.primary;
  Color get _mutedColor => _p.textSecondary;
  Color get _borderColor => _p.border;

  /// The purple the welcome screen's `Get started` button is painted in. Used
  /// for the search glyph, the search FAB and the carousel's current-page dot so
  /// those read as the same accent as the onboarding flow, rather than drifting
  /// into the theme's own violet. Shared with the price colour through
  /// [AppColors.brandPurple] so a screen cannot end up with two purples.
  static const Color brandPurple = AppColors.brandPurple;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductsCatalogViewModel();
    _scrollCtrl.addListener(_onScroll);
    _hotPageController = PageController(initialPage: 5000);
    _viewModel.load();
    _startAutoScroll();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final show = _scrollCtrl.offset > backToTopThreshold;
    if (show != _showBackToTop && mounted) {
      setState(() => _showBackToTop = show);
    }
  }

  void _scrollToTop() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// Advances the carousel one tile on a fixed cadence.
  ///
  /// A single [Timer.periodic] rather than the self-rescheduling
  /// `Future.delayed` chain this replaces. The chain allocated a new timer and
  /// a new closure on every single advance, and it kept rescheduling while
  /// paused — so a finger resting on the carousel still queued work at 3Hz for
  /// as long as it was held there. One periodic timer that simply does nothing
  /// when paused costs one closure and stops entirely in [dispose].
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (_disposed || !mounted || _hotPaused) return;

      final hotProducts = _viewModel.hotProducts;
      if (hotProducts.length <= 1 || !_hotPageController.hasClients) return;

      _hotIndex = (_hotIndex + 1) % hotProducts.length;
      _hotPageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _autoScrollTimer?.cancel();
    _scrollCtrl.dispose();
    _viewModel.dispose();
    _search.dispose();
    _hotPageController.dispose();
    super.dispose();
  }

  void _openProduct(CatalogProductView p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
    );
  }

  /// Opens a package's detail screen.
  ///
  /// That screen needs a `Category` as well as the package — it labels the
  /// package's header — so the category is looked up from the ones already
  /// loaded here. The fallback is deliberately the package's own name rather than
  /// an empty category: a package whose category is not in the current page (the
  /// grid is a `productLimit` preview, not the whole shop) still opens with
  /// something readable in the header instead of a blank one.
  void _openPackage(PackageEntity package) {
    final match = _viewModel.categories
        .where((c) => c.id == package.categoryId)
        .firstOrNull;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PackageDetailsScreen(
          package: package,
          category:
              match?.toCategory() ??
              Category(id: package.categoryId, name: package.name),
        ),
      ),
    );
  }

  void _showDeleteDialog(CatalogProductView p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.t('Delete Product')),
        content: Text(
          context.l10n
              .t('Are you sure you want to delete "{v1}"?')
              .replaceAll('{v1}', (p.name).toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.t('Cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _viewModel.deleteProduct(p.id);
              if (!success && mounted && _viewModel.hasError) {
                showErrorSnackBar(context, _viewModel.errorMessage!);
              }
            },
            child: Text(
              context.l10n.t('Delete'),
              style: TextStyle(color: context.palette.dangerFg),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              navigateToDashboard(context);
            }
          },
          child: AppShell(
            active: DrawerDestination.product,
            scaffoldKey: _scaffoldKey,
            backgroundColor: context.palette.scaffoldBg,
            wrap: (_, shell) => shell,
            floatingActionButton: _floatingActions(),
            body: _content,
          ),
        );
      },
    );
  }

  /// The two floating controls, stacked.
  ///
  /// A [Scaffold] has room for one floating action button, so the search
  /// button — which has always been there — is joined by the back-to-top control
  /// in a column above it. Search stays at the bottom because it is the control
  /// used from anywhere on the page, while back-to-top only matters once the page
  /// is scrolled.
  Widget _floatingActions() {
    final search = FloatingActionButton(
      onPressed: () => setState(() => _isSearchOpen = !_isSearchOpen),
      backgroundColor: brandPurple,
      child: Icon(_isSearchOpen ? Icons.close : Icons.search, color: Colors.white),
    );

    if (!_showBackToTop) return search;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'catalogBackToTop',
          onPressed: _scrollToTop,
          backgroundColor: _p.surface,
          tooltip: context.l10n.t('Back to top'),
          child: Icon(Icons.keyboard_arrow_up_rounded, color: _accentColor),
        ),
        const SizedBox(height: 12),
        search,
      ],
    );
  }

  Widget _content(BuildContext context, bool isWide) {
    final categories = _viewModel.categories;

    return ListenableBuilder(
      listenable: _search,
      builder: (context, _) {
        return SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  AppScreenTopBar(
                    title: context.l10n.t('Products'),
                    // No hamburger on a wide window: the sidebar is already on
                    // screen. This also fixes the button having been dead here —
                    // the old wide branch built its Scaffold without the key this
                    // callback needs, so `openDrawer()` was a no-op on desktop.
                    showMenuButton: !isWide,
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(
                    child: RefreshableBody(
                      scrollController: _scrollCtrl,
                      onRefresh: () => _viewModel.refresh(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: _buildBody(categories, isWide),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isSearchOpen)
                Positioned(
                  top: 72,
                  left: 24,
                  right: 24,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        Expanded(child: _searchField()),
                        const SizedBox(width: 8),
                        _iconButton(
                          Icons.close,
                          onTap: () {
                            setState(() {
                              _isSearchOpen = false;
                              _search.clear();
                              _viewModel.setSearchQuery('');
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              if (_viewModel.isSearching && _viewModel.searchLoading)
                Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _accentColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(List<CategoryShowcaseData> categories, bool isWide) {
    if (_viewModel.isSearching) {
      return _buildSearchResults();
    }

    if (_viewModel.isLoading && categories.isEmpty) {
      return CategorySkeleton(showBorder: isWide);
    }

    if (_viewModel.hasError && categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: _p.textMuted),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage ?? 'Unable to load categories',
              style: TextStyle(color: _p.dangerFg, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _viewModel.load(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(context.l10n.t('Retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 64, color: _p.textMuted),
            const SizedBox(height: 16),
            Text(
              context.l10n.t('No categories available'),
              style: TextStyle(fontSize: 16, color: _mutedColor),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.t('Add products to see categories here'),
              style: TextStyle(fontSize: 13, color: _p.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_viewModel.hotProducts.isNotEmpty) ...[
          _hotCarousel(_viewModel.hotProducts),
          const SizedBox(height: 28),
        ],
        CategoryShowcaseGrid(
          categories: categories,
          // The window is wide, so the cards sit side by side and the outline is
          // what separates them. On a phone they are one per row and the border
          // would only draw a column of boxes.
          showCardBorder: isWide,
          onProductTap: _openProduct,
          onProductLongPress: _showDeleteDialog,
          onCategoryTap: (cat) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategoryProductsScreen(
                categoryId: cat.id,
                categoryName: cat.name,
              ),
            ),
          ),
        ),
        // The gap belongs to the section rather than sitting outside it: with no
        // packages to show the section renders as nothing at all, and a spacer
        // left behind would be a band of dead space above the footer.
        if (_viewModel.packages.isNotEmpty) ...[
          const SizedBox(height: 28),
          ExplorePackagesSection(
            packages: _viewModel.packages,
            previewCount: ProductsCatalogViewModel.packagePreviewCount,
            onPackageTap: _openPackage,
          ),
        ],
        const CatalogFooter(),
      ],
    );
  }

  Widget _searchTileIcon(CatalogProductView p) {
    return Container(
      color: _p.selectionTint,
      alignment: Alignment.center,
      child: Icon(p.icon, color: p.color, size: 20),
    );
  }

  Widget _searchResultTile(CatalogProductView p) {
    final imageUrl = p.imageUrl ?? '';
    return InkWell(
      onTap: () => _openProduct(p),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _p.surface,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _searchTileIcon(p),
                    )
                  : _searchTileIcon(p),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  if (p.brand.isNotEmpty)
                    Text(
                      p.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  Text(
                    context.l10n
                        .t('Stock: {v1}')
                        .replaceAll('{v1}', (p.stock).toString()),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.palette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _viewModel.searchResults;

    if (_viewModel.searchLoading || !_viewModel.searchRequested) {
      return const SizedBox.shrink();
    }

    if (_viewModel.hasError && results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: _p.textMuted),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage ?? 'Unable to search products',
              style: TextStyle(color: _p.dangerFg, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _viewModel.searchProducts(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(context.l10n.t('Retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      final query = _viewModel.searchQuery.trim();
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: _p.textMuted),
            const SizedBox(height: 16),
            Text(
              context.l10n
                  .t('No products found for "{v1}"')
                  .replaceAll('{v1}', (query).toString()),
              style: TextStyle(fontSize: 16, color: _mutedColor),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.t('Try a different keyword or brand'),
              style: TextStyle(fontSize: 13, color: _p.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: results.map((p) => _searchResultTile(p)).toList(),
    );
  }

  Widget _iconButton(IconData icon, {required VoidCallback onTap}) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: IconButton(
        icon: Icon(icon, color: context.palette.textPrimary, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: _viewModel.setSearchQuery,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: context.l10n.t('Search...'),
        hintStyle: TextStyle(
          color: context.palette.textSecondary,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: brandPurple,
          size: 18,
        ),
        isDense: true,
        filled: true,
        fillColor: _p.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _accentColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static const List<LinearGradient> _promoGradients = [
    LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
    LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF2563EB)]),
    LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)]),
    LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFEA580C)]),
    LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF4F46E5)]),
  ];

  static LinearGradient _lightWallGradient(LinearGradient g) {
    final left = Color.lerp(g.colors[0], Colors.white, 0.72)!;
    final right = Color.lerp(g.colors[1], Colors.white, 0.38)!;
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [left, Color.lerp(left, right, 0.5)!, right],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  Widget _hotCarousel(List<CatalogProductView> items) {
    final loopCount = 10000;
    return RepaintBoundary(
      child: GestureDetector(
        onPanDown: (_) => setState(() => _hotPaused = true),
        onPanEnd: (_) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _hotPaused = false);
          });
        },
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                key: const PageStorageKey('hotCarousel'),
                controller: _hotPageController,
                itemCount: loopCount,
                onPageChanged: (i) =>
                    setState(() => _hotIndex = i % items.length),
                itemBuilder: (ctx, i) => _hotBanner(items[i % items.length], i),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  // The dot for the banner on screen is the brand purple and
                  // the long one; the rest stay muted.
                  width: i == _hotIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _hotIndex ? brandPurple : _p.borderStrong,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hotBanner(CatalogProductView p, int index) {
    final gradient = _promoGradients[index % _promoGradients.length];
    final accent = Color.lerp(gradient.colors[0], gradient.colors[1], 0.6)!;
    final lightGradient = _lightWallGradient(gradient);
    final hasImage = (p.imageUrl ?? '').isNotEmpty;
    return GestureDetector(
      onTap: () => _openProduct(p),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: 194,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                gradient: lightGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 126,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p.category.isEmpty ? 'Featured' : p.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          PriceText(
                            p.price,
                            // `accentText`, not the `#7952DB` literal this used
                            // to carry: at 16px bold this is body text, so it
                            // needs 4.5:1, and the brand purple only reaches
                            // 2.54:1 on a dark surface.
                            style: TextStyle(
                              fontSize: AppTypography.bodyLargeSize,
                              fontWeight: FontWeight.bold,
                              color: _p.accentText,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [gradient.colors[1], accent],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              context.l10n.t('View Details'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 90),
                ],
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                width: 150,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: RadialGradient(
                    radius: 1.1,
                    colors: [
                      Colors.black.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: hasImage
                      ? _GradientBlendedImage(
                          imageUrl: p.imageUrl!,
                          width: 160,
                          errorFallback: _promoBadge(p, gradient),
                        )
                      : _promoBadge(p, gradient),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promoBadge(CatalogProductView p, LinearGradient gradient) {
    final accent = Color.lerp(
      gradient.colors[0],
      const Color(0xFF111827),
      0.7,
    )!;
    return Center(
      child: Icon(
        p.icon,
        color: accent,
        size: 64,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 14),
        ],
      ),
    );
  }
}

class _GradientBlendedImage extends StatefulWidget {
  const _GradientBlendedImage({
    required this.imageUrl,
    required this.width,
    required this.errorFallback,
  });

  final String imageUrl;
  final double width;
  final Widget errorFallback;

  @override
  State<_GradientBlendedImage> createState() => _GradientBlendedImageState();
}

class _GradientBlendedImageState extends State<_GradientBlendedImage> {
  ui.Image? _image;
  bool _failed = false;
  ImageStream? _stream;
  late final ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(
      (info, _) {
        if (mounted) setState(() => _image = info.image);
      },
      onError: (_, _) {
        if (mounted) setState(() => _failed = true);
      },
    );
    _load(widget.imageUrl);
  }

  @override
  void didUpdateWidget(_GradientBlendedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _stream?.removeListener(_listener);
      _load(widget.imageUrl);
    }
  }

  void _load(String url) {
    if (!mounted) return;
    _failed = false;
    _image = null;
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    _stream = stream;
    stream.addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    // While the photo is in flight the banner shows the same gradient-and-glyph
    // fallback it shows when the photo fails. Returning an empty box here instead
    // is what made the carousel look like it was loading: a blank half-tile that
    // popped into a framed photo a moment later, every time it advanced.
    if (_failed || image == null) return widget.errorFallback;

    return CustomPaint(
      size: Size(widget.width, double.infinity),
      painter: _GradientColorImagePainter(image),
    );
  }
}

class _GradientColorImagePainter extends CustomPainter {
  _GradientColorImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final scale = math.min(size.width / src.width, size.height / src.height);
    final imgRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: src.width * scale,
      height: src.height * scale,
    );

    // Frame geometry: photo, an ivory mat around it, then a 3D wooden frame.
    const double mat = 7;
    const double frame = 15;
    final matRect = imgRect.inflate(mat);
    final frameOuterRect = matRect.inflate(frame);
    final frameOuter = RRect.fromRectAndRadius(
      frameOuterRect,
      const Radius.circular(16),
    );
    final frameInner = RRect.fromRectAndRadius(
      matRect,
      const Radius.circular(10),
    );

    // Lay the frame down slightly from vertical (little tilt).
    const double tiltDeg = 7.5;
    final tilt = tiltDeg * math.pi / 180;
    final cosT = math.cos(tilt);
    final sinT = math.sin(tilt);
    final fw = frameOuterRect.width;
    final fh = frameOuterRect.height;
    final rotW = fw * cosT + fh * sinT;
    final rotH = fw * sinT + fh * cosT;
    final fit = math.min(1.0, math.min(size.width / rotW, size.height / rotH));

    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(tilt);
    canvas.scale(fit);
    canvas.translate(-cx, -cy);

    // Drop shadow so the frame appears lifted off the wall.
    canvas.save();
    canvas.translate(0, 12);
    canvas.drawRRect(
      frameOuter,
      Paint()
        ..color = const Color(0x4D000000)
        ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.restore();
    canvas.drawRRect(
      frameOuter,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Ivory mat between the frame and the photo.
    canvas.drawRRect(frameInner, Paint()..color = const Color(0xFFF7F1E6));

    // Wooden frame ring with a vertical bevel gradient.
    final framePath = Path.combine(
      PathOperation.difference,
      Path()..addRRect(frameOuter),
      Path()..addRRect(frameInner),
    );
    canvas.drawPath(
      framePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE7C08A),
            Color(0xFF9C6B3A),
            Color(0xFF3E2610),
            Color(0xFF6B4520),
          ],
          stops: [0.0, 0.35, 0.85, 1.0],
        ).createShader(frameOuterRect),
    );
    // Bevel lip: light inner edge, dark outer edge.
    canvas.drawRRect(
      frameInner,
      Paint()
        ..color = const Color(0x99FFF3DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawRRect(
      frameOuter,
      Paint()
        ..color = const Color(0x40000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // The photo, full color, on top of the mat.
    canvas.drawImageRect(
      image,
      src,
      imgRect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GradientColorImagePainter oldDelegate) =>
      oldDelegate.image != image;
}
