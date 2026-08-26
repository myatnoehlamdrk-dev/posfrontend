import 'package:flutter/material.dart';
import 'package:posfrontend/modules/shop/view/shop_screen.dart';

void main() {
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
      ),
      home: const ShopScreen(),
    );
  }
}
