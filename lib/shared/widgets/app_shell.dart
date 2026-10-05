import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';

/// The app's navigation shell.
///
/// One place decides how navigation is presented, because that decision used to
/// live in each screen's `build` and the copies disagreed. Two screens built a
/// permanent sidebar from 768px up; the other six passed `drawer:` always. On
/// desktop, moving between the two kinds made the sidebar vanish and reappear —
/// navigating from Product to Dashboard on a wide window lost the sidebar
/// entirely, because the destination only ever had a hamburger.
///
/// So the rule lives here:
///
/// * **768px and up** — a fixed [sidebarWidth] sidebar, always visible, and no
///   hamburger. Desktop and landscape-tablet users navigate without opening
///   anything.
/// * **Below 768px** — the sidebar is the [Scaffold]'s overlay `drawer`, opened
///   by the hamburger, exactly as a phone should.
///
/// [body] is a builder rather than a `Widget` because the screen's top bar has
/// to hide its hamburger on a wide window, and the only way to know that is from
/// the width the shell just measured. Screens already need this seam —
/// `InventoryScreen._buildContent` and the catalog's `_content` both already
/// take an `isWide` flag — so this is the shape the codebase had already chosen.
class AppShell extends StatelessWidget {
  /// The destination to highlight in the sidebar, and the drawer this shell owns.
  final DrawerDestination active;

  /// The screen's own content. Receives the measured width class so it can, for
  /// example, hide its hamburger.
  final Widget Function(BuildContext context, bool isWide) body;

  /// The key the screen's top bar opens the drawer with, if it opens it by key
  /// rather than through `Scaffold.of`.
  ///
  /// Must be the same key the screen's `AppScreenTopBar.onMenuTap` closes over,
  /// or the hamburger will do nothing.
  final GlobalKey<ScaffoldState>? scaffoldKey;

  /// Passed straight through. Some screens own a FAB (catalog's search and
  /// back-to-top, purchase's add button).
  final Widget? floatingActionButton;

  /// The page fill. `null` means "whatever the theme's scaffold background is",
  /// which is the right default; the inventory screen passes `Colors.transparent`
  /// because it paints a gradient behind the `Scaffold` instead.
  final Color? backgroundColor;

  /// Where the width measurement happens, and where the [Scaffold] is finally
  /// placed. Almost always `(_, shell) => shell`.
  ///
  /// The seam exists for the two screens that need something around the
  /// `Scaffold`: the inventory screen paints a page gradient behind it, and the
  /// catalog and inventory screens both put a `PopScope` outside it. Keeping the
  /// measurement inside the shell means they no longer each have to know the
  /// breakpoint.
  final Widget Function(BuildContext context, Widget shell) wrap;

  /// The width at which the sidebar becomes permanent.
  ///
  /// The value the two screens already used, kept so neither of them changes
  /// behaviour as a side effect of this refactor.
  static const double wideBreakpoint = 768;

  /// The permanent sidebar's width.
  static const double sidebarWidth = 240;

  const AppShell({
    super.key,
    required this.active,
    required this.body,
    required this.wrap,
    this.scaffoldKey,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= wideBreakpoint;

        final shell = Scaffold(
          key: scaffoldKey,
          backgroundColor: backgroundColor,
          // Only the narrow layout gets an overlay drawer. On a wide window the
          // sidebar is in the body instead, and giving the Scaffold a drawer as
          // well would leave a hidden one that the hamburger could still open.
          drawer: isWide ? null : AppDrawer(active: active),
          floatingActionButton: floatingActionButton,
          body: Row(
            children: [
              if (isWide) ...[
                // The sidebar respects the safe area so a notch or a status bar
                // in landscape does not overlap it. The content keeps its own
                // `SafeArea`, as every screen already has one, so nothing is
                // padded twice.
                SafeArea(
                  child: SizedBox(
                    width: sidebarWidth,
                    child: AppDrawer(active: active),
                  ),
                ),
              ],
              Expanded(child: body(context, isWide)),
            ],
          ),
        );

        return wrap(context, shell);
      },
    );
  }
}