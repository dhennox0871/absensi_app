import 'dart:convert';
import 'map_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color _primaryColor = const Color(0xFF6A11CB);
  final Color _secondaryColor = const Color(0xFF2575FC);

  // --- CONTROLLERS ---
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();
  double _currentRadiusVal = 0.5;

  // --- WAKTU (4 Variabel) ---
  TimeOfDay _jamMasuk = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _jamPulang = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _scanStart = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _scanEnd = const TimeOfDay(hour: 8, minute: 15);

  int _expandedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  // --- FUNGSI PILIH JAM ---
  Future<void> _pickTime(String type) async {
    TimeOfDay initial;
    switch (type) {
      case 'masuk':
        initial = _jamMasuk;
        break;
      case 'pulang':
        initial = _jamPulang;
        break;
      case 'scan_start':
        initial = _scanStart;
        break;
      case 'scan_end':
        initial = _scanEnd;
        break;
      default:
        initial = TimeOfDay.now();
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: _primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'masuk':
            _jamMasuk = picked;
            break;
          case 'pulang':
            _jamPulang = picked;
            break;
          case 'scan_start':
            _scanStart = picked;
            break;
          case 'scan_end':
            _scanEnd = picked;
            break;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(":");
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  // --- GPS & MAP ---
  Future<void> _getCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = pos.latitude.toString();
        _lngController.text = pos.longitude.toString();
      });
    } catch (e) {
      debugPrint("GPS Error");
    }
  }

  Future<void> _openMapPicker() async {
    double lat = double.tryParse(_latController.text) ?? -7.2575;
    double lng = double.tryParse(_lngController.text) ?? 112.7521;
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              MapPickerPage(initialLat: lat, initialLng: lng)),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _latController.text = result.latitude.toString();
        _lngController.text = result.longitude.toString();
      });
    }
  }

  // --- FETCH DATA ---
  Future<void> _fetchSettings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await http.get(Uri.parse(AppConfig.getSettings), headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _latController.text = data['office_lat']?.toString() ?? "-7.2575";
            _lngController.text = data['office_lng']?.toString() ?? "112.7521";

            // RADIUS 1 DESIMAL
            double radVal =
                double.tryParse(data['radius_km']?.toString() ?? "0.5") ?? 0.5;
            _currentRadiusVal = radVal;
            _radiusController.text = radVal.toStringAsFixed(1);

            if (data['work_start'] != null) {
              _jamMasuk = _parseTime(data['work_start']);
            }
            if (data['work_end'] != null) {
              _jamPulang = _parseTime(data['work_end']);
            }
            if (data['scan_start'] != null) {
              _scanStart = _parseTime(data['scan_start']);
            }
            if (data['scan_end'] != null) {
              _scanEnd = _parseTime(data['scan_end']);
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Err: $e");
    }
  }

  // --- SIMPAN DATA ---
  Future<void> _saveSettings() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Menyimpan...")));
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await http.post(
        Uri.parse(AppConfig.saveSettings),
        body: {
          'office_lat': _latController.text,
          'office_lng': _lngController.text,
          'radius_km': _radiusController.text,
          'work_start': _formatTime(_jamMasuk),
          'work_end': _formatTime(_jamPulang),
          'scan_start': _formatTime(_scanStart),
          'scan_end': _formatTime(_scanEnd),
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        _showSnack("Pengaturan Berhasil Disimpan!", Colors.green);
      } else {
        _showSnack("Gagal: ${response.body}", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnack("Error: $e", Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Header Background
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30)),
            ),
          ),

          // Header Content (JUDUL SAJA - TANPA BACK ICON)
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Row(
                children: [
                  // ICON BACK SUDAH DIHAPUS
                  Text("Pengaturan Sistem",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Main Content
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildAccordionItem(
                    index: 0,
                    title: "Lokasi & Radius",
                    icon: Icons.location_on,
                    child: _buildLocationContent()),
                const SizedBox(height: 15),
                _buildAccordionItem(
                    index: 1,
                    title: "Jam Operasional",
                    icon: Icons.access_time_filled,
                    child: _buildTimeContent()),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    child: const Text("SIMPAN PERUBAHAN",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- KONTEN JAM ---
  Widget _buildTimeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Waktu Kerja",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _buildTimeBox(
                    "Jam Masuk", _jamMasuk, 'masuk', Icons.wb_sunny_outlined)),
            const SizedBox(width: 15),
            Expanded(
                child: _buildTimeBox("Jam Pulang", _jamPulang, 'pulang',
                    Icons.nights_stay_outlined)),
          ],
        ),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
        const Text("Toleransi Absensi",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _buildTimeBox("Awal Scan (Buka)", _scanStart,
                    'scan_start', Icons.lock_open)),
            const SizedBox(width: 15),
            Expanded(
                child: _buildTimeBox("Akhir Scan (Telat)", _scanEnd, 'scan_end',
                    Icons.lock_clock)),
          ],
        ),
        const SizedBox(height: 10),
        const Text("*Absen di atas jam 'Akhir Scan' dianggap TERLAMBAT.",
            style: TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildTimeBox(
      String label, TimeOfDay time, String type, IconData icon) {
    return InkWell(
      onTap: () => _pickTime(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 5)
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_formatTime(time),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor)),
          ],
        ),
      ),
    );
  }

  // --- KONTEN LOKASI ---
  Widget _buildLocationContent() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text("GPS", style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _primaryColor),
                        foregroundColor: _primaryColor))),
            const SizedBox(width: 10),
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map, size: 16, color: Colors.white),
                    label: const Text("Peta",
                        style: TextStyle(fontSize: 11, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor))),
          ],
        ),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: _buildTF(_latController, "Lat")),
          const SizedBox(width: 10),
          Expanded(child: _buildTF(_lngController, "Lng"))
        ]),
        const SizedBox(height: 15),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Radius (M)",
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
              width: 60,
              child: TextField(
                  controller: _radiusController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                      isDense: true, contentPadding: EdgeInsets.all(5)),
                  onChanged: (v) {
                    double? n = double.tryParse(v);
                    if (n != null && n <= 5) {
                      setState(() => _currentRadiusVal = n);
                    }
                  }))
        ]),
        Slider(
            value: _currentRadiusVal,
            min: 5.0,
            max: 10.0,
            divisions: 49,
            activeColor: _primaryColor,
            onChanged: (v) {
              setState(() {
                _currentRadiusVal = v;
                _radiusController.text = v.toStringAsFixed(1);
              });
            }),
      ],
    );
  }

  // --- ACCORDION ITEM (PANAH CHEVRON DIKEMBALIKAN) ---
  Widget _buildAccordionItem(
      {required int index,
      required String title,
      required IconData icon,
      required Widget child}) {
    bool isExpanded = _expandedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isExpanded
              ? Border.all(color: _primaryColor.withValues(alpha: 0.5))
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(children: [
        InkWell(
            onTap: () => setState(() => _expandedIndex = index),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Icon(icon, color: isExpanded ? _primaryColor : Colors.grey),
                  const SizedBox(width: 15),
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16))),
                  // PANAH INI MUNCUL LAGI UNTUK NAVIGASI LIPATAN
                  Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey),
                ]))),
        if (isExpanded)
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: child),
      ]),
    );
  }

  Widget _buildTF(TextEditingController c, String h) => TextField(
      controller: c,
      decoration: InputDecoration(
          labelText: h,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0)));
}
