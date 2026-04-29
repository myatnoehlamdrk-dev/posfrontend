import 'package:flutter/material.dart';
import '../order.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GiftPage extends StatefulWidget {
  const GiftPage({super.key});

  @override
  State<GiftPage> createState() => _GiftPageState();
}

class _GiftPageState extends State<GiftPage> {
  List<Map<String, dynamic>> giftItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGiftProducts();
  }

  // ✅ API CALL
  Future<void> fetchGiftProducts() async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8000/api/productgift"), 
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);

      setState(() {
        giftItems = data.map((item) {
          return {
            // ✅ FROM DATABASE
            'name': item['name'],
            'price': item['selling_price'],

            // ✅ UI fields (NOT in DB)
            'icon': getIcon(item['name']),
            'color': getColor(item['stock_quantity']),
          };
        }).toList();

        isLoading = false;
      });
    }
  }

  // ✅ UI helper functions
  IconData getIcon(String name) {
    if (name.toLowerCase().contains('cake')) return Icons.cake;
    if (name.toLowerCase().contains('flower')) return Icons.local_florist;
    if (name.toLowerCase().contains('card')) return Icons.favorite;
    if (name.toLowerCase().contains('teddy')) return Icons.toys;
    if (name.toLowerCase().contains('watch')) return Icons.watch;
    return Icons.card_giftcard;
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
      appBar: AppBar(
        title: const Text("Gift Shop"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: giftItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final item = giftItems[index];
                return _buildGiftCard(context, item);
              },
            ),
    );
  }

  Widget _buildGiftCard(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        goToOrderPage(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: item['color'].withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Icon(item['icon'], size: 50, color: item['color']),
              ),
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "\$${item['price']}",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
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