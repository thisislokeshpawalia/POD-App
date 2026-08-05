import '../api/api_constants.dart';
import '../api/api_service.dart';
import '../models/delivery_partner_model.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  Future<bool> checkPhoneExists(String phone) async {
    final response = await _apiService.post(
      ApiConstants.checkPhone,
      body: {'phone': phone},
    );
    return response['exists'] ?? false;
  }

  Future<String> sendOtp(String phone) async {
    final response = await _apiService.post(
      ApiConstants.sendOtp,
      body: {'phone': phone},
    );
    return response['otp'] ?? '1234';
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    final response = await _apiService.post(
      ApiConstants.verifyOtp,
      body: {'phone': phone, 'otp': otp},
    );
    return response['valid'] ?? false;
  }

  Future<AuthResponseModel> loginOrRegister({
    required String phone,
    String? name,
    String? password,
  }) async {
    final response = await _apiService.post(
      ApiConstants.loginOrRegister,
      body: {
        'phone': phone,
        'name': name,
        'password': password ?? '123456',
      },
    );
    return AuthResponseModel.fromJson(response);
  }

  Future<DeliveryPartnerModel> getMe() async {
    final response = await _apiService.get(ApiConstants.me);
    return DeliveryPartnerModel.fromJson(response);
  }

  Future<DeliveryPartnerModel> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _apiService.patch(
      ApiConstants.profile,
      body: profileData,
    );
    return DeliveryPartnerModel.fromJson(response);
  }
}
