import 'package:flutter/material.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/modules/dashboard/view/dashboard_screen.dart';
import 'package:posfrontend/modules/inventory/view/inventory_screen.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/login/view/login_screen.dart';
import 'package:posfrontend/modules/product/view/products_catalog_screen.dart';
import 'package:posfrontend/modules/purchase_items/view/purchase_items_screen.dart';
import 'package:posfrontend/modules/sale/view/new_sale_screen.dart';
import 'package:posfrontend/modules/sale_items/view/sale_items_screen.dart';
import 'package:posfrontend/modules/settings/view/settings_screen.dart';

import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

class AppDrawer extends StatelessWidget {
  final LoginResponse? user;
  final String activeItem;

  const AppDrawer({
    super.key,
    this.user,
    this.activeItem = 'Dashboard',
  });

  static const Color purple = Color(0xFF6D28D9);
  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  String get _userName =>
      user != null && user!.fullName.trim().isNotEmpty ? user!.fullName : 'John Doe';

  String get _email => user?.email ?? '';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(_userName);
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: ProfileImageNotifier.instance,
                    builder: (context, imageUrl, _) {
                      return CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  children: [
                    _navItem(context, 'Dashboard', Icons.dashboard_outlined),
                    _navItem(context, 'Inventory', Icons.inventory_2_outlined),
                    _navItem(context, 'Product', Icons.category_outlined),
                    _navItem(context, 'Sale', Icons.point_of_sale_outlined),
                    _navItem(context, 'Sale Item', Icons.receipt_long_outlined),
                    
                    _navItem(context, 'Purchase Item', Icons.local_shipping_outlined),
                    _navItem(context, 'Setting', Icons.settings_outlined)
                    ],
                ),
              ),
            ),
            const Divider(height: 1, color: border),
            _logoutItem(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, String label, IconData icon) {
    final active = label == activeItem;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: active
          ? BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: active ? purple : gray,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: active ? purple : titleColor,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => _onTap(context, label),
      ),
    );
  }

  Widget _logoutItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 22),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _onTap(BuildContext context, String label) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
    if (label == activeItem) return;

    Widget destination;
    switch (label) {
      case 'Dashboard':
        destination = DashboardScreen(user: user);
        break;
      case 'Inventory':
        destination = InventoryScreen(user: user);
        break;
      case 'Product':
        destination = ProductsCatalogScreen(user: user);
        break;
      case 'Sale':
        destination = NewSaleScreen(user: user);
        break;
      case 'Sale Item':
        destination = SaleItemScreen(user: user);
        break;
      case 'Purchase Item':
        destination = PurchaseItemsScreen(user: user);
        break;
      case 'Setting':
        destination = SettingsScreen(user: user);
        break;

      default:
        return;
    }
    if (label == 'Setting' || label == 'Sale' || label == 'Sale Item' || label == 'Purchase Item') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destination),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}
