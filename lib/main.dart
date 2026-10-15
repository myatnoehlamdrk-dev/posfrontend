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
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';
import 'package:posfrontend/shared/widgets/sync_status_pill.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bound the decoded-image budget. Every photo in the app now decodes
  // through a memCacheWidth cap (see CachedProductImage), so entries are a few
  // hundred KB rather than multi-MB camera originals; 64MB / 500 entries is
  // roughly 80 grid tiles — far more than a screenful, and low enough that a
  // long shift on a 2GB POS tablet can't let the image cache crowd out the
  // UI. Flutter's defaults are 100MB / 1000 entries.
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSizeBytes = 64 * 1024 * 1024;
  imageCache.maximumSize = 500;
  LocalStore.reset();
  SyncManager.reset();
  OutboxQueue.reset();
  OfflineWrites.enabled = true; // Enable offline
  await init(); //wait app load
  await ConnectivityService.instance.start(); // checking internect conectivity
  SyncManager.instance.start(); //checking internet local storage to backend
  unawaited(SyncManager.instance.loadPersistedSyncTime()); //Restore the last synchronization time
  unawaited(OutboxQueue.instance.refreshCounts()); //Restore queued-write counts
  try {
    await getIt<FcmService>().setup(); // Initialize Firebase Cloud Messaging 
  } catch (e) {
    // FCM initialization failure should not block app startup
  }
  await ThemeModeNotifier.load(); //Load the saved theme
  await LocaleNotifier.load(); //Load the saved language
  await NotificationStore.instance.init(); //Initialize notification history
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
              // Tracks which named destinations are still alive so drawer
              // navigation can pop back to a screen it already has instead of
              // rebuilding (and re-fetching) it on every tap.
              navigatorObservers: DestinationRouteTracker.observers,
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
