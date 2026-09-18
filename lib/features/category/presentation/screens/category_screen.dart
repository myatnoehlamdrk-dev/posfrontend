import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';
import 'package:posfrontend/features/category/presentation/screens/add_category_screen.dart';
import 'package:posfrontend/features/category/presentation/viewmodels/category_view_model.dart';
import 'package:posfrontend/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:posfrontend/features/package/presentation/screens/package_screen.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/error_snackbar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

class CategoryScreen extends StatefulWidget {
  final String inventoryType;

  const CategoryScreen({super.key, this.inventoryType = 'self'});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final CategoryViewModel _viewModel;

  static const Color bg = Color(0xFFFFFFFF);
  static const Color title = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);
  static const Color border = Color(0xFFE5E7EB);

  String get _inventoryLabel {
    switch (widget.inventoryType) {
      case 'public':
        return 'Public Inventory';
      case 'self':
      default:
        return 'Self Inventory';
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = CategoryViewModel(
      repository: GetIt.instance<CategoryRepository>(),
      inventoryRepository: GetIt.instance<InventoryRepository>(),
      type: widget.inventoryType,
    );
  }

  Future<void> _openAddCategory() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(
          inventoryType: widget.inventoryType,
        ),
      ),
    );
    if (result is Category) {
      _viewModel.addCategory(result);
    }
  }

  Future<void> _openEditCategory(Category category) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(
          inventoryType: widget.inventoryType,
          existingCategory: category,
        ),
      ),
    );
    if (result is Category) {
      _viewModel.updateCategory(result);
    }
  }

  void _showDeleteDialog(Category c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${c.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _viewModel.deleteCategory(c.id);
              if (!success && mounted && _viewModel.hasError) {
                showErrorSnackBar(context, _viewModel.errorMessage!);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final body = _buildContent(isWide: isWide);

          if (isWide) {
            return Scaffold(
              backgroundColor: bg,
              floatingActionButton: FloatingActionButton(
                onPressed: _openAddCategory,
                backgroundColor: const Color(0xFF4FD1D9),
                child: const Icon(Icons.category, color: Colors.white),
              ),
              body: Row(
                children: [
                  const SizedBox(
                    width: 240,
                    child: AppDrawer(activeItem: 'Inventory'),
                  ),
                  Expanded(child: body),
                ],
              ),
            );
          }

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: bg,
            drawer: const AppDrawer(activeItem: 'Inventory'),
            floatingActionButton: FloatingActionButton(
              onPressed: _openAddCategory,
              backgroundColor: const Color(0xFF4FD1D9),
              child: const Icon(Icons.category, color: Colors.white),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
            body: body,
          );
        },
    );
  }

  Widget _buildContent({required bool isWide}) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final items = _viewModel.filtered;
          return RefreshableBody(
            onRefresh: () => _viewModel.load(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTopBar(
                    title: _inventoryLabel,
                    showMenuButton: !isWide,
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(height: 20),
                  _breadcrumb(),
                  const SizedBox(height: 16),
                  _headingRow(),
                  const SizedBox(height: 20),
                  _filterToolbar(),
                  const SizedBox(height: 20),
                  if (_viewModel.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: purple),
                      ),
                    )
                  else if (_viewModel.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          _viewModel.errorMessage ?? 'Failed to load categories.',
                          style: const TextStyle(color: gray),
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (c, constraints) {
                        final cols = constraints.maxWidth >= 560 ? 2 : 1;
                        return _categoryGrid(items, cols);
                      },
                    ),
                  const SizedBox(height: 20),
                  _pagination(items.length),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _breadcrumb() {
    const style = TextStyle(fontSize: 13, color: gray);
    return Wrap(
      children: [
        GestureDetector(
          onTap: () {},
          child: const Text('Dashboard', style: TextStyle(fontSize: 13, color: purple)),
        ),
        const Text('  >  ', style: style),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Text('Inventory', style: TextStyle(fontSize: 13, color: purple)),
        ),
        const Text('  >  ', style: style),
        GestureDetector(
          onTap: () {},
          child: Text(
            _inventoryLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: purple),
          ),
        ),
        const Text('  >  ', style: style),
        const Text('Categories', style: style),
      ],
    );
  }

  Widget _headingRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: title,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _viewModel.status,
              style: const TextStyle(color: title, fontSize: 14),
              items: const [
                DropdownMenuItem(value: 'All Status', child: Text('All Status')),
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => _viewModel.setStatus(v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: _viewModel.setSearch,
            decoration: InputDecoration(
              hintText: 'Search categories...',
              hintStyle: const TextStyle(color: gray, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: gray, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: PopupMenuButton<CategorySort>(
            icon: const Icon(Icons.filter_list, color: title),
            tooltip: 'Sort',
            onSelected: (v) => _viewModel.setSort(v),
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: CategorySort.dateNewest,
                child: Text('Newest first'),
              ),
              PopupMenuItem(
                value: CategorySort.dateOldest,
                child: Text('Oldest first'),
              ),
              PopupMenuItem(
                value: CategorySort.nameAz,
                child: Text('Name (A\u2013Z)'),
              ),
              PopupMenuItem(
                value: CategorySort.nameZa,
                child: Text('Name (Z\u2013A)'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryGrid(List<Category> items, int cols) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No categories found.', style: TextStyle(color: gray)),
        ),
      );
    }
    if (cols == 1) {
      return Column(
        children: items
            .map((c) => Padding(
                  key: ValueKey(c.id),
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _categoryCard(c),
                ))
            .toList(),
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final a = _categoryCard(items[i]);
      final b = i + 1 < items.length
          ? _categoryCard(items[i + 1])
          : const SizedBox.shrink();
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 20),
            Expanded(child: b),
          ],
        ),
      );
      rows.add(const SizedBox(height: 20));
    }
    return Column(children: rows);
  }

  Widget _categoryCard(Category c) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PackageScreen(
            category: c,
          ),
        ),
      ),
      onLongPress: () => _showDeleteDialog(c),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _categoryImage(c),
                  Positioned(
                    left: -8,
                    bottom: -8,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6D28D9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.category, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: title,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _packageBadge(c.packageCount, c.packageLimit),
                    const SizedBox(height: 8),
                    Text(
                      c.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: gray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: purple),
                tooltip: 'Edit category',
                onPressed: () => _openEditCategory(c),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Created: ${c.createdDate}',
                style: const TextStyle(fontSize: 12, color: gray),
              ),
              if (c.createdBy.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  'by ${c.createdBy}',
                  style: const TextStyle(fontSize: 11, color: gray, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(width: 8),
              _statusBadge(c.active),
              const Spacer(),
              const Icon(Icons.chevron_right, color: gray),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _categoryImage(Category c) {
    final images = c.productImages;
    if (images.isEmpty) {
      return Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6D28D9).withValues(alpha: 0.85),
              const Color(0xFF6D28D9).withValues(alpha: 0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.category,
            color: Colors.white.withValues(alpha: 0.9),
            size: 42,
          ),
        ),
      );
    }

    return SizedBox(
      width: 110,
      height: 110,
      child: images.length == 1
          ? _singleImage(images[0])
          : images.length == 2
              ? _twoImageMosaic(images)
              : _threeImageMosaic(images),
    );
  }

  Widget _singleImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(url, fit: BoxFit.cover, width: 110, height: 110,
        errorBuilder: (_, __, ___) => Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.image_not_supported_outlined, color: gray, size: 32),
        ),
      ),
    );
  }

  Widget _twoImageMosaic(List<String> urls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _mosaicTile(urls[0])),
                const SizedBox(width: 2),
                Expanded(child: _mosaicTile(urls.length > 1 ? urls[1] : '')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _threeImageMosaic(List<String> urls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(child: _mosaicTile(urls[0])),
                const SizedBox(width: 2),
                Expanded(child: _mosaicTile(urls[1])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            flex: 2,
            child: _mosaicTile(urls[2]),
          ),
        ],
      ),
    );
  }

  Widget _mosaicTile(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: const Icon(Icons.image_outlined, color: gray, size: 20),
      );
    }
    return Image.network(url, fit: BoxFit.cover, width: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF3F4F6),
        child: const Icon(Icons.image_not_supported_outlined, color: gray, size: 20),
      ),
    );
  }

  Widget _packageBadge(int count, int limit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count in $limit',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: purple,
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
        ),
      ),
    );
  }

  Widget _pagination(int shown) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'First $shown of ${_viewModel.totalCount} categories',
            style: const TextStyle(fontSize: 13, color: gray),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.chevron_left, color: gray),
          onPressed: null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: purple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '1',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: gray),
          onPressed: null,
        ),
      ],
    );
  }
}
