import 'package:flutter/material.dart';
import '../order.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FashionPage extends StatefulWidget {
  const FashionPage({super.key});

  @override
  State<FashionPage> createState() => _FashionPageState();
}

class _FashionPageState extends State<FashionPage> {
  List<Map<String, dynamic>> fashionItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFashionProducts();
  }

  // ✅ API CALL
  Future<void> fetchFashionProducts() async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8000/api/productfashion"), // 👈 your API
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);

      setState(() {
        fashionItems = data.map((item) {
          return {
            // ✅ FROM DATABASE
            'name': item['name'],
            'price': item['selling_price'],
            'stock_quantity': item['stock_quantity'],

            // ✅ UI fields
            'icon': getIcon(item['name']),
            'color': getColor(item['stock_quantity']),
          };
        }).toList();

        isLoading = false;
      });
    }
  }

  // ✅ Icon logic
  IconData getIcon(String name) {
    final n = name.toLowerCase();

    if (n.contains('shirt')) return Icons.checkroom;
    if (n.contains('jeans')) return Icons.shopping_bag;
    if (n.contains('jacket')) return Icons.dry_cleaning;
    if (n.contains('shoe')) return Icons.directions_run;
    if (n.contains('hat')) return Icons.face;

    return Icons.checkroom;
  }

  // ✅ Color based on stock
  Color getColor(int stock) {
    if (stock <= 2) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  String getStockText(int stock) {
    if (stock <= 0) return "Out of Stock";
    if (stock <= 2) return "Low Stock";
    return "In Stock";
  }

  void goToOrderPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OrderPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fashion Inventory"),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: fashionItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final item = fashionItems[index];
                return _buildProductCard(context, item);
              },
            ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          goToOrderPage(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE / ICON
            Expanded(
              child: Container(
                width: double.infinity,
                color: item['color'].withOpacity(0.15),
                child: Icon(item['icon'], size: 50, color: item['color']),
              ),
            ),

            // TEXT
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "\$${item['price']}",
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    getStockText(item['stock_quantity']),
                    style: TextStyle(
                      color: item['color'],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}