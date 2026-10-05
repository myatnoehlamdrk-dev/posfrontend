import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/inventory/domain/entities/inventory.dart';
import 'package:posfrontend/features/inventory/presentation/viewmodels/inventory_view_model.dart';
import 'package:posfrontend/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:posfrontend/features/category/presentation/screens/category_screen.dart';
import 'package:posfrontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

/// Inventory selection: pick which inventory to work in.
///
/// The page is a single left-aligned column capped at [_contentMaxWidth]. A
/// centred wrapper would leave the breadcrumb floating in the middle of a wide
/// window, away from where the drawer puts the user's eye on entry, so the cap
/// pins the content to the leading edge and only stops it stretching.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final InventoryViewModel _viewModel;

  /// Reading measure, not screen measure: on a wide window the drawer takes
  /// 240px, so a threshold tested against the whole screen would put two cards
  /// side by side in a column that cannot hold them.
  static const double _contentMaxWidth = 672;
  static const double _twoColumnFrom = 560;
  static const double _gridGap = 16;

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

  @override
  Widget build(BuildContext context) {
    final colors = _InventoryColors.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          navigateToDashboard(context);
        }
      },
      // The gradient is painted behind the Scaffold rather than set as its
      // backgroundColor, so it runs under the top bar too. The bar's own fill
      // would otherwise cut a hard horizontal seam across the gradient.
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: colors.pageGradient),
        child: AppShell(
          active: DrawerDestination.inventory,
          scaffoldKey: _scaffoldKey,
          backgroundColor: Colors.transparent,
          wrap: (_, shell) => shell,
          body: (context, isWide) => _buildContent(isWide: isWide),
        ),
      ),
    );
  }

  Widget _buildContent({required bool isWide}) {
    final colors = _InventoryColors.of(context);
    return SafeArea(
      child: Column(
        children: [
          AppScreenTopBar(
            title: context.l10n.t('Inventory'),
            showMenuButton: !isWide,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            backgroundColor: Colors.transparent,
          ),
          Expanded(
            child: RefreshableBody(
              onRefresh: () async {},
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _contentMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _breadcrumb(colors),
                        const SizedBox(height: 8),
                        const SizedBox(height: 20),
                        _buildOptionCards(
                          _viewModel.options,
                          colors: colors,
                        ),
                        const SizedBox(height: 28),
                        _infoCard(colors),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breadcrumb(_InventoryColors colors) {
    return Row(
      children: [
        _BreadcrumbLink(
          label: context.l10n.t('Dashboard'),
          color: colors.link,
          hoverColor: colors.linkHover,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => DashboardScreen())),
        ),
        const SizedBox(width: 8),
        Text('›', style: TextStyle(fontSize: 14, color: colors.separator)),
        const SizedBox(width: 8),
        Text(
          context.l10n.t('Inventory'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.breadcrumbCurrent,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCards(
    List<InventoryOptionEntity> options, {
    required _InventoryColors colors,
  }) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cards = options
            .map(
              (o) => _InventoryOptionCard(
                option: o,
                colors: colors,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(inventoryType: o.key),
                  ),
                ),
              ),
            )
            .toList();

        if (constraints.maxWidth >= _twoColumnFrom) {
          // IntrinsicHeight so both cards share the taller card's height.
          // Without it the shorter one's Open button rides up while its
          // neighbour's sits at the bottom, and the row reads as broken.
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gridGap),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: _gridGap),
              cards[i],
            ],
          ],
        );
      },
    );
  }

  Widget _infoCard(_InventoryColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.infoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colors.infoIcon, size: 20),
              const SizedBox(width: 8),
              Text(
                context.l10n.t("What's the difference?"),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bullet(colors, context.l10n.t('Self Inventory: Only you can view and manage.')),
          const SizedBox(height: 6),
          _bullet(
            colors,
            context.l10n.t('Public Inventory: Shared and visible to other users.'),
          ),
        ],
      ),
    );
  }

  Widget _bullet(_InventoryColors colors, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: TextStyle(fontSize: 13, color: colors.muted)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: colors.muted,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// A breadcrumb entry that lightens on hover.
///
/// [Hoverable] rather than a bare `GestureDetector` so the affordance shows on
/// desktop; the tap target is unchanged on touch, where hover never fires.
class _BreadcrumbLink extends StatefulWidget {
  final String label;
  final Color color;
  final Color hoverColor;
  final VoidCallback onTap;

  const _BreadcrumbLink({
    required this.label,
    required this.color,
    required this.hoverColor,
    required this.onTap,
  });

  @override
  State<_BreadcrumbLink> createState() => _BreadcrumbLinkState();
}

class _BreadcrumbLinkState extends State<_BreadcrumbLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 140),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _hovered ? widget.hoverColor : widget.color,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

