import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config.dart';
import '../login_page.dart';

// Import Page Admin Lainnya
import 'staff_page.dart';
import 'approval_page.dart';
import 'settings_page.dart'; // Buat nanti

class AdminDashboardPage extends StatefulWidget {
  final Map userData;
  const AdminDashboardPage({super.key, required this.userData});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // State Data
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'total_staff': 0,
    'hadir': 0,
    'ijin': 0,
    'alpha': 0
  };
  List _activities = [];

  // Bottom Nav Index
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Pastikan URL ini benar & bisa diakses browser HP
      var response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/admin/dashboard"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _stats = json['stats'];
            _activities = json['activities'];
            _isLoading = false;
          });
        }
      } else {
        // TAMPILKAN ERROR JIKA SERVER GAGAL (Misal Error 500)
        debugPrint("Server Error: ${response.body}");
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Gagal memuat data: Kode ${response.statusCode}")));
        }
      }
    } catch (e) {
      debugPrint("Koneksi Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        // TAMPILKAN PESAN ERROR KONEKSI
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Koneksi Error: $e")));
      }
    }
  }

  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    // List Halaman untuk Bottom Nav
    final List<Widget> pages = [
      _buildHomeContent(), // Index 0: Home Dashboard
      const StaffPage(), // Index 1: Kelola Staff
      const ApprovalPage(), // Index 2: Approval Ijin
      const SettingsPage(), // Index 3
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6A11CB),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded), label: "Staff"),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_turned_in_rounded),
              label: "Approval"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded), label: "Setting"),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    // Grouping Data
    Map<String, List> groupedActivities = {};
    for (var item in _activities) {
      String name = item['name'] ?? 'Unknown';
      if (!groupedActivities.containsKey(name)) {
        groupedActivities[name] = [];
      }
      groupedActivities[name]!.add(item);
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Aktivitas Hari Ini",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  IconButton(
                    onPressed: _fetchDashboardData,
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    tooltip: "Refresh Data",
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator())
                : groupedActivities.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: groupedActivities.length,
                        itemBuilder: (context, index) {
                          String name = groupedActivities.keys.elementAt(index);
                          List logs = groupedActivities[name]!;
                          return _buildStaffCard(name, logs);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  // --- KARTU STAFF (FIXED: toList dihapus, withOpacity diganti) ---
  Widget _buildStaffCard(String name, List logs) {
    String initial = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                // FIX: Ganti withOpacity -> withValues
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  // FIX: Ganti withOpacity -> withValues
                  backgroundColor:
                      const Color(0xFF6A11CB).withValues(alpha: 0.1),
                  child: Text(initial,
                      style: const TextStyle(
                          color: Color(0xFF6A11CB),
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          // FIX: Hapus .toList() di sini karena pakai spread operator (...)
          ...logs.map((log) => _buildLogSubItem(log)),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- SUB ITEM (FIXED: TIPE DATA & PARSING) ---
  Widget _buildLogSubItem(Map item) {
    // 1. Parsing Waktu (Aman untuk String/Int)
    String time =
        "${item['shour'].toString().padLeft(2, '0')}:${item['sminute'].toString().padLeft(2, '0')}";

    // 2. Parsing Status
    String status = item['status'] ?? 'F';

    // 3. FIX CRASH: Parse Shift secara aman (String "1" -> Int 1)
    int shift = int.tryParse(item['shift'].toString()) ?? 1;

    // --- LOGIKA WARNA ---
    String label = "Masuk";
    Color labelColor = Colors.green;
    // Gunakan withValues agar modern & tidak warning
    Color timeBgColor = Colors.green.withValues(alpha: 0.1);

    if (status == 'I') {
      label = "Ijin";
      labelColor = Colors.orange;
      timeBgColor = Colors.orange.withValues(alpha: 0.1);
    } else if (status == 'S') {
      label = "Sakit";
      labelColor = Colors.orange;
      timeBgColor = Colors.orange.withValues(alpha: 0.1);
    } else if (status == 'L') {
      label = "Telat";
      labelColor = Colors.red;
      timeBgColor = Colors.red.withValues(alpha: 0.1);
    } else if (shift == 4) {
      // Shift 4 biasanya Pulang
      label = "Pulang";
      labelColor = Colors.blue;
      timeBgColor = Colors.blue.withValues(alpha: 0.1);
    }

    // --- DATA PENDUKUNG ---
    String photoName = item['freedescription1'] ?? '';
    String imageUrl = "${AppConfig.baseUrl}/storage/attendance/$photoName";
    String lat = item['freedescription3'] ?? '';
    String lng = item['freedescription2'] ?? '';

    // --- TAMPILAN ---
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KOTAK JAM
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: timeBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(time,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                        fontSize: 16)),
                Text("WIB", style: TextStyle(fontSize: 10, color: labelColor)),
              ],
            ),
          ),
          const SizedBox(width: 15),

          // INFO LABEL & LOKASI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 5),
                InkWell(
                  onTap: () {
                    double? dLat = double.tryParse(lat);
                    double? dLng = double.tryParse(lng);
                    if (dLat != null && dLng != null) {
                      _showMapPopup(dLat, dLng, item['name']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Lokasi tidak tersedia")));
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                          (lat.isNotEmpty && lng.isNotEmpty)
                              ? "Lihat Lokasi"
                              : "Tanpa Lokasi",
                          style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              decoration: TextDecoration.underline)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // FOTO THUMBNAIL
          if (photoName.isNotEmpty)
            GestureDetector(
              onTap: () =>
                  _showImagePopup(imageUrl, item['name'], "$label - $time"),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                    image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (e, s) =>
                            const AssetImage("assets/images/logo_icon.png"))),
              ),
            )
        ],
      ),
    );
  }

  // 1. HEADER (Gradient + Stats)
  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
          child: Column(
            children: [
              // Info User
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.admin_panel_settings,
                          color: Color(0xFF6A11CB)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Halo, ${widget.userData['name']}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const Text("Administrator Mode",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => _logout(),
                  )
                ],
              ),
              const SizedBox(height: 25),

              // Kartu Statistik Putih Mengambang
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Total Staff", "${_stats['total_staff']}",
                        Colors.blue, Icons.people),
                    _buildStatItem("Hadir", "${_stats['hadir']}", Colors.green,
                        Icons.check_circle),
                    _buildStatItem("Ijin", "${_stats['ijin']}", Colors.orange,
                        Icons.assignment),
                    _buildStatItem("Alpha", "${_stats['alpha']}", Colors.red,
                        Icons.cancel),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildStatItem(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("Belum ada aktivitas hari ini",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // POPUP MAP
  void _showMapPopup(double lat, double lng, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 400,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Lokasi: $title",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close)),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: FlutterMap(
                    options: MapOptions(
                        initialCenter: LatLng(lat, lng), initialZoom: 15.0),
                    children: [
                      TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                      MarkerLayer(markers: [
                        Marker(
                            point: LatLng(lat, lng),
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 40))
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // POPUP FOTO
  void _showImagePopup(String url, String title, String time) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text("Waktu: $time WIB",
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(url, fit: BoxFit.contain),
              ),
              const SizedBox(height: 15),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false);
  }
}
