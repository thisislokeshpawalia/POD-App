import 'dart:io';

class ApiConstants {
  /// Leave empty for emulator/desktop.
  /// Set this only when testing on a physical phone.
  static const String customHost = '192.168.1.49';

  static String get baseUrl {
    if (customHost.isNotEmpty) {
      return 'http://$customHost:8000';
    }

    if (Platform.isAndroid) {
      // Android Emulator
      return 'http://10.0.2.2:8000';
    }

    // Windows / macOS / Linux desktop and iOS simulator
    return 'http://127.0.0.1:8000';
  }

  // Auth
  static const checkPhone = '/auth/check-phone';
  static const sendOtp = '/auth/send-otp';
  static const verifyOtp = '/auth/verify-otp';
  static const loginOrRegister = '/auth/login-or-register';
  static const profile = '/auth/profile';
  static const me = '/auth/me';

  // Farmers
  static const farmers = '/farmers';
  static String farmerDetail(String id) => '/farmers/$id';
  static String farmerDeliver(String id) => '/farmers/$id/deliver';
}