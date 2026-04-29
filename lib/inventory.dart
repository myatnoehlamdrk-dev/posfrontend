import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  final String baseUrl = "http://10.0.2.2:8000/api";

  List<Map<String, dynamic>> logs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  // =========================
  // ✅ FETCH
  // =========================
  Future<void> fetchLogs() async {
    final res = await http.get(Uri.parse("$baseUrl/inventory-log"));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        logs = List<Map<String, dynamic>>.from(data.map((l) => {
              "id": l["id"],
              "product_id": l["product_id"],
              "user_id": l["user_id"],
              "qty": l["change_amount"],
              "reason": l["reason"],
            }));

        isLoading = false;
      });
    }
  }

  // =========================
  // ➕ ADD
  // =========================
  void _addLog() {
    final productCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Inventory Log"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: productCtrl, decoration: const InputDecoration(labelText: "Product ID")),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "User ID")),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Change Amount")),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: "Reason")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final res = await http.post(
                Uri.parse("$baseUrl/inventorylog"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "product_id": int.tryParse(productCtrl.text) ?? 1,
                  "user_id": int.tryParse(userCtrl.text) ?? 1,
                  "change_amount": int.tryParse(qtyCtrl.text) ?? 0,
                  "reason": reasonCtrl.text,
                }),
              );

              if (res.statusCode == 201) {
                fetchLogs();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // =========================
  // ✏️ UPDATE
  // =========================
  void _editLog(int index) {
    final log = logs[index];

    final qtyCtrl = TextEditingController(text: log["qty"].toString());
    final reasonCtrl = TextEditingController(text: log["reason"]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Inventory Log"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Product ID: ${log["product_id"]}"),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Change Amount")),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: "Reason")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final res = await http.put(
                Uri.parse("$baseUrl/inventory-log/${log["id"]}"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "product_id": log["product_id"],
                  "user_id": log["user_id"],
                  "change_amount": int.tryParse(qtyCtrl.text) ?? 0,
                  "reason": reasonCtrl.text,
                }),
              );

              if (res.statusCode == 200) {
                fetchLogs();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // =========================
  // 🗑 DELETE
  // =========================
  void _deleteLog(int index) {
    final log = logs[index];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Log"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final res = await http.delete(
                Uri.parse("$baseUrl/inventory-log/${log["id"]}"),
              );

              if (res.statusCode == 200) {
                fetchLogs();
              }

              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Logs"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchLogs),
          IconButton(icon: const Icon(Icons.add), onPressed: _addLog),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : logs.isEmpty
              ? const Center(child: Text("No logs found"))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final l = logs[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text("Product: ${l["product_id"]}"),
                        subtitle: Text(
                            "Qty: ${l["qty"]} • User: ${l["user_id"]}\nReason: ${l["reason"]}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editLog(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteLog(index),
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