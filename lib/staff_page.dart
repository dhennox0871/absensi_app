import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import 'area_page.dart'; // <--- Import Halaman Area

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  bool _isLoading = true;
  List<dynamic> _staffList = [];
  final ImagePicker _picker = ImagePicker();

  // Warna Tema Admin
  final Color _primaryColor = const Color(0xFF6A11CB);
  //final Color _secondaryColor = const Color(0xFF2575FC);

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  // --- 1. AMBIL DATA STAFF (TETAP) ---
  Future<void> _fetchStaff() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await http.get(
        Uri.parse(AppConfig.staffList),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _staffList = json['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) _showSnack("Gagal mengambil data staff", isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack("Error koneksi: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. UPDATE ROLE ADMIN (TETAP) ---
  Future<void> _updateRole(int staffId, bool isAdmin, int index) async {
    int oldRole = _staffList[index]['staffcategoryid'];
    setState(() {
      _staffList[index]['staffcategoryid'] = isAdmin ? 1 : 0;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await http.post(
        Uri.parse(AppConfig.updateRole),
        body: {
          'id': staffId.toString(),
          'is_admin': isAdmin ? '1' : '0',
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) _showSnack("Hak akses berhasil diubah!");
      } else {
        if (mounted) {
          setState(() => _staffList[index]['staffcategoryid'] = oldRole);
          _showSnack("Gagal update server.", isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _staffList[index]['staffcategoryid'] = oldRole);
        _showSnack("Gagal koneksi server.", isError: true);
      }
    }
  }

  // --- 3. REGISTER WAJAH (TETAP) ---
  Future<void> _registerFace(String staffId, String staffName) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (photo == null) return;
      if (!mounted) return;

      _showLoadingDialog("Mengupload Wajah...");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var uri = Uri.parse("${AppConfig.baseUrl}/api/admin/register-face");
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['staff_id'] = staffId;
      request.files.add(await http.MultipartFile.fromPath('image', photo.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        _showSnack("SUKSES! Wajah $staffName berhasil didaftarkan.");
      } else {
        var json = jsonDecode(response.body);
        _showSnack(json['message'] ?? "Gagal upload.", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showSnack("Error Upload: $e", isError: true);
    }
  }

  // --- 4. UPDATE DATABASE WAJAH (TETAP) ---
  Future<void> updateDatabaseWajah() async {
    _showLoadingDialog("Melatih AI Wajah...\n(Mohon Tunggu)");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/admin/sync-faces'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        _showDialogInfo("Sukses",
            "Database wajah seluruh karyawan telah diperbarui!\nSekarang login wajah akan lebih cepat.");
      } else {
        var msg = jsonDecode(response.body)['message'] ?? 'Gagal update';
        _showDialogInfo("Gagal", "Error: $msg");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showDialogInfo("Error Koneksi", e.toString());
    }
  }

  // --- HELPER UI ---
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  void _showLoadingDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
  }

  void _showDialogInfo(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Kelola Pegawai",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // TOMBOL MASTER AREA (BARU)
          IconButton(
            tooltip: "Kelola Area Penempatan",
            icon: Icon(Icons.map_outlined, color: _primaryColor),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AreaPage()));
            },
          ),
          // TOMBOL UPDATE WAJAH
          IconButton(
            tooltip: "Update DB Wajah",
            icon: const Icon(Icons.sync, color: Colors.orange),
            onPressed: updateDatabaseWajah,
          ),
          // TOMBOL REFRESH
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchStaff();
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchStaff,
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: _staffList.length,
                itemBuilder: (context, index) {
                  var staff = _staffList[index];
                  bool isAdmin = staff['staffcategoryid'].toString() == '1';
                  String name =
                      staff['name'] ?? staff['staffname'] ?? "No Name";
                  String nik = staff['staffcode'] ?? "-";
                  String position =
                      staff['position']?['description'] ?? "Staff";
                  int staffId = staff['staffid'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: isAdmin
                            ? _primaryColor.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        child: Text(
                          _getInitials(name),
                          style: TextStyle(
                            color: isAdmin ? _primaryColor : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$position • $nik",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                          // Tampilkan status admin kecil di bawah
                          if (isAdmin)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text("ADMIN",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tombol Register Wajah
                          IconButton(
                            icon: const Icon(Icons.face_retouching_natural,
                                color: Colors.green),
                            tooltip: "Daftar Wajah",
                            onPressed: () =>
                                _registerFace(staffId.toString(), name),
                          ),
                          // Switch Admin
                          Switch(
                            value: isAdmin,
                            activeThumbColor: _primaryColor,
                            onChanged: (val) =>
                                _updateRole(staffId, val, index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(" ");
    if (nameParts.isEmpty) return "";
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
  }
}
