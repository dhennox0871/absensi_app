import 'dart:convert';
//import 'package:absensi_app/setting_ip_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

// IMPORT DUA DASHBOARD BERBEDA
import 'dashboard_page.dart'; // Dashboard User Biasa
import 'admin_dashboard_page.dart'; // Dashboard Admin

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
  bool _isAdminLogin = false; // Checkbox Admin

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
          'is_admin': _isAdminLogin ? '1' : '0', // Kirim status checkbox
        },
        headers: {'Accept': 'application/json'},
      );

      var json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // --- LOGIN SUKSES ---
        String token = json['access_token'];
        Map<String, dynamic> user = json['user'];

        // Simpan sesi ke HP
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(user));

        if (!mounted) return;

        // --- LOGIKA PEMISAH HALAMAN (ROUTING) ---
        Widget targetPage;

        // Kita cek status CHECKBOX (_isAdminLogin), bukan cuma databasenya.
        if (_isAdminLogin == true) {
          // Jika user mencentang "Administrator", arahkan ke Admin Dashboard
          // (Backend sudah memastikan hanya user staffcategoryid=1 yang bisa lolos ke sini)
          targetPage = AdminDashboardPage(userData: user);
        } else {
          // Jika TIDAK mencentang, arahkan ke User Dashboard (Absen Biasa)
          // Tidak peduli apakah dia Staff atau Admin, kalau login biasa ya masuk dashboard biasa
          targetPage = DashboardPage(userData: user);
        }

        // Pindah Halaman & Hapus Riwayat Login (agar tidak bisa back)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      } else {
        // --- LOGIN GAGAL ---
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gagal Masuk"),
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
      // TAMBAHKAN APP BAR INI
      /*appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            tooltip: "Setting IP Server",
            onPressed: () {
              // Buka Halaman Setting IP
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingIpPage()),
              );
            },
          )
        ],
      ),*/
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // ILUSTRASI / GAMBAR
              Center(
                child: Image.asset(
                  "assets/images/login_illustration.png",
                  height: 200,
                  // Error Builder (jika gambar tidak ketemu, muncul icon)
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

              // TOMBOL LOGIN
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

              // SEPARATOR GOOGLE
              Row(children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("OR", style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ]),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () {},
                icon:
                    const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                label: const Text("Masuk dengan Google",
                    style: TextStyle(color: Colors.black)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
