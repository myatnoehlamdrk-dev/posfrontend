import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posfrontend/modules/dashboard/view/dashboard_screen.dart';
import 'package:posfrontend/modules/inventory/view/inventory_screen.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/login/view/login_screen.dart';
import 'package:posfrontend/modules/product/view/products_catalog_screen.dart';
import 'package:posfrontend/modules/profile/view/profile_screen.dart';

LoginResponse? _userArg(BuildContext context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  return args is LoginResponse? ? args : null;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'POS Frontend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B2CBF),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const LoginScreen(),
      routes: {
        '/dashboard': (ctx) => DashboardScreen(user: _userArg(ctx)),
        '/inventory': (ctx) => InventoryScreen(user: _userArg(ctx)),
        '/products': (ctx) => ProductsCatalogScreen(user: _userArg(ctx)),
        '/profile': (ctx) => ProfileScreen(user: _userArg(ctx)),
      },
    );
  }
}
