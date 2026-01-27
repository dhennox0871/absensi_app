import 'package:flutter/material.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy Data (Nanti diganti API Get Ijin)
  final List<Map<String, dynamic>> _leaveData = [
    {
      'id': 1,
      'type': 'Sakit',
      'date': '27 Jan 2026',
      'status': 'Pending',
      'reason': 'Demam tinggi'
    },
    {
      'id': 2,
      'type': 'Cuti Tahunan',
      'date': '10 Jan 2026',
      'status': 'Approved',
      'reason': 'Liburan keluarga'
    },
    {
      'id': 3,
      'type': 'Ijin',
      'date': '01 Jan 2026',
      'status': 'Rejected',
      'reason': 'Acara mendadak'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Fungsi Batalkan Ijin (Hanya update status)
  void _cancelLeave(int id) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Batalkan Ijin?"),
              content: const Text(
                  "Permohonan akan dibatalkan tapi tetap tersimpan di riwayat."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Kembali")),
                ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      // TODO: Panggil API Cancel Leave disini
                      setState(() {
                        var index = _leaveData.indexWhere((e) => e['id'] == id);
                        if (index != -1) {
                          _leaveData[index]['status'] = 'Cancelled';
                        }
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Ijin dibatalkan")));
                    },
                    child: const Text("Batalkan"))
              ],
            ));
  }

  // Modal Form Pengajuan
  void _showAddLeaveForm() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ajukan Ijin Baru",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField(
                    decoration: const InputDecoration(
                        labelText: "Tipe Ijin", border: OutlineInputBorder()),
                    items: ["Sakit", "Ijin", "Cuti Tahunan", "Dinas Luar"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {},
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: "Tanggal",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      // Logic Date Picker Range
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: "Alasan", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Panggil API Submit Leave
                        },
                        child: const Text("KIRIM PERMOHONAN",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                  )
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Pengajuan Ijin",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "Berlangsung"), // Pending
            Tab(text: "Riwayat"), // Approved/Rejected/Cancelled
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(statusFilter: ['Pending']),
          _buildList(statusFilter: ['Approved', 'Rejected', 'Cancelled']),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLeaveForm,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList({required List<String> statusFilter}) {
    var filtered =
        _leaveData.where((e) => statusFilter.contains(e['status'])).toList();

    if (filtered.isEmpty) {
      return const Center(
          child: Text("Tidak ada data", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        var item = filtered[index];
        Color statusColor = Colors.grey;
        if (item['status'] == 'Pending') statusColor = Colors.orange;
        if (item['status'] == 'Approved') statusColor = Colors.green;
        if (item['status'] == 'Rejected') statusColor = Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['type'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(item['status'],
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['date'], style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text("Alasan: ${item['reason']}",
                    style: const TextStyle(fontSize: 13)),

                // Tombol Batalkan hanya jika Pending
                if (item['status'] == 'Pending')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red)),
                        onPressed: () => _cancelLeave(item['id']),
                        child: const Text("Batalkan Permohonan",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}
