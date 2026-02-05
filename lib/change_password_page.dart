import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password baru tidak sama!")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
          Uri.parse("${AppConfig.baseUrl}/api/change-password"),
          headers: {
            'Authorization': 'Bearer $token'
          },
          body: {
            'old_password': _oldPassCtrl.text,
            'new_password': _newPassCtrl.text,
            'new_password_confirmation': _confirmPassCtrl.text,
          });

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Password Berhasil Diubah"),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(json['message'] ?? "Gagal"),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ganti Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: _oldPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Password Lama", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(
                controller: _newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Password Baru", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(
                controller: _confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Konfirmasi Password Baru",
                    border: OutlineInputBorder())),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
