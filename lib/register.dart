import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'login.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  bool _obscurePassword = true;

  Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;

  final response = await http.post(
    Uri.parse("http://10.0.2.2:8000/api/register"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "name": nameCtrl.text,
      "email": emailCtrl.text,
      "phone": phoneCtrl.text,
      "password": passwordCtrl.text,
    }),
  );

  if (response.statusCode == 201) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registered successfully")),
    );

      Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),);
    
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed: ${response.body}")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // 🔹 NAME
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Name",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter name" : null,
              ),

              const SizedBox(height: 15),

              // 🔹 EMAIL
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Enter email";
                  if (!value.contains("@")) return "Invalid email";
                  return null;
                },
              ),

              const SizedBox(height: 15),

              // 🔹 PHONE
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? "Enter phone number" : null,
              ),

              const SizedBox(height: 15),

              // 🔹 PASSWORD
              TextFormField(
                controller: passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Enter password";
                  if (value.length < 6) return "Min 6 characters";
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // 🔹 REGISTER BUTTON
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Register"),
              ),
              TextButton(
                onPressed: () {
                 Navigator.push(
                  context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text("Already have account? Login"),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}