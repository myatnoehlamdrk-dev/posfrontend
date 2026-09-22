import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  List<CatalogProductView> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  static const Color bg = Color(0xFFF8F9FC);
  static const Color purple = Color(0xFF6D28D9);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadProducts();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final dio = ApiClient.create();
      final response = await dio.get('/api/products', queryParameters: {
        'categoryId': widget.categoryId,
        'page': _currentPage,
        'per_page': 20,
      });

      final data = response.data;
      final List<dynamic> items = data is Map ? (data['data'] ?? []) : (data as List? ?? []);
      final meta = data is Map ? data['meta'] : null;

      final newProducts = items.map((json) {
        final p = json as Map<String, dynamic>;
        final categoryName = widget.categoryName;
        return CatalogProductView(
          id: p['id']?.toString() ?? '',
          name: p['name']?.toString() ?? '',
          brand: p['brand']?.toString() ?? '',
          sku: p['sku']?.toString() ?? '',
          price: (p['variants'] as List?)?.isNotEmpty == true
              ? ((p['variants'] as List).first['price'] ?? 0).toDouble()
              : 0.0,
          stock: (p['stock'] as num?)?.toInt() ?? 0,
          isSet: p['isSet'] == true,
          category: categoryName,
          packageId: p['packageId']?.toString() ?? '',
          icon: CatalogProductView.iconFor(categoryName),
          color: CatalogProductView.colorFor(categoryName),
          imageUrl: p['image']?.toString().trim(),
          createdBy: p['createdBy']?.toString() ?? '',
        );
      }).toList();

      setState(() {
        _products = [..._products, ...newProducts];
        _currentPage++;
        if (meta != null) {
          _hasMore = _currentPage <= (meta['last_page'] ?? 1);
        } else {
          _hasMore = items.isNotEmpty;
        }
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to load products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: AppTopBar(
                title: widget.categoryName,
                showMenuButton: false,
                showBackButton: true,
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_products.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator(color: purple));
    }

    if (_error != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 15)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _currentPage = 1;
                  _hasMore = true;
                  _products = [];
                });
                _loadProducts();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No products in this category',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int crossAxisCount;
        if (w >= 1100) {
          crossAxisCount = 5;
        } else if (w >= 820) {
          crossAxisCount = 4;
        } else if (w >= 500) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return GridView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: _products.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _products.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: purple),
                ),
              );
            }
            final p = _products[index];
            return _ProductCard(
              product: p,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final CatalogProductView product;
  final VoidCallback? onTap;

  const _ProductCard({required this.product, this.onTap});

  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallback())
                      : _fallback(),
                ),
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PriceText(
                    product.price,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stock: ${product.stock}',
                    style: const TextStyle(fontSize: 11, color: gray),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        child: Icon(product.icon, color: Colors.white, size: 36),
      ),
    );
  }
}
