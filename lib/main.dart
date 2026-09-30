import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:posfrontend/core/auth/auth_redirect.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:posfrontend/shared/l10n/locale_notifier.dart';
import 'package:posfrontend/shared/theme/app_theme.dart';
import 'package:posfrontend/shared/theme/theme_mode_notifier.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  // Resolve the theme and the language before the first frame so a dark-mode
  // user never sees a white flash, and a Burmese or Thai user never sees a
  // frame of English. The server copies are authoritative but arrive too late
  // for this; the local mirrors are the launch-time source of truth.
  await ThemeModeNotifier.load();
  await LocaleNotifier.load();
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
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
