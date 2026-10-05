import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

class AppScreenTopBar extends StatelessWidget {
  final String title;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  /// Overrides the bar's fill. Defaults to the palette surface, which is right
  /// for a page on the scaffold. A page that paints its own background wants
  /// [Colors.transparent] instead, so the bar does not lay an opaque rectangle
  /// across it.
  final Color? backgroundColor;

  const AppScreenTopBar({
    super.key,
    required this.title,
    this.showMenuButton = true,
    this.onMenuTap,
    this.showBackButton = false,
    this.onBackTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.userOf(context);
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? p.surface,
        border: Border(bottom: BorderSide(color: p.border, width: 1)),
      ),
      child: Row(
        children: [
          if (showBackButton)
            CustomBackButton(
              onTap:
                  onBackTap ??
                  () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      navigateToDashboard(context);
                    }
                  },
            ),
          if (showMenuButton)
            Builder(
              builder: (ctx) => IconButton(
                onPressed: onMenuTap ?? () => Scaffold.of(ctx).openDrawer(),
                icon: const GradientIcon(icon: Icons.menu),
              ),
            ),
          Expanded(
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: AppTypography.titleSmallSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // The notification bell used to sit here as an IconButton with
          // `onPressed: () {}` — it accepted the tap and did nothing — wearing a
          // red "3 unread" dot that no code ever incremented. It advertised a
          // feature the build does not have, and an unread badge that can never
          // clear is worse than no badge: it trains staff to ignore it.
          //
          // Removed rather than disabled so the affordance does not come back by
          // accident. When notifications ship, this is where the live button
          // belongs, with the dot driven by a real unread count.
          const SizedBox(width: AppSpacing.s4),
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: ValueListenableBuilder<String>(
              valueListenable: ProfileImageNotifier.instance,
              builder: (context, imageUrl, _) {
                return CircleAvatar(
                  radius: 18,
                  // Was `AppColors.teal`, which gives white initials only
                  // 2.49:1 — below the 4.5:1 that text needs. The brand purple
                  // gives white 5.19:1, and it is the same fill as the primary
                  // button, so the avatar no longer introduces a second accent.
                  backgroundColor: p.primary,
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  onBackgroundImageError: imageUrl.isNotEmpty
                      ? (_, _) {
                          ProfileImageNotifier.instance.update('');
                        }
                      : null,
                  child: imageUrl.isEmpty
                      ? Text(
                          user?.fullName.trim().isNotEmpty == true
                              ? user!.fullName.trim()[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: AppTypography.bodyMediumSize,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
    );
  }
}
