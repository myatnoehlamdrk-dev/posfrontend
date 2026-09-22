import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/category_products_screen.dart';
import 'package:posfrontend/features/product/presentation/viewmodels/products_catalog_view_model.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/error_snackbar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_grid.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_skeleton.dart';

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
  static const Color bg = Color(0xFFF8F9FC);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);
  static const Color titleColor = Color(0xFF111827);

  @override
  void initState() {
    super.initState();
    _viewModel = ProductsCatalogViewModel();
    _hotPageController = PageController(initialPage: 5000);
    _viewModel.load();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_disposed) return;
      if (!mounted || _hotPaused) {
        _startAutoScroll();
        return;
      }
      final hotProducts = _viewModel.hotProducts;
      if (hotProducts.length > 1 && _hotPageController.hasClients) {
        _hotIndex = (_hotIndex + 1) % hotProducts.length;
        _hotPageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollCtrl.dispose();
    _viewModel.dispose();
    _search.dispose();
    _hotPageController.dispose();
    super.dispose();
  }

  void _openProduct(CatalogProductView p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: p.id),
      ),
    );
  }

  void _showDeleteDialog(CatalogProductView p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _viewModel.deleteProduct(p.id);
              if (!success && mounted && _viewModel.hasError) {
                showErrorSnackBar(context, _viewModel.errorMessage!);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth >= 768;

              if (isWide) {
                return Scaffold(
                  backgroundColor: bg,
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => setState(() => _isSearchOpen = !_isSearchOpen),
                    backgroundColor: purple,
                    child: Icon(
                      _isSearchOpen ? Icons.close : Icons.search,
                      color: Colors.white,
                    ),
                  ),
                  body: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          width: 240,
                          child: AppDrawer(activeItem: 'Product'),
                        ),
                        Expanded(child: _content()),
                      ],
                    ),
                  ),
                );
              }
              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: bg,
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => _isSearchOpen = !_isSearchOpen),
                  backgroundColor: purple,
                  child: Icon(
                    _isSearchOpen ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                ),
                drawer: const AppDrawer(activeItem: 'Product'),
                body: SafeArea(child: _content()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _content() {
    final categories = _viewModel.categories;

    return ListenableBuilder(
      listenable: _search,
      builder: (context, _) {
        return Stack(
          children: [
            Column(
              children: [
                AppScreenTopBar(
                  title: 'Products',
                  showMenuButton: true,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: RefreshableBody(
                    scrollController: _scrollCtrl,
                    onRefresh: () => _viewModel.load(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: _buildBody(categories),
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
                      _iconButton(Icons.close, onTap: () {
                        setState(() {
                          _isSearchOpen = false;
                          _search.clear();
                          _viewModel.setSearchQuery('');
                        });
                      }),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBody(List<CategoryShowcaseData> categories) {
    if (_viewModel.isLoading && categories.isEmpty) {
      return const CategorySkeleton();
    }

    if (_viewModel.hasError && categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage ?? 'Unable to load categories',
              style: const TextStyle(color: Colors.red, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _viewModel.load(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No categories available',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products to see categories here',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
      ],
    );
  }

  Widget _iconButton(IconData icon, {required VoidCallback onTap}) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: IconButton(
        icon: Icon(icon, color: titleColor, size: 20),
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
        hintText: 'Search...',
        hintStyle: const TextStyle(color: gray, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: gray, size: 18),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: purple),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
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
              height: 190,
              child: PageView.builder(
                key: const PageStorageKey('hotCarousel'),
                controller: _hotPageController,
                itemCount: loopCount,
                onPageChanged: (i) => setState(() => _hotIndex = i % items.length),
                itemBuilder: (ctx, i) => _hotBanner(items[i % items.length]),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _hotIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _hotIndex ? purple : const Color(0xFFD1D5DB),
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

  Widget _hotBanner(CatalogProductView p) {
    return GestureDetector(
      onTap: () => _openProduct(p),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (p.imageUrl != null)
              Image.network(
                p.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imageFallback(p, 60),
              )
            else
              _imageFallback(p, 60),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              right: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.brand,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  if (p.variants.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: p.variants.take(3).map((v) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${v.size}${v.color.isNotEmpty ? '/${v.color}' : ''} (${v.quantity})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 4),
                  PriceText(
                    p.price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: purple,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(CatalogProductView p, double iconSize) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            p.color.withValues(alpha: 0.85),
            p.color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(p.icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}
