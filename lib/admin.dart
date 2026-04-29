import 'package:flutter/material.dart';
import 'inventory.dart';
import 'product.dart';
import 'adminorder.dart';
import 'adminaccount.dart';
import 'customer.dart';
import 'mastersetup.dart';


class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("POS System"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
             _buildMenuCard(
              context,
              "Account",
              Icons.person,
              const AdminAccountPage(),
            ),
            // 🔹 PRODUCTS
            _buildMenuCard(
              context,
              "Products",
              Icons.production_quantity_limits,
              const InventoryPage(),
            ),

            // 🔹 ORDERS
            _buildMenuCard(
              context,
              "Orders",
              Icons.receipt,
              const AdminOrderPage(),
            ),

            // 🔹 ACCOUNT
            _buildMenuCard(
              context,
              "Master Setup",
              Icons.build,
              const MasterSetup(),
            ),

            // 🔹 SALES / HOME
            _buildMenuCard(
              context,
              "Inventory",
              Icons.point_of_sale,
              const AdminInventoryPage(),
            ),
            _buildMenuCard(
              context,
              "Customer",
              Icons.list_alt,
              const CustomerPage(),
            ),
           
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}