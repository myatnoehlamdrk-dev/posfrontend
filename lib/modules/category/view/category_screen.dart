import 'package:flutter/material.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository_impl.dart';
import 'package:posfrontend/modules/category/view/add_category_screen.dart';
import 'package:posfrontend/modules/package/view/package_screen.dart';
import 'package:posfrontend/modules/category/viewmodel/category_view_model.dart';
import 'package:posfrontend/modules/inventory/repository/inventory_repository_impl.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

class CategoryScreen extends StatefulWidget {
  final LoginResponse? user;
  final String inventoryType;

  const CategoryScreen({super.key, this.user, this.inventoryType = 'self'});

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
      repository: CategoryRepositoryImpl(),
      inventoryRepository: InventoryRepositoryImpl(),
      type: widget.inventoryType,
    );
  }

  Future<void> _openAddCategory() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(
          user: widget.user,
          inventoryType: widget.inventoryType,
        ),
      ),
    );
    if (result is Category) {
      _viewModel.addCategory(result);
    }
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
                  SizedBox(
                    width: 240,
                    child: AppDrawer(user: widget.user, activeItem: 'Inventory'),
                  ),
                  Expanded(child: body),
                ],
              ),
            );
          }

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: bg,
            drawer: AppDrawer(user: widget.user, activeItem: 'Inventory'),
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
                    user: widget.user,
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
                child: Text('Name (A–Z)'),
              ),
              PopupMenuItem(
                value: CategorySort.nameZa,
                child: Text('Name (Z–A)'),
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
          builder: (_) => PackageScreen(user: widget.user, category: c),
        ),
      ),
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
                        color: c.iconColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(c.icon, color: Colors.white, size: 18),
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
                      style: const TextStyle(fontSize: 13, color: gray),
                    ),
                  ],
                ),
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
    return Container(
      width: 110,
      height: 110,
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
      child: c.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(c.imageUrl!, fit: BoxFit.cover),
            )
          : Center(
              child: Icon(
                c.icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 42,
              ),
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
