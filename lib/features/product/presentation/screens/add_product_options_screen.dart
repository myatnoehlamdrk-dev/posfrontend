import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/connectivity.dart';
import 'package:posfrontend/features/cart/presentation/screens/add_to_cart_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/add_product_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/quick_add_product_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/stock_add_screen.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_page_transitions.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';

/// The "Add Product" landing page.
///
/// Four ways into the product flow, presented as a bento grid. The page now
/// carries the shared app bar so the drawer stays reachable on narrow windows,
/// matching the rest of the app.
class AddProductOptionsScreen extends StatefulWidget {
  const AddProductOptionsScreen({super.key});

  @override
  State<AddProductOptionsScreen> createState() =>
      _AddProductOptionsScreenState();
}

class _AddProductOptionsScreenState extends State<AddProductOptionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Bento grid (true) or compact single-column list (false).
  bool _gridView = true;

  /// Built on each build rather than cached so the copy follows a language
  /// change and the accent steps follow a light/dark switch.
  List<_WorkflowOption> get _options {
    final p = context.palette;
    return [
      _WorkflowOption(
        id: 'express',
        title: context.l10n.t('Express Item'),
        description: context.l10n.t(
          'Add a product with minimal details — name, price, and stock only.',
        ),
        icon: Icons.bolt_rounded,
        accent: p.warningFg,
        iconBackground: p.warningBg,
        badge: context.l10n.t('Fastest • ~15 sec'),
        shortcut: '⌘1',
        tags: [
          context.l10n.t('Enable-Category'),
          context.l10n.t('Instant POS Ready'),
          context.l10n.t('3 Fields Only'),
        ],
      ),
      _WorkflowOption(
        id: 'stock',
        title: context.l10n.t('Update Stock'),
        description: context.l10n.t(
          'Add stock to an existing product or create with detailed inventory tracking.',
        ),
        icon: Icons.inventory_2_rounded,
        accent: p.successFg,
        iconBackground: p.successBg,
        badge: context.l10n.t('Inventory Sync'),
        shortcut: '⌘2',
        tags: [
          context.l10n.t('Add Quickly'),
          context.l10n.t('Search Quickly'),
          context.l10n.t('Reorder Alerts'),
        ],
      ),
      _WorkflowOption(
        id: 'new',
        title: context.l10n.t('New Product'),
        description: context.l10n.t(
          'Full product creation with all details — image, variants, categories, and supply chain.',
        ),
        icon: Icons.edit_note_rounded,
        accent: p.accentText,
        iconBackground: p.selectionTint,
        badge: context.l10n.t('Complete Catalog'),
        shortcut: '⌘3',
        tags: [
          context.l10n.t('Media Gallery'),
          context.l10n.t('Multi-Variant Matrix'),
          context.l10n.t('Supplier & Cost'),
        ],
      ),
      _WorkflowOption(
        id: 'cart',
        title: context.l10n.t('Add to Cart'),
        description: context.l10n.t(
          'View the products saved in your cart and pick up where you left off.',
        ),
        icon: Icons.shopping_cart_rounded,
        accent: p.infoFg,
        iconBackground: p.infoBg,
        badge: context.l10n.t('Saved Drafts'),
        shortcut: '⌘4',
        tags: [
          context.l10n.t('Resume Drafts'),
          context.l10n.t('Batch Checkout'),
          context.l10n.t('Auto-Synced'),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      active: DrawerDestination.addProduct,
      scaffoldKey: _scaffoldKey,
      backgroundColor: Colors.transparent,
      wrap: (_, shell) => shell,
      body: (context, isWide) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t('Add Product'),
              showMenuButton: !isWide,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              backgroundColor: Colors.transparent,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 40 : 20,
                  isWide ? 12 : 8,
                  isWide ? 40 : 20,
                  40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _hero(context, isWide),
                        const SizedBox(height: 32),
                        _workflowSection(context),
                        const SizedBox(height: 28),
                        _telemetryBar(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, bool isWide) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                context.l10n.t(
                  'Select an intake workflow matched to your speed and data depth — from rapid counter entry to full multi-variant catalog publishing.',
                ),
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: AppTypography.bodyMediumSize,
                  height: 1.55,
                ),
              ),
            ),
          ],
        );

        final toggle = _ViewToggle(
          grid: _gridView,
          onGrid: () => setState(() => _gridView = true),
          onList: () => setState(() => _gridView = false),
        );

        if (constraints.maxWidth < 780) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 20), toggle],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: text),
            const SizedBox(width: 32),
            toggle,
          ],
        );
      },
    );
  }

  Widget _workflowSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_gridView) {
          return Column(
            children: [
              for (var i = 0; i < _options.length; i++) ...[
                _WorkflowCard(
                  option: _options[i],
                  showTags: false,
                  compact: true,
                  onTap: () => _navigateTo(context, _options[i].id),
                ),
                if (i != _options.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        final twoColumns = constraints.maxWidth >= 680;
        if (!twoColumns) {
          return Column(
            children: [
              for (var i = 0; i < _options.length; i++) ...[
                _WorkflowCard(
                  option: _options[i],
                  showTags: true,
                  onTap: () => _navigateTo(context, _options[i].id),
                ),
                if (i != _options.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < _options.length; i += 2) {
          final hasSecond = i + 1 < _options.length;
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _WorkflowCard(
                      option: _options[i],
                      showTags: true,
                      onTap: () => _navigateTo(context, _options[i].id),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: hasSecond
                        ? _WorkflowCard(
                            option: _options[i + 1],
                            showTags: true,
                            onTap: () =>
                                _navigateTo(context, _options[i + 1].id),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
          if (i + 2 < _options.length) rows.add(const SizedBox(height: 20));
        }
        return Column(children: rows);
      },
    );
  }

  Widget _telemetryBar(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: context.isDark ? 0.55 : 1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final status = ValueListenableBuilder<bool>(
            valueListenable: ConnectivityService.instance.isOnline,
            builder: (context, online, _) {
              final color = online ? p.successFg : p.warningFg;
              return _TelemetryItem(
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                label: context.l10n.t('Catalog'),
                value: online
                    ? context.l10n.t('Operational')
                    : context.l10n.t('Offline'),
                valueColor: color,
              );
            },
          );

          final details = Wrap(
            spacing: 24,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              status,
              _TelemetryDivider(color: p.border),
              _TelemetryItem(label: context.l10n.t('Workflows'), value: '4'),
              _TelemetryDivider(color: p.border),
              _TelemetryItem(
                label: context.l10n.t('Enable-Category'),
                value: context.l10n.t('Enabled'),
                valueColor: p.accentText,
              ),
            ],
          );

          final hint = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.t('Pick a card to begin'),
                style: TextStyle(
                  color: p.textMuted,
                  fontSize: AppTypography.labelMediumSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 16, color: p.accentText),
            ],
          );

          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [details, const SizedBox(height: 14), hint],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              hint,
            ],
          );
        },
      ),
    );
  }

  void _navigateTo(BuildContext context, String type) {
    final Widget screen = switch (type) {
      'express' => const QuickAddProductScreen(),
      'stock' => const StockAddScreen(),
      'cart' => const AddToCartScreen(),
      _ => const AddProductScreen(),
    };
    Navigator.of(context).push(AppPageTransitions.fadeSlide<void>(screen));
  }
}

