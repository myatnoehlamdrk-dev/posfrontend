import 'dart:math';
import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/cart/data/cart_store.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_card_entity.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_item_entity.dart';
import 'package:posfrontend/features/cart/presentation/screens/add_to_cart_screen.dart';
import 'package:posfrontend/features/cart/presentation/screens/cart_card_screen.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_repository_impl.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

class VariantPick {
  final ProductVariant variant;
  final int qty;

  const VariantPick({required this.variant, required this.qty});
}

String variantTitle(ProductVariant v) {
  final parts = <String>[
    if (v.size.isNotEmpty) v.size,
    if (v.color.isNotEmpty) v.color,
  ];
  return parts.isEmpty ? 'Default' : parts.join(' · ');
}

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

  final Set<String> _selectedIds = {};
  final Map<String, int> _quantities = {};
  final Map<String, TextEditingController> _qtyCtrls = {};
  final Map<String, List<VariantPick>> _variantPicks = {};
  bool _isAddingToCart = false;

  static const Color bg = Color(0xFFF8F9FC);
  static const Color purple = Color(0xFF6D28D9);
  static const Color titleColor = Color(0xFF111827);

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
      final response = await dio.get(
        '/api/products',
        queryParameters: {
          'categoryId': widget.categoryId,
          'page': _currentPage,
          'per_page': 20,
        },
      );

      final data = response.data;
      final newProducts = _parseProducts(data);
      final meta = data is Map ? data['meta'] : null;

      setState(() {
        _products = [..._products, ...newProducts];
        _currentPage++;
        if (meta != null) {
          _hasMore = _currentPage <= (meta['last_page'] ?? 1);
        } else {
          _hasMore = newProducts.isNotEmpty;
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

  List<CatalogProductView> _parseProducts(Object? data) {
    final items = data is Map ? (data['data'] ?? []) : (data as List? ?? []);
    return items.map((json) {
      final p = json as Map<String, dynamic>;
      final variants = (p['variants'] as List? ?? const [])
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList();
      return CatalogProductView(
        id: p['id']?.toString() ?? '',
        name: p['name']?.toString() ?? '',
        brand: p['brand']?.toString() ?? '',
        sku: p['sku']?.toString() ?? '',
        price: variants.isNotEmpty ? variants.first.price : 0.0,
        stock: (p['stock'] as num?)?.toInt() ?? 0,
        isSet: p['isSet'] == true,
        category: widget.categoryName,
        packageId: p['packageId']?.toString() ?? '',
        icon: CatalogProductView.iconFor(widget.categoryName),
        color: CatalogProductView.colorFor(widget.categoryName),
        imageUrl: resolveMediaUrl(p['image']?.toString()),
        variants: variants,
        createdBy: p['createdBy']?.toString() ?? '',
      );
    }).toList();
  }

  Future<void> _refreshProducts() async {
    try {
      final dio = ApiClient.create();
      final response = await dio.get(
        '/api/products',
        queryParameters: {
          'categoryId': widget.categoryId,
          'page': 1,
          'per_page': 20,
        },
      );
      if (!mounted) return;
      final data = response.data;
      final newProducts = _parseProducts(data);
      final meta = data is Map ? data['meta'] : null;
      final existing = newProducts.map((e) => e.id).toSet();
      setState(() {
        _products = newProducts;
        _currentPage = 2;
        if (meta != null) {
          _hasMore = 2 <= (meta['last_page'] ?? 1);
        } else {
          _hasMore = newProducts.isNotEmpty;
        }
        _error = null;
        _selectedIds.removeWhere((id) => !existing.contains(id));
        _variantPicks.removeWhere((key, _) => !existing.contains(key));
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is ApiException
            ? e.message
            : 'Failed to refresh products: $e',
      );
    }
  }

  int get _selectedCount => _selectedIds.length;

  void _openCart() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddToCartScreen()));
  }

  double get _selectedTotal {
    double total = 0;
    for (final id in _selectedIds) {
      final p = _products.firstWhere((x) => x.id == id);
      final picks = _variantPicks[id];
      if (picks != null && picks.isNotEmpty) {
        for (final pick in picks) {
          total += pick.variant.price * pick.qty;
        }
      } else {
        total += _priceFor(p) * (_quantities[id] ?? 0);
      }
    }
    return total;
  }

  int _totalQtyFor(String id) {
    final picks = _variantPicks[id];
    if (picks != null && picks.isNotEmpty) {
      return picks.fold(0, (sum, e) => sum + e.qty);
    }
    return _quantities[id] ?? 0;
  }

  double _priceFor(CatalogProductView p) {
    if (p.variants.isNotEmpty) return p.variants.first.price;
    return p.price;
  }

  int _stockFor(CatalogProductView p) {
    return p.stock;
  }

  void _ensureQtyCtrl(String id) {
    _qtyCtrls.putIfAbsent(id, () => TextEditingController(text: '0'));
  }

  void _syncQtyCtrl(String id) {
    final ctrl = _qtyCtrls[id];
    if (ctrl == null) return;
    final v = '${_quantities[id] ?? 0}';
    if (ctrl.text != v) {
      ctrl.value = TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      );
    }
  }

  Future<void> _toggleSelect(String id) async {
    _ensureQtyCtrl(id);
    final p = _products.firstWhere((x) => x.id == id);
    if (_selectedIds.contains(id)) {
      setState(() {
        _selectedIds.remove(id);
        _variantPicks.remove(id);
        _quantities[id] = 0;
        _syncQtyCtrl(id);
      });
      return;
    }
    if (p.variants.isNotEmpty) {
      final picks = await _pickVariants(p);
      if (picks == null || picks.isEmpty) return;
      setState(() {
        _variantPicks[id] = picks;
        _selectedIds.add(id);
        _quantities[id] = picks.fold(0, (sum, e) => sum + e.qty);
        _syncQtyCtrl(id);
      });
      return;
    }
    setState(() {
      _selectedIds.add(id);
      _quantities[id] = 2;
      _syncQtyCtrl(id);
    });
  }

  Future<List<VariantPick>?> _pickVariants(CatalogProductView p) {
    return showDialog<List<VariantPick>>(
      context: context,
      builder: (_) => _VariantPickDialog(
        product: p,
        onConfirm: (picks) => Navigator.of(context).pop(picks),
      ),
    );
  }

  Future<void> _editVariants(String id) async {
    final p = _products.firstWhere((x) => x.id == id);
    final picks = await _pickVariants(p);
    if (picks == null || picks.isEmpty) {
      setState(() {
        _selectedIds.remove(id);
        _variantPicks.remove(id);
        _quantities[id] = 0;
        _syncQtyCtrl(id);
      });
      return;
    }
    setState(() {
      _variantPicks[id] = picks;
      _quantities[id] = picks.fold(0, (sum, e) => sum + e.qty);
      _syncQtyCtrl(id);
    });
  }

  void _adjustQty(String id, int delta) {
    setState(() {
      final newQty = (_quantities[id] ?? 0) + delta;
      if (newQty <= 0) {
        _quantities[id] = 0;
        _selectedIds.remove(id);
        _syncQtyCtrl(id);
      } else {
        _quantities[id] = newQty;
        _selectedIds.add(id);
        _syncQtyCtrl(id);
      }
    });
  }

  void _updateQtyFromCtrl(String id, String value) {
    final n = int.tryParse(value) ?? 0;
    setState(() {
      _quantities[id] = n;
      if (n <= 0) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _addToCart() async {
    final items = <CartItemEntity>[];
    for (final id in _selectedIds) {
      final p = _products.firstWhere((x) => x.id == id);
      final picks = _variantPicks[id];
      final qty = _totalQtyFor(id);
      if (qty <= 0) continue;
      if (picks != null && picks.isNotEmpty) {
        for (final pick in picks) {
          final avail = pick.variant.quantity;
          if (pick.qty > avail) {
            showErrorMessage(
              context,
              '${p.name} (${variantTitle(pick.variant)}) has only $avail in stock',
            );
            return;
          }
          items.add(
            CartItemEntity(
              productId: p.id,
              productName: p.name,
              imageUrl: p.imageUrl,
              unitPrice: pick.variant.price,
              quantity: pick.qty,
              category: p.category,
              size: pick.variant.size.isNotEmpty ? pick.variant.size : null,
              color: pick.variant.color.isNotEmpty ? pick.variant.color : null,
            ),
          );
        }
        continue;
      }
      final available = _stockFor(p);
      if (qty > available) {
        showErrorMessage(context, '${p.name} has only $available in stock');
        return;
      }
      items.add(
        CartItemEntity(
          productId: p.id,
          productName: p.name,
          imageUrl: p.imageUrl,
          unitPrice: _priceFor(p),
          quantity: qty,
          category: p.category,
        ),
      );
    }
    if (items.isEmpty) {
      showErrorMessage(
        context,
        _selectedCount == 0
            ? 'Select at least one product with a quantity'
            : 'No item selected',
      );
      return;
    }
    if (_isAddingToCart) return;
    setState(() => _isAddingToCart = true);
    try {
      final choice = await showDialog<_AddToCartChoice>(
        context: context,
        builder: (_) => const _AddToCartChoiceDialog(),
      );
      if (choice == null || !mounted) return;
      if (choice == _AddToCartChoice.newCard) {
        await _addToCartCore(items);
        return;
      }
      await _addToExistingCard(items);
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Future<void> _addToExistingCard(List<CartItemEntity> items) async {
    final cards = CartStore.instance.value
        .where((c) => c.orderId.isNotEmpty)
        .toList();
    if (cards.isEmpty) {
      if (!mounted) return;
      showErrorMessage(
        context,
        'No existing card to add into. Start a new card first.',
      );
      return;
    }
    final card = await showModalBottomSheet<CartCardEntity>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ExistingCardPicker(cards: cards),
    );
    if (card == null || !mounted) return;

    try {
      await OrderRepositoryImpl().addOrderItems(
        orderId: card.orderId,
        items: items
            .map(
              (e) => SaleItemEntity(
                productId: e.productId,
                productName: e.productName,
                imageUrl: e.imageUrl,
                unitPrice: e.unitPrice,
                quantity: e.quantity,
                size: e.size,
                color: e.color,
                category: e.category,
              ),
            )
            .toList(),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      showErrorMessage(context, e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      showErrorMessage(context, 'Failed to add to existing card: $e');
      return;
    }

    final updatedCard = await CartStore.instance.appendToCard(card.id, items);
    if (!mounted) return;
    setState(() {
      for (final id in _selectedIds) {
        _quantities[id] = 0;
        _syncQtyCtrl(id);
      }
      _selectedIds.clear();
      _variantPicks.clear();
    });
    if (updatedCard == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CartCardScreen(card: updatedCard)),
    );
  }

  Future<void> _addToCartCore(List<CartItemEntity> items) async {
    String createOrderId = '';
    try {
      createOrderId = await OrderRepositoryImpl().createOrder(
        userName: AuthScope.userOf(context)?.fullName ?? 'Staff',
        voucherNo: 'INV-${_random5()}',
        orderId: 'ORD-${_random5()}',
        items: items
            .map(
              (e) => SaleItemEntity(
                productId: e.productId,
                productName: e.productName,
                imageUrl: e.imageUrl,
                unitPrice: e.unitPrice,
                quantity: e.quantity,
                size: e.size,
                color: e.color,
                category: e.category,
              ),
            )
            .toList(),
        grandTotal: items.fold(0.0, (sum, e) => sum + e.subtotal),
        status: 'draft',
      );
    } on AppException catch (e) {
      if (!mounted) return;
      showErrorMessage(context, e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      showErrorMessage(context, 'Failed to add to cart: $e');
      return;
    }

    final card = await CartStore.instance.addCard(
      items,
      orderId: createOrderId,
    );
    if (!mounted) return;
    setState(() {
      for (final id in _selectedIds) {
        _quantities[id] = 0;
        _syncQtyCtrl(id);
      }
      _selectedIds.clear();
      _variantPicks.clear();
    });
    if (card == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CartCardScreen(card: card)));
  }

  String _random5() {
    final rand = Random();
    return (10000 + rand.nextInt(90000)).toString();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: widget.categoryName,
              showMenuButton: false,
              showBackButton: true,
            ),
            Expanded(child: _buildBody()),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshableBody(
      onRefresh: _refreshProducts,
      scrollController: _scrollCtrl,
      child: LayoutBuilder(
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

          if (_products.isEmpty && _isLoading) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator(color: purple)),
            );
          }

          if (_error != null && _products.isEmpty) {
            return Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 15),
                  ),
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
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No products in this category',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
              final selected = _selectedIds.contains(p.id);
              return _ProductCard(
                product: p,
                selected: selected,
                quantity: _totalQtyFor(p.id),
                picks: p.variants.isNotEmpty
                    ? (_variantPicks[p.id] ?? const [])
                    : null,
                qtyCtrl: _qtyCtrls[p.id],
                onToggleSelect: () => _toggleSelect(p.id),
                onEditVariants: p.variants.isNotEmpty
                    ? () => _editVariants(p.id)
                    : null,
                onQtyDecrease: () => _adjustQty(p.id, -1),
                onQtyIncrease: () => _adjustQty(p.id, 1),
                onQtyChanged: (v) => _updateQtyFromCtrl(p.id, v),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(productId: p.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _openCart,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.shopping_cart,
                        size: 24,
                        color: titleColor,
                      ),
                    ),
                  ),
                ),
                if (_selectedCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: purple,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Text(
                        '$_selectedCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCount > 0
                        ? '$_selectedCount Items Selected'
                        : 'No items selected',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  PriceText(
                    _selectedTotal,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: (_isAddingToCart || _selectedCount == 0)
                  ? null
                  : _addToCart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: (_isAddingToCart || _selectedCount == 0)
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)],
                        ),
                  color: (_isAddingToCart || _selectedCount == 0)
                      ? const Color(0xFFD1D5DB)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isAddingToCart
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Add to Cart',
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
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final CatalogProductView product;
  final bool selected;
  final int quantity;
  final List<VariantPick>? picks;
  final TextEditingController? qtyCtrl;
  final VoidCallback onToggleSelect;
  final VoidCallback? onEditVariants;
  final VoidCallback onQtyDecrease;
  final VoidCallback onQtyIncrease;
  final ValueChanged<String> onQtyChanged;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.product,
    required this.selected,
    this.quantity = 0,
    this.picks,
    this.qtyCtrl,
    required this.onToggleSelect,
    this.onEditVariants,
    required this.onQtyDecrease,
    required this.onQtyIncrease,
    required this.onQtyChanged,
    this.onTap,
  });

  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);

  double get _displayPrice => (picks != null && picks!.isNotEmpty)
      ? picks!.first.variant.price
      : (product.variants.isNotEmpty
            ? product.variants.first.price
            : product.price);

  int get _displayStock => product.stock;

  String get _picksSummary => (picks ?? const [])
      .map((e) => '${variantTitle(e.variant)} ×${e.qty}')
      .join(', ');

  double get _itemTotal {
    final pl = picks;
    if (pl != null && pl.isNotEmpty) {
      return pl.fold(0.0, (sum, e) => sum + e.variant.price * e.qty);
    }
    return _displayPrice * quantity;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? purple : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
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
              child: Stack(
                children: [
                  Positioned.fill(child: _image()),
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
                        'Stock: ${product.stock}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onToggleSelect,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: selected
                              ? purple
                              : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: selected ? purple : const Color(0xFFD1D5DB),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PriceText(
                    _displayPrice,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (product.variants.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.tune, size: 12, color: gray),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            selected && (picks != null && picks!.isNotEmpty)
                                ? 'Variant: $_picksSummary'
                                : '${product.variants.length} Variants',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: gray),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Stock: $_displayStock',
                      style: const TextStyle(fontSize: 11, color: gray),
                    ),
                  if (selected) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (picks != null && picks!.isNotEmpty) ...[
                            Text(
                              _picksSummary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: purple,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (onEditVariants != null)
                              GestureDetector(
                                onTap: onEditVariants,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      size: 12,
                                      color: AppColors.teal,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Edit variants',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (onEditVariants != null)
                              const SizedBox(height: 6),
                          ] else ...[
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Quantity',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: gray,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _qtyEditor(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: gray,
                                ),
                              ),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: PriceText(
                                    _itemTotal,
                                    maxLength: 10,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _image() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        child: product.imageUrl != null
            ? Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _qtyEditor() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(Icons.remove, onQtyDecrease),
          SizedBox(
            width: 34,
            child: TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: onQtyChanged,
            ),
          ),
          _qtyBtn(Icons.add, onQtyIncrease),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: gray),
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
      child: Center(child: Icon(product.icon, color: Colors.white, size: 36)),
    );
  }
}

