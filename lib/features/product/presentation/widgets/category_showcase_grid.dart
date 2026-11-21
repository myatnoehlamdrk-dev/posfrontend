import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_card.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';

/// How many category cards fit on one row of the showcase grid, for a grid
/// [width] wide.
///
/// Single source of truth for the breakpoints, so the grid, its loading
/// skeleton and the screen that pages categories in cannot disagree about how
/// many cards a row holds.
int categoryGridColumns(double width) {
  if (width >= 1100) return 4;
  if (width >= 820) return 3;
  if (width >= 500) return 2;
  return 1;
}

class CategoryShowcaseGrid extends StatelessWidget {
  final List<CategoryShowcaseData> categories;

  /// Draw the hairline outline on each card. Passed in rather than derived from
  /// this widget's own width, because "is the window wide" is the screen's
  /// question to answer — it already has to make it to decide between a side
  /// drawer and a bottom nav, and the width *inside* the drawer is not the same
  /// number.
  final bool showCardBorder;

  /// First index that entrance-animates.
  ///
  /// Cards before it are already on screen and must not replay an entrance on
  /// every rebuild; cards from it on are the batch a "show more" press just
  /// revealed, and they arrive one after another rather than all at once. Zero
  /// on first paint, so the opening row settles in behind the skeleton.
  final int animateFromIndex;

  final ValueChanged<CatalogProductView>? onProductTap;
  final ValueChanged<CatalogProductView>? onProductLongPress;
  final ValueChanged<CategoryShowcaseData>? onCategoryTap;

  const CategoryShowcaseGrid({
    super.key,
    required this.categories,
    this.showCardBorder = true,
    this.animateFromIndex = 0,
    this.onProductTap,
    this.onProductLongPress,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossAxisCount = categoryGridColumns(w);

        // Wider gutters when the cards are bordered, to account for the outline
        // on both sides of a run. Borderless cards at one column already read as
        // separate, and extra gutter there would just make the page loose.
        final spacing = showCardBorder ? 16.0 : 12.0;
        final cardW = (w - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < categories.length; i++)
              SizedBox(
                width: cardW,
                child: _StaggeredEntrance(
                  order: i >= animateFromIndex ? i - animateFromIndex : -1,
                  child: CategoryShowcaseCard(
                    category: categories[i],
                    showBorder: showCardBorder,
                    onProductTap: onProductTap,
                    onProductLongPress: onProductLongPress,
                    onSeeAll: onCategoryTap != null
                        ? () => onCategoryTap!(categories[i])
                        : null,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Fades and lifts a card into place the first time it appears.
///
/// Every card is wrapped, not only the new ones, so the element is created
/// once and kept for as long as the card stays in the grid — a rebuild never
/// replays the entrance. [order] is `-1` for a card that was already on screen
/// (it starts at its final frame) and otherwise that card's place within the
/// batch just revealed, which is what makes a new row arrive one card after
/// another instead of all at once.
class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  late final Animation<double> _fade = _controller.drive(
    CurveTween(curve: Curves.easeOutCubic),
  );

  late final Animation<Offset> _slide = _controller.drive(
    Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).chain(
      CurveTween(curve: Curves.easeOutCubic),
    ),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Nothing to move for a card already on screen, and nothing for anyone who
    // has asked the OS for reduced motion — both land on the final frame.
    if (widget.order < 0 || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }

    Future.delayed(Duration(milliseconds: widget.order * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
