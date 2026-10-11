import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';

/// The point where the drawer stops floating over the page and docks beside it.
///
/// Shared with Inventory and Products, which already lay themselves out this
/// way, so the whole app flips between the two arrangements on the same line.
const double kWideBreakpoint = 768;

/// The width the drawer holds when it is docked beside the content.
const double kDrawerWidth = 240;

/// The page scaffold shared by every drawer-backed screen.
///
/// One screen describes the two arrangements instead of each screen carrying
/// its own `LayoutBuilder`:
///
/// * **Below [kWideBreakpoint]** the drawer floats over the page, opened by the
///   menu button, exactly as it did before.
/// * **At or above it** the drawer is docked at [kDrawerWidth] on the leading
///   edge and the menu button disappears, because there is nothing to open —
///   the navigation is already on screen.
///
/// The title bar and the body are therefore built from the same inputs in both
/// modes, so the only thing that changes between a phone and a desktop window
/// is where the drawer lives.
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.active,
    required this.body,
    this.scaffoldKey,
    this.backgroundColor,
    this.topBarBackgroundColor,
    this.floatingActionButton,
  });

  /// Shown in the title bar.
  final String title;

  /// Which drawer entry reads as current.
  final DrawerDestination active;

  /// Everything below the title bar.
  final Widget body;

  /// Owns the floating drawer so a caller can still open it programmatically.
  final GlobalKey<ScaffoldState>? scaffoldKey;

  /// Page fill. Defaults to the active palette's scaffold colour.
  final Color? backgroundColor;

  /// Title bar fill. Leave null for the usual opaque bar; a page that paints
  /// its own background behind the bar wants [Colors.transparent].
  final Color? topBarBackgroundColor;

  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kWideBreakpoint;
        final drawer = AppDrawer(active: active);

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: backgroundColor ?? context.palette.scaffoldBg,
          // A docked drawer is a child of the body below, not a drawer the
          // Scaffold manages, so the two must never be wired up at once.
          drawer: isWide ? null : drawer,
          floatingActionButton: floatingActionButton,
          body: SafeArea(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: kDrawerWidth, child: drawer),
                      Expanded(child: _content(context, showMenuButton: false)),
                    ],
                  )
                : _content(context, showMenuButton: true),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, {required bool showMenuButton}) {
    return Column(
      children: [
        AppScreenTopBar(
          title: title,
          showMenuButton: showMenuButton,
          backgroundColor: topBarBackgroundColor,
        ),
        Expanded(child: body),
      ],
    );
  }
}

/// Docks the navigation drawer beside a screen that has no drawer of its own.
///
/// Drill-down screens — a product detail, a purchase detail, a form — are
/// reached with a back button and used to leave the user with no way to jump
/// somewhere else on a wide window. On desktop this puts the drawer beside the
/// page.
///
/// A narrow window is handed [child] untouched rather than rebuilt, so a
/// phone keeps its back button, its floating drawer behaviour and its exact
/// layout. Nothing about the mobile arrangement is affected.
class WideDrawerDock extends StatelessWidget {
  const WideDrawerDock({super.key, required this.active, required this.child});

  /// The drawer entry to read as current. Pass the screen's parent area, e.g.
  /// [DrawerDestination.product] for a product detail.
  final DrawerDestination active;

  /// The screen's own body, unchanged on narrow windows.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kWideBreakpoint) return child;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: kDrawerWidth,
              child: AppDrawer(active: active),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
