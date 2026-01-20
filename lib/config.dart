class AppConfig {
  // ⚠️ GANTI BAGIAN INI SESUAI HASIL IPCONFIG LAPTOP ANDA
  // Pastikan formatnya: http://IP_ADDRESS:8000
  static const String baseUrl = "http://192.168.1.10:8000";

  // Endpoint API (Otomatis mengikuti baseUrl di atas)
  static const String login = "$baseUrl/api/login";
  static const String history = "$baseUrl/api/attendance/history";
  static const String attendance = "$baseUrl/api/attendance";

  // Endpoint Admin
  static const String staffList = "$baseUrl/api/admin/staff";
  static const String updateRole = "$baseUrl/api/admin/update-role";

  // TAMBAHKAN BAGIAN INI:
  static const String getSettings = "$baseUrl/api/admin/settings";
  static const String saveSettings = "$baseUrl/api/admin/settings";
}
