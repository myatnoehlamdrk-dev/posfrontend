import 'package:flutter/material.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/inventory/view/inventory_sidebar.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/package/model/product_models.dart';
import 'package:posfrontend/modules/product/model/product_detail_models.dart';
import 'package:posfrontend/modules/product/repository/product_detail_repository.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final LoginResponse? user;
  final Product product;
  final Category category;

  const ProductDetailScreen({
    super.key,
    this.user,
    required this.product,
    required this.category,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ProductDetail _detail;
  int _tabIndex = 0;

  String get _initials {
    final name = widget.user?.fullName.trim() ?? 'John Doe';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _detail = ProductDetailRepositoryImpl().getDetail(widget.product, widget.category);
  }

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
    final c = widget.category;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InventoryHeader(
              title: 'Product Detail',
              initials: _initials,
              showMenu: false,
            ),
            const SizedBox(height: 20),
            const Breadcrumb([
              BreadcrumbItem('Dashboard', false),
              BreadcrumbItem('Inventory', false),
              BreadcrumbItem('Products', false),
              BreadcrumbItem('Detail', true),
            ]),
            const SizedBox(height: 24),
            _heroImage(c),
            const SizedBox(height: 16),
            _summaryCard(),
            const SizedBox(height: 16),
            _segmented(),
            const SizedBox(height: 16),
            _tabContent(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _heroImage(Category c) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
              size: 84,
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard() {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _detail.categoryName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kPurple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _detail.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _detail.id,
                  style: const TextStyle(fontSize: 13, color: kGray),
                ),
              ],
            ),
          ),
          Text(
            '\$${_detail.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmented() {
    const tabs = ['Info', 'Stock', 'Supplier'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active
                      ? const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: active ? kPurple : kGray,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _tabContent() {
    switch (_tabIndex) {
      case 1:
        return _stockTab();
      case 2:
        return _supplierTab();
      default:
        return _infoTab();
    }
  }

  Widget _infoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identification',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTitle),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.tag, 'Product ID', _detail.id),
          _row(Icons.qr_code, 'SKU', _detail.sku),
          _row(Icons.layers, 'Is Set / Bundle', _detail.isBundle),
        ]),
        const SizedBox(height: 24),
        const Text(
          'Attributes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTitle),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.inventory_2, 'Product Name', _detail.name),
          _row(Icons.business, 'Brand', _detail.brand),
          _row(Icons.category, 'Category', _detail.categoryName),
          _row(Icons.color_lens, 'Color', _detail.color),
          _row(Icons.straighten, 'Size', _detail.size),
          _row(Icons.inventory, 'Package ID', _detail.packageId),
          _row(Icons.store, 'Inventory ID', _detail.inventoryId),
          _row(Icons.check_circle, 'Product Status', _detail.status),
        ]),
      ],
    );
  }

  Widget _stockTab() {
    final pct = _detail.stockAvailable / _detail.maxCapacity;
    final color = _detail.stockStatus == 'Optimal'
        ? const Color(0xFF16A34A)
        : (_detail.stockStatus == 'Low Stock'
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2, color: Color(0xFF16A34A)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_detail.stockAvailable}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: kTitle,
                      ),
                    ),
                    const Text(
                      'Units in Stock',
                      style: TextStyle(fontSize: 13, color: kGray),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        ),
        const SizedBox(height: 24),
        const Text(
          'Stock Info',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTitle),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.check_box, 'Available', '${_detail.stockAvailable} units'),
          _row(Icons.lock, 'Reserved', '${_detail.stockReserved} units'),
          _row(Icons.warning, 'Reorder Level', '${_detail.reorderLevel} units'),
          _row(Icons.remove_circle, 'Minimum Stock', '${_detail.minStock} units'),
          _row(Icons.inventory, 'Maximum Capacity', '${_detail.maxCapacity} units'),
        ]),
        const SizedBox(height: 16),
        Container(
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
                  const Text(
                    'Current Stock Status',
                    style: TextStyle(fontSize: 14, color: kGray),
                  ),
                  const Spacer(),
                  Text(
                    _detail.stockStatus,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _supplierTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supplier Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTitle),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.badge, 'Supplier ID', _detail.supplierId),
          _row(Icons.business, 'Supplier Name', _detail.supplierName),
          _row(Icons.description, 'Contract Number', _detail.contractNumber),
          _row(Icons.calendar_today, 'Supplier Since', _detail.supplierSince),
        ]),
      ],
    );
  }

  Widget _card(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: kBorder),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: kGray),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTitle,
            ),
          ),
        ],
      ),
    );
  }
}
