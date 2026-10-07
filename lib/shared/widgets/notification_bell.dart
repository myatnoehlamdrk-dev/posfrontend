import 'package:flutter/material.dart';
import 'package:posfrontend/features/notifications/data/notification_store.dart';
import 'package:posfrontend/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:posfrontend/shared/l10n/app_strings.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// The app-bar notification bell, with the unread badge driven by
/// [NotificationStore].
///
/// Lives in `shared/widgets` because both top bars render it: the old
/// `AppTopBar` wore a hardcoded red dot that no code could ever increment —
/// an unread badge that can never clear trains staff to ignore it — and
/// `AppScreenTopBar` had it removed outright pending this button. One
/// implementation, one source of truth for the count.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListenableBuilder(
      listenable: NotificationStore.instance,
      builder: (context, _) {
        final count = NotificationStore.instance.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none_outlined,
                color: p.textPrimary,
              ),
              tooltip: AppStrings.of(context).notifications,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: EdgeInsets.symmetric(
                    horizontal: count > 9 ? 4 : 0,
                  ),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    // Red-600 rather than the old 8px dot's #EF4444: white
                    // text needs 4.5:1 and #EF4444 only gives 3.76.
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
