import 'package:flutter/material.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/package/presentation/viewmodels/assign_product_to_package_view_model.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/data/repositories/product_repository_impl.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class AssignProductToPackageScreen extends StatefulWidget {
  final PackageEntity package;
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

  // Brightness-dependent tokens; the `k*` constants are light-only.
  AppPalette get _p => context.palette;
  Color get _titleColor => _p.textPrimary;
  Color get _mutedColor => _p.textSecondary;
  Color get _accentColor => _p.primary;
  Color get _borderColor => _p.border;

  @override
  void initState() {
    super.initState();
    _viewModel = AssignProductToPackageViewModel(
      productRepository: ProductRepositoryImpl(),
      package: widget.package,
    );
    _viewModel.loadProducts();
  }

  Future<void> _assignToPackage() async {
    final successCount = await _viewModel.assignToPackage();
    if (successCount > 0 && mounted) {
      showSuccessMessage(context, '$successCount product(s) added to package');
      Navigator.of(context).pop(true);
    } else if (_viewModel.hasError && mounted) {
      showErrorMessage(
        context,
        _viewModel.errorMessage ?? 'Failed to assign products',
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
          backgroundColor: _p.scaffoldBg,
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
            CustomBackButton(onTap: () => Navigator.of(context).pop(false)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Add Products to Package',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.package.name} • ${widget.category.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: _mutedColor),
                  ),
                ],
              ),
            ),
            if (!_viewModel.isLoading)
              GestureDetector(
                onTap: _viewModel.toggleSelectAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _p.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Text(
                    _viewModel.allFilteredSelected
                        ? 'Deselect All'
                        : 'Select All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accentColor,
                    ),
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
          hintStyle: TextStyle(color: _p.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: _mutedColor, size: 20),
          filled: true,
          fillColor: _p.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor),
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
                color: active ? _accentColor : _p.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? _accentColor : _borderColor),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : _mutedColor,
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
      return Center(child: CircularProgressIndicator(color: _accentColor));
    }
    if (_viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _viewModel.errorMessage!,
              style: TextStyle(color: _mutedColor),
            ),
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
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: _p.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No unassigned products found.',
              style: TextStyle(color: _mutedColor, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'All products are already in a package.',
              style: TextStyle(
                color: _mutedColor.withValues(alpha: 0.7),
                fontSize: 13,
              ),
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

  Widget _productCard(CatalogProductView p) {
    final selected = _viewModel.selectedIds.contains(p.id);
    return GestureDetector(
      onTap: () => _viewModel.toggleSelect(p.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _accentColor : _borderColor,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _p.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? _accentColor : _p.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected ? _accentColor : _p.borderStrong,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: p.stock > 0
                              ? _p.successBg
                              : _p.dangerBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.stock > 0 ? '${p.stock} in stock' : 'Out of stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.stock > 0
                                ? _p.successFg
                                : _p.dangerFg,
                          ),
                        ),
                      ),
                      if (p.brand.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: _mutedColor),
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
      decoration: BoxDecoration(
        color: _p.surface,
        border: Border(top: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: _p.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(Icons.inventory_2, size: 28, color: _titleColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_viewModel.selectedCount} product(s) selected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _titleColor,
                ),
              ),
            ),
            GestureDetector(
              onTap: _viewModel.isAssigning ? null : _assignToPackage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: !_viewModel.isAssigning
                      ? LinearGradient(
                          colors: [_accentColor, _p.primaryDark],
                        )
                      : null,
                  color: _viewModel.isAssigning ? _p.borderStrong : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _viewModel.isAssigning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Add to Package',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
