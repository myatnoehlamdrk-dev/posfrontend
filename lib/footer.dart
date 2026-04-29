import 'package:flutter/material.dart';
class PosFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PosFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      // Fixed type ensures all labels are visible
      type: BottomNavigationBarType.fixed, 
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale),
          label: 'Sales',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.production_quantity_limits),
          label: 'Product',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.reorder_rounded),
          label: 'Order',
        ),
      ],
    );
  }
}