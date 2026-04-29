import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final String baseUrl = "http://10.0.2.2:8000/api"; 
  // Android emulator → http://10.0.2.2:8000/api

  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  //  FETCH
  Future<void> fetchCustomers() async {
    final res = await http.get(Uri.parse("$baseUrl/customer"));

    print("FETCH STATUS: ${res.statusCode}");
    print("FETCH BODY: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        customers = List<Map<String, dynamic>>.from(data.map((c) => {
              "id": c["id"],
              "name": c["name"],
              "phone": c["phone"],
              "email": c["email"],
              "points": c["points"] ?? 0,
            }));
      });
    }
  }

  // ➕ ADD
  void _addCustomer() {
    final nameCtrl = TextEditingController();
    final passwordCtrl=TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: "Password or Pin_code")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final res = await http.post(
                Uri.parse("$baseUrl/addcustomer"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "name": nameCtrl.text,
                  "phone": phoneCtrl.text,
                  "email": emailCtrl.text,
                  "password": emailCtrl.text,
                }),
              );

              print("ADD STATUS: ${res.statusCode}");
              print("ADD BODY: ${res.body}");

              if (res.statusCode == 201) {
                fetchCustomers();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ✏️ EDIT
  void _editCustomer(int index) {
    final customer = customers[index];

    final nameCtrl = TextEditingController(text: customer["name"]?.toString() ??"",);
    final phoneCtrl = TextEditingController(text: customer["phone"]?.toString() ??"");
    final emailCtrl = TextEditingController(text: customer["email"]?.toString() ??"");
    

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final id = customer["id"];

              final res = await http.put(
                Uri.parse("$baseUrl/customer/$id"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "_method": "PUT",
                  "name": nameCtrl.text,
                  "phone": phoneCtrl.text,
                  "email": emailCtrl.text,
                }),
              );

              print("UPDATE STATUS: ${res.statusCode}");
              print("UPDATE BODY: ${res.body}");

              if (res.statusCode == 200) {
                fetchCustomers();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // 🗑 DELETE
  void _deleteCustomer(int index) {
    final customer = customers[index];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Customer"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final id = customer["id"];

              final res = await http.delete(
                Uri.parse("$baseUrl/customer/$id"),
              );

              print("DELETE STATUS: ${res.statusCode}");

              if (res.statusCode == 200) {
                fetchCustomers();
              }

              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 👁 VIEW PROFILE
  void _viewCustomer(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(c["name"]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("ID: ${c["id"]}"),
            Text("Phone: ${c["phone"]}"),
            Text("Email: ${c["email"]}"),
            Text("Points: ${c["points"]}"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchCustomers,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addCustomer,
          )
        ],
      ),

      body: customers.isEmpty
          ? const Center(child: Text("No customers found"))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final c = customers[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(c["name"]),
                    subtitle: Text("${c["phone"]} • ${c["points"]} pts"),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () => _viewCustomer(c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCustomer(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCustomer(index),
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