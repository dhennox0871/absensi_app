import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart'; // TIDAK PERLU LAGI
import '../config.dart';

class KioskPage extends StatefulWidget {
  const KioskPage({super.key});

  @override
  State<KioskPage> createState() => _KioskPageState();
}

class _KioskPageState extends State<KioskPage> {
  CameraController? _controller;
  bool _isProcessing = false;
  // String? _token; // SUDAH DIHAPUS BIAR GAK WARNING
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initKiosk();
  }

  Future<void> _initKiosk() async {
    // Token tidak perlu diambil lagi karena route sudah Public

    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      // Prioritas Kamera Depan (Index 1)
      var cam = _cameras!.length > 1 ? _cameras![1] : _cameras![0];
      _controller =
          CameraController(cam, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // --- 1. SCAN WAJAH ---
  Future<void> _scanWajah() async {
    if (_isProcessing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }
    setState(() => _isProcessing = true);

    try {
      final image = await _controller!.takePicture();
      Position position = await Geolocator.getCurrentPosition();

      if (!mounted) return;
      _showLoading("Memindai Wajah...");

      var uri = Uri.parse("${AppConfig.baseUrl}/api/kiosk/scan");
      var request = http.MultipartRequest('POST', uri);

      request.fields['lat'] = position.latitude.toString();
      request.fields['lng'] = position.longitude.toString();
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      Navigator.pop(context); // Tutup Loading

      if (response.statusCode == 200) {
        if (response.body.trim().startsWith("<")) {
          _showHtmlError(response.body);
        } else {
          var data = jsonDecode(response.body)['data'];
          _showConfirmDialog(data, image.path, position);
        }
      } else {
        try {
          var msg = jsonDecode(response.body)['message'] ?? 'Gagal Scan';
          _showError("Gagal: $msg");
        } catch (e) {
          _showHtmlError(response.body);
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showError("Error System: $e");
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- 2. SUBMIT FINAL ---
  Future<void> _submitFinal(
      String staffId, String imagePath, Position pos) async {
    _showLoading("Menyimpan...");
    try {
      var uri = Uri.parse("${AppConfig.baseUrl}/api/kiosk/submit");
      var request = http.MultipartRequest('POST', uri);

      request.fields['staff_id'] = staffId;
      request.fields['latitude'] = pos.latitude.toString();
      request.fields['longitude'] = pos.longitude.toString();
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      var res = await http.Response.fromStream(await request.send());

      if (!mounted) return;
      Navigator.pop(context);

      if (res.statusCode == 200) {
        var body = jsonDecode(res.body);
        _showSuccess(body['message'], body['detail']);
      } else {
        try {
          var body = jsonDecode(res.body);
          _showError("Gagal Submit: ${body['message']}");
        } catch (e) {
          _showError("Gagal Submit: ${res.statusCode}");
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showError(e.toString());
    }
  }

  // --- 3. SHOW LIST ABSENSI HARI INI ---
  void _showTodayList() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => FutureBuilder(
              future:
                  http.get(Uri.parse("${AppConfig.baseUrl}/api/kiosk/today")),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
                  return const Center(child: Text("Gagal memuat data."));
                }

                var list = jsonDecode(snapshot.data!.body)['data'] as List;

                return Column(
                  children: [
                    const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text("Absensi Hari Ini",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18))),
                    const Divider(),
                    Expanded(
                      child: list.isEmpty
                          ? const Center(child: Text("Belum ada yang absen."))
                          : ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, i) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage:
                                      NetworkImage(list[i]['foto_url']),
                                  onBackgroundImageError: (_, __) =>
                                      const Icon(Icons.person),
                                ),
                                title: Text(list[i]['nama'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text("Pukul ${list[i]['jam']}"),
                                trailing: const Icon(Icons.check_circle,
                                    color: Colors.green),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ));
  }

  // --- UI HELPER ---
  void _showHtmlError(String html) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Server Error"),
              content: SizedBox(
                  height: 200, child: SingleChildScrollView(child: Text(html))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup"))
              ],
            ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showLoading(String msg) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => AlertDialog(
                content: Row(children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(msg)
            ])));
  }

  void _showConfirmDialog(Map data, String path, Position pos) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        Image.file(File(path), height: 180, fit: BoxFit.cover)),
                const SizedBox(height: 15),
                Text(data['staff_name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center),
                Text(data['jabatan'] ?? "-", textAlign: TextAlign.center),
                const Divider(),
                Text("${data['jam']}",
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Batal",
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () {
                      Navigator.pop(context);
                      _submitFinal(data['staff_id'].toString(), path, pos);
                    },
                    child: const Text("ABSEN SEKARANG",
                        style: TextStyle(color: Colors.white)))
              ],
            ));
  }

  void _showSuccess(String msg, Map detail) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title:
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
              content: Text("$msg\n\n${detail['nama']}\n${detail['jam']}",
                  textAlign: TextAlign.center),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),
          Positioned(
              top: 40,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
              )),
          Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.list_alt, color: Colors.blue),
                  onPressed: _showTodayList,
                  tooltip: "Lihat yang sudah absen",
                ),
              )),
          Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _scanWajah,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4)),
                    child: const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt,
                            size: 35, color: Colors.blue)),
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
