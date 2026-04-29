import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MasterSetup extends StatefulWidget {
  const MasterSetup({super.key});

  @override
  State<MasterSetup> createState() => _MasterSetupState();
}

class _MasterSetupState extends State<MasterSetup> {

  final String baseUrl = "http://10.0.2.2:8000/api"; 

  // Controllers
  final roleController = TextEditingController();
  final categoryController = TextEditingController();

  final productNameController = TextEditingController();
  final skuController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final categoryIdController = TextEditingController();

  // ================= ROLE =================
  Future<void> addRole() async {
    final res = await http.post(
      Uri.parse("$baseUrl/roleadd"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": roleController.text
      }),
    );

    showMessage(res.body);
  }

  // ================= CATEGORY =================
  Future<void> addCategory() async {
    final res = await http.post(
      Uri.parse("$baseUrl/categoryadd"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": categoryController.text
      }),
    );

    showMessage(res.body);
  }

  // ================= PRODUCT =================
  Future<void> addProduct() async {
    final res = await http.post(
      Uri.parse("$baseUrl/productadd"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "category_id": int.parse(categoryIdController.text),
        "name": productNameController.text,
        "sku": skuController.text,
        "selling_price": double.parse(priceController.text),
        "stock_quantity": int.parse(stockController.text),
        
      }),
    );

    showMessage(res.body);
  }

  void showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Response"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Master Setup")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ROLE
            const Text("Add Role", style: TextStyle(fontSize: 18)),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: "Role Name"),
            ),
            ElevatedButton(onPressed: addRole, child: const Text("Add Role")),

            const Divider(),

            // CATEGORY
            const Text("Add Category", style: TextStyle(fontSize: 18)),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category Name"),
            ),
            ElevatedButton(onPressed: addCategory, child: const Text("Add Category")),

            const Divider(),

            // PRODUCT
            const Text("Add Product", style: TextStyle(fontSize: 18)),
            TextField(
              controller: categoryIdController,
              decoration: const InputDecoration(labelText: "Category ID"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: productNameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: skuController,
              decoration: const InputDecoration(labelText: "SKU"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: "Stock"),
              keyboardType: TextInputType.number,
            ),
            

            ElevatedButton(onPressed: addProduct, child: const Text("Add Product")),

          ],
        ),
      ),
    );
  }
}