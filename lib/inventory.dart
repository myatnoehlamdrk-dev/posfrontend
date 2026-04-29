import 'package:flutter/material.dart';

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {

  // 🔹 Product List
  List<Map<String, dynamic>> products = [
    {
      "name": "Coffee",
      "sku": "CF001",
      "price": 2.5,
      "qty": 50,
      "category": "Drinks",
      "reason": "Initial stock"
    }
  ];

  // 🔹 Categories
  List<String> categories = ["Drinks", "Food"];

  // ➕ ADD PRODUCT
  void _addProduct() {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    String selectedCategory = categories.first;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Product"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "ID")),
              TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: "product_id")),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Price")),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "user_id")),
              
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => selectedCategory = val!,
                decoration: const InputDecoration(labelText: "Category"),
              ),

              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: "Reason")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                products.add({
                  "name": nameCtrl.text,
                  "sku": skuCtrl.text,
                  "price": double.tryParse(priceCtrl.text) ?? 0,
                  "qty": int.tryParse(qtyCtrl.text) ?? 0,
                  "category": selectedCategory,
                  "reason": reasonCtrl.text,
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ✏️ EDIT PRODUCT
  void _editProduct(int index) {
    final product = products[index];

    final nameCtrl = TextEditingController(text: product["name"]);
    final skuCtrl = TextEditingController(text: product["sku"]);
    final priceCtrl = TextEditingController(text: product["price"].toString());
    final qtyCtrl = TextEditingController(text: product["qty"].toString());
    final reasonCtrl = TextEditingController(text: product["reason"]);

    String selectedCategory = product["category"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Product"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: "SKU")),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Price")),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Quantity")),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => selectedCategory = val!,
                decoration: const InputDecoration(labelText: "Category"),
              ),

              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: "Reason")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                product["name"] = nameCtrl.text;
                product["sku"] = skuCtrl.text;
                product["price"] = double.tryParse(priceCtrl.text) ?? 0;
                product["qty"] = int.tryParse(qtyCtrl.text) ?? 0;
                product["category"] = selectedCategory;
                product["reason"] = reasonCtrl.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // 🗑 DELETE
  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() => products.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ➕ ADD CATEGORY
  void _addCategory() {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Category"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "Category Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() => categories.add(ctrl.text));
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // 🔁 CHANGE STOCK ONLY
  void _changeStock(int index) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Stock"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "New Quantity"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                products[index]["qty"] = int.tryParse(ctrl.text) ?? 0;
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Inventory"),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addProduct),
          IconButton(icon: const Icon(Icons.category), onPressed: _addCategory),
        ],
      ),

      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(p["name"]),
              subtitle: Text(
                  "${p["category"]} • SKU: ${p["sku"]}\nPrice: \$${p["price"]} • Stock: ${p["qty"]}"),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // 🔁 STOCK
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => _changeStock(index),
                  ),

                  // ✏️ EDIT
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editProduct(index),
                  ),

                  // 🗑 DELETE
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProduct(index),
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