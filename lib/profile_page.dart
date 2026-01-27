import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_page.dart'; // Import Login untuk Logout

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Dummy Stats (Nanti bisa load dari API dashboard)
  final Map<String, String> stats = {
    'Hadir': '20',
    'Telat': '2',
    'Ijin': '1',
    'Alpha': '0'
  };

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
    // Foto Profil default jika null
    String? photoUrl =
        widget.userData['photo_url']; // Pastikan backend kirim ini

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER CURVE ---
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 220,
                  decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40))),
                ),
                Positioned(
                  top: 60,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? const Icon(Icons.person,
                                  size: 50, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text(role,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            // --- STATISTIK BULAN INI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statCard("Hadir", stats['Hadir']!, Colors.green),
                  _statCard("Telat", stats['Telat']!, Colors.orange),
                  _statCard("Ijin", stats['Ijin']!, Colors.blue),
                  _statCard("Alpha", stats['Alpha']!, Colors.red),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- MENU SETTINGS ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  _menuItem(Icons.lock_outline, "Ubah Password", () {
                    /* Navigasi Ubah Pass */
                  }),
                  const Divider(height: 1),
                  _menuItem(Icons.info_outline, "Tentang Aplikasi", () {}),
                  const Divider(height: 1),
                  _menuItem(Icons.help_outline, "Bantuan", () {}),
                  const Divider(height: 1),
                  _menuItem(Icons.logout, "Keluar", _logout,
                      isDestructive: true),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text("Versi 1.0.0", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon,
            color: isDestructive ? Colors.red : Colors.blue, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              color: isDestructive ? Colors.red : Colors.black87,
              fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
