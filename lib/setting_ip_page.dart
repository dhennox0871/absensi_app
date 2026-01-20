import 'package:flutter/material.dart';
import 'config.dart';

class SettingIpPage extends StatefulWidget {
  const SettingIpPage({super.key});

  @override
  State<SettingIpPage> createState() => _SettingIpPageState();
}

class _SettingIpPageState extends State<SettingIpPage> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tampilkan IP yang sedang aktif di kolom input
    _ipController.text = AppConfig.baseUrl;
  }

  void _saveIp() async {
    String input = _ipController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("IP Address tidak boleh kosong")),
      );
      return;
    }

    // Simpan ke Config
    //await AppConfig.saveBaseUrl(input);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("IP Server Berhasil Disimpan!")),
    );

    // Kembali ke Login Page
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan Server"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan URL / IP Server:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                hintText: "Contoh: http://192.168.1.10:8000",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "*Pastikan HP dan Laptop terhubung di WiFi yang sama jika menggunakan IP Lokal.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveIp,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("SIMPAN PENGATURAN",
                    style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
