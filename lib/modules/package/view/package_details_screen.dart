import 'package:flutter/material.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/inventory/view/inventory_sidebar.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/package/model/product_models.dart';
import 'package:posfrontend/modules/package/repository/product_repository_impl.dart';
import 'package:posfrontend/modules/product/view/product_detail_screen.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

class PackageDetailsScreen extends StatefulWidget {
  final LoginResponse? user;
  final Package package;
  final Category category;

  const PackageDetailsScreen({
    super.key,
    this.user,
    required this.package,
    required this.category,
  });

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _search = TextEditingController();
  late final List<Product> _products;

  String get _initials {
    final name = widget.user?.fullName.trim() ?? 'John Doe';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get _stockLabel {
    switch (widget.package.status) {
      case StockStatus.inStock:
        return 'Optimal';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'No Stock';
    }
  }

  int get _stockPct {
    switch (widget.package.status) {
      case StockStatus.inStock:
        return 75;
      case StockStatus.lowStock:
        return 40;
      case StockStatus.outOfStock:
        return 5;
    }
  }

  @override
  void initState() {
    super.initState();
    _products = ProductRepositoryImpl().getProducts(widget.package);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return _products;
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q))
        .toList();
  }

  int get _totalUnits =>
      _products.fold(0, (sum, p) => sum + p.quantity);

  @override
  Widget build(BuildContext context) {
    final sidebar = InventorySidebar(
      user: widget.user,
      activeItem: 'Inventory',
      onNavigate: (_) {},
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _content();

        if (isWide) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Row(children: [sidebar, Expanded(child: body)]),
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: Drawer(child: sidebar),
          body: body,
        );
      },
    );
  }

  Widget _content() {
    final p = widget.package;
    final c = widget.category;

    return SafeArea(
      child: ListenableBuilder(
        listenable: _search,
        builder: (context, _) {
          final products = _filtered;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InventoryHeader(
                  title: 'Package Details',
                  initials: _initials,
                  showMenu: false,
                ),
                const SizedBox(height: 20),
                const Breadcrumb([
                  BreadcrumbItem('Dashboard', false),
                  BreadcrumbItem('Inventory', false),
                  BreadcrumbItem('Packages', false),
                  BreadcrumbItem('Package Details', true),
                ]),
                const SizedBox(height: 24),
                _summaryCard(p, c),
                const SizedBox(height: 16),
                _stockSection(p),
                const SizedBox(height: 24),
                _productsHeader(),
                const SizedBox(height: 12),
                if (products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No products found.', style: TextStyle(color: kGray)),
                    ),
                  )
                else
                  Column(
                    children: products
                        .map((pr) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _productRow(pr, c),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(Package p, Category c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      c.iconColor.withValues(alpha: 0.85),
                      c.iconColor.withValues(alpha: 0.55),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: c.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(c.imageUrl!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Icon(
                          c.icon,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 52,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kPurple,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: kTitle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.spec,
                      style: const TextStyle(fontSize: 14, color: kGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(p, c),
        ],
      ),
    );
  }

  Widget _infoBlock(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: kPurple),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: kGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(Package p, Category c) {
    final blocks = [
      _infoBlock(Icons.monitor, 'Category', c.name),
      _infoBlock(Icons.location_on_outlined, 'Location', p.location),
      _infoBlock(Icons.inventory_2, 'Amount of Products', '${p.quantity} Units'),
    ];
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: blocks
                .map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: b,
                    ))
                .toList(),
          );
        }
        return Row(
          children: [
            Expanded(child: blocks[0]),
            const SizedBox(width: 8),
            Expanded(child: blocks[1]),
            const SizedBox(width: 8),
            Expanded(child: blocks[2]),
          ],
        );
      },
    );
  }

  Widget _stockSection(Package p) {
    final color = stockFg(p.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: kPurple, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Stock Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTitle,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stockBg(p.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _stockLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _stockPct / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_stockPct%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Products in this Package ($_totalUnits)',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTitle,
                ),
              ),
            ),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: kTitle),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, color: kTitle),
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) {},
          decoration: fieldDecoration('Search products...'),
        ),
      ],
    );
  }

  Widget _productRow(Product pr, Category c) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            user: widget.user,
            product: pr,
            category: c,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    c.iconColor.withValues(alpha: 0.85),
                    c.iconColor.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  c.icon,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pr.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pr.description,
                    style: const TextStyle(fontSize: 13, color: kGray),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${pr.quantity}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right, color: kGray),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
