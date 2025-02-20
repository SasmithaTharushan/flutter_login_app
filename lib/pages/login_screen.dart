import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'register_screen.dart'; // Import RegisterScreen
import '../database/database_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isPasswordVisible = false;

  /// Handles user login
  Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError("Please enter both username and password");
      return;
    }

    _showLoading();

    try {
      final response = await http.post(
        Uri.parse("https://api.ezuite.com/api/External_Api/Mobile_Api/Invoke"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "API_Body": [
            {"Unique_Id": "", "Pw": password}
          ],
          "Api_Action": "GetUserData",
          "Company_Code": username
        }),
      );

      Navigator.pop(context); // Close loading dialog

      print("API Response: ${response.body}");
      //_showJsonResponse(response.body); // Show JSON in a popup

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data["Status_Code"] == 200) {
          final user = data["Response_Body"][0];

          await _dbHelper.insertUser({
            'user_code': user['User_Code'],
            'display_name': user['User_Display_Name'],
            'email': user['Email'],
            'employee_code': user['User_Employee_Code'],
            'company_code': user['Company_Code'],
          });

          // Print stored user data from SQLite
          await _dbHelper.printUsers();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                user['User_Display_Name'],
                user['Email'],
              ),
            ),
          );
        } else {
          _showError("Invalid credentials");
        }
      } else {
        _showError("API error: ${response.reasonPhrase}");
      }
    } catch (e) {
      Navigator.pop(context);
      _showError("Network error: $e");
    }
  }

  /// Shows a dialog with the raw API response JSON
  void _showJsonResponse(String jsonData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("API Response"),
        content: SingleChildScrollView(child: Text(jsonData)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  /// Shows an error message using SnackBar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Shows a loading indicator
  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              const Icon(Icons.lock, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),

              // Title
              const Text(
                "Welcome Back!",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),

              // Username Input Field
              TextField(
                controller: usernameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 15),

              // Password Input Field
              TextField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              ElevatedButton.icon(
                onPressed: _login,
                icon: const Icon(Icons.login),
                label: const Text("Login"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 20),

              // Forgot Password
              GestureDetector(
                onTap: () {
                  // Implement forgot password functionality
                },
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),

              // Divider
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 15),

              // New User Registration
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    text: "New to our App? ",
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                    children: [
                      TextSpan(
                        text: "Register Now",
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