/// One inventory choice: badge, icon, copy and the Open button.
///
/// Hover and focus are tracked separately because they are different states.
/// Hover is transient and desktop-only; focus is what a keyboard or switch
/// device gets, and it has to persist, so it gets the stronger "selected"
/// treatment from the spec rather than the faint hover one.
class _InventoryOptionCard extends StatefulWidget {
  final InventoryOptionEntity option;
  final _InventoryColors colors;
  final VoidCallback onOpen;

  const _InventoryOptionCard({
    required this.option,
    required this.colors,
    required this.onOpen,
  });

  @override
  State<_InventoryOptionCard> createState() => _InventoryOptionCardState();
}

class _InventoryOptionCardState extends State<_InventoryOptionCard> {
  bool _hovered = false;
  bool _focused = false;

  static const double _radius = 16;
  static const double _iconSize = 80;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final active = _hovered || _focused;
    final accent = switch (widget.option.key) {
      'self' => _OptionLook.private,
      _ => _OptionLook.shared,
    };

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusableActionDetector(
        onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
        mouseCursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onOpen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: active ? c.cardGradientHover : c.cardGradient,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: _focused
                    ? c.borderActive
                    : active
                    ? c.borderHover
                    : c.border,
              ),
              boxShadow: active ? c.cardGlow : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: _Badge(label: accent.badge, colors: c),
                ),
                const SizedBox(height: 4),
                Center(child: _iconCircle(accent, active, c)),
                const SizedBox(height: 8),
                Text(
                  context.l10n.t(widget.option.title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: c.title,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  context.l10n.t(widget.option.description),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.muted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                _OpenButton(
                  label: context.l10n.t('Open'),
                  onPressed: widget.onOpen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconCircle(_OptionLook look, bool active, _InventoryColors c) {
    return Container(
      width: _iconSize,
      height: _iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: active ? c.iconGradientHover : c.iconGradient,
        ),
        boxShadow: active ? c.iconGlow : null,
      ),
      child: Icon(
        look.icon,
        size: 36,
        color: active ? c.iconHover : c.icon,
      ),
    );
  }
}

/// The violet pill in the card's top-right corner.
///
/// The badge text is uppercased at the widget rather than being stored that
/// way, so a Burmese or Thai translation is left alone: those scripts have no
/// case, and calling `toUpperCase` on them is a no-op that only makes the
/// intent clearer.
class _Badge extends StatelessWidget {
  final String label;
  final _InventoryColors colors;

  const _Badge({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.badgeBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.badgeBorder),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: colors.badgeText,
        ),
      ),
    );
  }
}

class _OpenButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _OpenButton({required this.label, required this.onPressed});

  @override
  State<_OpenButton> createState() => _OpenButtonState();
}

