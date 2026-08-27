import 'package:flutter/material.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/modules/inventory/view/inventory_screen.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/login/view/login_screen.dart';

class DashboardDrawer extends StatelessWidget {
  final LoginResponse? user;

  const DashboardDrawer({super.key, this.user});

  static const Color purpleAction = Color(0xFF6D28D9);
  static const Color titleColor = Color(0xFF0F172A);
  static const Color grayText = Color(0xFF6B7280);

  String get _userName =>
      user != null && user!.fullName.trim().isNotEmpty ? user!.fullName : 'John Doe';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
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
              height: 180,
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'johndoe@gmail.com',
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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Column(
                  children: [
                    _drawerItem(context, 'Dashboard', Icons.dashboard, true),
                    _drawerItem(
                      context,
                      'Inventory',
                      Icons.inventory_2,
                      false,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InventoryScreen(user: user),
                          ),
                        );
                      },
                    ),
                    _drawerItem(context, 'Product', Icons.category, false),
                    _drawerItem(context, 'Sale', Icons.point_of_sale, false),
                    _drawerItem(context, 'Purchase', Icons.shopping_bag, false),
                    _drawerItem(context, 'Setting', Icons.settings, false),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _drawerItem(context, 'Logout', Icons.logout, false, isLogout: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    String label,
    IconData icon,
    bool active, {
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    final color = isLogout ? const Color(0xFFEF4444) : (active ? Colors.white : titleColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: active
          ? BoxDecoration(
              color: purpleAction,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap ??
            () async {
              if (isLogout) {
                await TokenStorage.clearToken();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } else {
                Navigator.of(context).pop();
              }
            },
      ),
    );
  }
}
