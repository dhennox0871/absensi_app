import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Wajib: flutter pub add intl
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoading = true;
  List<dynamic> _historyList = [];
  List<dynamic> _filteredList = [];

  // Filter Vars
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchCtrl = TextEditingController();

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

      // Panggil API History (Sesuaikan endpoint di backend bapak)
      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/attendance/history"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _historyList = data['data']; // Asumsi response: { data: [...] }
          _filteredList = _historyList;
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logika Filter Lokal (Search & Date)
  void _runFilter() {
    setState(() {
      _filteredList = _historyList.where((item) {
        // 1. Filter Nama / Info (Search Text)
        // Sesuaikan key JSON bapak, misal 'staff_name' atau 'freedescription1'
        String info = (item['freedescription1'] ?? "").toString().toLowerCase();
        bool matchText = _searchCtrl.text.isEmpty ||
            info.contains(_searchCtrl.text.toLowerCase());

        // 2. Filter Tanggal
        bool matchDate = true;
        if (_selectedDateRange != null) {
          DateTime itemDate = DateTime.parse(
              item['createdate']); // Asumsi format YYYY-MM-DD HH:mm:ss
          matchDate = itemDate.isAfter(_selectedDateRange!.start
                  .subtract(const Duration(days: 1))) &&
              itemDate.isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1)));
        }

        return matchText && matchDate;
      }).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final newRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (ctx, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: Colors.blue,
              colorScheme: const ColorScheme.light(primary: Colors.blue),
            ),
            child: child!,
          );
        });

    if (newRange != null) {
      setState(() => _selectedDateRange = newRange);
      _runFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Riwayat Absensi",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Reset Filter
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.red),
              onPressed: () {
                setState(() => _selectedDateRange = null);
                _runFilter();
              },
            )
        ],
      ),
      body: Column(
        children: [
          // --- FILTER AREA ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => _runFilter(),
                    decoration: InputDecoration(
                      hintText: "Cari Keterangan...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedDateRange != null
                          ? Colors.blue[50]
                          : Colors.white,
                      border: Border.all(
                          color: _selectedDateRange != null
                              ? Colors.blue
                              : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_month,
                        color: _selectedDateRange != null
                            ? Colors.blue
                            : Colors.grey),
                  ),
                )
              ],
            ),
          ),

          // --- LIST DATA ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(
                        child: Text("Tidak ada data ditemukan",
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          var item = _filteredList[index];
                          // Parsing Data (Sesuaikan dengan JSON API Bapak)
                          DateTime tgl = DateTime.parse(item['createdate']);
                          String jamMasuk = DateFormat('HH:mm').format(tgl);
                          String status =
                              item['status'] ?? 'Hadir'; // F = Full/Hadir

                          Color statusColor = Colors.green;
                          if (status == 'L') {
                            statusColor = Colors.orange; // Late
                          }
                          if (status == 'A') statusColor = Colors.red; // Alpha

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // TANGGAL
                                  Column(
                                    children: [
                                      Text(DateFormat('dd').format(tgl),
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      Text(DateFormat('MMM').format(tgl),
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    ],
                                  ),
                                  Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.grey[200],
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16)),

                                  // DETAIL JAM
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Scan Masuk",
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12)),
                                        Text(jamMasuk,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ],
                                    ),
                                  ),

                                  // STATUS BADGE
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text(
                                        status == 'F'
                                            ? 'Hadir'
                                            : (status == 'L'
                                                ? 'Telat'
                                                : status),
                                        style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
