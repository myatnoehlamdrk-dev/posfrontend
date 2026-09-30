import 'package:flutter/material.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for a "View all" table.
///
/// Shaped like the real table: same column widths, same total width, so the
/// header and the rows land in the same place once the data arrives. A centred
/// spinner would be shorter to write and would cause everything below it to
/// jump when the rows show up.
///
/// The real table prepends a row-number column, so the skeleton reserves that
/// slot too; otherwise every header cell would shift right when loading ends.
class DashboardTableSkeleton extends StatelessWidget {
  final List<TableColumn> columns;
  final double totalWidth;
  final int rowCount;

  /// Matches the row-number column in DashboardTableScreen.
  static const double _numberWidth = 48;

  const DashboardTableSkeleton({
    super.key,
    required this.columns,
    required this.totalWidth,
    this.rowCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SkeletonSweep(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SkeletonBox(height: 40, radius: 10),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: totalWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            _numberCell(),
                            for (final column in columns)
                              SizedBox(
                                width: column.width,
                                child: SkeletonBox(
                                  height: 12,
                                  width: column.width * 0.6,
                                ),
                              ),
                          ],
                        ),
                      ),
                      for (var i = 0; i < rowCount; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              _numberCell(),
                              for (final column in columns)
                                SizedBox(
                                  width: column.width,
                                  child: SkeletonBox(
                                    height: 12,
                                    width: column.width * 0.75,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberCell() {
    return const SizedBox(
      width: _numberWidth,
      child: SkeletonBox(height: 12, width: 24),
    );
  }
}
