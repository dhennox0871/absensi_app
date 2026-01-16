import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'main.dart'; // Untuk ambil variabel 'cameras'
import 'package:geolocator/geolocator.dart';

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // Menyiapkan kamera (Pilih kamera depan jika ada)
  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;

    // Cari kamera depan (Front), kalau tidak ada pakai kamera pertama (biasanya belakang)
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // FUNGSI UTAMA: Ambil Foto & Deteksi Wajah
  Future<void> _captureAndDetect() async {
    if (_isProcessing) return; // Mencegah klik double
    setState(() => _isProcessing = true);

    try {
      // 1. Ambil Gambar
      final image = await _controller.takePicture();
      final File imageFile = File(image.path);

      // 2. Siapkan Detektor Wajah
      final inputImage = InputImage.fromFile(imageFile);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
        ),
      );

      // 3. Proses Deteksi
      final List<Face> faces = await faceDetector.processImage(inputImage);

      // 4. Cek Hasil
      if (faces.isNotEmpty) {
        // --- LOGIKA BARU DI SINI ---

        // A. Beri info ke user
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Wajah OK. Sedang mengambil lokasi..."),
              backgroundColor: Colors.blue),
        );

        try {
          // B. Ambil Lokasi (Tunggu sampai dapat)
          Position position = await _determinePosition();

          // C. Selesai! Kembali ke Dashboard bawa SEMUA data
          if (!mounted) return;
          Navigator.pop(context, {
            "status": "success",
            "image": imageFile, // File Foto
            "latitude": position.latitude, // Koordinat Lat
            "longitude": position.longitude, // Koordinat Long
            "address": "Lokasi didapatkan" // (Nanti bisa diisi nama jalan)
          });
        } catch (e) {
          // Kalau GPS gagal
          if (!mounted) return;
          _showError("Gagal ambil lokasi: $e");
        }
        // ---------------------------
      } else {
        // TIDAK ADA WAJAH
        if (!mounted) return;
        _showError("Wajah tidak terlihat. Coba lagi!");
      }

      faceDetector.close();
    } catch (e) {
      _showError("Gagal mengambil gambar: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Tampilan Kamera Full Screen
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: CameraPreview(_controller),
          ),

          // Overlay Lingkaran (Panduan posisi wajah)
          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(200), // Bentuk Oval
              ),
            ),
          ),

          // Tombol Capture di Bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: FloatingActionButton.extended(
                onPressed: _captureAndDetect,
                label: _isProcessing
                    ? const Text("Memproses...")
                    : const Text("Ambil Foto"),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt),
                backgroundColor: const Color(0xFF4285F4),
              ),
            ),
          ),

          // Tombol Back
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek GPS nyala/mati
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS dimatikan. Harap nyalakan GPS.');
    }

    // Cek Izin Aplikasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Cek setting HP.');
    }

    // Ambil lokasi akurat
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
