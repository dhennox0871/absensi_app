import 'dart:io';
import 'package:absensi_app/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home_view.dart'; // Pastikan file ini ada
import 'face_scan_page.dart'; // Pastikan file ini ada

class DashboardPage extends StatefulWidget {
  final Map userData;
  const DashboardPage({super.key, required this.userData});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeView(userData: widget.userData), // Index 0: Home
      const Center(child: Text("Halaman History")), // Index 1
      const Center(child: Text("Halaman Ijin")), // Index 2
      const Center(child: Text("Halaman Profile")), // Index 3
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- 1. FUNGSI TOMBOL SCAN TENGAH ---
  void _onScanPressed() async {
    // Buka Halaman Scan Wajah
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceScanPage()),
    );

    // Jika berhasil scan & bawa data
    if (result != null && result is Map && result['status'] == 'success') {
      File image = result['image'];
      double lat = result['latitude'];
      double long = result['longitude'];

      // Tampilkan Dialog Konfirmasi (Versi Baru)
      _showConfirmationDialog(image, lat, long);
    }
  }

  // --- 2. DIALOG KONFIRMASI (VERSI BARU: Ada Jam & Tombol X) ---
  void _showConfirmationDialog(File image, double lat, double long) {
    // Format Tanggal & Jam Manual
    DateTime now = DateTime.now();
    List<String> months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Ags",
      "Sep",
      "Okt",
      "Nov",
      "Des"
    ];
    String dateStr = "${now.day} ${months[now.month]} ${now.year}";
    String timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Konfirmasi Kehadiran",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    // FOTO HASIL SCAN
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(image,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),

                    const SizedBox(height: 15),

                    // INFO LOKASI
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Lokasi: $lat, $long",
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // INFO TANGGAL & JAM (SESUAI REQUEST)
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled,
                            color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "$dateStr • Jam $timeStr",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // TOMBOL AKSI
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context); // Tutup dialog
                              _onScanPressed(); // Ulangi Scan
                            },
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: const Text("Ulangi Foto",
                                style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Tutup dialog
                              _uploadAbsensi(image, lat, long); // KIRIM DATA
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("KIRIM ABSEN",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // TOMBOL CLOSE (X) di Pojok Kanan Atas (SESUAI REQUEST)
              Positioned(
                right: 5,
                top: 5,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. FUNGSI UPLOAD KE SERVER ---
  Future<void> _uploadAbsensi(File image, double lat, double long) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // ⚠️ PASTIKAN IP INI SESUAI LAPTOP (cek ipconfig)
      var uri = Uri.parse(AppConfig.attendance);

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['latitude'] = lat.toString();
      request.fields['longitude'] = long.toString();

      var pic = await http.MultipartFile.fromPath('image', image.path);
      request.files.add(pic);

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (!mounted) return;
      Navigator.pop(context); // Tutup Loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(
            "Gagal Absen (${response.statusCode}):\n$responseBody");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog("Terjadi kesalahan koneksi: $e");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Berhasil", style: TextStyle(color: Colors.green)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 10),
            Text("Absensi berhasil disimpan!"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gagal", style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _pages[_selectedIndex],

      // TOMBOL SCAN TENGAH
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: _onScanPressed,
          backgroundColor: const Color(0xFF4285F4),
          elevation: 10,
          shape: const CircleBorder(),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner_rounded,
                  size: 30, color: Colors.white),
              Text("Scan", style: TextStyle(fontSize: 10, color: Colors.white)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // NAVIGASI BAWAH
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem(
                      icon: Icons.home_rounded, label: "Home", index: 0),
                  _buildNavItem(
                      icon: Icons.history_rounded, label: "History", index: 1),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem(
                      icon: Icons.mail_outline_rounded,
                      label: "Ijin",
                      index: 2),
                  _buildNavItem(
                      icon: Icons.person_outline_rounded,
                      label: "Profile",
                      index: 3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return MaterialButton(
      minWidth: 40,
      onPressed: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isSelected ? const Color(0xFF4285F4) : Colors.grey,
              size: 28),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4285F4) : Colors.grey,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
