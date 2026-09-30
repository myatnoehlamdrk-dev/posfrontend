import 'package:flutter/material.dart';
import 'package:posfrontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
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

  const AppScreenTopBar({
    super.key,
    required this.title,
    this.showMenuButton = true,
    this.onMenuTap,
    this.showBackButton = false,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.userOf(context);
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
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
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications_outlined, color: p.textPrimary),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
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
                  backgroundColor: AppColors.teal,
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
                            fontSize: 15,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
