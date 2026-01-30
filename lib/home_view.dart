import 'dart:convert';
import 'dart:io';
import 'package:absensi_app/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
// TAMBAHAN IMPORT UNTUK MAP
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'config.dart';

class HomeView extends StatefulWidget {
  final Map userData;

  const HomeView({super.key, required this.userData});

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  List _rawHistoryData = [];
  Map<String, List<dynamic>> _groupedHistory = {};
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // --- 1. FETCH DATA & GROUPING ---
  Future<void> _fetchHistory() async {
    // Tambahkan setState loading agar user tau sedang refresh
    if (mounted) setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      var url = Uri.parse(AppConfig.history);

      var response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _rawHistoryData = json['data'];
            _groupDataByDate(_rawHistoryData);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _groupDataByDate(List data) {
    _groupedHistory = {};
    for (var item in data) {
      String dateKey = item['entrydate'].toString().split(' ')[0];
      if (!_groupedHistory.containsKey(dateKey)) {
        _groupedHistory[dateKey] = [];
      }
      _groupedHistory[dateKey]!.add(item);
    }
  }

  // --- 2. LOGIKA ABSENSI (TIDAK DIUBAH) ---
  Future<void> handleAttendance() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      _showSnack("Mohon aktifkan GPS.", Colors.orange);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      _showSnack("Izin lokasi ditolak permanen.", Colors.red);
      return;
    }

