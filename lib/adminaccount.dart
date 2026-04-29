import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAccountPage extends StatefulWidget {
  const AdminAccountPage({super.key});

  @override
  State<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> {

  // 🔹 Admin Data (single profile)
  String userId = "";
  String roleId = "";
  String roleName = "";
  String name = "";
  String email = "";
  String pincode = "";

   @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
  try{final response = await http.get(
    Uri.parse("http://10.0.2.2:8000/api/adminprofile"),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    setState(() {
      userId = data['id']?.toString() ?? "";
      roleId=data['role_id']?.toString()??"";
      roleName=data['rolename']?.toString()??"";
      name = data['name']?.toString() ?? "";
      email = data['email']?.toString()?? "";
      
      pincode = data['created_at']?.toString()?? ""; 
    });
  }}catch (e) {
    print("ERROR: $e");
  }
}

  // 🔹 Edit Profile
  void _editProfile() {
    TextEditingController nameCtrl = TextEditingController(text: name);
    TextEditingController emailCtrl = TextEditingController(text: email);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                name = nameCtrl.text;
                email = emailCtrl.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // 🔹 Mask pincode (security)
  String get maskedPin => "*" * pincode.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔹 PROFILE ICON
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.admin_panel_settings, size: 50),
            ),

            const SizedBox(height: 20),

            // 🔹 DETAILS
            _buildTile("User ID", userId),
            _buildTile("Role ID", roleId),
            _buildTile("Role Name", roleName),
            _buildTile("Name", name),
            _buildTile("Email", email),
            _buildTile("Pincode", maskedPin),

            const SizedBox(height: 30),

            // 🔹 LOGOUT
            ElevatedButton.icon(
              onPressed: () {
                // TODO logout
              },
              icon: const Icon(Icons.logout),
              label: const Text("Log Out"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}