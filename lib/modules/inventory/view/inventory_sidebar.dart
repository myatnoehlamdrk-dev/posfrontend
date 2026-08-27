import 'package:flutter/material.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/login/view/login_screen.dart';

class InventorySidebar extends StatelessWidget {
  final LoginResponse? user;
  final String activeItem;
  final void Function(String)? onNavigate;

  const InventorySidebar({
    super.key,
    this.user,
    this.activeItem = 'Inventory',
    this.onNavigate,
  });

  static const Color bg = Color(0xFFFAFAFC);
  static const Color border = Color(0xFFE5E7EB);
  static const Color purple = Color(0xFF6D28D9);
  static const Color title = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);

  String get _name =>
      user != null && user!.fullName.trim().isNotEmpty ? user!.fullName : 'John Doe';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static const List<_NavItem> _items = [
    _NavItem('Dashboard', Icons.dashboard_outlined),
    _NavItem('Inventory', Icons.inventory_2_outlined),
    _NavItem('Product', Icons.category_outlined),
    _NavItem('Sale', Icons.point_of_sale_outlined),
    _NavItem('Purchase', Icons.shopping_bag_outlined),
    _NavItem('Customer', Icons.people_outlined),
    _NavItem('Report', Icons.bar_chart_outlined),
    _NavItem('Setting', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final initials = _initials(_name);

    return Container(
      width: 240,
      color: bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: purple,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: title,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'Store Owner',
                            style: TextStyle(fontSize: 14, color: gray),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Pro',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: purple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: _items
                    .map((item) => _navTile(context, item))
                    .toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: border),
          _logoutTile(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _navTile(BuildContext context, _NavItem item) {
    final active = item.label == activeItem;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: active
          ? BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: ListTile(
        leading: Icon(
          item.icon,
          color: active ? purple : gray,
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: active ? purple : title,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => _onItemTap(context, item.label),
      ),
    );
  }

  Widget _logoutTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 22),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () async {
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold != null && scaffold.isDrawerOpen) {
            Navigator.of(context).pop();
          }
          await TokenStorage.clearToken();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  void _onItemTap(BuildContext context, String label) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
    switch (label) {
      case 'Dashboard':
        Navigator.of(context).pushNamed('/dashboard', arguments: user);
        break;
      case 'Inventory':
        Navigator.of(context).pushNamed('/inventory', arguments: user);
        break;
      case 'Product':
        Navigator.of(context).pushNamed('/products', arguments: user);
        break;
      default:
        onNavigate?.call(label);
    }
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
