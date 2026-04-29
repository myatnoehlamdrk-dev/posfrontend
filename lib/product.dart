import 'footer.dart';
import 'main.dart';
import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'orderdialog.dart';
import 'order.dart';
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  int _currentIndex = 1;
  final String baseUrl = "http://10.0.2.2:8000/api";

  void _onFooterTap(int index) {
    if (index == 2) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const OrderPage()));
    } else if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const POSHome()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // 🔹 Dummy product list
   List<Map<String, dynamic>> products = [];  
   Future<void> fetchProducts() async {
  final res = await http.get(Uri.parse("$baseUrl/product"));

  print("STATUS: ${res.statusCode}");
  print("BODY: ${res.body}");

  if (res.statusCode == 200) {
    setState(() {
      products = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    });
  }
}
  @override
void initState() {
  super.initState();
  fetchProducts();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Products"),
      actions: [
  IconButton(
    icon: const Icon(Icons.search),
    onPressed: () {
      Map<String, dynamic> product = {
  "id": 1,
  "name": "Test Product",
  "price": 100,
  "stock_quantity": 5,
};
      OrderDialog.show(context, product);
        },
      ),
    ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.builder(
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 🔹 change to 3 for tablet
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final product = products[index];

            return GestureDetector(
              onTap: () {OrderDialog.show(context, product);},
                
              
              child: Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inventory, size: 30),
        const SizedBox(height: 8),

        Text(
          product["name"],
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text("Category: ${product["category_id"]}"),
        // Text("Name: ${product["name"]}"),
        Text("SKU: ${product["sku"]}"),
        
        Text("Price: \$${product["selling_price"]}"),
        Text("Stock: ${product["stock_quantity"]}"),
      ],
    ),
  ),
),
            );
          },
        ),
      ),

      bottomNavigationBar: PosFooter(
        currentIndex: _currentIndex,
        onTap: _onFooterTap,
      ),
    );
    
  }
  
}
