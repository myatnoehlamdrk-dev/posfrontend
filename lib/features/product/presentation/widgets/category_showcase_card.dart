import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_tile.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/l10n/app_strings.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';

/// One category: its name, its description, and a preview of its products.
///
/// ## The border is conditional
///
/// [showBorder] draws the hairline outline and is off on a phone. At one column
/// the cards are already separated by their own spacing and by the product
/// tiles inside them, and a border round each one just draws a long column of
/// boxes that makes a phone screen look like a form. From tablet width the cards
/// sit side by side and the border is what tells them apart, so it comes back.
class CategoryShowcaseCard extends StatelessWidget {
  final CategoryShowcaseData category;

  /// Draw the hairline outline. See the class doc for why it is conditional.
  final bool showBorder;

  final ValueChanged<CatalogProductView>? onProductTap;
  final ValueChanged<CatalogProductView>? onProductLongPress;
  final VoidCallback? onSeeAll;

  const CategoryShowcaseCard({
    super.key,
    required this.category,
    this.showBorder = true,
    this.onProductTap,
    this.onProductLongPress,
    this.onSeeAll,
  });

  /// The category name's type size, and the chevron's.
  ///
  /// The two are deliberately the same number. A chevron matched to the name
  /// reads as part of the heading — "this is the title, this is where it goes" —
  /// whereas a smaller arrow reads as a separate control floating beside it, and
  /// on a card that is already entirely tappable it is also ambiguous about
  /// whether it is a separate target.
  static const double nameSize = 20;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: showBorder ? Border.all(color: p.border) : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: p.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSeeAll,
          hoverColor: p.surfaceAlt,
          child: Padding(
            // A borderless card gets more room: with no outline to set it off,
            // the padding is the only thing separating this card from the last,
            // so it carries more of the gap on its own.
            padding: EdgeInsets.all(showBorder ? 16 : 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context, p),
                const SizedBox(height: 14),
                _productGrid(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppPalette p) {
    return Row(
      // The chevron is a fixed-width slot at the top-right so it does not shift
      // horizontally when a name wraps from one line to two.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name and count share a line: the count describes the name, so
              // putting it directly after the name keeps that relationship
              // visible. Below the description it read as a third line of prose.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: _nameChip(context, p)),
                  if (category.displayCount > 0) ...[
                    const SizedBox(width: 8),
                    _count(context, p),
                  ],
                ],
              ),
              if (category.hasDescription) ...[
                const SizedBox(height: 4),
                _description(context, p),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            // Same size as the name, per the note on [nameSize].
            size: nameSize,
            color: p.textSecondary,
          ),
        ),
      ],
    );
  }

  /// The category name, on its own filled surface.
  ///
  /// This is what makes it distinct from the description: the name has a
  /// background and the description does not, so the two cannot be mistaken for
  /// each other at a glance even though they sit one or two lines apart and are
  /// the same width. [selectionTint] is the palette's existing tint for "this is
  /// the thing you are on", which is exactly what the name is.
  ///
  /// One line now that it shares a row with the count. Two lines were needed
  /// while the count sat underneath and the name had the full card width; on a
  /// line shared with the count and a chevron there is not room for two, and a
  /// wrapping name would push the count off the end. A long name ellipsises
  /// instead, and the full text is one tap away on the category's own screen.
  Widget _nameChip(BuildContext context, AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.selectionTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: nameSize,
          height: 1.15,
          fontWeight: FontWeight.w900,
          color: p.textPrimary,
        ),
      ),
    );
  }

  /// The category description: one line, italic, muted, with no surface of its
  /// own.
  ///
  /// One line only. These are free text written when the category was created and
  /// they are routinely longer than a card is wide — letting them wrap over three
  /// or four lines turns the header into a paragraph and pushes the product
  /// preview, which is the reason the card exists, off the bottom. The full text
  /// is one tap away on the category's own screen, so truncating here loses
  /// nothing that matters.
  ///
  /// Italic as well as grey: the two signals are redundant on purpose. Grey alone
  /// is weak, and italic carries the "this is a note, not a heading" reading even
  /// for someone who struggles to make out the muted colour.
  Widget _description(BuildContext context, AppPalette p) {
    return Text(
      category.description.trim(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: p.textSecondary,
      ),
    );
  }

  /// The product count, shown beside the name.
  ///
  /// This is the category's real total from the server, not the size of the
  /// preview grid below — which is capped at four. So a category can read
  /// "12 products" directly above four thumbnails, and that is deliberate: the
  /// grid is a sample, and reporting the sample's size would understate what is
  /// in the category.
  Widget _count(BuildContext context, AppPalette p) {
    return Text(
      context.l10n
          .t(
            category.displayCount == 1 ? '{v1} product' : '{v1} products',
          )
          .replaceAll('{v1}', category.displayCount.toString()),
      // One line, and never the thing that gives up its width: a long category
      // name should ellipsis beside the count rather than push the count off the
      // edge of the card.
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: p.textMuted.withValues(alpha: 0.75),
      ),
    );
  }

  Widget _productGrid(AppPalette p) {
    final products = category.products;
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            AppStrings.current.t('No products'),
            style: TextStyle(fontSize: 13, color: p.textMuted),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 10.0;
        final tileW = (constraints.maxWidth - spacing) / 2;
        final tileH = tileW + 28;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: products.map((p) {
            return SizedBox(
              width: tileW,
              height: tileH,
              child: CategoryTile(
                product: p,
                onTap: onProductTap != null ? () => onProductTap!(p) : null,
                onLongPress: onProductLongPress != null
                    ? () => onProductLongPress!(p)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}