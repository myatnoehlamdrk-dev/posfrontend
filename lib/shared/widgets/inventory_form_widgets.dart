import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';

/// `kTitle`, `kGray` and `kBorder` used to live here as `static const`
/// colours, and `sale_preview_screen` plus `package_details_screen` imported
/// them — which meant the invoice preview painted `#111827` headings and `#6B7280`
/// captions unconditionally. In dark mode that is 1.35:1 and 3.10:1: the
/// preview was unreadable. Both screens now read `palette.textPrimary` /
/// `textSecondary` / `border`, so the values follow the theme.
const Color kBg = Color(0xFFFFFFFF);

/// The one purple the inventory forms are built in, shared with the welcome
/// screen's `Get started` button, the product prices and the sale buttons.
///
/// Named aliases for [AppColors.brandPurple] rather than fresh hex values: this
/// file is the base every inventory form sits on — add category, add package,
/// add product, quick add, add stock — so a second purple defined here would be
/// one more place the accent could drift.
const Color kPurple = AppColors.brandPurple;

/// The purple ramp for filled actions. Both steps come from [AppColors] so the
/// gradient cannot fade a brand purple into an unrelated violet.
const LinearGradient kPurpleGradient = LinearGradient(
  colors: [AppColors.brandPurple, AppColors.brandPurpleDark],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

/// Themed field decoration. There is deliberately no context-free variant: the
/// light-only one that used to sit here painted a white fill with a grey hint,
/// which is unreadable in dark mode.
InputDecoration fieldDecorationFor(
  BuildContext context,
  String hint, {
  bool alignRight = false,
}) {
  final p = context.palette;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: p.textSecondary,
      fontSize: AppTypography.bodySmallSize,
    ),
    filled: true,
    fillColor: p.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.s16,
      vertical: AppSpacing.s12,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: p.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: p.border),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: p.border),
    ),
  );
}

class InventoryHeader extends StatelessWidget {
  final String title;
  final String initials;
  final VoidCallback? onBack;
  final bool showMenu;
  final VoidCallback? onMenu;

  const InventoryHeader({
    super.key,
    required this.title,
    required this.initials,
    this.onBack,
    this.showMenu = false,
    this.onMenu,
  });

  @override
  Widget build(BuildContext ctx) {
    final p = ctx.palette;
    return Row(
      children: [
        if (showMenu)
          IconButton(
            icon: const GradientIcon(icon: Icons.menu),
            onPressed: onMenu,
          )
        else
          CustomBackButton(onTap: onBack ?? () => Navigator.of(ctx).pop()),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.titleLargeSize,
              fontWeight: FontWeight.bold,
              color: p.textPrimary,
            ),
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none_outlined,
                color: p.textPrimary,
              ),
              onPressed: () {},
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.dangerFg,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.s8),
        CircleAvatar(
          radius: 20,
          backgroundColor: kPurple,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: AppTypography.bodySmallSize,
            ),
          ),
        ),
      ],
    );
  }
}

class InventoryBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const InventoryBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: kPurple,
      unselectedItemColor: p.textSecondary,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: context.l10n.t('Dashboard'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: context.l10n.t('Inventory'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: context.l10n.t('Product'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale),
          label: context.l10n.t('Sale'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: context.l10n.t('More'),
        ),
      ],
    );
  }
}

class BreadcrumbItem {
  final String label;
  final bool active;
  const BreadcrumbItem(this.label, this.active);
}

class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  const Breadcrumb(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(
          Text(
            '  >  ',
            style: TextStyle(
              fontSize: AppTypography.labelMediumSize,
              color: p.textSecondary,
            ),
          ),
        );
      }
      children.add(
        Text(
          items[i].label,
          style: TextStyle(
            fontSize: AppTypography.labelMediumSize,
            color: items[i].active ? p.textSecondary : kPurple,
          ),
        ),
      );
    }
    return Wrap(children: children);
  }
}

class FormCard extends StatelessWidget {
  final String label;
  final String? helper;
  final bool required;
  final Widget child;

  const FormCard({
    super.key,
    required this.label,
    this.helper,
    this.required = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.bodyMediumSize,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
              if (required)
                Text(
                  ' *',
                  style: TextStyle(
                    color: p.dangerFg,
                    fontSize: AppTypography.bodyMediumSize,
                  ),
                ),
            ],
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              helper!,
              style: TextStyle(
                fontSize: AppTypography.labelMediumSize,
                color: p.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s12),
          child,
        ],
      ),
    );
  }
}

class DisabledField extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool alignRight;

  const DisabledField({
    super.key,
    required this.icon,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: p.textSecondary),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              value,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: AppTypography.bodySmallSize,
                color: p.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CounterTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int max;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const CounterTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.max,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: fieldDecorationFor(context, hint),
        ),
        const SizedBox(height: AppSpacing.s4),
        Align(
          alignment: Alignment.centerRight,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Text(
              context.l10n
                  .t('{v1} / {v2}')
                  .replaceAll('{v1}', (controller.text.length).toString())
                  .replaceAll('{v2}', (max).toString()),
              style: TextStyle(
                fontSize: AppTypography.labelSmallSize,
                color: p.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const DropdownField({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: p.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: AppTypography.bodySmallSize,
            ),
          ),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class FormActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final String saveLabel;
  final bool loading;

  const FormActions({
    super.key,
    required this.onCancel,
    this.onSave,
    this.saveLabel = 'Save',
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: p.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                context.l10n.t('Cancel'),
                style: TextStyle(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: AppTypography.bodyMediumSize,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              // The shared ramp, not a gradient written out here: this button is
              // the save action on every inventory form, and it was the one
              // control still painted in the old violet-to-violet pair while the
              // rest of the app moved to the brand purple.
              gradient: kPurpleGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: p.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: loading ? null : onSave,
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          saveLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: AppTypography.bodyMediumSize,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InfoBox extends StatelessWidget {
  final String title;
  final String body;

  const InfoBox({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: p.selectionTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: kPurple),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTypography.bodyMediumSize,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: AppTypography.labelMediumSize,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
