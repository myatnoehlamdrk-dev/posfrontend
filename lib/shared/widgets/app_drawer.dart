import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/auth/presentation/screens/login_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/products_catalog_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/add_product_options_screen.dart';
import 'package:posfrontend/features/sale/presentation/screens/sale_items_screen.dart';
import 'package:posfrontend/features/sale/presentation/screens/quick_sale_screen.dart';
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
///
/// These eight destinations used to carry an `iconColor` each — purple, teal,
/// green, orange, blue, pink, indigo, slate. Four were duplicates of names
/// already in `AppColors` and four existed nowhere else, and because they were
/// `const` inside an enum none of them could vary by brightness, so every one
/// was wrong in dark mode.
///
/// The hues also carried no meaning: there is no system in which "cart" is
/// orange and "inventory" is blue. Colour that encodes nothing still costs
/// attention, and it fights the brand purple on every drawer open. Position and
/// the icon shape already identify the destination; the accent now marks the one
/// thing that genuinely differs, which is where you are.
enum DrawerDestination {
  dashboard(label: 'Dashboard', icon: Icons.dashboard_outlined),

  /// Sell from the shelf: a category-filtered product grid with the cart
  /// beside it, where a tap is a line and the sale is made in place. The
  /// history of those sales is [saleItem]; this is where they are created.
  quickSale(label: 'Quick Sale', icon: Icons.point_of_sale_outlined),
  product(label: 'Product', icon: Icons.category_outlined),
  addProduct(label: 'Add Product', icon: Icons.add_circle_outline),
  addToCart(label: 'Add to Cart', icon: Icons.shopping_cart_outlined),
  inventory(label: 'Inventory', icon: Icons.inventory_2_outlined),
  saleItem(label: 'Sale Item', icon: Icons.receipt_long_outlined),
  purchaseItem(label: 'Purchase Item', icon: Icons.local_shipping_outlined),
  setting(label: 'Setting', icon: Icons.settings_outlined);

  const DrawerDestination({required this.label, required this.icon});

  /// English source text. Looked up in the translation store; never compared
  /// for equality.
  final String label;

  final IconData icon;

  /// The route name this destination's screen is pushed under, so a live copy
  /// can be found again later. The enum's own name — stable, unique, and not
  /// the (translated) label the old switch used to compare on.
  String get routeName => name;

  String localized(AppStrings strings) => strings.t(label);

  Widget get screen => switch (this) {
    DrawerDestination.dashboard => const DashboardScreen(),
    DrawerDestination.inventory => const InventoryScreen(),
    DrawerDestination.product => const ProductsCatalogScreen(),
    DrawerDestination.addProduct => const AddProductOptionsScreen(),
    DrawerDestination.saleItem => const SaleItemScreen(),
    DrawerDestination.quickSale => const QuickSaleScreen(),
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
                            ? CachedNetworkImageProvider(imageUrl, maxWidth: 280)
                            : null,
                        // No `onBackgroundImageError` handler on purpose -- see
                        // the note in app_screen_top_bar. Erasing the shared URL
                        // here blanked the avatar app-wide after one failed
                        // load, and nothing else refetches it.
                        child: imageUrl.isEmpty
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppTypography.titleSmallSize,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.s16),
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
                            fontSize: AppTypography.titleSmallSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: AppTypography.labelMediumSize,
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
            const SizedBox(height: AppSpacing.s16),
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
    // Idle icons are one neutral for all nine destinations; the brand accent is
    // spent on the active row only. See [DrawerDestination] for why the eight
    // per-item hues that preceded [DrawerDestination.quickSale] went.
    final idleIcon = p.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s4),
      decoration: active
          ? BoxDecoration(
              color: p.selectionTint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            )
          : null,
      child: Material(
        // The tint belongs to the Container, so the tile needs its own
        // (transparent) Material to paint pressed feedback on — otherwise the
        // tint hides the ink and Flutter flags the tile in debug builds.
        type: MaterialType.transparency,
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? p.primary : p.chipBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              destination.icon,
              color: active ? Colors.white : idleIcon,
              size: AppIconSize.md,
            ),
          ),
          title: Text(
            destination.localized(context.l10n),
            style: TextStyle(
              // `accentText`, not `primary`: this is text on the page, not a
              // fill, and on a dark surface the fill value only reaches
              // 2.54:1.
              color: active ? p.accentText : p.textPrimary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              fontSize: AppTypography.bodyMediumSize,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          onTap: () => _onTap(context, destination),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, DrawerDestination destination) {
    // Close the drawer before navigating, but only when there is one. On a wide
    // window the sidebar is permanent — there is no `DrawerController` and
    // `isDrawerOpen` is false — so this must be a no-op there; popping the
    // navigator instead would have taken the user off the page they tapped.
    //
    // `closeDrawer()` rather than `Navigator.pop()`: it is the API that actually
    // owns this, it runs the open/close animation, and it cannot pop a page route
    // if this ever runs while the drawer is not the top route.
    // Close the drawer before navigating, and only when there is one. On a wide
    // window the sidebar is permanent — no `DrawerController`, so `isDrawerOpen`
    // is false — and this must be a no-op there.
    //
    // `closeDrawer()` rather than `Navigator.pop()`: it is the API that owns this,
    // it runs the open/close animation, and it cannot pop a page route even if
    // this ever runs while the drawer is not the top route. The old
    // `Navigator.pop()` was already guarded by `isDrawerOpen`, so it was not the
    // source of the sidebar disappearing — it is just the wrong tool.
    final scaffold = Scaffold.maybeOf(context);
    final drawerOpen = scaffold?.isDrawerOpen ?? false;
    if (drawerOpen) scaffold!.closeDrawer();

    if (destination == active) return;

    navigateToDestination(context, destination);
  }
}

