import 'package:absensi_app/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Durasi splash screen 3 detik sebelum pindah ke Login
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // Desain Gradasi Modern
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Aplikasi (Ganti dengan Image.asset jika sudah ada filenya)
            //const Icon(Icons.fingerprint, size: 100, color: Colors.white),
            Image.asset("assets/images/logo_putih.png", width: 100),
            const SizedBox(height: 8),
            const Text(
              "LogMe",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const Text(
              "Attendance System",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            //const SizedBox(height: 50),
            //const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
