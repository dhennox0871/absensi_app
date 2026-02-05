import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tentang Aplikasi")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/logo_icon.png", height: 100),
            const SizedBox(height: 20),
            const Text("Absensi Mobile App",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Versi 1.0.0", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                  "Aplikasi absensi mobile dengan fitur GPS Geofencing dan Face Recognition untuk memudahkan pencatatan kehadiran karyawan.",
                  textAlign: TextAlign.center),
            ),
            const Spacer(),
            const Text("© 2026 PT. Density Data Digital",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
