import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../config.dart';
import 'map_search_page.dart';

class AreaPage extends StatefulWidget {
  const AreaPage({super.key});

  @override
  State<AreaPage> createState() => _AreaPageState();
}

class _AreaPageState extends State<AreaPage> {
  bool _isLoading = true;
  List<dynamic> _areas = [];
  final Color _primaryColor = const Color(0xFF6A11CB);

  @override
  void initState() {
    super.initState();
    _fetchAreas();
  }

  // --- HELPER: AMBIL ID DENGAN AMAN ---
  int? _getId(Map item) {
    var val = item['areaid'] ?? item['AREAID'] ?? item['AreaId'];
    if (val != null) return int.tryParse(val.toString());
    return null;
  }

  void _showResultDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
  }

  Future<void> _fetchAreas() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/admin/areas"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (mounted) {
          setState(() => _areas = json['data']);
        }
      } else {
        _showResultDialog("Gagal Load", "Server: ${response.statusCode}");
      }
    } catch (e) {
      _showResultDialog("Error", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ERROR SYNTAX YANG BAPAK ALAMI ADA DI SINI, INI SUDAH DIPERBAIKI ---
  Future<void> _saveArea({Map? item}) async {
    int? detectedId;
    if (item != null) {
      detectedId = _getId(item);
    }

    String latVal = "";
    String lngVal = "";

    // PERBAIKAN: MENGGUNAKAN KURUNG KURAWAL { } UNTUK SEMUA IF
    if (item != null) {
      if (item['latitude1'] != null) {
        latVal = item['latitude1'].toString();
      } else if (item['latitude'] != null) {
        latVal = item['latitude'].toString();
      }

      if (item['longitude1'] != null) {
        lngVal = item['longitude1'].toString();
      } else if (item['longitude'] != null) {
        lngVal = item['longitude'].toString();
      }
    }

    if (latVal.toLowerCase() == "null") {
      latVal = "";
    }
    if (lngVal.toLowerCase() == "null") {
      lngVal = "";
    }

    final codeCtrl = TextEditingController(text: item?['areacode'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final latCtrl = TextEditingController(text: latVal);
    final lngCtrl = TextEditingController(text: lngVal);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title:
            Text(item == null ? "Tambah Area" : "Edit Area (ID: $detectedId)"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                      labelText: "Kode Area", isDense: true)),
              const SizedBox(height: 10),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: "Nama Lokasi", isDense: true)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          Position pos = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high);
                          latCtrl.text = pos.latitude.toString();
                          lngCtrl.text = pos.longitude.toString();
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text("GPS Gagal")));
                          }
                        }
                      },
                      icon: const Icon(Icons.my_location, size: 14),
                      label: const Text("GPS", style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        double initLat = double.tryParse(latCtrl.text) ?? -6.2;
                        double initLng = double.tryParse(lngCtrl.text) ?? 106.8;
                        final LatLng? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MapSearchPage(
                                    initialLat: initLat, initialLng: initLng)));
                        if (result != null) {
                          latCtrl.text = result.latitude.toString();
                          lngCtrl.text = result.longitude.toString();
                        }
                      },
                      icon:
                          const Icon(Icons.map, size: 14, color: Colors.white),
                      label: const Text("Peta",
                          style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: latCtrl,
                        decoration: const InputDecoration(
                            labelText: "Lat", isDense: true))),
                const SizedBox(width: 5),
                Expanded(
                    child: TextField(
                        controller: lngCtrl,
                        decoration: const InputDecoration(
                            labelText: "Lng", isDense: true))),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _submitData(
                  id: detectedId,
                  code: codeCtrl.text,
                  desc: descCtrl.text,
                  lat: latCtrl.text,
                  lng: lngCtrl.text);
            },
            child: const Text("SIMPAN"),
          )
        ],
      ),
    );
  }

  // --- SAVE DATA VIA POST ---
  Future<void> _submitData(
      {int? id,
      required String code,
      required String desc,
      required String lat,
      required String lng}) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // POST KE /save
      var uri = Uri.parse("${AppConfig.baseUrl}/api/admin/areas/save");
      var request = http.Request("POST", uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      });

      request.body = jsonEncode({
        'areaid': id,
        'areacode': code,
        'description': desc,
        'latitude1': lat,
        'longitude1': lng
      });

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return; // <-- CEK MOUNTED (FIX ASYNC GAP)
      Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var json = jsonDecode(response.body);
        _fetchAreas();
        _showResultDialog("Hasil", json['message'] ?? "Sukses");
      } else {
        _showResultDialog(
            "Gagal Simpan", "Code: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showResultDialog("Error App", e.toString());
    }
  }

  // --- DELETE AREA VIA POST ---
  Future<void> _deleteArea(Map item) async {
    int? id = _getId(item);
    if (id == null) {
      _showResultDialog("Error", "ID Area tidak terbaca!");
      return;
    }

    bool confirm = await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text("Hapus Data"),
                  content: Text("Hapus area '${item['description']}'?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Batal")),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Hapus",
                            style: TextStyle(color: Colors.red))),
                  ],
                )) ??
        false;

    if (!confirm) return;

    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // POST KE /delete
      var uri = Uri.parse("${AppConfig.baseUrl}/api/admin/areas/delete");
      var request = http.Request("POST", uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      });

      request.body = jsonEncode({'areaid': id});

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return; // <-- CEK MOUNTED (FIX ASYNC GAP)
      Navigator.pop(context);

      if (response.statusCode == 200) {
        _fetchAreas();
        _showResultDialog("Berhasil", "Data Terhapus");
      } else {
        _showResultDialog("Gagal Hapus", response.body);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showResultDialog("Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Master Area Penempatan",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAreas)
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saveArea(),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _areas.isEmpty
              ? const Center(child: Text("Belum ada data"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _areas.length,
                  itemBuilder: (context, index) {
                    var item = _areas[index];

                    var lat = item['latitude1'] ?? item['latitude'];
                    var lng = item['longitude1'] ?? item['longitude'];

                    String latStr = (lat != null && lat.toString() != "null")
                        ? lat.toString()
                        : "-";
                    String lngStr = (lng != null && lng.toString() != "null")
                        ? lng.toString()
                        : "-";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: const Icon(Icons.location_city,
                              color: Colors.blue),
                        ),
                        title: Text(item['description'] ?? "-",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Lat: $latStr, Lng: $lngStr",
                            style: const TextStyle(fontSize: 12)),
                        trailing: PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'edit') _saveArea(item: item);
                            if (value == 'delete') {
                              _deleteArea(item); // KIRIM ITEM UTUH
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text("Edit")),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Text("Hapus",
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
