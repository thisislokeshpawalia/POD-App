import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
          );
        }
      } catch (e) {
        debugPrint('Could not get location: $e');
      }

      _farmers = await _farmerRepository.fetchFarmers();

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
      final created = await _farmerRepository.createFarmer(customer);
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
      final updated = await _farmerRepository.updateFarmer(farmerId, customer);
      final index = _farmers.indexWhere((f) => f.id == farmerId);
      if (index != -1) {
        _farmers[index] = updated;
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
      await _farmerRepository.deleteFarmer(farmerId);
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
      final updated = await _farmerRepository.markDelivered(farmerId);
      final index = _farmers.indexWhere((f) => f.id == farmerId);
      if (index != -1) {
        _farmers[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProofAndMarkDelivered(String farmerId, String? videoPath, [List<String>? photoPaths]) async {
    _errorMessage = null;
    try {
      final updated = await _farmerRepository.uploadProofAndMarkDelivered(farmerId, videoPath, photoPaths);
      final index = _farmers.indexWhere((f) => f.id == farmerId);
      if (index != -1) {
        _farmers[index] = updated;
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
