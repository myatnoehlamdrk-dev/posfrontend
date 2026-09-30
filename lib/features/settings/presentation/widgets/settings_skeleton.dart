import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for settings.
///
/// Mirrors the screen's section order and card heights: profile, appearance,
/// regional, business (shop image plus shop type), support, about, and the
/// sign-out button. Getting the row counts right per card matters more here than
/// anywhere else, because these cards are stacked full-width, so one wrong
/// height pushes every section below it off by that much.
///
/// The appearance card is drawn with two rows. The real one hides its second row
/// when the theme is following the system, so the placeholder is right only some
/// of the time — but a placeholder that is short by 55px every time the till is
/// on "Match System" is the worse error.
class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonSweep(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ProfileSkeleton(),
            SizedBox(height: 28),
            _HeaderSkeleton(width: 96),
            SizedBox(height: 10),
            _SettingsCardSkeleton(
              rows: [
                _RowSkeleton(switchLike: true),
                _RowSkeleton(switchLike: true),
              ],
            ),
            SizedBox(height: 28),
            _HeaderSkeleton(width: 72),
            SizedBox(height: 10),
            _SettingsCardSkeleton(rows: [_RowSkeleton(trailingWidth: 74)]),
            SizedBox(height: 28),
            _HeaderSkeleton(width: 78),
            SizedBox(height: 10),
            _ShopImageCardSkeleton(),
            SizedBox(height: 12),
            _SettingsCardSkeleton(rows: [_RowSkeleton(trailingWidth: 74)]),
            SizedBox(height: 28),
            _HeaderSkeleton(width: 70),
            SizedBox(height: 10),
            _SettingsCardSkeleton(rows: [_RowSkeleton(), _RowSkeleton()]),
            SizedBox(height: 28),
            _HeaderSkeleton(width: 48),
            SizedBox(height: 10),
            _SettingsCardSkeleton(
              rows: [_RowSkeleton(), _RowSkeleton(), _RowSkeleton()],
            ),
            SizedBox(height: 32),
            _SignOutSkeleton(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// `_sectionHeader` is 12px bold with letter spacing.
class _HeaderSkeleton extends StatelessWidget {
  final double width;

  const _HeaderSkeleton({required this.width});

  @override
  Widget build(BuildContext context) =>
      SkeletonBox(height: 12, width: width, radius: 4);
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      child: Row(
        children: const [
          SkeletonBox(width: 48, height: 48, radius: 24),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 15, width: 124, radius: 6),
                SizedBox(height: 4),
                SkeletonBox(height: 12, width: 92, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `_settingsCard` wraps rows in a 16px-radius surface with no padding of its
/// own, because each `_settingsRow` supplies its own 16px.
class _SettingsCardSkeleton extends StatelessWidget {
  final List<Widget> rows;

  const _SettingsCardSkeleton({required this.rows});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SkeletonDivider(),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Matches `_settingsRow`: 22px icon, 14px gap, label, trailing widget, inside
/// 16px of vertical padding — so each row is 54px tall.
class _RowSkeleton extends StatelessWidget {
  final double? trailingWidth;

  /// A switch is wider and shorter than a chevron-and-value, and getting this
  /// backwards is what makes an appearance placeholder look the wrong height.
  final bool switchLike;

  const _RowSkeleton({this.trailingWidth, this.switchLike = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const SkeletonBox(width: 22, height: 22, radius: 6),
          const SizedBox(width: 14),
          const Expanded(child: SkeletonBox(height: 15, radius: 6)),
          SkeletonBox(
            width: switchLike ? 42 : (trailingWidth ?? 24),
            height: switchLike ? 24 : 24,
            radius: switchLike ? 12 : 6,
          ),
        ],
      ),
    );
  }
}

/// The shop-image card is the odd one out: a labelled header, then a fixed 140px
/// upload target.
class _ShopImageCardSkeleton extends StatelessWidget {
  const _ShopImageCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              SkeletonBox(width: 22, height: 22, radius: 6),
              SizedBox(width: 14),
              SkeletonBox(height: 15, width: 92, radius: 6),
            ],
          ),
          SizedBox(height: 12),
          SkeletonBox(height: 140, radius: 12),
        ],
      ),
    );
  }
}

class _SignOutSkeleton extends StatelessWidget {
  const _SignOutSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(child: SkeletonBox(width: 124, height: 48, radius: 16));
  }
}
