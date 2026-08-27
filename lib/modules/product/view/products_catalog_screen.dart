import 'package:flutter/material.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/inventory/view/inventory_sidebar.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/package/model/product_models.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/product/repository/catalog_product_repository_impl.dart';
import 'package:posfrontend/modules/product/view/add_product_screen.dart';
import 'package:posfrontend/modules/product/view/product_detail_screen.dart';

class ProductsCatalogScreen extends StatefulWidget {
  final LoginResponse? user;
  const ProductsCatalogScreen({super.key, this.user});

  @override
  State<ProductsCatalogScreen> createState() => _ProductsCatalogScreenState();
}

class _ProductsCatalogScreenState extends State<ProductsCatalogScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _search = TextEditingController();
  late final List<CatalogProduct> _all;
  bool _isGrid = true;
  String _category = 'All';
  static const Color bg = Color(0xFFF8F9FC);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);
  static const Color titleColor = Color(0xFF111827);

  final List<String> _filters = const [
    'All',
    'Audio',
    'Charging',
    'Peripherals',
    'Accessories',
  ];

  String get _initials {
    final name = widget.user?.fullName.trim() ?? 'John Doe';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _all = CatalogProductRepositoryImpl().getProducts();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CatalogProduct> get _filtered {
    final q = _search.text.toLowerCase();
    return _all.where((p) {
      final matchesCat = _category == 'All' || p.category == _category;
      final matchesSearch =
          q.isEmpty || p.name.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();
  }

  void _open(CatalogProduct p) {
    final category = Category(
      id: p.category.toLowerCase(),
      name: p.category,
      packageCount: 0,
      description: '',
      createdDate: '',
      active: true,
      iconColor: p.color,
      icon: p.icon,
    );
    final product = Product(
      name: p.name,
      description: p.brand,
      quantity: p.stock,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          user: widget.user,
          product: product,
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sidebar = InventorySidebar(
      user: widget.user,
      activeItem: 'Product',
      onNavigate: (_) {},
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _content();

        if (isWide) {
          return Scaffold(
            backgroundColor: bg,
            body: Row(children: [sidebar, Expanded(child: body)]),
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bg,
          drawer: Drawer(child: sidebar),
          body: body,
        );
      },
    );
  }

  Widget _content() {
    final dateLabel = _formatDate(DateTime.now());
    final products = _filtered;
    final featured = _all.first;

    return SafeArea(
      child: ListenableBuilder(
        listenable: _search,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
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
                    _iconButton(
                      Icons.filter_list,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _searchField(),
                const SizedBox(height: 16),
                _pills(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      "Today's Products",
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
                _banner(featured),
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
                    const Spacer(),
                    Text(
                      '${products.length} items',
                      style: const TextStyle(fontSize: 14, color: gray),
                    ),
                    const SizedBox(width: 12),
                    _addProductButton(),
                  ],
                ),
                const SizedBox(height: 12),
                _isGrid ? _grid(products) : _list(products),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: titleColor),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const Spacer(),
        Container(
          width: 90,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 20,
          backgroundColor: purple,
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddProductScreen(user: widget.user),
            ),
          ),
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

  Widget _banner(CatalogProduct p) {
    return Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.brand,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '\$${p.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _open(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
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
                const SizedBox(width: 12),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    p.icon,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 14,
            right: 20,
            child: Row(
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: i == 0 ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == 0 ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
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
          childAspectRatio: 0.72,
          children: products.map(_gridCard).toList(),
        );
      },
    );
  }

  Widget _gridCard(CatalogProduct p) {
    return GestureDetector(
      onTap: () => _open(p),
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
                    gradient: LinearGradient(
                      colors: [
                        p.color.withValues(alpha: 0.85),
                        p.color.withValues(alpha: 0.55),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Icon(p.icon, color: Colors.white, size: 44),
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
            Padding(
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
                  const SizedBox(height: 8),
                  Text(
                    '\$${p.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: purple,
                    ),
                  ),
                ],
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
                child: Icon(p.icon, color: Colors.white, size: 34),
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
                  Text(
                    '\$${p.price.toStringAsFixed(0)}',
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

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
