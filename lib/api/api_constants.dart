

class ApiConstants {
  /// Leave empty for emulator/desktop.
  /// Set this only when testing on a physical phone.
  static const String customHost = '192.168.1.49';

  static String get baseUrl {
    return 'https://pod-app-production-818a.up.railway.app';
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