class _VariantPickDialog extends StatefulWidget {
  final CatalogProductView product;
  final ValueChanged<List<VariantPick>> onConfirm;

  const _VariantPickDialog({required this.product, required this.onConfirm});

  @override
  State<_VariantPickDialog> createState() => _VariantPickDialogState();
}

class _VariantPickDialogState extends State<_VariantPickDialog> {
  static const Color purple = Color(0xFF6D28D9);
  static const Color gray = Color(0xFF6B7280);

  final List<TextEditingController> _ctrls = [];
  late final List<int> _qtys;

  CatalogProductView get _product => widget.product;

  int get _totalPicked => _qtys.fold(0, (sum, q) => sum + q);

  int get _totalStock =>
      _product.variants.fold(0, (sum, v) => sum + v.quantity);
  int get _productStock => _product.stock > 0 ? _product.stock : _totalStock;

  @override
  void initState() {
    super.initState();
    _qtys = List.filled(_product.variants.length, 0);
    for (final _ in _product.variants) {
      _ctrls.add(TextEditingController(text: '0'));
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  int _maxFor(int i) {
    final other = _totalPicked - _qtys[i];
    return min(_product.variants[i].quantity, _productStock - other);
  }

  void _setQty(int i, int qty) {
    if (qty < 0) qty = 0;
    final maxQ = _maxFor(i);
    if (qty > maxQ) qty = maxQ;
    setState(() {
      _qtys[i] = qty;
      _ctrls[i].value = TextEditingValue(
        text: '$qty',
        selection: TextSelection.collapsed(offset: '$qty'.length),
      );
    });
  }

  void _fromCtrl(int i, String txt) {
    _setQty(i, int.tryParse(txt) ?? 0);
  }

  void _fillAll() {
    setState(() {
      var remaining = _productStock;
      for (var i = 0; i < _qtys.length; i++) {
        final take = min(_product.variants[i].quantity, remaining);
        _qtys[i] = take;
        remaining -= take;
        _ctrls[i].text = '$take';
      }
    });
  }

  void _confirm() {
    final picks = <VariantPick>[];
    for (var i = 0; i < _qtys.length; i++) {
      if (_qtys[i] > 0) {
        picks.add(VariantPick(variant: _product.variants[i], qty: _qtys[i]));
      }
    }
    widget.onConfirm(picks);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose Variants',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            _product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: gray),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_totalPicked / $_productStock pieces',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: purple,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _fillAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 13, color: purple),
                      SizedBox(width: 4),
                      Text(
                        'Fill all stock',
                        style: TextStyle(
                          fontSize: 11,
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
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _product.variants.length; i++) _variantRow(i),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: gray),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _totalPicked > 0 ? _confirm : null,
          style: FilledButton.styleFrom(
            backgroundColor: purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _variantRow(int i) {
    final v = _product.variants[i];
    final qty = _qtys[i];
    final maxQ = _maxFor(i);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: qty > 0 ? purple : const Color(0xFFE5E7EB),
          width: qty > 0 ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 16, color: qty > 0 ? purple : gray),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      variantTitle(v),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stock: ${v.quantity}',
                      style: const TextStyle(fontSize: 11, color: gray),
                    ),
                  ],
                ),
              ),
              PriceText(
                v.price,
                maxLength: 8,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                qty > 0 ? 'Selected: $qty' : 'Tap + to select',
                style: TextStyle(fontSize: 11, color: qty > 0 ? purple : gray),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _stepBtn(
                      Icons.remove,
                      qty > 0 ? () => _setQty(i, qty - 1) : null,
                    ),
                    SizedBox(
                      width: 38,
                      child: TextField(
                        controller: _ctrls[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 4,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (t) => _fromCtrl(i, t),
                      ),
                    ),
                    _stepBtn(
                      Icons.add,
                      qty < maxQ ? () => _setQty(i, qty + 1) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Icon(
          icon,
          size: 14,
          color: onTap == null ? const Color(0xFFD1D5DB) : gray,
        ),
      ),
    );
  }
}

