// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'config.dart';

// Import Page Baru
import 'change_password_page.dart';
import 'about_page.dart';
import 'help_page.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Stats Real (Bulanan)
  int _statHadir = 0;
  int _statTelat = 0;
  int _statIjin = 0;
  int _statAlpha = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchMonthlyStats();
  }

  // --- LOGIKA HITUNG STATISTIK BULAN INI ---
  Future<void> _fetchMonthlyStats() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Request ke API History (Pastikan backend sudah diupdate ke startOfMonth)
      /*var response = await http.get(
        Uri.parse(AppConfig.history),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );*/

      // TAMBAHKAN ?type=month
      var response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/attendance/history?type=month"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        List data = json['data'];

        // 1. Grouping Data API
        Map<String, List> grouped = {};
        for (var item in data) {
          String dateKey = item['entrydate'].toString().split(' ')[0];
          if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
          grouped[dateKey]!.add(item);
        }

        int hadir = 0;
        int telat = 0;
        int ijin = 0;
        int alpha = 0;
        const int lateLimit = 485; // 08:05 (Toleransi)

        // 2. Loop Tanggal 1 s/d Hari Ini
        DateTime now = DateTime.now();
        int daysInMonth = now.day; // Loop sampai tanggal hari ini saja

        for (int day = 1; day <= daysInMonth; day++) {
          DateTime d = DateTime(now.year, now.month, day);
          if (d.weekday == 7) continue; // Skip Minggu

          String dateKey =
              "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
          bool isToday = (day == now.day);

          if (grouped.containsKey(dateKey)) {
            // --- ADA DATA DI TANGGAL INI ---
            List scans = grouped[dateKey]!;
            bool hasIn = false;
            bool hasOut = false;
            int earliest = 9999;
            String statusDB = "";

            for (var s in scans) {
              int shift = int.tryParse(s['shift'].toString()) ?? 0;
              int h = int.tryParse(s['shour'].toString()) ?? 0;
              int m = int.tryParse(s['sminute'].toString()) ?? 0;
              int total = h * 60 + m;
              statusDB = s['status'] ?? 'F';

              if (shift == 1) {
                hasIn = true;
                if (total < earliest) earliest = total;
              } else if (shift == 4) hasOut = true;
            }

            // Cek Ijin / Sakit (Status S/I dari database)
            if (statusDB == 'I' || statusDB == 'S') {
              ijin++;
            } else if (hasIn) {
              hadir++;
              if (earliest > lateLimit) telat++;

              // Alpha Logika (Jika tidak lengkap, dan bukan hari ini)
              if (!isToday && !hasOut) alpha++;
            }
          } else {
            // --- TIDAK ADA DATA ---
            // Jika hari berlalu (bukan hari ini), hitung Alpha
            if (!isToday) alpha++;
          }
        }

        if (mounted) {
          setState(() {
            _statHadir = hadir;
            _statTelat = telat;
            _statIjin = ijin;
            _statAlpha = alpha;
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Err Stats: $e");
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.userData['name'] ?? "User";
    String role = widget.userData['position'] != null
        ? widget.userData['position']['description']
        : "Staff";

    // Warna Avatar
    bool isAdmin = widget.userData['staffcategoryid'].toString() == '1';
    Color themeColor =
        isAdmin ? const Color(0xFF6A11CB) : const Color(0xFF4285F4);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER (MODIFIED: Solid Color, Smaller Avatar) ---
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 200, // Lebih pendek dari sebelumnya (240 -> 200)
                  decoration: const BoxDecoration(
                      // WARNA SOLID BIRU (Sama dengan Home)
                      color: Color(0xFF4285F4),
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30))),
                ),
                Positioned(
                  top: 50, // Lebih naik (sebelumnya 70)
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 30, // Lebih kecil (sebelumnya 50)
                          backgroundColor: themeColor.withValues(alpha: 0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: themeColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20, // Font sedikit diperkecil
                              fontWeight: FontWeight.bold)),
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(role,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            // --- STATISTIK BULAN INI (4 GRID) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Layout 4 Kolom Rapat
                        _statCardCompact("Hadir", "$_statHadir", Colors.green,
                            Icons.check_circle),
                        _statCardCompact(
                            "Telat", "$_statTelat", Colors.orange, Icons.timer),
                        _statCardCompact("Ijin", "$_statIjin", Colors.blue,
                            Icons.assignment),
                        _statCardCompact(
                            "Alpha", "$_statAlpha", Colors.red, Icons.cancel),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // --- MENU SETTINGS ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ]),
              child: Column(
                children: [
                  _menuItem(Icons.lock_outline_rounded, "Ganti Password", () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage()));
                  }),
                  _divider(),
                  _menuItem(Icons.info_outline_rounded, "Tentang Aplikasi", () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutPage()));
                  }),
                  _divider(),
                  _menuItem(Icons.help_outline_rounded, "Bantuan", () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HelpPage()));
                  }),
                  _divider(),
                  _menuItem(Icons.logout_rounded, "Keluar", _logout,
                      isDestructive: true),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text("Versi 1.0.0", style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey[100], indent: 60);

  // Widget Stat Card yang lebih ramping agar muat 4
  Widget _statCardCompact(
      String label, String value, Color color, IconData icon) {
    return Container(
      width: 80, // Ukuran fix agar rata
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.8), size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon,
            color: isDestructive ? Colors.red : Colors.blue, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              color: isDestructive ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 15)),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: Colors.grey[300]),
      onTap: onTap,
    );
  }
}
