import 'package:flutter/material.dart';
import 'package:posfrontend/modules/dashboard/view/dashboard_screen.dart';
import 'package:posfrontend/modules/category/view/category_screen.dart';
import 'package:posfrontend/modules/inventory/model/inventory_models.dart';
import 'package:posfrontend/modules/inventory/repository/inventory_repository_impl.dart';
import 'package:posfrontend/modules/inventory/view/inventory_sidebar.dart';
import 'package:posfrontend/modules/inventory/viewmodel/inventory_view_model.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';

class InventoryScreen extends StatefulWidget {
  final LoginResponse? user;

  const InventoryScreen({super.key, this.user});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final InventoryViewModel _viewModel;

  static const Color bg = Color(0xFFFFFFFF);
  static const Color title = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);

  String get _userName =>
      widget.user != null && widget.user!.fullName.trim().isNotEmpty
          ? widget.user!.fullName
          : 'John Doe';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _viewModel = InventoryViewModel(repository: InventoryRepositoryImpl());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onNavigate(String label) {
    if (label == 'Dashboard') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DashboardScreen(user: widget.user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(_userName);
    final sidebar = InventorySidebar(
      user: widget.user,
      activeItem: 'Inventory',
      onNavigate: _onNavigate,
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        if (isWide) {
          return Scaffold(
            backgroundColor: bg,
            body: Row(
              children: [
                sidebar,
                Expanded(child: _buildContent(initials, isWide: true)),
              ],
            ),
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bg,
          drawer: Drawer(child: sidebar),
          body: _buildContent(initials, isWide: false),
        );
      },
    );
  }

  Widget _buildContent(String initials, {required bool isWide}) {
    final options = _viewModel.options;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(initials, isWide: isWide),
            const SizedBox(height: 24),
            _breadcrumb(),
            const SizedBox(height: 16),
            const Text(
              'Inventory',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: title,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose an inventory to manage your items.',
              style: TextStyle(fontSize: 16, color: gray),
            ),
            const SizedBox(height: 32),
            _buildOptionCards(options, isWide: isWide),
            const SizedBox(height: 32),
            _infoCard(),
          ],
        ),
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
          child: const Text(
            'Inventory',
            style: TextStyle(
              fontSize: 34,
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
    return Row(
      children: [
        GestureDetector(
          onTap: () => _onNavigate('Dashboard'),
          child: const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: purple,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('>', style: TextStyle(fontSize: 14, color: gray)),
        const SizedBox(width: 8),
        const Text(
          'Inventory',
          style: TextStyle(fontSize: 14, color: gray),
        ),
      ],
    );
  }

  Widget _buildOptionCards(List<InventoryOption> options, {required bool isWide}) {
    final cards = options
        .map((o) => _optionCard(o))
        .toList();
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 24),
          Expanded(child: cards[1]),
        ],
      );
    }
    return Column(
      children: [
        cards[0],
        const SizedBox(height: 24),
        cards[1],
      ],
    );
  }

  Widget _optionCard(InventoryOption option) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 430, maxHeight: 480),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder,
                color: Color(0xFF6D28D9),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              option.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: title,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              option.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: gray),
            ),
            const Spacer(),
            _gradientButton(
              'Open',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryScreen(
                    user: widget.user,
                    inventoryType: option.key,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF6D28D9)),
              SizedBox(width: 8),
              Text(
                "What's the difference?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bullet('Self Inventory: Only you can view and manage.'),
          const SizedBox(height: 6),
          _bullet('Public Inventory: Shared and visible to other users.'),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  ', style: TextStyle(fontSize: 14, color: gray)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: gray),
          ),
        ),
      ],
    );
  }
}
