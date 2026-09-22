import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/search_input_bar.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

class ProductCardScreen extends StatefulWidget {
  const ProductCardScreen({super.key});

  @override
  State<ProductCardScreen> createState() => _ProductCardScreenState();
}

class _ProductCardScreenState extends State<ProductCardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _search = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  static const Color bg = Color(0xFFF8F9FC);

  List<CatalogProductView> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _search.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ApiClient.create();
      final resp = await dio.get('/api/products');
      final data = resp.data;
      final items = _extractList(data);
      final products = items.map((item) {
        final json = item as Map<String, dynamic>;
        final variants = json['variants'];
        final variantList = variants is List ? variants : const [];
        final price = variantList.isNotEmpty
            ? (variantList.first['price'] ?? 0).toDouble()
            : 0.0;
        final category = (json['category'] as String?)?.trim() ?? '';
        final image = (json['image'] as String?)?.trim();
        return CatalogProductView(
          id: json['id']?.toString() ?? '',
          name: json['name']?.toString() ?? 'Unnamed',
          brand: json['brand']?.toString() ?? '',
          sku: json['sku']?.toString() ?? '',
          price: price,
          stock: (json['stock'] as num?)?.toInt() ?? 0,
          isSet: json['isSet'] == true,
          category: category,
          packageId: json['packageId']?.toString() ?? '',
          icon: CatalogProductView.iconFor(category),
          color: CatalogProductView.colorFor(category),
          imageUrl: image != null && image.isNotEmpty ? image : null,
          createdBy: json['createdBy']?.toString() ?? '',
        );
      }).toList();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  List<CatalogProductView> get _filteredProducts {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _products;
    return _products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.brand.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _search,
      builder: (context, _) {
        final filtered = _filteredProducts;
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
                  body: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(width: 240, child: AppDrawer(activeItem: 'Product')),
                        Expanded(child: _buildContent(filtered)),
                      ],
                    ),
                  ),
                );
              }
              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: bg,
                drawer: const AppDrawer(activeItem: 'Product'),
                body: SafeArea(child: _buildContent(filtered)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(List<CatalogProductView> products) {
    return Column(
      children: [
        AppScreenTopBar(
          title: 'Products',
          showMenuButton: true,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProducts,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchInputBar(
                    controller: _search,
                    hintText: 'Search products by name, brand, SKU...',
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 20),
                  _buildProductGrid(products),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid(List<CatalogProductView> products) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }
    if (_error != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    if (products.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int crossAxisCount;
        if (w >= 1100) {
          crossAxisCount = 4;
        } else if (w >= 820) {
          crossAxisCount = 3;
        } else if (w >= 500) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final spacing = 16.0;
        final cardW = (w - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: products.map((p) {
            return SizedBox(
              width: cardW,
              child: _ProductCard(
                product: p,
                onTap: () => _openProduct(p),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _openProduct(CatalogProductView p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: p.id),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final CatalogProductView product;
  final VoidCallback? onTap;

  const _ProductCard({required this.product, this.onTap});

  static const Color _titleColor = Color(0xFF111827);
  static const Color _gray = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final stock = product.stock;
    final stockColor = stock == 0
        ? Colors.red
        : (stock < 10 ? const Color(0xFFD97706) : const Color(0xFF16A34A));
    final stockLabel = stock == 0
        ? 'Out of Stock'
        : (stock < 10 ? 'Low Stock' : 'In Stock');

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: const Color(0xFFF3F4F6),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (c, o, s) => _imageFallback(),
                          )
                        : _imageFallback(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    if (product.brand.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _gray),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: PriceText(
                            product.price,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stockLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: stockColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (product.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _gray),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
        child: Icon(product.icon, color: Colors.white, size: 36),
      ),
    );
  }
}
