import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart'; // Wajib untuk peta
import 'package:latlong2/latlong.dart'; // Wajib untuk koordinat
import '../config.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoading = true;
  List _rawHistoryData = [];
  Map<String, List<dynamic>> _groupedHistory = {};
  DateTimeRange? _selectedDateRange;

  // Statistik Ringkas (Bulan Ini / Range Terpilih)
  int _statHadir = 0;
  int _statTelat = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      /*final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/attendance/history"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );*/

      // TAMBAHKAN ?type=all
      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/attendance/history?type=all"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _rawHistoryData = json['data'];
            _filterAndGroupData(); // Proses data
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

  // --- LOGIKA FILTER & GROUPING ---
  void _filterAndGroupData() {
    List filtered = _rawHistoryData;

    // 1. Filter Tanggal (Jika ada)
    if (_selectedDateRange != null) {
      filtered = _rawHistoryData.where((item) {
        DateTime date = DateTime.parse(item['entrydate']);
        return date.isAfter(
                _selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // 2. Grouping & Hitung Statistik
    _groupedHistory = {};
    _statHadir = 0; // Total scan (bukan hari)
    _statTelat = 0; // Total terlambat

    // Sort descending (terbaru diatas)
    filtered.sort((a, b) => b['entrydate'].compareTo(a['entrydate']));

    for (var item in filtered) {
      String dateKey = item['entrydate'].toString().split(' ')[0];
      if (!_groupedHistory.containsKey(dateKey)) {
        _groupedHistory[dateKey] = [];
      }
      _groupedHistory[dateKey]!.add(item);

      // Hitung Statistik Sederhana
      // Logika Terlambat Sederhana (Bisa disesuaikan logic server)
      // Misal jam masuk > 08:00 (480 menit)
      int shift = int.tryParse(item['shift'].toString()) ?? 0;
      int h = int.tryParse(item['shour'].toString()) ?? 0;
      int m = int.tryParse(item['sminute'].toString()) ?? 0;

      if (shift == 1) {
        // Masuk
        _statHadir++;
        if ((h * 60 + m) > 485) _statTelat++; // Toleransi 08:05
      }
    }
  }

  Future<void> _pickDateRange() async {
    final newRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (ctx, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: const Color(0xFF6A11CB),
              colorScheme: const ColorScheme.light(primary: Color(0xFF6A11CB)),
            ),
            child: child!,
          );
        });

    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
        _filterAndGroupData();
      });
    }
  }

  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Abu muda bersih
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _groupedHistory.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        itemCount: _groupedHistory.keys.length,
                        itemBuilder: (context, index) {
                          String dateKey =
                              _groupedHistory.keys.elementAt(index);
                          List dayScans = _groupedHistory[dateKey]!;
                          return _buildDayCard(dateKey, dayScans);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // 1. HEADER (Mirip Home View)
  Widget _buildHeader() {
    String periode = _selectedDateRange == null
        ? "Semua Riwayat"
        : "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}";

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 50, 25, 25),
      decoration: const BoxDecoration(
        color: Color(0xFF4285F4),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Riwayat Absensi",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Row(
                children: [
                  if (_selectedDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      tooltip: "Reset Filter",
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                          _filterAndGroupData();
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month_rounded,
                        color: Colors.white),
                    tooltip: "Filter Tanggal",
                    onPressed: _pickDateRange,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),

          // STATISTIK RINGKAS (PENGGANTI SEARCH)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(periode,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text("Statistik Periode Ini",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    _buildMiniStat("Hadir", "$_statHadir", Colors.greenAccent),
                    const SizedBox(width: 15),
                    _buildMiniStat("Telat", "$_statTelat", Colors.orangeAccent),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  // 2. DAY CARD (Sama persis Home View)
  Widget _buildDayCard(String date, List scans) {
    // Sort jam
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
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // HEADER TANGGAL
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
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: Color(0xFF6A11CB)),
                const SizedBox(width: 10),
                Text(_formatDate(date),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87)),
              ],
            ),
          ),

          // LIST SCAN
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
                children: scans.map((scan) => _buildScanRow(scan)).toList()),
          ),
        ],
      ),
    );
  }

  // 3. SCAN ROW (ITEM DETAIL)
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
    String timeStr =
        "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} WIB";
    String dateStr = _formatDate(scan['entrydate'].toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // JAM
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Text(
                    "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}",
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

          // INFO LOKASI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    double? dLat = double.tryParse(lat);
                    double? dLng = double.tryParse(lng);
                    if (dLat != null && dLng != null) {
                      _showMapPopup(dLat, dLng, label);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.blue[400]),
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

          // FOTO THUMBNAIL
          GestureDetector(
            onTap: () {
              if (photoName.isNotEmpty) {
                _showImagePopup(imageUrl, label, dateStr, timeStr, lat, lng);
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
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.broken_image,
                            size: 20,
                            color: Colors.grey))
                    : const Icon(Icons.image_not_supported,
                        size: 20, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- POPUP MAP ---
  void _showMapPopup(double lat, double lng, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 450,
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close)),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20)),
                  child: FlutterMap(
                    options: MapOptions(
                        initialCenter: LatLng(lat, lng), initialZoom: 16.0),
                    children: [
                      TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                              point: LatLng(lat, lng),
                              color: Colors.blue.withValues(alpha: 0.3),
                              borderColor: Colors.blue,
                              borderStrokeWidth: 2,
                              useRadiusInMeter: true,
                              radius: 100),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                              point: LatLng(lat, lng),
                              width: 80,
                              height: 80,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40)),
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

  // --- POPUP IMAGE ---
  void _showImagePopup(String imageUrl, String label, String date, String time,
      String lat, String lng) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Detail Bukti $label",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey)),
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
                      backgroundColor: const Color(0xFF6A11CB),
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
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          SizedBox(
              width: 70,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey))),
          const Text(": ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history_toggle_off_rounded,
            size: 80, color: Colors.grey[300]),
        const SizedBox(height: 10),
        const Text("Belum ada riwayat absensi.",
            style: TextStyle(color: Colors.grey))
      ],
    );
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
}