/// Mirrors the root navigator's live route stack, bottom to top, so
/// navigation can ask "is there already a screen for this drawer item, and is
/// anything standing in front of it?" before pushing another one.
///
/// Flutter exposes no public way to read a navigator's history, and guessing
/// with [Navigator.popUntil] is dangerous: with a predicate that never
/// matches it keeps popping until the stack is empty. So the answer is
/// tracked from the observer callbacks instead — every push, pop, remove and
/// replace goes through them, which makes this mirror exact rather than a
/// heuristic. Routes are held by identity, so an unnamed drill-down and a
/// destination that happens to share a screen class cannot be confused.
class DestinationRouteTracker extends NavigatorObserver {
  DestinationRouteTracker();

  /// App-wide instance. Registered once on the root [MaterialApp] navigator —
  /// the only navigator drawer navigation ever addresses.
  static final DestinationRouteTracker instance = DestinationRouteTracker();

  /// The list to hand to `MaterialApp.navigatorObservers`.
  ///
  /// Stable identity on purpose: a fresh list on every rebuild makes the
  /// navigator tear down and re-attach its observers each time the theme or
  /// locale changes, for no reason at all.
  static final List<NavigatorObserver> observers = <NavigatorObserver>[
    instance,
  ];

  /// Live routes, bottom of the stack first.
  final List<Route<dynamic>> routes = <Route<dynamic>>[];

  /// Index of the *topmost* live route named [name], or -1.
  ///
  /// Topmost on purpose: popping stops at the first match coming down from
  /// the top, so this is the copy that will actually be reached — checking
  /// the deepest one instead would report "blocked" by the very duplicate a
  /// previous blocked attempt pushed.
  int lastIndexOf(String name) =>
      routes.lastIndexWhere((route) => route.settings.name == name);

  bool _hasNonDestinationAbove(int index) => routes
      .skip(index + 1)
      .any((route) => !isDestinationRouteName(route.settings.name));

  /// Whether [name] is one of the drawer's own destinations. Anything else is
  /// a drill-down — a product detail, a sale being written — and is never
  /// popped to reach a destination.
  static bool isDestinationRouteName(String? name) =>
      name != null && DrawerDestination.values.any((d) => d.routeName == name);

  void _remove(Route<dynamic> route) => routes.remove(route);

  @override
  void didPush(Route route, Route? previousRoute) => routes.add(route);

  @override
  void didPop(Route route, Route? previousRoute) => _remove(route);

  @override
  void didRemove(Route route, Route? previousRoute) => _remove(route);

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    final old = oldRoute;
    final index = old == null ? -1 : routes.indexOf(old);
    if (index < 0) {
      if (newRoute != null) routes.add(newRoute);
      return;
    }
    final fresh = newRoute;
    if (fresh == null) {
      routes.removeAt(index);
    } else {
      routes[index] = fresh;
    }
  }
}

/// Goes to [destination] without rebuilding what is already on screen.
///
/// This is the fix for the drawer's reload-on-every-tap: the old code pushed
/// a fresh route each time, so returning to Quick Sale ran `initState` →
/// `load()` → skeleton again — even though a live copy of the very same screen
/// was sitting a few routes below, fully loaded, cart and scroll position
/// intact. Now a destination already in the stack is *popped back to* (its
/// State was never disposed, so the frame is instant and nothing is
/// fetched), and only a first-ever visit builds anything.
///
/// Two rules keep that from costing anything else:
///
///  * **drill-downs are never popped.** Routes above the target that are not
///    drawer destinations — a product detail, above all a sale still being
///    written — are somebody's in-progress work, so the pop stops there and a
///    fresh instance is pushed instead. Reopening a screen beats losing what
///    was on it.
///  * **nothing is popped when the destination is absent.** The old
///    `pushReplacement` for non-tab destinations destroyed the screen below —
///    which is exactly why Quick Sale reloaded after a trip to Inventory.
///
/// [force] skips the drill-down guard: it is what "back to the dashboard"
/// means, *leave whatever is on screen*.
///
/// [replace] is for the two hand-offs that must not keep the screen they came
/// from in history — splash and login.
void navigateToDestination(
  BuildContext context,
  DrawerDestination destination, {
  bool replace = false,
  bool force = false,
}) {
  final navigator = Navigator.of(context);
  final name = destination.routeName;
  final tracker = DestinationRouteTracker.instance;

  final index = tracker.lastIndexOf(name);
  final reachable =
      index >= 0 && (force || !tracker._hasNonDestinationAbove(index));
  if (reachable) {
    // Known to be present and unobstructed, so the predicate matches before
    // it can reach the root and the pop cannot empty the stack.
    navigator.popUntil((route) => route.settings.name == name || route.isFirst);
    return;
  }

  final route = MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => destination.screen,
  );
  if (replace) {
    navigator.pushReplacement(route);
  } else {
    navigator.push(route);
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
      final dio = ApiClient.instance;
      await dio.post('/auth/logout');
    } catch (_) {
      // Logout API failure is non-critical; proceed with local cleanup
    }
    await TokenStorage.clearToken();
    await SessionStore.clear();
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
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s4,
      ),
      child: Material(
        // As in [_navItem]: the tile needs a Material of its own to paint its
        // ink on, above the drawer's filled background.
        type: MaterialType.transparency,
        child: ListTile(
          leading: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: red,
                    strokeWidth: 2.5,
                  ),
                )
              : const Icon(Icons.logout, color: red, size: 22),
          title: Text(
            context.l10n.t('Logout'),
            style: TextStyle(
              color: red,
              fontWeight: FontWeight.w600,
              fontSize: AppTypography.bodyMediumSize,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          onTap: _isLoading
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
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
      ),
    );
  }
}
