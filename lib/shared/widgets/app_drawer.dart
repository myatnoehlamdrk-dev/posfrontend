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

import 'package:posfrontend/shared/l10n/app_strings.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

/// Stable identity for a drawer destination.
///
/// This used to be the display label itself, so `_onTap` did a `switch` over
/// strings like 'Sale Item' and every screen passed `activeItem: 'Dashboard'`.
/// That made the English copy load-bearing: translating the labels would have
/// silently broken navigation and the active-item highlight. Identity now lives
/// here, and [label] is only the English source text used to look up a
/// translation.
enum DrawerDestination {
  dashboard(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    iconColor: Color(0xFF6D28D9),
  ),
  product(
    label: 'Product',
    icon: Icons.category_outlined,
    iconColor: Color(0xFF0D9488),
  ),
  addProduct(
    label: 'Add Product',
    icon: Icons.add_circle_outline,
    iconColor: Color(0xFF16A34A),
    isTabRoot: true,
  ),
  addToCart(
    label: 'Add to Cart',
    icon: Icons.shopping_cart_outlined,
    iconColor: Color(0xFFF97316),
    isTabRoot: true,
  ),
  inventory(
    label: 'Inventory',
    icon: Icons.inventory_2_outlined,
    iconColor: Color(0xFF2563EB),
  ),
  saleItem(
    label: 'Sale Item',
    icon: Icons.receipt_long_outlined,
    iconColor: Color(0xFFDB2777),
    isTabRoot: true,
  ),
  purchaseItem(
    label: 'Purchase Item',
    icon: Icons.local_shipping_outlined,
    iconColor: Color(0xFF4F46E5),
    isTabRoot: true,
  ),
  setting(
    label: 'Setting',
    icon: Icons.settings_outlined,
    iconColor: Color(0xFF64748B),
    isTabRoot: true,
  );

  const DrawerDestination({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.isTabRoot = false,
  });

  /// English source text. Looked up in the translation store; never compared
  /// for equality.
  final String label;

  final IconData icon;
  final Color iconColor;

  /// True when the destination is pushed rather than swapped in. The three
  /// root tabs replace the stack so Back does not walk a growing history;
  /// anything else is a drill-down and pushes.
  final bool isTabRoot;

  String localized(AppStrings strings) => strings.t(label);

  Widget get screen => switch (this) {
    DrawerDestination.dashboard => const DashboardScreen(),
    DrawerDestination.inventory => const InventoryScreen(),
    DrawerDestination.product => const ProductsCatalogScreen(),
    DrawerDestination.addProduct => const AddProductOptionsScreen(),
    DrawerDestination.saleItem => const SaleItemScreen(),
    DrawerDestination.purchaseItem => const PurchaseItemsScreen(),
    DrawerDestination.addToCart => const AddToCartScreen(),
    DrawerDestination.setting => const SettingsScreen(),
  };
}

class AppDrawer extends StatelessWidget {
  final DrawerDestination active;

  const AppDrawer({super.key, this.active = DrawerDestination.dashboard});

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.userOf(context);
    final userName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName
        : 'John Doe';
    final email = user?.email ?? '';
    final initials = _initials(userName);
    final p = context.palette;

    return Drawer(
      child: Container(
        color: p.surface,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 16,
                20,
                20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.brandRamp,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
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
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                        onBackgroundImageError: imageUrl.isNotEmpty
                            ? (error, stackTrace) {
                                ProfileImageNotifier.instance.update('');
                              }
                            : null,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Column(
                  children: [
                    for (final destination in DrawerDestination.values)
                      _navItem(context, destination),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: p.border),
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

  Widget _navItem(BuildContext context, DrawerDestination destination) {
    final p = context.palette;
    final active = destination == this.active;
    final iconColor = destination.iconColor;
    // The per-item accents are tuned for a white drawer. In dark the icon is
    // lifted toward white so the hue stays recognisable but readable.
    final idleIcon = context.isDark
        ? Color.lerp(iconColor, Colors.white, 0.4)!
        : iconColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: active
          ? BoxDecoration(
              color: p.selectionTint,
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
            destination.icon,
            color: active ? Colors.white : idleIcon,
            size: 20,
          ),
        ),
        title: Text(
          destination.localized(context.l10n),
          style: TextStyle(
            color: active ? p.primary : p.textPrimary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => _onTap(context, destination),
      ),
    );
  }

  void _onTap(BuildContext context, DrawerDestination destination) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
    if (destination == active) return;

    final screen = destination.screen;
    if (destination.isTabRoot) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }
}

class _LogoutTile extends StatefulWidget {
  const _LogoutTile();

  @override
  State<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<_LogoutTile> {
  bool _isLoading = false;

  static const Color red = Color(0xFFEF4444);

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      final dio = ApiClient.create();
      await dio.post('/auth/logout');
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
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: red, strokeWidth: 2.5),
              )
            : const Icon(Icons.logout, color: red, size: 22),
        title: Text(
          context.l10n.t('Logout'),
          style: TextStyle(
            color: red,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        context.l10n.t('Logout'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: p.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: p.textSecondary),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _handleLogout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                              : Text(context.l10n.t('Logout')),
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