    if (!mounted) return;
    _showLoadingDialog("Mencari Lokasi...");

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack("Gagal ambil lokasi.", Colors.red);
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 40,
      );

      if (photo == null) return;

      if (!mounted) return;
      _submitAttendance(File(photo.path), position);
    } catch (e) {
      _showSnack("Gagal membuka kamera: $e", Colors.red);
    }
  }

  Future<void> _submitAttendance(File imageFile, Position pos) async {
    _showLoadingDialog("Mengirim Data...");
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var request = http.MultipartRequest(
          'POST', Uri.parse("${AppConfig.baseUrl}/api/attendance"));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['latitude'] = pos.latitude.toString();
      request.fields['longitude'] = pos.longitude.toString();
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        var respData = jsonDecode(response.body);
        _showSuccessDialog("Absen Berhasil",
            "Shift Terdeteksi: ${respData['shift_detect'] ?? '-'}");

        // FITUR 1: Update list history setelah sukses
        _fetchHistory();
      } else {
        var err = jsonDecode(response.body);
        _showSnack(err['message'] ?? "Gagal", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack("Error: $e", Colors.red);
    }
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopSection(context),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Aktivitas Minggu Ini",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              // FITUR 2: Tombol Refresh & Lihat Semua
              Row(
                children: [
                  IconButton(
                    onPressed: _fetchHistory,
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    tooltip: "Refresh History",
                  ),
                  /*Text("Lihat Semua",
                      style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600)),*/
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _groupedHistory.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                      itemCount: _groupedHistory.keys.length,
                      itemBuilder: (context, index) {
                        String dateKey = _groupedHistory.keys.elementAt(index);
                        List dayScans = _groupedHistory[dateKey]!;
                        return _buildDayCard(dateKey, dayScans);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDayCard(String date, List scans) {
    scans.sort((a, b) {
      int hA = int.tryParse(a['shour'].toString()) ?? 0;
      int hB = int.tryParse(b['shour'].toString()) ?? 0;
      return hA.compareTo(hB);
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.blue),
                const SizedBox(width: 10),
                Text(_formatDate(date),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text("Hadir",
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
                children: scans.map((scan) => _buildScanRow(scan)).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildScanRow(dynamic scan) {
    int h = int.tryParse(scan['shour'].toString()) ?? 0;
    int m = int.tryParse(scan['sminute'].toString()) ?? 0;
    int shift = int.tryParse(scan['shift'].toString()) ?? 1;
    String photoName = scan['freedescription1'] ?? '';

    String lat = scan['freedescription3']?.toString() ?? '-';
    String lng = scan['freedescription2']?.toString() ?? '-';

    String label = "Masuk";
    Color color = Colors.blue;

    if (shift == 4) {
      label = "Pulang";
      color = Colors.orange;
    } else if (shift == 2) {
      label = "Keluar Istirahat";
      color = Colors.grey;
    } else if (shift == 3) {
      label = "Masuk Istirahat";
      color = Colors.grey;
    }

    String imageUrl = "${AppConfig.baseUrl}/storage/attendance/$photoName";

    String timeStr = "${_formatTime(h, m)} WIB";
    String dateStr = _formatDate(scan['entrydate'].toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Text(_formatTime(h, m),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14)),
                Text("WIB",
                    style: TextStyle(
                        color: color.withValues(alpha: 0.8), fontSize: 10))
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),

                // FITUR 3: Tombol Lokasi Terdata (Clickable)
                InkWell(
                  onTap: () {
                    double? dLat = double.tryParse(lat);
                    double? dLng = double.tryParse(lng);
                    if (dLat != null && dLng != null) {
                      _showMapPopup(dLat, dLng, label);
                    } else {
                      _showSnack("Lokasi tidak valid", Colors.red);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Agar tidak memenuhi baris
                    children: [
                      Icon(Icons.location_on,
                          size: 14,
                          color: Colors.blue[
                              400]), // Ubah warna jadi biru biar terlihat clickable
                      const SizedBox(width: 4),
                      Text("Lokasi Terdata (Klik)",
                          style: TextStyle(
                              color: Colors.blue[400],
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (photoName.isNotEmpty) {
                _showImagePopup(imageUrl, label, dateStr, timeStr, lat, lng);
              } else {
                _showSnack("Foto tidak tersedia", Colors.grey);
              }
            },
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: photoName.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image,
                              size: 20, color: Colors.grey);
                        },
                      )
                    : const Icon(Icons.image_not_supported,
                        size: 20, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FITUR 3: FUNGSI POPUP MAP RADIUS 100M ---
  void _showMapPopup(double lat, double lng, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          height: 450,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              // Header Map
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Lokasi: $title",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close)),
                  ],
                ),
              ),
              // Map View
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15)),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(lat, lng), // Titik Absen
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.absensi.dhenny', // Ganti dengan package name app anda
                      ),
                      // Layer Radius 100M
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(lat, lng),
                            color: Colors.blue.withValues(alpha: 0.3),
                            borderColor: Colors.blue,
                            borderStrokeWidth: 2,
                            useRadiusInMeter: true,
                            radius: 100, // Radius 100 Meter
                          ),
                        ],
                      ),
                      // Layer Marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 40),
                          ),
                        ],
                      ),
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

  // --- TOP SECTION & HELPER FUNCTIONS (TIDAK DIUBAH SIGNIFIKAN) ---
  Widget _buildTopSection(BuildContext context) {
    int hariHadir = _groupedHistory.keys.length;
    return Stack(
      children: [
        Container(
          height: 180,
          decoration: const BoxDecoration(
              color: Color(0xFF4285F4),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 50, 25, 0),
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
                        image: const DecorationImage(
                            image: AssetImage("assets/images/logo_app.png"),
                            fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Halo, ${widget.userData['name'] ?? 'User'}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          Text(
                              widget.userData['position'] != null
                                  ? widget.userData['position']['description']
                                  : "Staff",
                              style: const TextStyle(color: Colors.white70),
                              overflow: TextOverflow.ellipsis),
                        ]),
                  ),
                  IconButton(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF2575FC).withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("Hadir", "$hariHadir", Icons.check_circle),
                    _buildStatItem(
                        "Terlambat", "0", Icons.warning_amber_rounded),
                    _buildStatItem("Alpha", "0", Icons.cancel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showImagePopup(String imageUrl, String label, String date, String time,
      String lat, String lng) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Detail Bukti $label",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              Icon(Icons.broken_image,
                                  size: 50, color: Colors.grey),
                              Text("Gagal memuat gambar")
                            ])));
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.calendar_today, "Tanggal", date),
              _buildInfoRow(Icons.access_time, "Waktu", time),
              _buildInfoRow(Icons.location_on, "Lokasi", "$lat, $lng"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text("Tutup",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const Text(": ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history, size: 80, color: Colors.grey[300]),
      const SizedBox(height: 10),
      const Text("Belum ada riwayat absensi minggu ini.",
          style: TextStyle(color: Colors.grey))
    ]);
  }

  Widget _buildStatItem(String label, String count, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white, size: 28),
      const SizedBox(height: 5),
      Text(count,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))
    ]);
  }

  String _formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
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
      List<String> days = [
        "",
        "Senin",
        "Selasa",
        "Rabu",
        "Kamis",
        "Jumat",
        "Sabtu",
        "Minggu"
      ];
      return "${days[dt.weekday]}, ${dt.day} ${months[dt.month]} ${dt.year}";
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(int h, int m) =>
      "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";

  void _showLoadingDialog(String msg) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
                content: Row(children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(msg)
            ])));
  }

  void _showSuccessDialog(String title, String content) {
    showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
                icon: const Icon(Icons.check_circle,
                    color: Colors.green, size: 50),
                title: Text(title),
                content: Text(content, textAlign: TextAlign.center),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"))
                ]));
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Yakin ingin keluar?"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal")),
                  TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                            (route) => false);
                      },
                      child:
                          const Text("Ya", style: TextStyle(color: Colors.red)))
                ]));
  }
}
