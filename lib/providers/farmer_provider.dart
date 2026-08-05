import 'package:flutter/material.dart';
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
      _farmers = await _farmerRepository.fetchFarmers();
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      if (e is UnauthenticatedException) rethrow;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshFarmers() async {
    try {
      _farmers = await _farmerRepository.fetchFarmers();
      _errorMessage = null;
    } catch (e) {
      if (e is UnauthenticatedException) rethrow;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> addFarmer(Customer customer) async {
    _errorMessage = null;
    try {
      final created = await _farmerRepository.createFarmer(customer);
      _farmers.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      if (e is UnauthenticatedException) rethrow;
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
      if (e is UnauthenticatedException) rethrow;
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
      if (e is UnauthenticatedException) rethrow;
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
      } else {
        await refreshFarmers();
      }
      notifyListeners();
      return true;
    } catch (e) {
      if (e is UnauthenticatedException) rethrow;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
