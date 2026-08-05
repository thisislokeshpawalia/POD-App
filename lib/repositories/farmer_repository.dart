import '../models/customer.dart';
import '../services/farmer_service.dart';

class FarmerRepository {
  final FarmerService _farmerService;

  FarmerRepository(this._farmerService);

  Future<List<Customer>> fetchFarmers({DeliveryStatus? statusFilter}) async {
    return await _farmerService.getFarmers(statusFilter: statusFilter);
  }

  Future<Customer> getFarmer(String farmerId) async {
    return await _farmerService.getFarmer(farmerId);
  }

  Future<Customer> createFarmer(Customer customer) async {
    return await _farmerService.createFarmer(customer);
  }

  Future<Customer> updateFarmer(String farmerId, Customer customer) async {
    return await _farmerService.updateFarmer(farmerId, customer);
  }

  Future<void> deleteFarmer(String farmerId) async {
    await _farmerService.deleteFarmer(farmerId);
  }

  Future<Customer> markDelivered(String farmerId) async {
    return await _farmerService.markDelivered(farmerId);
  }
}
