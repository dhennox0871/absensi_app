import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import 'area_page.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  bool _isLoading = true;
  List<dynamic> _staffList = [];
  List<dynamic> _areaList = [];
  final ImagePicker _picker = ImagePicker();

  // Warna Tema (Sesuai Screenshot Admin Home)
  final Color _primaryColor = const Color(0xFF6A11CB); // Ungu Admin
  final Color _secondaryColor = const Color(0xFF2575FC); // Biru Gradient

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ===========================================================================
  // 1. LOGIC LOAD DATA
  // ===========================================================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchStaff(),
      _fetchAreas(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchStaff() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      var response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/admin/staff"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (mounted) setState(() => _staffList = json['data']);
      }
    } catch (e) {
      debugPrint("Err Staff: $e");
    }
  }

  Future<void> _fetchAreas() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      var response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/admin/areas"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (mounted) setState(() => _areaList = json['data']);
      }
    } catch (e) {
      debugPrint("Err Area: $e");
    }
  }

  // ===========================================================================
  // 2. LOGIC ACTIONS
  // ===========================================================================

  Future<void> _updateRole(int staffId, bool isAdmin) async {
    Navigator.pop(context);
    _showLoadingDialog("Mengupdate Hak Akses...");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/admin/update-role"),
        body: {
          'id': staffId.toString(),
          'is_admin': isAdmin ? '1' : '0',
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        _showSnack("Hak akses berhasil diubah!");
        _fetchStaff();
      } else {
        _showSnack("Gagal update role.", isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack("Error: $e", isError: true);
    }
  }

  Future<void> _registerFace(String staffId, String staffName) async {
    Navigator.pop(context);

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
        _showSnack("SUKSES! Wajah $staffName terdaftar.");
      } else {
        var json = jsonDecode(response.body);
        _showSnack(json['message'] ?? "Gagal upload.", isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack("Error Upload: $e", isError: true);
    }
  }

  Future<void> updateDatabaseWajah() async {
    _showLoadingDialog("Melatih AI Wajah...");
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/admin/sync-faces'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) Navigator.pop(context);
      if (response.statusCode == 200) {
        _showSnack("Database AI Wajah Diperbarui!");
      } else {
        _showSnack("Gagal update AI", isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack("Error: $e", isError: true);
    }
  }

  Future<void> _updatePlacement(dynamic staffId, int? areaId) async {
    Navigator.pop(context);
    _showLoadingDialog("Menyimpan Penempatan...");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var uri = Uri.parse("${AppConfig.baseUrl}/api/admin/staff/placement");
      var request = http.Request("POST", uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      });
      request.body = jsonEncode({'staffid': staffId, 'areaid': areaId});

      var response = await request.send();
      var respStr = await http.Response.fromStream(response);

      if (mounted) Navigator.pop(context);

      if (respStr.statusCode == 200) {
        _fetchStaff();
        _showSnack("Lokasi Penempatan Berhasil Diupdate");
      } else {
        _showSnack("Gagal: ${respStr.body}", isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack("Error: $e", isError: true);
    }
  }

  // ===========================================================================
  // 3. UI HELPERS
  // ===========================================================================

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showLoadingDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(msg))
        ]),
      ),
    );
  }

  // ===========================================================================
  // 4. MAIN UI BUILD (RE-DESIGNED LIKE ADMIN HOME)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Background abu-abu muda
      body: Stack(
        children: [
          // --- A. BACKGROUND GRADIENT (HEADER) ---
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor, _secondaryColor],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // --- B. CONTENT ---
          SafeArea(
            child: Column(
              children: [
                // 1. TITLE BAR
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        "Kelola Pegawai",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 2. FLOATING MENU CARD (Menggantikan Grid Lama)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMenuIcon(
                          "Area",
                          Icons.map_outlined,
                          Colors.blue,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AreaPage()))),
                      _buildMenuIcon("Update AI", Icons.face, Colors.orange,
                          updateDatabaseWajah),
                      _buildMenuIcon("Refresh", Icons.refresh_rounded,
                          Colors.green, _loadData),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. TITLE "Daftar Staff"
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Daftar Staff",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 4. LIST STAFF
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            itemCount: _staffList.length,
                            itemBuilder: (context, index) {
                              return _buildStaffCard(_staffList[index]);
                            },
                          ),
                        ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: MENU ICON (Bulat seperti Home Admin)
  Widget _buildMenuIcon(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // WIDGET: STAFF CARD (Clean Style)
  Widget _buildStaffCard(Map item) {
    String name = item['name'] ?? item['staffname'] ?? "No Name";
    String nik = item['staffcode'] ?? "-";
    bool isAdmin = item['staffcategoryid'].toString() == '1';

    // Logika Lokasi
    String locationName = "Mobile";
    Color badgeColor = Colors.green;

    if (item['freeinteger1'] != null && _areaList.isNotEmpty) {
      var area = _areaList.firstWhere(
          (a) => a['areaid'].toString() == item['freeinteger1'].toString(),
          orElse: () => null);
      if (area != null) {
        locationName = area['description'];
        badgeColor = Colors.blue;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showStaffDetailSheet(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // AVATAR
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (isAdmin ? _primaryColor : Colors.blue)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: TextStyle(
                          color: isAdmin ? _primaryColor : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // TEXT INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text("NIK: $nik",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500])),
                      const SizedBox(height: 8),

                      // BADGE LOKASI
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                size: 12, color: badgeColor),
                            const SizedBox(width: 4),
                            Text(
                              locationName,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // ICON ADMIN / MENU
                if (isAdmin)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text("ADMIN",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  )
                else
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. BOTTOM SHEET (DETAIL)
  // ===========================================================================
  void _showStaffDetailSheet(Map staff) {
    String name = staff['name'] ?? staff['staffname'] ?? "No Name";
    String nik = staff['staffcode'] ?? "-";
    int staffId = staff['staffid'];
    bool isAdmin = staff['staffcategoryid'].toString() == '1';

    int? currentAreaId;
    if (staff['freeinteger1'] != null) {
      currentAreaId = int.tryParse(staff['freeinteger1'].toString());
    }
    int? selectedArea = currentAreaId;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(
                  25, 20, 25, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),

                  // HEADER PROFIL
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: (isAdmin ? _primaryColor : Colors.blue)
                            .withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "?",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isAdmin ? _primaryColor : Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("NIK: $nik",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 15),

                  // DROPDOWN AREA
                  Text("Area Penugasan",
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedArea,
                        isExpanded: true,
                        hint: const Text("Pilih Lokasi"),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Row(children: [
                              Icon(Icons.phonelink_ring_rounded,
                                  size: 20, color: Colors.green),
                              SizedBox(width: 10),
                              Text("Mobile / Bebas")
                            ]),
                          ),
                          ..._areaList.map((area) {
                            int val = int.parse(area['areaid'].toString());
                            return DropdownMenuItem<int>(
                              value: val,
                              child: Row(children: [
                                const Icon(Icons.business_rounded,
                                    size: 20, color: Colors.blue),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(area['description'] ?? "-",
                                        overflow: TextOverflow.ellipsis))
                              ]),
                            );
                          })
                        ],
                        onChanged: (val) {
                          setModalState(() => selectedArea = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => _updatePlacement(staffId, selectedArea),
                      child: const Text("SIMPAN LOKASI",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // FIX ERROR DISINI: Menghapus const pada Text karena Colors.grey[500] bukan konstanta
                  Text("Tindakan Cepat",
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // MENU ACTIONS (Tile)
                  _buildActionTile(
                      icon: Icons.face_retouching_natural_rounded,
                      color: Colors.orange,
                      title: "Daftarkan Wajah",
                      subtitle: "Update data biometrik",
                      onTap: () => _registerFace(staffId.toString(), name)),

                  _buildActionTile(
                      icon: Icons.admin_panel_settings_rounded,
                      color: Colors.purple,
                      title: "Akses Administrator",
                      subtitle: isAdmin
                          ? "Aktif (Bisa kelola sistem)"
                          : "Tidak Aktif",
                      trailing: Switch(
                        value: isAdmin,
                        activeThumbColor: Colors.white,
                        activeTrackColor: _primaryColor,
                        onChanged: (val) => _updateRole(staffId, val),
                      )),
                ],
              ),
            );
          });
        });
  }

  Widget _buildActionTile(
      {required IconData icon,
      required Color color,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey)
                : null),
        onTap: onTap,
      ),
    );
  }
}
