import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/notification_bell.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

/// Back to the dashboard, reusing the one already in the stack when there is
/// one. Popping to it keeps every screen below alive for an instant return;
/// pushing only when it is genuinely absent is what happens straight after
/// login, when there is nothing to pop back to.
///
/// `force: true` because this is the "leave this page" action: whatever is on
/// screen — a drill-down, a half-written sale — goes, exactly as the old
/// clear-the-whole-stack implementation did.
void navigateToDashboard(BuildContext context) {
  navigateToDestination(context, DrawerDestination.dashboard, force: true);
}

class AppTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBackTap;
  final bool showMenuButton;
  final bool showBackButton;

  const AppTopBar({
    super.key,
    required this.title,
    this.onMenuTap,
    this.onBackTap,
    this.showMenuButton = true,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        if (showMenuButton)
          IconButton(
            icon: const GradientIcon(icon: Icons.menu),
            onPressed: onMenuTap,
          ),
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
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppTypography.titleMediumSize,
              fontWeight: FontWeight.bold,
              color: p.textPrimary,
            ),
          ),
        ),
        const NotificationBell(),
        const SizedBox(width: AppSpacing.s8),
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
                radius: 20,
                backgroundColor: const Color(0xFF6D28D9),
                backgroundImage: imageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(imageUrl, maxWidth: 224)
                    : null,
                // No `onBackgroundImageError` handler on purpose -- see the
                // note in app_screen_top_bar. Erasing the shared URL here
                // blanked the avatar app-wide after one failed load, and
                // nothing else refetches it.
                child: imageUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 22)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
