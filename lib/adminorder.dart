import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminOrderPage extends StatefulWidget {
  const AdminOrderPage({super.key});

  @override
  State<AdminOrderPage> createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage> {

  final String baseUrl = "http://10.0.2.2:8000/api";

  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  // ✅ FETCH FROM BACKEND
  Future<void> fetchOrders() async {
    final res = await http.get(Uri.parse("$baseUrl/order"));

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        orders = List<Map<String, dynamic>>.from(data.map((o) => {
               "id": o['id'],
               "user_id": o['user_id'],
              "orderId": "ORD-${o['id']}",
              "invoice": o["invoice_no"],
              "customer": o["c_id"].toString(),
              "total": o["total_amount"],
              "payment": o["payment"],
              "time": o["created_at"],
            }));
      });
    }
  }

  // 🔹 DELETE (UI only)
  void _deleteOrder(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Order"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
           onPressed: () async {
  final id = orders[index]['id']; // must have id

  final res = await http.delete(
    Uri.parse("$baseUrl/order/$id"),
  );

  print("DELETE STATUS: ${res.statusCode}");

  if (res.statusCode == 200) {
    setState(() {
      orders.removeAt(index); // remove from UI AFTER success
    });
  }

  Navigator.pop(context);
},
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 🔹 VIEW
  void _viewOrder(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(order["orderId"]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Invoice: ${order["invoice"]}"),
            Text("Customer: ${order["customer"]}"),
            Text("Payment: ${order["payment"]}"),
            Text("Total: \$${order["total"]}"),
            Text("Time: ${order["time"]}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  // 🔹 EDIT
void _editOrder(int index) {
  final order = orders[index];

  // controllers with existing values
  TextEditingController customerCtrl =
      TextEditingController(text: order["customer"]);
  TextEditingController invoiceCtrl =
      TextEditingController(text: order["invoice"]);
  TextEditingController totalCtrl =
      TextEditingController(text: order["total"].toString());

  String paymentMethod = order["payment"];

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Edit Order"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: customerCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Customer ID"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: invoiceCtrl,
              decoration: const InputDecoration(labelText: "Invoice No"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: totalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Total Amount"),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: paymentMethod,
              items: ["Cash", "KBZPay", "WavePay"]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (val) {
                paymentMethod = val!;
              },
              decoration: const InputDecoration(
                labelText: "Payment",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        TextButton(
          onPressed: () async {
            final id = order["id"];

            final res = await http.put(
              Uri.parse("$baseUrl/order/$id"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "user_id": order["user_id"], // 🔥 adjust if needed
                "c_id": int.parse(customerCtrl.text),
                "invoice_no": invoiceCtrl.text,
                "total_amount": double.parse(totalCtrl.text),
                "payment": paymentMethod,
              }),
            );

            print("UPDATE STATUS: ${res.statusCode}");
            print("UPDATE BODY: ${res.body}");

            if (res.statusCode == 200) {
              // ✅ update UI AFTER success
              setState(() {
                orders[index]["customer"] = customerCtrl.text;
                orders[index]["invoice"] = invoiceCtrl.text;
                orders[index]["total"] = double.parse(totalCtrl.text);
                orders[index]["payment"] = paymentMethod;
              });

              Navigator.pop(context);
            } else {
              print("Update failed");
            }
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Orders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchOrders, // 🔄 reload
          )
        ],
      ),

      body: orders.isEmpty
          ? const Center(child: Text("No Orders Found"))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(order["orderId"]),
                    subtitle: Text(
                        "${order["customer"]} • \$${order["total"]}"),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () => _viewOrder(order),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editOrder(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteOrder(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}