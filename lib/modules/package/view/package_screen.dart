import 'package:flutter/material.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/inventory/view/inventory_sidebar.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/package/repository/package_repository_impl.dart';
import 'package:posfrontend/modules/package/view/add_package_screen.dart';
import 'package:posfrontend/modules/package/view/package_details_screen.dart';
import 'package:posfrontend/modules/package/viewmodel/package_view_model.dart';

class PackageScreen extends StatefulWidget {
  final LoginResponse? user;
  final Category category;

  const PackageScreen({super.key, this.user, required this.category});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PackageViewModel _viewModel;

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

  String get _badgeCode {
    final cleaned = widget.category.id.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    final len = cleaned.length >= 4 ? 4 : cleaned.length;
    return 'CAT-${cleaned.toUpperCase().substring(0, len)}';
  }

  @override
  void initState() {
    super.initState();
    _viewModel = PackageViewModel(
      repository: PackageRepositoryImpl(),
      categoryId: widget.category.id,
    );
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
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddPackageScreen(user: widget.user),
              ),
            ),
            backgroundColor: const Color(0xFF4FD1D9),
            child: const Icon(Icons.inventory_2, color: Colors.white),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
                Text(
                  'List of Packages (${_viewModel.total})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: title,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (c, constraints) {
                    final cols = constraints.maxWidth >= 560 ? 2 : 1;
                    return _packageGrid(items, cols);
                  },
                ),
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
        IconButton(
          icon: const Icon(Icons.arrow_back, color: title),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Text(
            'Self Inventory',
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
          onTap: () {},
          child: const Text('Inventory', style: TextStyle(fontSize: 13, color: purple)),
        ),
        const Text('  >  ', style: style),
        GestureDetector(
          onTap: () {},
          child: const Text('Self Inventory', style: TextStyle(fontSize: 13, color: purple)),
        ),
        const Text('  >  ', style: style),
        Text(widget.category.name, style: style),
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
            children: [
              Text(
                widget.category.name,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: title,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage your inventory categories and their packages.',
                style: TextStyle(fontSize: 16, color: gray),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _addButton(),
      ],
    );
  }

  Widget _addButton() {
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddPackageScreen(user: widget.user),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.add, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Package',
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
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: _viewModel.setSearch,
            decoration: InputDecoration(
              hintText: 'Search packages in this category...',
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
          child: IconButton(
            icon: const Icon(Icons.filter_list, color: title),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _packageGrid(List<Package> items, int cols) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No packages found.', style: TextStyle(color: gray)),
        ),
      );
    }
    if (cols == 1) {
      return Column(
        children: items
            .map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _packageCard(p),
                ))
            .toList(),
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final a = _packageCard(items[i]);
      final b = i + 1 < items.length
          ? _packageCard(items[i + 1])
          : const SizedBox.shrink();
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 16),
            Expanded(child: b),
          ],
        ),
      );
      rows.add(const SizedBox(height: 16));
    }
    return Column(children: rows);
  }

  Widget _packageCard(Package p) {
    final c = widget.category;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PackageDetailsScreen(
            user: widget.user,
            package: p,
            category: c,
          ),
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
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 90,
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
                        size: 38,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.code,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: title,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _catBadge(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: title,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.spec,
                    style: const TextStyle(fontSize: 13, color: gray),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Qty: ${p.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: title,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: gray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.location,
                          style: const TextStyle(fontSize: 13, color: gray),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _statusBadge(p.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _badgeCode,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: purple,
        ),
      ),
    );
  }

  Widget _statusBadge(StockStatus s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: stockBg(s),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        stockLabel(s),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: stockFg(s),
        ),
      ),
    );
  }

}
