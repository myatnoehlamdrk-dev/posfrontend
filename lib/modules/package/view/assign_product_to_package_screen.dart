import 'package:flutter/material.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/package/viewmodel/assign_product_to_package_view_model.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/product/repository/catalog_product_repository_impl.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

class AssignProductToPackageScreen extends StatefulWidget {
  final Package package;
  final Category category;

  const AssignProductToPackageScreen({
    super.key,
    required this.package,
    required this.category,
  });

  @override
  State<AssignProductToPackageScreen> createState() =>
      _AssignProductToPackageScreenState();
}

class _AssignProductToPackageScreenState
    extends State<AssignProductToPackageScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final AssignProductToPackageViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AssignProductToPackageViewModel(
      productRepository: CatalogProductRepositoryImpl(),
      package: widget.package,
    );
    _viewModel.loadProducts();
  }

  Future<void> _assignToPackage() async {
    final successCount = await _viewModel.assignToPackage();
    if (successCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount product(s) added to package'),
        ),
      );
      Navigator.of(context).pop(true);
    } else if (_viewModel.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!)),
      );
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Column(
            children: [
              _header(),
              _searchBar(),
              _categoryChips(),
              Expanded(child: _productList()),
              if (_viewModel.selectedCount > 0) _bottomBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(false),
              child: const Icon(Icons.arrow_back, size: 24, color: kTitle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Products to Package',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTitle),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.package.name} • ${widget.category.name}',
                    style: const TextStyle(fontSize: 13, color: kGray),
                  ),
                ],
              ),
            ),
            if (!_viewModel.isLoading)
              GestureDetector(
                onTap: _viewModel.toggleSelectAll,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorder),
                  ),
                  child: Text(
                    _viewModel.allFilteredSelected
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPurple),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _viewModel.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search products by name, SKU, brand...',
          hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: kGray, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder),
          ),
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _viewModel.categories.length,
        separatorBuilder: (ctx, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _viewModel.categories[i];
          final active = _viewModel.selectedCategory == cat;
          return GestureDetector(
            onTap: () => _viewModel.setSelectedCategory(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? kPurple : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? kPurple : kBorder,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : kGray,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _productList() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPurple),
      );
    }
    if (_viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_viewModel.errorMessage!, style: const TextStyle(color: kGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _viewModel.loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final items = _viewModel.filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            const Text('No unassigned products found.',
                style: TextStyle(color: kGray, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'All products are already in a package.',
              style: TextStyle(color: kGray.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => KeyedSubtree(
        key: ValueKey(items[i].id),
        child: _productCard(items[i]),
      ),
    );
  }

  Widget _productCard(CatalogProduct p) {
    final selected = _viewModel.selectedIds.contains(p.id);
    return GestureDetector(
      onTap: () => _viewModel.toggleSelect(p.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kPurple : kBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? kPurple : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected ? kPurple : const Color(0xFFD1D5DB),
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: p.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: p.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(p.imageUrl!, fit: BoxFit.cover),
                    )
                  : Icon(p.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14, color: kTitle),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.stock > 0
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.stock > 0 ? '${p.stock} in stock' : 'Out of stock',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.stock > 0
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626)),
                        ),
                      ),
                      if (p.brand.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: kGray),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
        boxShadow: [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(Icons.inventory_2, size: 28, color: kTitle),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_viewModel.selectedCount} product(s) selected',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: kTitle),
              ),
            ),
            GestureDetector(
              onTap: _viewModel.isAssigning ? null : _assignToPackage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: !_viewModel.isAssigning
                      ? const LinearGradient(
                          colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)])
                      : null,
                  color: _viewModel.isAssigning ? const Color(0xFFD1D5DB) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _viewModel.isAssigning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add to Package',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
