import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  bool _isLoading = true;
  List<dynamic> _staffList = [];

  // Warna Tema Admin
  final Color _primaryColor = const Color(0xFF6A11CB);

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  // 1. Ambil Data Staff dari Server
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
        setState(() {
          _staffList = json['data'];
          _isLoading = false;
        });
      } else {
        _showSnack("Gagal mengambil data staff");
      }
    } catch (e) {
      _showSnack("Error koneksi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Fungsi Ganti Role (Switch Toggle)
  Future<void> _updateRole(int userId, bool isAdmin, int index) async {
    // Optimistic Update (Ubah tampilan dulu biar cepat)
    setState(() {
      _staffList[index]['staffcategoryid'] = isAdmin ? 1 : 0;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await http.post(
        Uri.parse(AppConfig.updateRole),
        body: {
          'id': userId.toString(),
          'is_admin': isAdmin ? '1' : '0',
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSnack("Hak akses berhasil diubah!");
      } else {
        // Kalau gagal, kembalikan tampilan switch ke posisi awal
        setState(() {
          _staffList[index]['staffcategoryid'] = isAdmin ? 0 : 1;
        });
        _showSnack("Gagal update server.");
      }
    } catch (e) {
      // Kalau error, kembalikan tampilan
      setState(() {
        _staffList[index]['staffcategoryid'] = isAdmin ? 0 : 1;
      });
      _showSnack("Gagal koneksi server.");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // APP BAR SEDERHANA
      appBar: AppBar(
        title: const Text("Kelola Pegawai",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                  String name = staff['name'] ?? "No Name";
                  String nik = staff['staffcode'] ?? "-";
                  String position =
                      staff['position']?['positionname'] ?? "Staff";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        children: [
                          // 1. AVATAR / FOTO
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: isAdmin
                                ? _primaryColor.withValues(
                                    alpha: 0.1) // Ungu Pucat kalau Admin
                                : Colors.blue.withValues(
                                    alpha: 0.1), // Biru Pucat kalau User
                            child: Text(
                              _getInitials(name),
                              style: TextStyle(
                                color: isAdmin ? _primaryColor : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),

                          // 2. INFO PEGAWAI
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$position • $nik",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isAdmin)
                                  Container(
                                    margin: const EdgeInsets.only(top: 5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: _primaryColor,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: const Text(
                                      "Administrator",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  )
                              ],
                            ),
                          ),

                          // 3. SWITCH TOGGLE
                          Column(
                            children: [
                              Switch(
                                value: isAdmin,
                                activeThumbColor: _primaryColor,
                                onChanged: (value) {
                                  // SALAH: staff['id'] mungkin null jika json key-nya 'staffid'
                                  // _updateRole(staff['id'], value, index);

                                  // BENAR: Gunakan staff['staffid']
                                  _updateRole(staff['staffid'], value, index);
                                },
                              ),
                              Text(
                                isAdmin ? "Admin" : "User",
                                style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        isAdmin ? _primaryColor : Colors.grey,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // Helper untuk ambil inisial nama (Misal: Dhenny Hariyanto -> DH)
  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(" ");
    if (nameParts.isEmpty) return "";
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
  }
}
