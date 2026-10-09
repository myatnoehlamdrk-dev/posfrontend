import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:posfrontend/core/auth/auth_redirect.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/core/local/sync_manager.dart';
import 'package:posfrontend/core/network/connectivity.dart';
import 'package:posfrontend/core/offline/offline_writes_flag.dart';
import 'package:posfrontend/core/offline/outbox_queue.dart';
import 'package:posfrontend/features/notifications/data/notification_store.dart';
import 'package:posfrontend/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:posfrontend/shared/l10n/locale_notifier.dart';
import 'package:posfrontend/shared/services/fcm_service.dart';
import 'package:posfrontend/shared/theme/app_theme.dart';
import 'package:posfrontend/shared/theme/theme_mode_notifier.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';
import 'package:posfrontend/shared/widgets/sync_status_pill.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reset singletons on hot restart to ensure fresh database connections
  LocalStore.reset();
  SyncManager.reset();
  OutboxQueue.reset();
  // Enable offline writes for development (create local orders when offline)
  OfflineWrites.enabled = true;
  // ConnectivityService doesn't hold resources that need reset
  await init();
  // Offline support. Connectivity first: the sync manager gates every run
  // on `isOnline`, so starting it second means the startup refresh sees a
  // considered answer instead of the optimistic initial value.
  await ConnectivityService.instance.start();
  SyncManager.instance.start();
  // Restore the persisted "last synced" time so a cold start offline can
  // say when the data on screen was last confirmed, not just that it is
  // saved.
  unawaited(SyncManager.instance.loadPersistedSyncTime());
  // Load the outbox counts so a relaunch with queued sales shows them on
  // the banner from the first frame, not after the next flush.
  unawaited(OutboxQueue.instance.refreshCounts());
  // Initialize Firebase Cloud Messaging (setup only, token registration after login)
  try {
    await getIt<FcmService>().setup();
  } catch (e) {
    // FCM initialization failure should not block app startup
  }
  // Resolve the theme and the language before the first frame so a dark-mode
  // user never sees a white flash, and a Burmese or Thai user never sees a
  // frame of English. The server copies are authoritative but arrive too late
  // for this; the local mirrors are the launch-time source of truth.
  await ThemeModeNotifier.load();
  await LocaleNotifier.load();
  // Load the saved notification history so the bell badge is correct on the
  // very first frame, before any message listener can fire.
  await NotificationStore.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      child: ShopScope(
        // Rebuilds MaterialApp when the mode or the language changes, which
        // repaints every subtree. One-time cost per toggle, and unavoidable:
        // the theme and the locale are the things being changed.
        child: ListenableBuilder(
          listenable: Listenable.merge([
            ThemeModeNotifier.instance,
            LocaleNotifier.instance,
          ]),
          builder: (context, _) {
            return MaterialApp(
              title: 'Inventory',
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeModeNotifier.instance.value,
              locale: LocaleNotifier.instance.value,
              supportedLocales: supportedAppLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const SplashScreen(),
              builder: (context, child) {
                // Kept inside the app rather than set once in main() so the
                // status bar adapts with the theme. A hardcoded light
                // brightness would be invisible on a dark app bar.
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                    statusBarBrightness: isDark
                        ? Brightness.dark
                        : Brightness.light,
                    systemNavigationBarColor: Theme.of(
                      context,
                    ).colorScheme.surface,
                    systemNavigationBarIconBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                  ),
                  // Floating sync status pill at top-right. Uses Stack so it
                  // floats above content without taking layout space.
                  child: Stack(
                    children: [
                      // Main app content
                      child ?? const SizedBox.shrink(),
                      // Sync status pill (top-right, below status bar)
                      const SyncStatusPill(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