enum _AddToCartChoice { newCard, existingCard }

class _AddToCartChoiceDialog extends StatelessWidget {
  const _AddToCartChoiceDialog();

  static const Color purple = Color(0xFF6D28D9);
  static const Color gray = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Add to Cart',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            context,
            icon: Icons.add_card,
            title: 'New Card',
            subtitle: 'Create a new cart card for these items',
            choice: _AddToCartChoice.newCard,
          ),
          const SizedBox(height: 10),
          _option(
            context,
            icon: Icons.folder_open,
            title: 'Existing Card',
            subtitle: 'Load an old card and add items to it (merge categories)',
            choice: _AddToCartChoice.existingCard,
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required _AddToCartChoice choice,
  }) {
    return InkWell(
      onTap: () => Navigator.of(ctx).pop(choice),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: purple, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: gray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: gray, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ExistingCardPicker extends StatefulWidget {
  final List<CartCardEntity> cards;

  const _ExistingCardPicker({required this.cards});

  @override
  State<_ExistingCardPicker> createState() => _ExistingCardPickerState();
}

class _ExistingCardPickerState extends State<_ExistingCardPicker> {
  static const Color purple = Color(0xFF6D28D9);
  static const Color gray = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Existing Cards',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 20, color: gray),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: widget.cards.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final card = widget.cards[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(card),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              color: purple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${card.totalQuantity} items',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card.items
                                      .take(3)
                                      .map((e) => e.productName)
                                      .join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PriceText(
                            card.total,
                            maxLength: 10,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
