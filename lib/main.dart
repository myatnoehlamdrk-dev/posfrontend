import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posfrontend/core/auth/auth_redirect.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/modules/onboarding/view/get_started_screen.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      child: ShopScope(
        child: MaterialApp(
          title: 'Inventory',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7B2CBF),
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
          home: const GetStartedScreen(),
        ),
      ),
    );
  }
}
