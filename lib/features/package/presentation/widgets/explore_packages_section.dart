import 'package:flutter/material.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/pressable_card.dart';

/// "Explore Packages": a horizontal strip of package tiles under the category
/// grid.
///
/// Exactly [previewCount] tiles and nothing more. This is a way in, not the place
/// packages are managed — the rail is scrolled by hand and the rest are reached
/// from the category screens, so a "show all" control here would only offer a
/// second way to do something that is already one tap away.
///
/// Tapping a tile opens that package's detail screen.
class ExplorePackagesSection extends StatelessWidget {
  final List<PackageEntity> packages;

  /// How many tiles to show. Passed in rather than hardcoded so the viewmodel
  /// stays the single place that decides the preview size.
  final int previewCount;

  final ValueChanged<PackageEntity> onPackageTap;

  const ExplorePackagesSection({
    super.key,
    required this.packages,
    required this.previewCount,
    required this.onPackageTap,
  });

  static const double tileWidth = 158;
  static const double tileImageHeight = 96;

  @override
  Widget build(BuildContext context) {
    // Nothing to show: the section is omitted rather than rendered as a heading
    // with an empty rail under it. A heading that leads nowhere reads as a bug.
    if (packages.isEmpty) return const SizedBox.shrink();

    final p = context.palette;
    final visible = previewCount > 0
        ? packages.take(previewCount).toList(growable: false)
        : packages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: Text(
            context.l10n.t('Explore Packages'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: tileImageHeight + 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: ExplorePackagesSection.tileWidth,
              child: _PackageTile(
                package: visible[i],
                onTap: () => onPackageTap(visible[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.package, required this.onTap});

  final PackageEntity package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // `PackageApiModel.fromJson` never populates `imageUrl`, so the package's
    // artwork is the first of its products' photos. Falling back to the package
    // name's glyph keeps a tile from being an empty grey rectangle.
    final imageUrl = package.productImages.isNotEmpty
        ? package.productImages.first
        : '';

    return PressableCard(
      onTap: onTap,
      pressedScale: 0.96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: ExplorePackagesSection.tileImageHeight,
              width: double.infinity,
              child: imageUrl.isEmpty
                  ? _glyph(context)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _glyph(context),
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : _glyph(context),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            package.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n
                .t('{v1} products')
                .replaceAll('{v1}', package.quantity.toString()),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: p.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _glyph(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.chipBg,
      child: Center(
        child: Icon(Icons.inventory_2_outlined, size: 28, color: p.textMuted),
      ),
    );
  }
}