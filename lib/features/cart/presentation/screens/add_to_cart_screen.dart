import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';

class AddToCartScreen extends StatelessWidget {
  const AddToCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: AppTopBar(title: 'Add to Cart', showMenuButton: false, showBackButton: true),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 20),
                    Text(
                      'Cart is empty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add products to your cart',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
