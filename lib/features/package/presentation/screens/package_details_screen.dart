import 'package:flutter/material.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/package/presentation/viewmodels/package_detail_view_model.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart' hide ProductVariant;
import 'package:posfrontend/features/product/data/repositories/product_repository_impl.dart';
import 'package:posfrontend/features/package/presentation/screens/assign_product_to_package_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

class PackageDetailsScreen extends StatefulWidget {
  final PackageEntity package;
  final Category category;

  const PackageDetailsScreen({
    super.key,
    required this.package,
    required this.category,
  });

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _search = TextEditingController();
  late final PackageDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PackageDetailViewModel(
      productRepository: ProductRepositoryImpl(),
      package: widget.package,
      category: CategoryInfo(
        name: widget.category.name,
        iconColor: widget.category.iconColor ?? const Color(0xFF6D28D9),
        icon: widget.category.icon ?? Icons.category,
        imageUrl: widget.category.imageUrl,
      ),
    );
    _viewModel.load();
  }

  Future<void> _openAddProduct() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssignProductToPackageScreen(
          package: widget.package,
          category: widget.category,
        ),
      ),
    );
    if (result == true) {
      _viewModel.load();
    }
  }

  Future<void> _removeProductFromPackage(CatalogProductView product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Product'),
        content: Text(
          'Remove "${product.name}" from this package? The product will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await _viewModel.removeProduct(product);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product removed from package')),
      );
    } else if (_viewModel.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!)),
      );
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _search.dispose();
    super.dispose();
  }

  List<CatalogProductView> get _filtered {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return _viewModel.products;
    return _viewModel.products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 768;
            final body = _content();

            if (isWide) {
              return Scaffold(
                backgroundColor: Colors.white,
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: _openAddProduct,
                  backgroundColor: const Color(0xFF4FD1D9),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Product', style: TextStyle(color: Colors.white)),
                ),
                body: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 240,
                        child: AppDrawer(activeItem: 'Inventory'),
                      ),
                      Expanded(child: _content()),
                    ],
                  ),
                ),
              );
            }
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.white,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _openAddProduct,
                backgroundColor: const Color(0xFF4FD1D9),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Product', style: TextStyle(color: Colors.white)),
              ),
              drawer: AppDrawer(activeItem: 'Inventory'),
              body: SafeArea(child: body),
            );
          },
        );
      },
    );
  }

  Widget _content() {
    final p = widget.package;
    final c = widget.category;

    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6D28D9)),
      );
    }
    if (_viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_viewModel.errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _viewModel.load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListenableBuilder(
        listenable: _search,
        builder: (context, _) {
          final products = _filtered;
          return RefreshableBody(
            onRefresh: _viewModel.load,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTopBar(
                    title: 'Package Details',
                    showMenuButton: false,
                    showBackButton: true,
                  ),
                  const SizedBox(height: 20),
                  Breadcrumb([
                    const BreadcrumbItem('Dashboard', false),
                    const BreadcrumbItem('Inventory', false),
                    BreadcrumbItem(widget.category.name, false),
                    BreadcrumbItem(widget.package.name, false),
                    const BreadcrumbItem('Package Detail', true),
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
                                child: _productRow(pr),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          );
        },
    );
  }

  Widget _summaryCard(PackageEntity p, Category c) {
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
                      (c.iconColor ?? const Color(0xFF6D28D9)).withValues(alpha: 0.85),
                      (c.iconColor ?? const Color(0xFF6D28D9)).withValues(alpha: 0.55),
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

  Widget _infoRow(PackageEntity p, Category c) {
    final blocks = [
      _infoBlock(Icons.monitor, 'Category', c.name),
      _infoBlock(Icons.location_on_outlined, 'Location', p.location),
      _infoBlock(Icons.inventory_2, 'Amount of Products', '${p.quantity} Units'),
      if (p.createdBy.isNotEmpty)
        _infoBlock(Icons.person_add, 'Created By', p.createdBy),
      if (p.updatedBy.isNotEmpty)
        _infoBlock(Icons.edit, 'Updated By', p.updatedBy),
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

  Widget _stockSection(PackageEntity p) {
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
                  _viewModel.stockLabel,
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
                  value: _viewModel.stockPct / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_viewModel.stockPct}%',
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
                'Products in this Package (${_viewModel.totalUnits})',
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

  Widget _productRow(CatalogProductView pr) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            productId: pr.id,
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
                color: pr.color,
              ),
              clipBehavior: Clip.antiAlias,
              child: pr.imageUrl != null
                  ? Image.network(
                      pr.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        pr.icon,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 36,
                      ),
                    )
                  : Icon(
                      pr.icon,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 36,
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
                    pr.brand,
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
                    '${pr.stock}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: kGray, size: 20),
                  tooltip: 'Actions',
                  onSelected: (value) {
                    if (value == 'remove') {
                      _removeProductFromPackage(pr);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Remove from package'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
