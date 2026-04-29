import 'package:flutter/material.dart';
import '../order.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewHomePage extends StatefulWidget {
  const NewHomePage({super.key});

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  List<Map<String, dynamic>> homeProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // ✅ API CALL (correct place)
  Future<void> fetchProducts() async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8000/api/producthome"),
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);

      setState(() {
        homeProducts = data.map((product) {
          return {
            'name': product['name'],
            'price': product['selling_price'],
            'stock_quantity': product['stock_quantity'],
            'sku': product['sku'],
            'created_at': product['created_at'],

            // UI fields
            'desc': getDescription(product['name']),
            'icon': getIcon(product['name']),
            'color': getColor(product['stock_quantity']),
          };
        }).toList();

        isLoading = false;
      });
    }
  }

  // ✅ UI helper functions (correct place)
  String getDescription(String name) {
    if (name.toLowerCase().contains('sofa')) {
      return 'Comfortable modern sofa';
    }
    return 'No description available';
  }

  IconData getIcon(String name) {
    if (name.toLowerCase().contains('sofa')) {
      return Icons.weekend;
    }
    return Icons.inventory;
  }

  Color getColor(int stock) {
    if (stock <= 2) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
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
      appBar: AppBar(title: const Text("New Home Collection")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: homeProducts.length,
              itemBuilder: (context, index) {
                final product = homeProducts[index];
                return _buildHomeCard(context, product);
              },
            ),
    );
  }

  Widget _buildHomeCard(BuildContext context, Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Container(
            height: 150,
            color: product['color'].withOpacity(0.2),
            child: Icon(product['icon'], size: 60),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                Text("\$${product['price']}"),

                Text(product['desc']),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Stock: ${product['stock_quantity']}"),
                    Text("SKU: ${product['sku']}"),
                  ],
                ),

                Text("Created: ${product['created_at']}"), // ✅ FIXED KEY

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    goToOrderPage(context);
                  },
                  child: const Text("Order"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}