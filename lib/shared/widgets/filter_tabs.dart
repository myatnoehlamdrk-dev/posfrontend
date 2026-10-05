import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class FilterTabs extends StatelessWidget {
  final List<(String label, int count)> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const FilterTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: p.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                decoration: BoxDecoration(
                  color: active ? AppColors.brandPurple : p.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    context.l10n
                        .t('{v1} ({v2})')
                        .replaceAll('{v1}', (tabs[i].$1).toString())
                        .replaceAll('{v2}', (tabs[i].$2).toString()),
                    style: TextStyle(
                      color: active ? Colors.white : p.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: AppTypography.labelMediumSize,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
