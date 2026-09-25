import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/data/repositories/product_repository_impl.dart';
import 'package:posfrontend/features/product/presentation/screens/add_product_screen.dart';
import 'package:posfrontend/features/product/presentation/viewmodels/product_detail_view_model.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductDetailViewModel(
      repository: ProductDetailRepositoryImpl(),
      productId: widget.productId,
    );
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 768;
            final body = _content(isWide: isWide);

            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(child: body),
            );
          },
        );
      },
    );
  }

  Widget _content({required bool isWide}) {
    return Column(
      children: [
        AppScreenTopBar(
          title: 'Product Detail',
          showBackButton: true,
          showMenuButton: false,
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Breadcrumb([
                BreadcrumbItem('Dashboard', false),
                BreadcrumbItem('Inventory', false),
                BreadcrumbItem('Products', false),
                BreadcrumbItem('Detail', true),
              ]),
            ],
          ),
        ),
        Expanded(
          child: RefreshableBody(
            onRefresh: _viewModel.load,
            child: _viewModel.isLoading
                ? const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                  )
                : _viewModel.hasError
                ? SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _viewModel.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _viewModel.load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _viewModel.detail == null
                ? const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroImage(),
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
          ),
        ),
      ],
    );
  }

  Widget _heroImage() {
    final d = _viewModel.detail!;
    final color = CatalogProductView.colorFor(d.categoryName);
    final hasImage = d.imageUrl != null;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color,
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Image.network(
                  d.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _heroFallback(color),
                )
              : _heroFallback(color),
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
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddProductScreen(existingProduct: _viewModel.detail),
                ),
              );
              if (mounted) _viewModel.load();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroFallback(Color color) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2,
          color: Colors.white.withValues(alpha: 0.9),
          size: 84,
        ),
      ),
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
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
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
              _viewModel.detail!.categoryName,
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
                  _viewModel.detail!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTitle,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          PriceText(
            _viewModel.detail!.price,
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
          final active = _viewModel.tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _viewModel.setTabIndex(i),
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
    switch (_viewModel.tabIndex) {
      case 1:
        return _stockTab();
      case 2:
        return _supplierTab();
      default:
        return _infoTab();
    }
  }

  Widget _infoTab() {
    final d = _viewModel.detail!;
    final variants = d.variants;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kTitle,
          ),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.qr_code, 'SKU', d.sku),
          _row(Icons.layers, 'Is Set / Bundle', d.isBundle),
        ]),
        const SizedBox(height: 24),
        const Text(
          'Attributes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kTitle,
          ),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.inventory_2, 'Product Name', d.name),
          _row(Icons.business, 'Brand', d.brand),
          _row(Icons.category, 'Category', d.categoryName),
          _row(Icons.color_lens, 'Color', d.color),
          _row(Icons.straighten, 'Size', d.size),
          _row(Icons.inventory, 'Package', d.packageName),
          _row(Icons.store, 'Inventory', d.inventoryType),
          _row(Icons.check_circle, 'Product Status', d.status),
        ]),
        if (d.createdBy.isNotEmpty || d.updatedBy.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Audit Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTitle,
            ),
          ),
          const SizedBox(height: 12),
          _card([
            if (d.createdBy.isNotEmpty)
              _row(Icons.person_add, 'Created By', d.createdBy),
            if (d.createdAt.isNotEmpty)
              _row(Icons.access_time, 'Created At', d.createdAt),
            if (d.updatedBy.isNotEmpty)
              _row(Icons.edit, 'Updated By', d.updatedBy),
            if (d.updatedAt.isNotEmpty)
              _row(Icons.update, 'Updated At', d.updatedAt),
          ]),
        ],
        if (variants.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Variants',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTitle,
            ),
          ),
          const SizedBox(height: 12),
          ...variants.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Color(0xFF6D28D9),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.size.isNotEmpty
                                ? v.size
                                : (v.color.isNotEmpty ? v.color : 'Default'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: kTitle,
                            ),
                          ),
                          if (v.color.isNotEmpty && v.size.isNotEmpty)
                            Text(
                              v.color,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kGray,
                              ),
                            ),
                          Text(
                            'Qty: ${v.quantity}',
                            style: const TextStyle(fontSize: 12, color: kGray),
                          ),
                        ],
                      ),
                    ),
                    PriceText(
                      v.price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _stockTab() {
    final d = _viewModel.detail!;
    final pct = d.stockAvailable / d.maxCapacity;
    final color = d.stockStatus == 'High Stock'
        ? const Color(0xFF16A34A)
        : (d.stockStatus == 'Mid-Cap Stock'
              ? const Color(0xFF2563EB)
              : (d.stockStatus == 'Low Stock'
                    ? const Color(0xFFD97706)
                    : const Color(0xFFDC2626)));
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
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
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
                      '${d.stockAvailable}',
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
        ),
        const SizedBox(height: 24),
        const Text(
          'Stock Info',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kTitle,
          ),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.check_box, 'Available', '${d.stockAvailable} units'),
          _row(Icons.remove_circle, 'Minimum', '${d.minStock} units'),
          _row(Icons.inventory, 'Maximum', '${d.maxCapacity} units'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
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
                    d.stockStatus,
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
    final d = _viewModel.detail!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supplier Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kTitle,
          ),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.badge, 'Supplier ID', d.supplierId),
          _row(Icons.business, 'Supplier Name', d.supplierName),
          _row(Icons.description, 'Contact No', d.contractNumber),
          _row(Icons.calendar_today, 'Supplier Since', d.supplierSince),
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
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
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
            flex: 2,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: kGray),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
