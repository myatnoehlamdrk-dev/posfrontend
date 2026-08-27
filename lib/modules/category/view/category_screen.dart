import 'package:flutter/material.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository_impl.dart';
import 'package:posfrontend/modules/category/view/add_category_screen.dart';
import 'package:posfrontend/modules/package/view/package_screen.dart';
import 'package:posfrontend/modules/category/viewmodel/category_view_model.dart';
import 'package:posfrontend/modules/inventory/view/inventory_sidebar.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';

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

  String get _userName =>
      widget.user != null && widget.user!.fullName.trim().isNotEmpty
          ? widget.user!.fullName
          : 'John Doe';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

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
    _viewModel = CategoryViewModel(repository: CategoryRepositoryImpl());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(_userName);
    final sidebar = InventorySidebar(
      user: widget.user,
      activeItem: 'Inventory',
      onNavigate: (_) {},
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _buildContent(initials, isWide: isWide);

        if (isWide) {
          return Scaffold(
            backgroundColor: bg,
            body: Row(
              children: [
                sidebar,
                Expanded(child: body),
              ],
            ),
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

  Widget _buildContent(String initials, {required bool isWide}) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final items = _viewModel.filtered;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(initials, isWide: isWide),
                const SizedBox(height: 20),
                _breadcrumb(),
                const SizedBox(height: 16),
                _headingRow(),
                const SizedBox(height: 20),
                _filterToolbar(),
                const SizedBox(height: 20),
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
          );
        },
      ),
    );
  }

  Widget _topBar(String initials, {required bool isWide}) {
    return Row(
      children: [
        if (!isWide)
          IconButton(
            icon: const Icon(Icons.menu, color: title),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        Expanded(
          child: Text(
            _inventoryLabel,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: title,
            ),
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: title),
              onPressed: () {},
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 20,
          backgroundColor: purple,
          child: Text(
            initials,
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
          child: Text(_inventoryLabel, style: const TextStyle(fontSize: 13, color: purple)),
        ),
        const Text('  >  ', style: style),
        const Text('Categories', style: style),
      ],
    );
  }

  Widget _headingRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: title,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 16),
        _addCategoryButton(),
      ],
    );
  }

  Widget _addCategoryButton() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onTap: () async {
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
        },
        child: const Row(
          children: [
            Icon(Icons.add, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Category',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterToolbar() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 280,
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
        IconButton(
          icon: const Icon(Icons.filter_list, color: title),
          style: IconButton.styleFrom(
            side: const BorderSide(color: border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {},
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: title,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _packageBadge(c.packageCount),
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

  Widget _packageBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count Packages',
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
            'Showing 1 to $shown of ${_viewModel.totalCount} categories',
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
