import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:posfrontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/notification_bell.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

void navigateToDashboard(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const DashboardScreen()),
    (route) => false,
  );
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
                    ? NetworkImage(imageUrl)
                    : null,
                onBackgroundImageError: imageUrl.isNotEmpty
                    ? (_, __) {
                        ProfileImageNotifier.instance.update('');
                      }
                    : null,
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
