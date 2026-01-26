import 'dart:convert';
//import 'dart:io'; // Tambahan untuk File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Tambahan untuk Kamera
import 'config.dart';

// IMPORT DUA DASHBOARD BERBEDA (Sesuai kode Bapak)
import 'dashboard_page.dart';
import 'admin_dashboard_page.dart';

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
  bool _isAdminLogin = false; // Checkbox Admin tetap ada

  // Init Image Picker untuk Wajah
  final ImagePicker _picker = ImagePicker();

  // --- LOGIKA LOGIN MANUAL (TIDAK DIUBAH SAMA SEKALI) ---
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

// --- LOGIKA LOGIN WAJAH (VERSI DEBUG DI HP) ---
  Future<void> _handleFaceLogin() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );

      if (photo == null) return;

      setState(() => _isLoading = true);

      // Pastikan URL Benar
      var uri = Uri.parse("${AppConfig.baseUrl}/api/login-face");
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', photo.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // --- LOGIKA PENANGANAN ERROR SERVER ---
      if (response.statusCode == 200) {
        // KEMUNGKINAN 1: SUKSES
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
          // Server bilang 200 OK, tapi datanya bukan JSON valid
          _showErrorDialog(
              "Format Data Salah: $e\n\nIsi: ${response.body.substring(0, 100)}...");
        }
      } else {
        // KEMUNGKINAN 2: ERROR DARI SERVER (500, 404, 401)
        String body = response.body.trim();

        if (body.startsWith("<")) {
          // INI DIA TERSANGKANYA! Server kirim HTML (Error Laravel)
          // Kita tampilkan sebagian isinya biar Bapak tau errornya apa
          // Biasanya ada tulisan "Whoops, something went wrong" atau detail error

          // Ambil 500 karakter pertama saja biar tidak kepanjangan
          String preview = body.length > 500 ? body.substring(0, 500) : body;
          _showErrorDialog("SERVER ERROR (${response.statusCode}):\n$preview");
        } else {
          // Error JSON biasa (misal: Wajah tidak dikenali)
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
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // ILUSTRASI (Tetap sesuai aset Bapak)
              Center(
                child: Image.asset(
                  "assets/images/login_illustration.png",
                  height: 200,
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

              // INPUT NIK
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

              // INPUT PASSWORD
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

              // PILIHAN ADMIN & LUPA PASSWORD
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

              // TOMBOL LOGIN (Function _login tetap dipakai)
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

              // SEPARATOR
              Row(children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("ATAU", style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ]),
              const SizedBox(height: 20),

              // TOMBOL SCAN WAJAH (Ganti Google)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : _handleFaceLogin, // Panggil Fungsi Wajah
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
