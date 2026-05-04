import 'footer.dart';
import 'main.dart';
import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'orderdialog.dart';
import 'order.dart';
class InventoryPage extends StatefulWidget {
  // const InventoryPage({super.key});
  final String? searchQuery; // nullable
  const InventoryPage({super.key, this.searchQuery});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  int _currentIndex = 1;
  final String baseUrl = "http://10.0.2.2:8000/api";
  List<Map<String, dynamic>> filteredProducts = [];

  void applySearch(String query) {
  final input = query.toLowerCase();

  final results = products.where((product) {
    final name = product['name'].toString().toLowerCase();
    return name.contains(input);
  }).toList();

  setState(() {
    filteredProducts = results;
  });
  }

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

  
   List<Map<String, dynamic>> products = [];  
Future<void> fetchProducts() async {
  final res = await http.get(Uri.parse("$baseUrl/product"));

  if (res.statusCode == 200) {
    final data = List<Map<String, dynamic>>.from(jsonDecode(res.body));

    products = data;

    if (widget.searchQuery != null &&
        widget.searchQuery!.trim().isNotEmpty) {
      applySearch(widget.searchQuery!);
    } else {
      filteredProducts = products;
    }

    setState(() {});
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
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Search"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter product name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();

              if (value.isEmpty) return;

              Navigator.pop(context);

              applySearch(value); // 🔥 APPLY SEARCH HERE
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  },
),
    ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.builder(
          itemCount: filteredProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 🔹 change to 3 for tablet
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final product = filteredProducts[index];

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
