import 'dart:convert';
import '../api/api_constants.dart';
import '../api/api_service.dart';
import '../models/customer.dart';

class FarmerService {
  final ApiService _apiService;

  FarmerService(this._apiService);

  Future<List<Customer>> getFarmers({DeliveryStatus? statusFilter}) async {
    Map<String, String>? queryParams;
    if (statusFilter != null) {
      queryParams = {'status_filter': statusFilter.name};
    }

    final response = await _apiService.get(
      ApiConstants.farmers,
      queryParams: queryParams,
    );

    if (response is List) {
      return response
          .map((item) => Customer.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Customer> getFarmer(String farmerId) async {
    final response = await _apiService.get(ApiConstants.farmerDetail(farmerId));
    return Customer.fromJson(response);
  }

  Future<Customer> createFarmer(Customer customer, String photoPath) async {
    final response = await _apiService.sendMultipart(
      ApiConstants.farmers,
      method: 'POST',
      fields: {'data': jsonEncode(customer.toCreateJson())},
      files: {'photo': photoPath},
    );
    return Customer.fromJson(response);
  }

  Future<Customer> updateFarmer(String farmerId, Customer customer) async {
    final response = await _apiService.patch(
      ApiConstants.farmerDetail(farmerId),
      body: customer.toUpdateJson(),
    );
    return Customer.fromJson(response);
  }

  Future<void> deleteFarmer(String farmerId) async {
    await _apiService.delete(ApiConstants.farmerDetail(farmerId));
  }

  Future<Customer> markDelivered(String farmerId) async {
    final response = await _apiService.patch(
      ApiConstants.farmerDeliver(farmerId),
    );
    return Customer.fromJson(response);
  }

  Future<Customer> uploadProofAndMarkDelivered(String farmerId, String? videoPath, List<String> photoPaths) async {
    final Map<String, dynamic> files = {};
    if (videoPath != null) {
      files['video'] = videoPath;
    }
    if (photoPaths.isNotEmpty) {
      files['photos'] = photoPaths;
    }

    final response = await _apiService.sendMultipart(
      '/farmers/$farmerId/upload_proof',
      method: 'POST',
      files: files,
    );
    return Customer.fromJson(response);
  }
}
