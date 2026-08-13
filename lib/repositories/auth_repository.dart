import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_service.dart';
import '../models/delivery_partner_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  final ApiService _apiService;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';

  AuthRepository({
    required AuthService authService,
    required ApiService apiService,
    FlutterSecureStorage? storage,
  })  : _authService = authService,
        _apiService = apiService,
        _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getSavedToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _apiService.setAuthToken(token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    _apiService.setAuthToken(null);
  }

  Future<bool> checkPhoneExists(String phone) async {
    return await _authService.checkPhoneExists(phone);
  }

  Future<String> sendOtp(String phone) async {
    return await _authService.sendOtp(phone);
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    return await _authService.verifyOtp(phone, otp);
  }

  Future<AuthResponseModel> loginOrRegister({
    required String phone,
    String? name,
    String? password,
  }) async {
    final response = await _authService.loginOrRegister(
      phone: phone,
      name: name,
      password: password,
    );
    await saveToken(response.accessToken);
    return response;
  }

  Future<DeliveryPartnerModel?> tryAutoLogin() async {
    final token = await getSavedToken();
    if (token == null || token.isEmpty) return null;

    _apiService.setAuthToken(token);
    try {
      final partner = await _authService.getMe();
      return partner;
    } on UnauthenticatedException {
      await clearToken();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DeliveryPartnerModel> updateProfile(
    Map<String, String> profileData, {
    String? profileImagePath,
  }) async {
    return await _authService.updateProfile(
      profileData,
      profileImagePath: profileImagePath,
    );
  }

  Future<void> logout() async {
    await clearToken();
  }
}
