import 'package:flutter/material.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/auth/presentation/screens/login_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/products_catalog_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/add_product_options_screen.dart';
import 'package:posfrontend/features/sale/presentation/screens/sale_items_screen.dart';
import 'package:posfrontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:posfrontend/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:posfrontend/features/purchase/presentation/screens/purchase_items_screen.dart';
import 'package:posfrontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:posfrontend/features/cart/presentation/screens/add_to_cart_screen.dart';

import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

class AppDrawer extends StatelessWidget {
  final String activeItem;

  const AppDrawer({
    super.key,
    this.activeItem = 'Dashboard',
  });

  static const Color purple = Color(0xFF6D28D9);
  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.userOf(context);
    final userName = user?.fullName.trim().isNotEmpty == true ? user!.fullName : 'John Doe';
    final email = user?.email ?? '';
    final initials = _initials(userName);

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
                        onBackgroundImageError: imageUrl.isNotEmpty ? (error, stackTrace) {
                          ProfileImageNotifier.instance.update('');
                        } : null,
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
                          userName,
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
                          email,
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
                    _navItem(context, 'Dashboard', Icons.dashboard_outlined, const Color(0xFF6D28D9)),
                    _navItem(context, 'Product', Icons.category_outlined, const Color(0xFF0D9488)),
                    _navItem(context, 'Add Product', Icons.add_circle_outline, const Color(0xFF16A34A)),
                    _navItem(context, 'Add to Cart', Icons.shopping_cart_outlined, const Color(0xFFF97316)),
                    _navItem(context, 'Inventory', Icons.inventory_2_outlined, const Color(0xFF2563EB)),
                    _navItem(context, 'Sale Item', Icons.receipt_long_outlined, const Color(0xFFDB2777)),
                    
                    _navItem(context, 'Purchase Item', Icons.local_shipping_outlined, const Color(0xFF4F46E5)),
                    _navItem(context, 'Setting', Icons.settings_outlined, const Color(0xFF64748B))
                    ],
                ),
              ),
            ),
            const Divider(height: 1, color: border),
            const _LogoutTile(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _navItem(
    BuildContext context,
    String label,
    IconData icon,
    Color iconColor,
  ) {
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
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active ? iconColor : iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : iconColor,
            size: 20,
          ),
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

  void _onTap(BuildContext context, String label) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
    if (label == activeItem) return;

    Widget destination;
    switch (label) {
      case 'Dashboard':
        destination = const DashboardScreen();
        break;
      case 'Inventory':
        destination = const InventoryScreen();
        break;
      case 'Product':
        destination = const ProductsCatalogScreen();
        break;
      case 'Add Product':
        destination = const AddProductOptionsScreen();
        break;
      case 'Sale Item':
        destination = const SaleItemScreen();
        break;
      case 'Purchase Item':
        destination = const PurchaseItemsScreen();
        break;
      case 'Add to Cart':
        destination = const AddToCartScreen();
        break;
      case 'Setting':
        destination = const SettingsScreen();
        break;

      default:
        return;
    }
    if (label == 'Setting' || label == 'Sale Item' || label == 'Purchase Item' || label == 'Add Product' || label == 'Add to Cart') {
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

class _LogoutTile extends StatefulWidget {
  const _LogoutTile();

  @override
  State<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<_LogoutTile> {
  bool _isLoading = false;

  static const Color gray = Color(0xFF6B7280);
  static const Color titleColor = Color(0xFF111827);

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      final dio = ApiClient.create();
      await dio.post('/api/auth/logout');
    } catch (_) {
      // Logout API failure is non-critical; proceed with local cleanup
    }
    await TokenStorage.clearToken();
    if (mounted) {
      AuthScope.updateUserOf(context, null);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Color(0xFFEF4444),
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.logout, color: Color(0xFFEF4444), size: 22),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: _isLoading
            ? null
            : () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
                      content: const Text('Are you sure you want to logout?', style: TextStyle(color: gray)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: gray)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _handleLogout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Logout'),
                        ),
                      ],
                    );
                  },
                );
              },
      ),
    );
  }
}
