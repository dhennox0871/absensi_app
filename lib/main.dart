import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'login_page.dart'; // <--- Panggil file Login yang sudah Anda amankan tadi

// 1. Variabel Global Kamera (Agar bisa diakses FaceScanPage)
List<CameraDescription> cameras = [];

Future<void> main() async {
  // 2. Wajib ada sebelum akses hardware
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 3. Cek Kamera yang tersedia di HP
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // 4. Arahkan ke Login Page
      home: const LoginPage(),
    );
  }
}
