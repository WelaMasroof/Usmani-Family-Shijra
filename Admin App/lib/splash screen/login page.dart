import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;

  Future<void> login() async {
    setState(() => _isLoggingIn = true);

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/token'), // Replace <your-ip>
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': _usernameController.text,
        'password': _passwordController.text,
      },
    );

    setState(() => _isLoggingIn = false);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final token = json['access_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', token);

      Navigator.pushReplacementNamed(context, '/add'); // Navigate to AddPersonPage
    } else {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Login Failed'),
          content: Text('Invalid username or password'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoggingIn ? null : login,
              child: _isLoggingIn
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
