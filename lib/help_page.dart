import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bantuan")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ExpansionTile(
            title: Text("Bagaimana cara absen?"),
            children: [
              Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                      "Masuk ke menu Home, pastikan GPS aktif, lalu tekan tombol 'Scan Wajah'. Pastikan Anda berada di area kantor."))
            ],
          ),
          ExpansionTile(
            title: Text("Kenapa lokasi tidak terdeteksi?"),
            children: [
              Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                      "Pastikan izin lokasi 'High Accuracy' aktif. Jika masih gagal, coba restart GPS atau aplikasi."))
            ],
          ),
          ExpansionTile(
            title: Text("Bagaimana jika lupa password?"),
            children: [
              Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                      "Hubungi Administrator untuk mereset password akun Anda."))
            ],
          ),
        ],
      ),
    );
  }
}
