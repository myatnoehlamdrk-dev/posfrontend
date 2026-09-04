import 'package:flutter/material.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/profile/view/profile_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

class AppScreenTopBar extends StatelessWidget {
  final String title;
  final LoginResponse? user;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;

  const AppScreenTopBar({
    super.key,
    required this.title,
    this.user,
    this.showMenuButton = true,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (ctx) => IconButton(
                onPressed: onMenuTap ?? () => Scaffold.of(ctx).openDrawer(),
                icon: const Icon(Icons.menu, color: AppColors.titleColor),
              ),
            ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.titleColor,
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
                icon: const Icon(Icons.notifications_outlined, color: AppColors.titleColor),
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
              );
            },
            child: ValueListenableBuilder<String>(
              valueListenable: ProfileImageNotifier.instance,
              builder: (context, imageUrl, _) {
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.teal,
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? Text(
                          user != null && user!.fullName.trim().isNotEmpty
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
