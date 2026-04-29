import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderDialog {
  static void show(BuildContext context, Map<String, dynamic> product) {
    final qtyController = TextEditingController(text: "1");
    final invoiceController = TextEditingController(text: "INV-001");

    String paymentMethod = "cash"; // default

    int stock = int.tryParse(product['stock_quantity'].toString()) ?? 0;
    double price = double.tryParse(product['price'].toString()) ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name']),

        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Price: \$${product['price']}"),
                Text("Stock: $stock"),

                const SizedBox(height: 10),

                TextField(
                  controller: invoiceController,
                  decoration: const InputDecoration(labelText: "Invoice No"),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  items: ["cash", "kbzpay", "wave"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      paymentMethod = val!;
                    });
                  },
                  decoration: const InputDecoration(labelText: "Payment"),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Quantity"),
                ),
              ],
            );
          },
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          TextButton(
            onPressed: () async {
              int qty = int.tryParse(qtyController.text) ?? 0;
              String invoice = invoiceController.text;

              if (qty <= 0) {
                _showError(context, "Invalid quantity");
                return;
              }

              if (qty > stock) {
                _showError(context, "Not enough stock");
                return;
              }

              double total = qty * price;

              await _createOrder(
                total,
                invoice,
                paymentMethod,
              );

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Order saved")),
              );
            },
            child: const Text("Order"),
          ),
        ],
      ),
    );
  }

  // ✅ ONLY send fields that backend expects
  static Future<void> _createOrder(
    double total,
    String invoice,
    String payment,
  ) async {
    final res = await http.post(
      Uri.parse("http://10.0.2.2:8000/api/order"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": 1,          // 🔥 MUST exist in DB
        "c_id": 1,             // 🔥 MUST exist in DB
        "invoice_no": invoice,
        "total_amount": total,
        "payment": payment,
      }),
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");
  }

  static void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}