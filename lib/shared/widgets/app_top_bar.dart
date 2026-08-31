import 'package:flutter/material.dart';
import 'package:posfrontend/modules/dashboard/view/dashboard_screen.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/profile/view/profile_screen.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

void navigateToDashboard(BuildContext context, {LoginResponse? user}) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
    (route) => false,
  );
}

class AppTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBackTap;
  final bool showMenuButton;
  final bool showBackButton;
  final LoginResponse? user;

  const AppTopBar({
    super.key,
    required this.title,
    this.onMenuTap,
    this.onBackTap,
    this.showMenuButton = true,
    this.showBackButton = false,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showMenuButton)
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF111827)),
            onPressed: onMenuTap,
          ),
        if (showBackButton)
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
            onPressed: onBackTap ??
                () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                navigateToDashboard(context, user: user);
              }
            },
          ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF111827)),
              onPressed: () {},
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfileScreen(user: user),
              ),
            );
          },
          child: ValueListenableBuilder<String>(
            valueListenable: ProfileImageNotifier.instance,
            builder: (context, imageUrl, _) {
              return CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6D28D9),
                backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
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
