import 'dart:io';

class ApiConstants {
  // Set your Mac's Wi-Fi IP address here when testing on a physical phone.
  // Current Mac Wi-Fi IP: 192.168.1.45
  static const String customHost = '192.168.1.45';

  static String get baseUrl {
    if (customHost.isNotEmpty) {
      return 'http://$customHost:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  // Auth Endpoints
  static const String checkPhone = '/auth/check-phone';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String loginOrRegister = '/auth/login-or-register';
  static const String profile = '/auth/profile';
  static const String me = '/auth/me';

  // Farmer Endpoints
  static const String farmers = '/farmers';
  static String farmerDetail(String id) => '/farmers/$id';
  static String farmerDeliver(String id) => '/farmers/$id/deliver';
}
