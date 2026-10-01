import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Numbered step indicator for the multi-step onboarding wizards.
///
/// Lives in shared rather than in either screen because the shop and register
/// wizards both use it, and the whole reason it is one widget is that they have
/// to look identical: a step circle that is brand violet on one screen and
/// primary purple on the next reads as two different products, and the two
/// wizards sit directly behind each other in the flow.
///
/// The filled circles are painted with [AppColors.brandRamp] — the same ramp
/// [GradientButton] and the onboarding hero use — so a step marker reads as a
/// small piece of the same button the user is about to press.
class WizardStepIndicator extends StatelessWidget {
  /// Untranslated step names, in order. Translated here via the l10n lookup.
  final List<String> labels;

  final int currentIndex;

  /// Width below which the names are dropped and the numbers stand alone. Three
  /// names plus the joining rules overflow a 320pt phone, and shrinking the type
  /// below legibility is worse than omitting it: the card title above the form
  /// already says which step this is.
  final double labelsFrom;

  const WizardStepIndicator({
    super.key,
    required this.labels,
    required this.currentIndex,
    this.labelsFrom = 460,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabels = constraints.maxWidth >= labelsFrom;

        return Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              Flexible(
                child: _StepPill(
                  index: i,
                  label: labels[i],
                  showLabel: showLabels,
                  done: i < currentIndex,
                  active: i == currentIndex,
                ),
              ),
              if (i < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      // The completed half of the rule carries the ramp too, so
                      // the marker and the path out of it are one graphic rather
                      // than a gradient dot joined by a flat line.
                      gradient: i < currentIndex
                          ? const LinearGradient(
                              colors: AppColors.brandRamp,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: i < currentIndex ? null : p.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _StepPill extends StatelessWidget {
  final int index;
  final String label;
  final bool showLabel;
  final bool done;
  final bool active;

  const _StepPill({
    required this.index,
    required this.label,
    required this.showLabel,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reached = done || active;
    final labelColor = active
        ? p.textPrimary
        : (done ? p.textSecondary : p.textMuted);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // Reached circles are filled with the brand ramp; the current one
            // also carries GradientButton's resting shadow, so the marker is
            // literally the button in miniature. An unreached one stays hollow so
            // the eye can count what is left.
            gradient: reached
                ? const LinearGradient(
                    colors: AppColors.brandRamp,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: reached ? null : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: reached ? Colors.transparent : p.border,
              width: 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: p.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: done
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: reached ? Colors.white : p.textMuted,
                  ),
                ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              context.l10n.t(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: labelColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
