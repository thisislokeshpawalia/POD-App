

class ApiConstants {
  /// Leave empty for emulator/desktop.
  /// Set this only when testing on a physical phone.
  static const String customHost = '192.168.1.49';

  static String get baseUrl {
    // TODO (Railway): Once deployed to Railway, replace the Render URL below with your new Railway URL
    // return 'https://your-railway-app.up.railway.app';
    return 'https://pod-backend-1yr8.onrender.com';
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