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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                decoration: BoxDecoration(
                  // Gradient pill with an outer violet bloom, matching the
                  // segmented control in the sales mockup. A flat fill read as
                  // disabled next to the glassy cards; the two-stop sweep plus
                  // the shadow is what makes the selected tab look raised.
                  gradient: active
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                        )
                      : null,
                  color: active ? null : p.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.brandPurpleDark.withValues(
                              alpha: 0.6,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: -6,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    context.l10n
                        .t('{v1} ({v2})')
                        .replaceAll('{v1}', context.l10n.t(tabs[i].$1))
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
