import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
  
}

class _AccountPageState extends State<AccountPage> {

  // 🔹 Dummy user data (later connect with backend)
   String name = "";
   String email = "";
   String phone = "";
   int loyaltyPoints = 0;
   String userId = "";
   String createdAt = "";

   @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
  try{final response = await http.get(
    Uri.parse("http://10.0.2.2:8000/api/customerprofile"),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    setState(() {
      name = data['name']?.toString() ?? "";
      email = data['email']?.toString()?? "";
      phone = data['phone']?.toString()?? "";
      loyaltyPoints = data['loyalty']?? 0;
      createdAt = data['created_at']?.toString()?? "";
      userId = data['id']?.toString() ?? "";
      
    });
  }}catch (e) {
    print("ERROR: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // 🔹 PROFILE PICTURE
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.person, size: 80, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt,
                            size: 18, color: Colors.blueAccent),
                        onPressed: () {
                          // TODO: upload image
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 USER DETAILS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildAccountTile("Name", name, Icons.badge),
                  _buildAccountTile("Email", email, Icons.email),
                  _buildAccountTile("Phone Number", phone, Icons.phone),
                  _buildAccountTile(
                      "Loyalty Points", "$loyaltyPoints pts", Icons.star),
                  _buildAccountTile("User ID", userId, Icons.fingerprint),
                  _buildAccountTile(
                      "Created At", createdAt, Icons.calendar_today),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: logout logic
                },
                icon: const Icon(Icons.logout),
                label: const Text("Log Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🔹 Reusable Tile Widget
  Widget _buildAccountTile(String label, String value, IconData icon) {
    final isLoyalty = label == "Loyalty Points";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isLoyalty ? Colors.yellow[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLoyalty ? Colors.orange : Colors.blueAccent,
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isLoyalty ? Colors.orange : Colors.black,
          ),
        ),
      ),
    );
  }
}