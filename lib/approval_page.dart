import 'package:flutter/material.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Warna Tema Admin (Ungu Gradient seperti di screenshot)
  final Color _primaryColor = const Color(0xFF6A11CB);
  //final Color _secondaryColor = const Color(0xFF2575FC);

  // Dummy Data (Nanti diganti API)
  final List<Map<String, dynamic>> _requests = [
    {
      'id': 1,
      'name': 'Budi Santoso',
      'role': 'Marketing',
      'type': 'Sakit',
      'date': '27 Jan 2026',
      'reason': 'Demam tinggi dan flu berat',
      'status': 'Pending',
      'avatar_color': Colors.blue
    },
    {
      'id': 2,
      'name': 'Siti Aminah',
      'role': 'Finance',
      'type': 'Cuti Tahunan',
      'date': '10 Feb - 12 Feb 2026',
      'reason': 'Acara keluarga di luar kota',
      'status': 'Pending',
      'avatar_color': Colors.orange
    },
    {
      'id': 3,
      'name': 'I Made Indrawan',
      'role': 'IT Support',
      'type': 'Ijin',
      'date': '28 Jan 2026',
      'reason': 'Ban bocor, datang terlambat',
      'status': 'Pending',
      'avatar_color': Colors.green
    },
  ];

  final List<Map<String, dynamic>> _history = [
    {
      'id': 4,
      'name': 'Dewi Lestari',
      'role': 'HRD',
      'type': 'Cuti',
      'date': '20 Jan 2026',
      'status': 'Approved',
      'reason': 'Liburan'
    },
    {
      'id': 5,
      'name': 'Eko Purnomo',
      'role': 'Driver',
      'type': 'Sakit',
      'date': '15 Jan 2026',
      'status': 'Rejected',
      'reason': 'Tidak ada surat dokter'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Fungsi saat tombol ditekan
  void _processApproval(int index, bool isApproved) {
    // Simulasi API Call
    String name = _requests[index]['name'];
    String action = isApproved ? "Disetujui" : "Ditolak";

    // Pindahkan ke history (Simulasi)
    setState(() {
      var item = _requests[index];
      item['status'] = isApproved ? 'Approved' : 'Rejected';
      _history.insert(0, item);
      _requests.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ijin $name berhasil $action"),
        backgroundColor: isApproved ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background terang
      appBar: AppBar(
        title: const Text(
          "Persetujuan Ijin",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Menunggu"),
                  const SizedBox(width: 8),
                  if (_requests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text("${_requests.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    )
                ],
              ),
            ),
            const Tab(text: "Riwayat"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(),
          _buildHistoryList(),
        ],
      ),
    );
  }

  // --- TAB 1: LIST MENUNGGU ---
  Widget _buildPendingList() {
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text("Tidak ada pengajuan baru",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        var item = _requests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
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
          child: Column(
            children: [
              // Header Kartu
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: (item['avatar_color'] as Color)
                          .withValues(alpha: 0.2),
                      child: Text(
                        _getInitials(item['name']),
                        style: TextStyle(
                            color: item['avatar_color'],
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(item['role'],
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.2))),
                            child: Text(
                              "${item['type']} • ${item['date']}",
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "\"${item['reason']}\"",
                            style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Garis Pemisah
              const Divider(height: 1),

              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _processApproval(index, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(15)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text("Tolak",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey[200]), // Garis vertikal
                  Expanded(
                    child: InkWell(
                      onTap: () => _processApproval(index, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: _primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text("Setujui",
                                style: TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // --- TAB 2: RIWAYAT ---
  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        var item = _history[index];
        bool isApproved = item['status'] == 'Approved';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.grey[100],
              child: Text(_getInitials(item['name']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            title: Text(item['name'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${item['type']} • ${item['date']}"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: isApproved ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                isApproved ? "Disetujui" : "Ditolak",
                style: TextStyle(
                    color: isApproved ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(" ");
    if (nameParts.isEmpty) return "";
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
  }
}
