class AppConfig {
  // GANTI IP INI SESUAI HASIL ipconfig DI LAPTOP ANDA
  static const String baseUrl = "http://192.168.0.185:8000/api";

  // Endpoint-endpoint
  static const String login = "$baseUrl/login";
  static const String history = "$baseUrl/attendance/history";
  static const String attendance = "$baseUrl/attendance";
}
