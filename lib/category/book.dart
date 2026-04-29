import 'package:flutter/material.dart';
import '../order.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../orderdialog.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  List<Map<String, dynamic>> bookItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookProducts();
  }

  // ✅ API CALL
  Future<void> fetchBookProducts() async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8000/api/productbook"), // API
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);

      setState(() {
        bookItems = data.map((item) {
          return {
            // ✅ FROM DATABASE
            'name': item['name'],
            'price': item['selling_price'],
            'stock_quantity': item['stock_quantity'],

            // ✅ UI fields (NOT in DB)
            'icon': getIcon(item['name']),
            'color': getColor(item['stock_quantity']),
          };
        }).toList();

        isLoading = false;
      });
    }
  }

  // ✅ Icon logic for books
  IconData getIcon(String name) {
    final n = name.toLowerCase();

    if (n.contains('math')) return Icons.calculate;
    if (n.contains('science')) return Icons.science;
    if (n.contains('history')) return Icons.menu_book;
    if (n.contains('novel')) return Icons.auto_stories;

    return Icons.book;
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
        title: const Text("Book Store"),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bookItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final item = bookItems[index];
                return _buildBookCard(context, item);
              },
            ),
    );
  }

  Widget _buildBookCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          
           OrderDialog.show(context, item);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON / IMAGE
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
                      color: Colors.indigo,
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