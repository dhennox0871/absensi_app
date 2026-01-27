import 'package:absensi_app/approval_page.dart';
import 'package:absensi_app/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'staff_page.dart';

// PERBAIKAN: Nama Class harus AdminDashboardPage (sesuai panggilan Login)
class AdminDashboardPage extends StatefulWidget {
  final Map userData;
  const AdminDashboardPage({super.key, required this.userData});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  // Warna Tema Admin (Ungu - Biru Gelap)
  final Color _adminPrimary = const Color(0xFF6A11CB);
  final Color _adminSecondary = const Color(0xFF2575FC);

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildAdminHome(), // Index 0
      _buildStaffPage(), // Index 1
      _buildApprovalPage(), // Index 2
      _buildSettingsPage(), // Index 3
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- HALAMAN 1: ADMIN HOME ---
  Widget _buildAdminHome() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // HEADER GRADASI UNGU
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_adminPrimary, _adminSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 60, 25, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.admin_panel_settings,
                              color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Halo, ${widget.userData['name']}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                "Administrator Mode",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // STATISTIK
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCounterItem(
                              "Total Staff", "25", Icons.people, Colors.blue),
                          _buildCounterItem(
                              "Hadir", "18", Icons.check_circle, Colors.green),
                          _buildCounterItem(
                              "Ijin", "2", Icons.assignment, Colors.orange),
                          _buildCounterItem(
                              "Alpha", "5", Icons.cancel, Colors.red),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // AKTIVITAS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Aktivitas Terbaru",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildLogItem(
                    "Dhenny Hariyanto", "Masuk - 08:00", Colors.green),
                _buildLogItem("Budi Santoso", "Masuk - 08:15", Colors.green),
                _buildLogItem("Siti Aminah", "Ijin Sakit", Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterItem(
      String label, String count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 5),
        Text(count,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildLogItem(String name, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(Icons.person, color: color),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(status, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

// --- HALAMAN 2: STAFF (Panggil File Baru) ---
  Widget _buildStaffPage() {
    return const StaffPage();
  }

  //Widget _buildStaffPage() => const Center(child: Text("Halaman Staff"));
  Widget _buildApprovalPage() {
    return const ApprovalPage();
  }

  //Widget _buildSettingsPage() => const Center(child: Text("Halaman Setting"));
// --- HALAMAN 2: STAFF (Panggil File Baru) ---
  Widget _buildSettingsPage() {
    return const SettingsPage();
  }

  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: _adminPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Staff'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fact_check), label: 'Approval'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
    );
  }
}
