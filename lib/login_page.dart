import 'dart:convert';
//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'config.dart';

// IMPORT DASHBOARD & KIOSK
import 'dashboard_page.dart';
import 'admin_dashboard_page.dart';
import 'kiosk_page.dart'; // <--- Pastikan file ini ada

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;
  bool _isAdminLogin = false;

  final ImagePicker _picker = ImagePicker();

  // --- LOGIKA LOGIN MANUAL (TETAP SAMA) ---
  Future<void> _login() async {
    if (_nikController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NIK dan Password harus diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var url = Uri.parse(AppConfig.login);
      var response = await http.post(
        url,
        body: {
          'email': _nikController.text,
          'password': _passwordController.text,
          'is_admin': _isAdminLogin ? '1' : '0',
        },
        headers: {'Accept': 'application/json'},
      );

      var json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String token = json['access_token'];
        Map<String, dynamic> user = json['user'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(user));

        if (!mounted) return;

        Widget targetPage;
        if (_isAdminLogin == true) {
          targetPage = AdminDashboardPage(userData: user);
        } else {
          targetPage = DashboardPage(userData: user);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      } else {
        String message = json['message'] ?? "Login Gagal";
        if (!mounted) return;
        _showErrorDialog(message);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Terjadi kesalahan koneksi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA LOGIN WAJAH (TETAP SAMA) ---
  Future<void> _handleFaceLogin() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );

      if (photo == null) return;

      setState(() => _isLoading = true);

      var uri = Uri.parse("${AppConfig.baseUrl}/api/login-face");
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', photo.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          var json = jsonDecode(response.body);

          if (json['token'] == null) {
            throw Exception(json['message'] ?? "Token tidak ditemukan");
          }

          String token = json['token'];
          Map<String, dynamic> user = json['user'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('user', jsonEncode(user));

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => DashboardPage(userData: user)),
          );
        } catch (e) {
          _showErrorDialog(
              "Format Data Salah: $e\n\nIsi: ${response.body.substring(0, 100)}...");
        }
      } else {
        String body = response.body.trim();
        if (body.startsWith("<")) {
          String preview = body.length > 500 ? body.substring(0, 500) : body;
          _showErrorDialog("SERVER ERROR (${response.statusCode}):\n$preview");
        } else {
          try {
            var json = jsonDecode(body);
            _showErrorDialog(
                json['message'] ?? "Gagal: ${response.statusCode}");
          } catch (e) {
            _showErrorDialog("Error Unknown (${response.statusCode}): $body");
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Aplikasi Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Info Login"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 25.0, vertical: 40.0), // Padding atas dikit biar pas
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TAMBAHAN: IKON KIOSK DI POJOK KANAN ATAS ---
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: "Mode Kiosk Kantor",
                  icon:
                      const Icon(Icons.storefront_outlined, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const KioskPage()),
                    );
                  },
                ),
              ),
              // ------------------------------------------------

              const SizedBox(height: 0),
              // ILUSTRASI (Tetap)
              Center(
                child: Image.asset(
                  "assets/images/login_illustration.png",
                  height: 180, // Sedikit disesuaikan biar muat
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.lock_clock,
                      size: 100,
                      color: Colors.blue),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                "Login Absensi",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
              const Text(
                "Masuk dengan ID Anda",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // INPUT NIK (Tetap)
              TextField(
                controller: _nikController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Staff ID / NIK",
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // INPUT PASSWORD (Tetap)
              TextField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),

              // PILIHAN ADMIN (Tetap)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _isAdminLogin,
                        activeColor: Colors.blue,
                        onChanged: (bool? value) {
                          setState(() {
                            _isAdminLogin = value ?? false;
                          });
                        },
                      ),
                      const Text("Administrator",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      "Lupa Password?",
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TOMBOL LOGIN (Tetap)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("MASUK",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),

              // SEPARATOR (Tetap)
              Row(children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("ATAU", style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ]),
              const SizedBox(height: 20),

              // TOMBOL SCAN WAJAH (Tetap)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleFaceLogin,
                  icon: const Icon(Icons.face_retouching_natural,
                      size: 28, color: Colors.blue),
                  label: const Text("Scan Wajah",
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
