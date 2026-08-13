import 'package:flutter/material.dart';
import '../models/delivery_partner_model.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  otpSent,
  needsProfile,
  authenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.initial;
  DeliveryPartnerModel? _partner;
  String? _currentPhone;
  String? _otpCode;
  String? _errorMessage;
  bool _isRegistrationFlow = false;

  AuthProvider(this._authRepository);

  AuthStatus get status => _status;
  DeliveryPartnerModel? get partner => _partner;
  String? get currentPhone => _currentPhone;
  String? get otpCode => _otpCode;
  String? get errorMessage => _errorMessage;
  bool get isRegistrationFlow => _isRegistrationFlow;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initAutoLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final partner = await _authRepository.tryAutoLogin();
      if (partner != null) {
        _partner = partner;
        // Check if profile needs completion (if key fields like address/pincode are missing)
        if (_isProfileIncomplete(partner)) {
          _status = AuthStatus.needsProfile;
        } else {
          _status = AuthStatus.authenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  bool _isProfileIncomplete(DeliveryPartnerModel p) {
    return p.address == null || p.address!.isEmpty || p.pincode == null || p.pincode!.isEmpty;
  }

  Future<bool> checkPhoneAndRequestOtp(String phone) async {
    _errorMessage = null;
    _currentPhone = phone.trim();
    notifyListeners();

    try {
      final exists = await _authRepository.checkPhoneExists(_currentPhone!);
      if (exists) {
        _isRegistrationFlow = false;
        _otpCode = await _authRepository.sendOtp(_currentPhone!);
        _status = AuthStatus.otpSent;
        notifyListeners();
        return true; // Exists
      } else {
        return false; // Not registered
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> startRegistration(String phone) async {
    _errorMessage = null;
    _currentPhone = phone.trim();
    _isRegistrationFlow = true;
    notifyListeners();

    try {
      _otpCode = await _authRepository.sendOtp(_currentPhone!);
      _status = AuthStatus.otpSent;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> verifyOtpAndLogin(String otp) async {
    if (_currentPhone == null) return false;
    _errorMessage = null;
    notifyListeners();

    try {
      final isValid = await _authRepository.verifyOtp(_currentPhone!, otp);
      if (!isValid) {
        _errorMessage = 'Invalid OTP. Please enter 1234 for testing.';
        _status = AuthStatus.otpSent;
        notifyListeners();
        return false;
      }

      final authResponse = await _authRepository.loginOrRegister(
        phone: _currentPhone!,
        name: _isRegistrationFlow ? 'Delivery Partner' : null,
      );

      _partner = authResponse.partner;

      if (authResponse.isNewUser || _isProfileIncomplete(authResponse.partner)) {
        _status = AuthStatus.needsProfile;
      } else {
        _status = AuthStatus.authenticated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeProfile({
    required String fullName,
    required String email,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required String vehicleType,
    required String vehicleNumber,
    required String aadhaar,
    String? profileImagePath,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedPartner = await _authRepository.updateProfile({
        'name': fullName,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'vehicle_type': vehicleType,
        'vehicle_number': vehicleNumber,
        'aadhaar': aadhaar,
      }, profileImagePath: profileImagePath);

      _partner = updatedPartner;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void loginBypass(String phone) {
    _currentPhone = phone;
    _partner = DeliveryPartnerModel(
      id: 999,
      name: 'Test Delivery Partner',
      phone: phone,
      address: 'Test Address',
      city: 'Test City',
      state: 'Test State',
      pincode: '000000',
      vehicleType: 'Bike',
      vehicleNumber: 'AB12CD3456',
      createdAt: DateTime.now(),
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void registerBypass(String name, String phone, String aadhaar) {
    _currentPhone = phone;
    _partner = DeliveryPartnerModel(
      id: 1000,
      name: name,
      phone: phone,
      aadhaar: aadhaar,
      address: 'Test Address',
      city: 'Test City',
      state: 'Test State',
      pincode: '000000',
      vehicleType: 'Bike',
      vehicleNumber: 'AB12CD3456',
      createdAt: DateTime.now(),
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _partner = null;
    _currentPhone = null;
    _otpCode = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void cancelOtpFlow() {
    _status = AuthStatus.unauthenticated;
    _currentPhone = null;
    _otpCode = null;
    _errorMessage = null;
    notifyListeners();
  }
}
