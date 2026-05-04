import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'footer.dart';
import 'main.dart';
import 'product.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}


class _OrderPageState extends State<OrderPage> {
  final String baseUrl = "http://10.0.2.2:8000/api";
      int _currentIndex=2;
    void _onFooterTap(int index) {
    if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const InventoryPage()));
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

  // 🔹 Controllers
  final TextEditingController userController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController invoiceController = TextEditingController();
  final TextEditingController totalController = TextEditingController();

  // 🔹 Dropdown state (FIXED POSITION)
  String paymentMethod = "Cash";

  // 🔹 Order list
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  //  Create Order
  Future<void> createOrder() async {
    if (userController.text.isEmpty ||
        customerController.text.isEmpty ||
        invoiceController.text.isEmpty ||
        totalController.text.isEmpty) {
      print("Fill all fields");
      return;
    }

    final res = await http.post(
      Uri.parse("$baseUrl/order"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": int.parse(userController.text),
        "c_id": int.parse(customerController.text),
        "invoice_no": invoiceController.text,
        "total_amount": double.parse(totalController.text),
        "payment": paymentMethod,
      }),
    );

    print("CREATE STATUS: ${res.statusCode}");
    print("CREATE BODY: ${res.body}");

    if (res.statusCode == 201) {
      userController.clear();
      customerController.clear();
      invoiceController.clear();
      totalController.clear();

       fetchOrders();
    }
  }

  // Fetch Orders
  Future<void> fetchOrders() async {
    final res = await http.get(Uri.parse("$baseUrl/order"));

    print("FETCH STATUS: ${res.statusCode}");
    print("FETCH BODY: ${res.body}");

    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);

        setState(() {
          orders = List<Map<String, dynamic>>.from(data);
        });
      } catch (e) {
        print("NOT JSON → ${res.body}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Page")),

      body: Row(
        children: [
          // 🔹 LEFT: FORM
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: userController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "User ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: customerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Customer ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: invoiceController,
                    decoration: const InputDecoration(
                      labelText: "Invoice No",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Total Amount",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  //DROPDOWN FIXED
                  DropdownButtonFormField<String>(
  value: paymentMethod,
  items: ["Cash", "KBZPay", "WavePay"]
      .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e),
          ))
      .toList(),
  onChanged: (val) {
    setState(() {
      paymentMethod = val!;
    });
  },
  decoration: const InputDecoration(
    labelText: "Payment",
    border: OutlineInputBorder(),
  ),
),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: createOrder,
                    child: const Text("Create Order"),
                  ),
                ],
              ),
            ),
          ),

          // 🔹 RIGHT: HISTORY
          Expanded(
            flex: 3,
            child: orders.isEmpty
                ? const Center(child: Text("No orders found"))
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(
                              "Invoice: ${order['invoice_no'] ?? ''}"),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Total: ${order['total_amount'] ?? ''}"),
                              Text(
                                  "Payment: ${order['payment'] ?? ''}"),

                              // optional fields
                              Text(
                                  "Name: ${order['name'] ?? '-'}"),
                              Text(
                                  "SKU: ${order['sku'] ?? '-'}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
            bottomNavigationBar: PosFooter(
        currentIndex: _currentIndex,
        onTap: _onFooterTap,
      ),
    );
  }
}