// ---------------------------------------------------------------------------
// Workflow card
// ---------------------------------------------------------------------------

class _WorkflowOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final Color iconBackground;
  final String badge;
  final String shortcut;
  final List<String> tags;

  const _WorkflowOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.iconBackground,
    required this.badge,
    required this.shortcut,
    required this.tags,
  });
}

class _WorkflowCard extends StatefulWidget {
  final _WorkflowOption option;
  final bool showTags;
  final bool compact;
  final VoidCallback onTap;

  const _WorkflowCard({
    required this.option,
    required this.showTags,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_WorkflowCard> createState() => _WorkflowCardState();
}

class _WorkflowCardState extends State<_WorkflowCard> {
  bool _hovered = false;
  Offset? _pointer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final option = widget.option;
    final accent = option.accent;
    final radius = BorderRadius.circular(20);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pointer = null;
      }),
      onHover: (event) => setState(() => _pointer = event.localPosition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              p.surface,
              Color.lerp(p.surface, accent, context.isDark ? 0.06 : 0.025)!,
            ],
          ),
          borderRadius: radius,
          border: Border.all(
            color: Color.lerp(
              p.border,
              accent,
              _hovered ? (context.isDark ? 0.45 : 0.55) : 0,
            )!,
          ),
          boxShadow: [
            if (context.isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.4 : 0.24),
                blurRadius: _hovered ? 30 : 18,
                offset: const Offset(0, 10),
              )
            else
              BoxShadow(
                color: _hovered
                    ? accent.withValues(alpha: 0.16)
                    : Colors.black.withValues(alpha: 0.045),
                blurRadius: _hovered ? 26 : 16,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            // Passthrough matters for the grid: the row stretches the card to
            // its neighbour's height, and the content column needs that tight
            // height so the tag row can sit at the bottom. In the one-column
            // layout the height is loose and the card keeps its natural size.
            fit: StackFit.passthrough,
            children: [
              // Cursor-following spotlight, the Flutter take on the HTML
              // card's `--mouse-x` / `--mouse-y` radial highlight.
              if (_pointer != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _hovered ? 1 : 0,
                      child: CustomPaint(
                        painter: _SpotlightPainter(
                          center: _pointer!,
                          color: accent.withValues(
                            alpha: context.isDark ? 0.16 : 0.10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: radius,
                  hoverColor: Colors.transparent,
                  splashColor: accent.withValues(alpha: 0.08),
                  highlightColor: accent.withValues(alpha: 0.04),
                  child: Padding(
                    padding: EdgeInsets.all(widget.compact ? 20 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _IconTile(
                                  icon: option.icon,
                                  accent: accent,
                                  background: option.iconBackground,
                                  compact: widget.compact,
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Wrap(
                                    alignment: WrapAlignment.end,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _Badge(
                                        label: option.badge,
                                        accent: accent,
                                      ),
                                      _ShortcutChip(
                                        label: option.shortcut,
                                        accent: accent,
                                        hovered: _hovered,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: widget.compact ? 16 : 22),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.title,
                                    style: TextStyle(
                                      color: p.textPrimary,
                                      fontSize: widget.compact
                                          ? AppTypography.titleSmallSize
                                          : AppTypography.titleMediumSize,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: _hovered
                                        ? accent.withValues(alpha: 0.14)
                                        : p.chipBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _hovered
                                          ? accent.withValues(alpha: 0.35)
                                          : p.border,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: _hovered ? accent : p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              option.description,
                              style: TextStyle(
                                color: p.textSecondary,
                                fontSize: AppTypography.bodySmallSize,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                        if (widget.showTags)
                          Padding(
                            padding: const EdgeInsets.only(top: 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Divider(height: 1, color: p.border),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final tag in option.tags)
                                      _Tag(label: tag),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final Color color;

  const _SpotlightPainter({required this.center, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide * 0.9;
    if (radius <= 0) return;
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          size.width == 0 ? 0 : (center.dx / size.width) * 2 - 1,
          size.height == 0 ? 0 : (center.dy / size.height) * 2 - 1,
        ),
        radius: 0.9,
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.color != color;
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color background;
  final bool compact;

  const _IconTile({
    required this.icon,
    required this.accent,
    required this.background,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = compact ? 46.0 : 54.0;
    final tint = context.isDark
        ? Color.lerp(p.surface, accent, 0.24)!
        : background;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(tint, Colors.white, context.isDark ? 0.04 : 0.25)!,
            tint,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: context.isDark ? 0.20 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: accent, size: compact ? 23 : 27),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color accent;

  const _Badge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: context.isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: AppTypography.labelSmallSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final String label;
  final Color accent;
  final bool hovered;

  const _ShortcutChip({
    required this.label,
    required this.accent,
    required this.hovered,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hovered ? accent.withValues(alpha: 0.10) : p.chipBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: hovered ? accent.withValues(alpha: 0.30) : p.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: hovered ? accent : p.textSecondary,
          fontSize: AppTypography.labelSmallSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: p.textSecondary,
          fontSize: AppTypography.labelSmallSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero controls and telemetry
// ---------------------------------------------------------------------------

class _ViewToggle extends StatelessWidget {
  final bool grid;
  final VoidCallback onGrid;
  final VoidCallback onList;

  const _ViewToggle({
    required this.grid,
    required this.onGrid,
    required this.onList,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleButton(
            icon: Icons.grid_view_rounded,
            label: context.l10n.t('Bento Grid'),
            active: grid,
            onTap: onGrid,
          ),
          _ViewToggleButton(
            icon: Icons.view_list_rounded,
            label: context.l10n.t('Compact List'),
            active: !grid,
            onTap: onList,
          ),
        ],
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? p.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: p.cardShadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? p.textPrimary : p.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? p.textPrimary : p.textSecondary,
                  fontSize: AppTypography.labelMediumSize,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryItem extends StatelessWidget {
  final Widget? leading;
  final String label;
  final String value;
  final Color? valueColor;

  const _TelemetryItem({
    required this.label,
    required this.value,
    this.leading,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Text(
          '$label: ',
          style: TextStyle(
            color: p.textMuted,
            fontSize: AppTypography.labelMediumSize,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? p.textPrimary,
            fontSize: AppTypography.labelMediumSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TelemetryDivider extends StatelessWidget {
  final Color color;

  const _TelemetryDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 14, color: color);
  }
}
