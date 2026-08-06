import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../api/api_service.dart';
import '../models/customer.dart';
import '../repositories/farmer_repository.dart';
import '../screens/customer_list_screen.dart';

class FarmerProvider with ChangeNotifier {
  final FarmerRepository _farmerRepository;

  List<Customer> _farmers = [];
  bool _isLoading = false;
  String? _errorMessage;
  CustomerFilter _filter = CustomerFilter.all;

  FarmerProvider(this._farmerRepository);

  List<Customer> get farmers => _farmers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CustomerFilter get filter => _filter;

  int get totalCount => _farmers.length;
  int get deliveredCount => _farmers.where((f) => f.isDelivered).length;
  int get pendingCount => _farmers.where((f) => f.isPending).length;

  List<Customer> get filteredFarmers {
    switch (_filter) {
      case CustomerFilter.pending:
        return _farmers.where((f) => f.isPending).toList();
      case CustomerFilter.delivered:
        return _farmers.where((f) => f.isDelivered).toList();
      case CustomerFilter.all:
        return _farmers;
    }
  }

  void setFilter(CustomerFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  Future<void> fetchFarmers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await [Permission.location, Permission.camera].request();
      Position? position;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
          );
        }
      } catch (e) {
        debugPrint('Could not get location: $e');
      }

      _farmers = [
        Customer(
          id: 'C001',
          name: 'Rahul Sharma',
          phone: '9876543210',
          village: 'Sector 132',
          address: 'Jaypee Wish Town',
          district: 'Noida',
          pinCode: '201304',
          status: DeliveryStatus.pending,
          latitude: 28.5118,
          longitude: 77.3736,
          items: const [
            DeliveryItem(name: 'Fertilizer', quantity: 2, unit: 'Bags'),
          ],
        ),
        Customer(
          id: 'C002',
          name: 'Priya Verma',
          phone: '9876543211',
          village: 'Sector 132',
          address: 'Paras Tierea',
          district: 'Noida',
          pinCode: '201304',
          status: DeliveryStatus.inTransit,
          latitude: 28.5079,
          longitude: 77.3708,
          items: const [
            DeliveryItem(name: 'Pesticide', quantity: 5, unit: 'Bottles'),
          ],
        ),
        Customer(
          id: 'C003',
          name: 'Amit Kumar',
          phone: '9876543212',
          village: 'Sector 128',
          address: 'Expressway Service Road',
          district: 'Noida',
          pinCode: '201304',
          status: DeliveryStatus.pending,
          latitude: 28.5174,
          longitude: 77.3669,
          items: const [
            DeliveryItem(name: 'Seed Packets', quantity: 15, unit: 'Packs'),
          ],
        ),
        Customer(
          id: 'C004',
          name: 'Neha Gupta',
          phone: '9876543213',
          village: 'Sector 132',
          address: 'Supertech Eco Village',
          district: 'Noida',
          pinCode: '201305',
          status: DeliveryStatus.delivered,
          latitude: 28.5008,
          longitude: 77.3823,
          items: const [
            DeliveryItem(name: 'Organic Compost', quantity: 4, unit: 'Bags'),
          ],
        ),
        Customer(
          id: 'C005',
          name: 'Suresh Yadav',
          phone: '9876543214',
          village: 'Sector 135',
          address: 'Assotech Business Cresterra',
          district: 'Noida',
          pinCode: '201304',
          status: DeliveryStatus.pending,
          latitude: 28.5059,
          longitude: 77.3775,
          items: const [
            DeliveryItem(name: 'Sprayer', quantity: 1, unit: 'Piece'),
          ],
        ),
        Customer(
          id: 'C006',
          name: 'Anjali Singh',
          phone: '9876543215',
          village: 'Sector 134',
          address: 'Expressway Link Road',
          district: 'Noida',
          pinCode: '201304',
          status: DeliveryStatus.inTransit,
          latitude: 28.5096,
          longitude: 77.3809,
          items: const [
            DeliveryItem(name: 'Urea', quantity: 3, unit: 'Bags'),
          ],
        ),
        Customer(
          id: 'C007',
          name: 'Vikas Chauhan',
          phone: '9876543216',
          village: 'Sector 143',
          address: 'Advant Navis',
          district: 'Noida',
          pinCode: '201306',
          status: DeliveryStatus.pending,
          latitude: 28.4955,
          longitude: 77.3908,
          items: const [
            DeliveryItem(name: 'Drip Pipe', quantity: 30, unit: 'Meters'),
          ],
        ),
        Customer(
          id: 'C008',
          name: 'Pooja Mishra',
          phone: '9876543217',
          village: 'Sector 129',
          address: 'Noida-Greater Noida Expressway',
          district: 'Noida',
          pinCode: '201304',
          status: DeliveryStatus.delivered,
          latitude: 28.5159,
          longitude: 77.3692,
          items: const [
            DeliveryItem(name: 'Plant Growth Booster', quantity: 6, unit: 'Packets'),
          ],
        ),
      ];

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshFarmers() async {
    await fetchFarmers();
  }

  Future<bool> addFarmer(Customer customer) async {
    _errorMessage = null;
    try {
      // Mocking local add
      final fakeId = 'F${DateTime.now().millisecondsSinceEpoch}';
      final created = Customer(
        id: fakeId,
        name: customer.name,
        phone: customer.phone,
        village: customer.village,
        address: customer.address,
        district: customer.district,
        pinCode: customer.pinCode,
        status: customer.status,
        latitude: customer.latitude,
        longitude: customer.longitude,
        items: customer.items,
        otp: customer.otp,
      );
      _farmers.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFarmer(String farmerId, Customer customer) async {
    _errorMessage = null;
    try {
      // Mock local update
      final index = _farmers.indexWhere((f) => f.id == farmerId);
      if (index != -1) {
        _farmers[index] = customer;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFarmer(String farmerId) async {
    _errorMessage = null;
    try {
      // Mock local delete
      _farmers.removeWhere((f) => f.id == farmerId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markDelivered(String farmerId) async {
    _errorMessage = null;
    try {
      // Mock local mark delivered
      final index = _farmers.indexWhere((f) => f.id == farmerId);
      if (index != -1) {
        _farmers[index] = _farmers[index]..status = DeliveryStatus.delivered;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
