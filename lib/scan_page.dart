import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // Controller kamera
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // TOMBOL SENTER (Versi Revisi - Lebih Stabil)
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          // TOMBOL GANTI KAMERA
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;

          if (barcodes.isNotEmpty && !_isScanned) {
            final String code = barcodes.first.rawValue ?? "---";

            setState(() {
              _isScanned = true;
            });

            _processScanResult(code);
          }
        },
      ),
    );
  }

  void _processScanResult(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Berhasil Scan: $code"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context, code);
      }
    });
  }
}
