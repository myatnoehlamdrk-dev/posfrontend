import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/notification_bell.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

class AppScreenTopBar extends StatelessWidget {
  final String title;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  /// False on the notifications page itself, so the bell cannot push a
  /// second copy of the screen it is already showing.
  final bool showNotificationsButton;

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
    this.showNotificationsButton = true,
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
          // The bell that used to sit here wore a red "3 unread" dot no code
          // ever incremented, and was removed rather than left dead. The live
          // button is back: unread count comes from NotificationStore, which
          // the FCM listener feeds.
          if (showNotificationsButton) const NotificationBell(),
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