class _OpenButtonState extends State<_OpenButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [AppColors.violet400, AppColors.purple700]
                  : [AppColors.purple700, AppColors.purple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple700.withValues(
                  alpha: _hovered ? 0.55 : 0.35,
                ),
                blurRadius: _hovered ? 24 : 14,
                offset: Offset(0, _hovered ? 10 : 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Per-option presentation that the entity deliberately does not carry.
///
/// Icon data and badge copy are display concerns. [InventoryOptionEntity] keys
/// off `key` alone, so a new inventory type added by the backend renders with
/// the shared treatment instead of a blank card.
enum _OptionLook {
  private(Icons.lock_outline, 'Private'),
  shared(Icons.language_rounded, 'Shared');

  const _OptionLook(this.icon, this.badge);

  final IconData icon;
  final String badge;
}

/// The colours for this page, per brightness.
///
/// These are deliberately not [AppPalette] tokens. The palette is the app's
/// neutral ramp, and this page is specified as a violet-tinted gradient rather
/// than a step off the scaffold: overriding `scaffoldBg` here would change what
/// every other widget on the page draws against. So the values live here, and
/// the light set is a straight inversion of the dark one rather than a
/// reinterpretation.
class _InventoryColors {
  final Gradient pageGradient;
  final Color link;
  final Color linkHover;
  final Color separator;
  final Color breadcrumbCurrent;
  final Color subtitle;

  final Gradient cardGradient;
  final Gradient cardGradientHover;
  final Color border;
  final Color borderHover;
  final Color borderActive;
  final List<BoxShadow> cardGlow;

  final List<Color> iconGradient;
  final List<Color> iconGradientHover;
  final List<BoxShadow> iconGlow;
  final Color icon;
  final Color iconHover;

  final Color title;
  final Color muted;

  final Color badgeBg;
  final Color badgeBorder;
  final Color badgeText;

  final Color infoBg;
  final Color infoBorder;
  final Color infoIcon;

  const _InventoryColors({
    required this.pageGradient,
    required this.link,
    required this.linkHover,
    required this.separator,
    required this.breadcrumbCurrent,
    required this.subtitle,
    required this.cardGradient,
    required this.cardGradientHover,
    required this.border,
    required this.borderHover,
    required this.borderActive,
    required this.cardGlow,
    required this.iconGradient,
    required this.iconGradientHover,
    required this.iconGlow,
    required this.icon,
    required this.iconHover,
    required this.title,
    required this.muted,
    required this.badgeBg,
    required this.badgeBorder,
    required this.badgeText,
    required this.infoBg,
    required this.infoBorder,
    required this.infoIcon,
  });

  static const _dark = _InventoryColors(
    // topLeft to bottomRight, as specified.
    pageGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF12152A), Color(0xFF1E1630)],
    ),
    link: AppColors.violet300,
    linkHover: AppColors.lavender,
    separator: Color(0x33FFFFFF),
    breadcrumbCurrent: Color(0x8CFFFFFF),
    subtitle: Color(0x80FFFFFF),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x0AFFFFFF), Color(0xF2141626)],
    ),
    cardGradientHover: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x1A8B5CF6), Color(0xF2181630)],
    ),
    border: Color(0x12FFFFFF),
    borderHover: Color(0x4D8B5CF6),
    borderActive: Color(0x8C8B5CF6),
    cardGlow: [
      BoxShadow(
        color: Color(0x4D8B5CF6),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ],
    iconGradient: [
      Color(0xE6322850),
      Color(0xF21E1932),
    ],
    iconGradientHover: [
      Color(0xF26D28D9),
      Color(0xF2472A8F),
    ],
    iconGlow: [
      BoxShadow(
        color: Color(0x668B5CF6),
        blurRadius: 24,
        spreadRadius: 2,
      ),
    ],
    icon: AppColors.purple700,
    iconHover: AppColors.violet300,
    title: Color(0xFFE2E0F0),
    muted: Color(0x6BFFFFFF),
    badgeBg: Color(0x1F7C3AED),
    badgeBorder: Color(0x4D8B5CF6),
    badgeText: AppColors.lavender,
    infoBg: Color(0x0DFFFFFF),
    infoBorder: Color(0x12FFFFFF),
    infoIcon: AppColors.violet300,
  );

  /// The light set is the dark one with the alphas re-pointed rather than
  /// simply reduced: a 4% white overlay is invisible on a near-white card, so
  /// the light values are opaque tints of the same hues.
  static const _light = _InventoryColors(
    pageGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFAFAFE), Color(0xFFF3EFFB)],
    ),
    link: AppColors.purple700,
    linkHover: AppColors.violet400,
    separator: Color(0x59000000),
    breadcrumbCurrent: Color(0x99111827),
    subtitle: Color(0x8A111827),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFBFAFF)],
    ),
    cardGradientHover: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF6F2FE)],
    ),
    border: Color(0xFFE7E3F4),
    borderHover: Color(0x998B5CF6),
    borderActive: AppColors.purple700,
    cardGlow: [
      BoxShadow(
        color: Color(0x338B5CF6),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    iconGradient: [
      Color(0xFFF3EEFE),
      Color(0xFFE7DFF9),
    ],
    iconGradientHover: [
      Color(0xFFEFE6FE),
      Color(0xFFDDD0FB),
    ],
    iconGlow: [
      BoxShadow(
        color: Color(0x4D8B5CF6),
        blurRadius: 20,
        spreadRadius: 1,
      ),
    ],
    icon: AppColors.purple700,
    iconHover: AppColors.violet400,
    title: Color(0xFF1F1B33),
    muted: Color(0x99111827),
    badgeBg: Color(0xFFF1EBFE),
    badgeBorder: Color(0xFFDDD3FB),
    badgeText: Color(0xFF6D28D9),
    infoBg: Color(0xFFF8F5FF),
    infoBorder: Color(0xFFE7E3F4),
    infoIcon: AppColors.purple700,
  );

  static _InventoryColors of(BuildContext context) =>
      context.isDark ? _dark : _light;
}