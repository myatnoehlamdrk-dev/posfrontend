import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/product/repository/catalog_product_repository_impl.dart';
import 'package:posfrontend/modules/product/view/add_product_screen.dart';
import 'package:posfrontend/modules/product/view/product_detail_screen.dart';
import 'package:posfrontend/modules/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

class ProductsCatalogScreen extends StatefulWidget {
  final LoginResponse? user;
  const ProductsCatalogScreen({super.key, this.user});

  @override
  State<ProductsCatalogScreen> createState() => _ProductsCatalogScreenState();
}

enum ProductSort {
  dateNewest,
  dateOldest,
  nameAz,
  nameZa,
  priceLow,
  priceHigh,
}

class _ProductsCatalogScreenState extends State<ProductsCatalogScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _search = TextEditingController();
  List<CatalogProduct> _all = [];
  bool _isGrid = true;
  bool _loading = true;
  String? _error;
  String _category = 'All';
  ProductSort _sort = ProductSort.dateNewest;
  late final PageController _hotPageController;
  int _hotIndex = 0;
  bool _hotPaused = false;
  static const Color bg = Color(0xFFF8F9FC);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);
  static const Color titleColor = Color(0xFF111827);

  List<String> get _filters {
    final cats = <String>{
      for (final p in _all)
        if (p.category.isNotEmpty) p.category,
    };
    final sorted = cats.toList()..sort();
    return ['All', ...sorted];
  }

  @override
  void initState() {
    super.initState();
    _hotPageController = PageController(initialPage: 5000);
    _load();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _hotPaused) {
        _startAutoScroll();
        return;
      }
      final hotProducts = _hotProducts;
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

  List<CatalogProduct> get _hotProducts {
    final list = List<CatalogProduct>.from(_all);
    return list.length > 4 ? list.sublist(list.length - 4) : list;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _all = await CatalogProductRepositoryImpl().getProducts();
      if (!mounted) return;
      _hotIndex = 0;
      if (_hotPageController.hasClients) {
        _hotPageController.jumpToPage(5000);
      }
      setState(() => _loading = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _hotPageController.dispose();
    super.dispose();
  }

  List<CatalogProduct> get _filtered {
    final q = _search.text.toLowerCase();
    final list = _all.where((p) {
      final matchesCat = _category == 'All' || p.category == _category;
      final matchesSearch =
          q.isEmpty || p.name.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case ProductSort.nameAz:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ProductSort.nameZa:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case ProductSort.priceLow:
          return a.price.compareTo(b.price);
        case ProductSort.priceHigh:
          return b.price.compareTo(a.price);
        case ProductSort.dateNewest:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case ProductSort.dateOldest:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
    return list;
  }

  void _open(CatalogProduct p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          user: widget.user,
          productId: p.id,
        ),
      ),
    );
  }

  void _showDeleteDialog(CatalogProduct p) {
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
              try {
                final dio = ApiClient.create();
                await dio.delete('/api/products/${p.id}');
                setState(() => _all.removeWhere((item) => item.id == p.id));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e')),
                  );
                }
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          navigateToDashboard(context, user: widget.user);
        }
      },
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final body = _content();

          if (isWide) {
            return Scaffold(
              backgroundColor: bg,
              body: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 240,
                      child: AppDrawer(user: widget.user, activeItem: 'Product'),
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
            drawer: AppDrawer(user: widget.user, activeItem: 'Product'),
            body: SafeArea(child: body),
          );
        },
      ),
    );
  }

  Widget _content() {
    final dateLabel = _formatDate(DateTime.now());
    final products = _filtered;

    return ListenableBuilder(
      listenable: _search,
      builder: (context, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTopBar(
                    title: 'Products',
                    showMenuButton: true,
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                    user: widget.user,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Catalog',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                      ),
                      _iconButton(
                        _isGrid ? Icons.grid_view : Icons.view_list,
                        onTap: () => setState(() => _isGrid = !_isGrid),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: PopupMenuButton<ProductSort>(
                          icon: const Icon(Icons.filter_list, color: titleColor),
                          tooltip: 'Sort',
                          onSelected: (v) => setState(() => _sort = v),
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(
                              value: ProductSort.dateNewest,
                              child: Text('Newest first'),
                            ),
                            PopupMenuItem(
                              value: ProductSort.dateOldest,
                              child: Text('Oldest first'),
                            ),
                            PopupMenuItem(
                              value: ProductSort.nameAz,
                              child: Text('Name (A–Z)'),
                            ),
                            PopupMenuItem(
                              value: ProductSort.nameZa,
                              child: Text('Name (Z–A)'),
                            ),
                            PopupMenuItem(
                              value: ProductSort.priceLow,
                              child: Text('Price (Low–High)'),
                            ),
                            PopupMenuItem(
                              value: ProductSort.priceHigh,
                              child: Text('Price (High–Low)'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _searchField(),
                  const SizedBox(height: 16),
                  _pills(),
                ],
              ),
            ),
            Expanded(
              child: RefreshableBody(
                onRefresh: _load,
                child: _loading
                    ? const SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF6D28D9)),
                        ),
                      )
                    : _error != null
                        ? SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_error!, style: const TextStyle(color: Colors.red)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _load,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "Hot Products",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      dateLabel,
                                      style: const TextStyle(fontSize: 14, color: gray),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_hotProducts.isNotEmpty) _hotCarousel(_hotProducts),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Text(
                                      'All Products',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${products.length}',
                                      style: const TextStyle(fontSize: 14, color: gray),
                                    ),
                                    const Spacer(),
                                    _addProductButton(),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                products.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 48),
                                        child: Center(
                                          child: Text(
                                            'No products found.',
                                            style: TextStyle(color: Color(0xFF6B7280)),
                                          ),
                                        ),
                                      )
                                    : (_isGrid ? _grid(products) : _list(products)),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _iconButton(IconData icon, {required VoidCallback onTap}) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: purple),
        onPressed: onTap,
      ),
    );
  }

  Widget _addProductButton() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddProductScreen(user: widget.user),
              ),
            );
            if (mounted) _load();
          },
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(
                  'Add Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: (_) {},
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: const TextStyle(color: gray, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: gray),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _pills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _category = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _category == f ? purple : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _category == f ? purple : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _category == f ? Colors.white : titleColor,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _hotCarousel(List<CatalogProduct> items) {
    final loopCount = 10000;
    return GestureDetector(
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
    );
  }

  Widget _hotBanner(CatalogProduct p) {
    return GestureDetector(
      onTap: () => _open(p),
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
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFDDD6FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(p.icon, color: Colors.white, size: 60),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFDDD6FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(p.icon, color: Colors.white, size: 60),
              ),
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
                  const SizedBox(height: 6),
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

  Widget _grid(List<CatalogProduct> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int cross = 2;
        if (w >= 1100) {
          cross = 4;
        } else if (w >= 820) {
          cross = 3;
        }
        return GridView.count(
          crossAxisCount: cross,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.62,
          children: products.map(_gridCard).toList(),
        );
      },
    );
  }

  Widget _gridCard(CatalogProduct p) {
    return GestureDetector(
      onTap: () => _open(p),
      onLongPress: () => _showDeleteDialog(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: p.imageUrl != null
                        ? Image.network(
                            p.imageUrl!,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _imageFallback(p, 44),
                          )
                        : _imageFallback(p, 44),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${p.stock} in stock',
                      style: const TextStyle(fontSize: 10, color: titleColor),
                    ),
                  ),
                ),
                if (p.isSet)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: purple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SET',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: gray),
                    ),
                    const Spacer(),
                    PriceText(
                      p.price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<CatalogProduct> products) {
    return Column(
      children: products
          .map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _listCard(p),
              ))
          .toList(),
    );
  }

  Widget _listCard(CatalogProduct p) {
    return GestureDetector(
      onTap: () => _open(p),
      onLongPress: () => _showDeleteDialog(p),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: p.imageUrl != null
                    ? Image.network(
                        p.imageUrl!,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imageFallback(p, 34),
                      )
                    : _imageFallback(p, 34),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('SKU: ${p.sku}', style: const TextStyle(fontSize: 12, color: gray)),
                  const SizedBox(height: 2),
                  Text(p.brand, style: const TextStyle(fontSize: 12, color: gray)),
                  const SizedBox(height: 4),
                  PriceText(
                    p.price,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: purple,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${p.stock} in stock',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: purple,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right, color: gray),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(CatalogProduct p, double iconSize) {
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

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
