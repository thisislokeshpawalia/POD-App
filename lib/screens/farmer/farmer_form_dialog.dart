import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/customer.dart';

// --- Premium Color Palette ---
const Color _kPrimary = Color(0xFF6366F1); // Indigo 500
const Color _kBackground = Color(0xFFF8FAFC); // Slate 50
const Color _kSurface = Colors.white;
const Color _kTextPrimary = Color(0xFF0F172A); // Slate 900
const Color _kTextSecondary = Color(0xFF64748B); // Slate 500

class FarmerFormDialog extends StatefulWidget {
  final Customer? farmer;

  const FarmerFormDialog({super.key, this.farmer});

  @override
  State<FarmerFormDialog> createState() => _FarmerFormDialogState();
}

class _FarmerFormDialogState extends State<FarmerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _villageController;
  late TextEditingController _addressController;
  late TextEditingController _districtController;
  late TextEditingController _pinCodeController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _otpController;

  File? _photoFile;
  final List<_ItemControllerGroup> _itemGroups = [];
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final f = widget.farmer;
    _nameController = TextEditingController(text: f?.name ?? '');
    _phoneController = TextEditingController(text: f?.phone ?? '');
    _villageController = TextEditingController(text: f?.village ?? '');
    _addressController = TextEditingController(text: f?.address ?? '');
    _districtController = TextEditingController(text: f?.district ?? '');
    _pinCodeController = TextEditingController(text: f?.pinCode ?? '');
    _latController = TextEditingController(text: f != null ? f.latitude.toString() : '');
    _lngController = TextEditingController(text: f != null ? f.longitude.toString() : '');
    _otpController = TextEditingController(text: f?.otp ?? '1234');

    if (f != null && f.items.isNotEmpty) {
      for (final item in f.items) {
        _itemGroups.add(_ItemControllerGroup(
          name: item.name,
          quantity: item.quantity.toString(),
          unit: item.unit,
        ));
      }
    } else {
      _itemGroups.add(_ItemControllerGroup(name: 'Cattle Feed', quantity: '25', unit: 'kg'));
    }

    if (f == null) {
      _fetchCurrentLocation();
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _latController.text = position.latitude.toStringAsFixed(6);
          _lngController.text = position.longitude.toStringAsFixed(6);
        });
      }

      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            _villageController.text = place.subLocality ?? place.locality ?? '';
            _districtController.text = place.subAdministrativeArea ?? place.administrativeArea ?? '';
            _pinCodeController.text = place.postalCode ?? '';
            _addressController.text = '${place.name ?? ''} ${place.thoroughfare ?? ''}'.trim();
          });
        }
      }
    } catch (e) {
      // Ignore errors (e.g. if geocoding fails)
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked != null) {
        setState(() {
          _photoFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _pinCodeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _otpController.dispose();
    for (final group in _itemGroups) {
      group.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _itemGroups.add(_ItemControllerGroup(name: '', quantity: '1', unit: 'kg'));
    });
  }

  void _removeItem(int index) {
    if (_itemGroups.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one delivery item is required')),
      );
      return;
    }
    setState(() {
      _itemGroups[index].dispose();
      _itemGroups.removeAt(index);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    final isCreating = widget.farmer == null;
    if (isCreating && _photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Farmer photo is required for face verification later.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final items = _itemGroups.map((g) {
      return DeliveryItem(
        name: g.nameController.text.trim(),
        quantity: double.tryParse(g.quantityController.text.trim()) ?? 1.0,
        unit: g.unitController.text.trim(),
      );
    }).toList();

    final result = Customer(
      id: widget.farmer?.id ?? '',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      village: _villageController.text.trim(),
      address: _addressController.text.trim(),
      district: _districtController.text.trim(),
      pinCode: _pinCodeController.text.trim(),
      status: widget.farmer?.status ?? DeliveryStatus.pending,
      latitude: double.tryParse(_latController.text.trim()) ?? 23.2599,
      longitude: double.tryParse(_lngController.text.trim()) ?? 77.4126,
      otp: _otpController.text.trim().isEmpty ? '1234' : _otpController.text.trim(),
      items: items,
    );

    // Return a map containing both the customer and the photo path (if any)
    Navigator.pop(context, {
      'customer': result,
      'photoPath': _photoFile?.path,
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextSecondary),
      filled: true,
      fillColor: _kBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.farmer != null;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(isEditing ? 'Update Farmer' : 'Add New Farmer', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: _kSurface,
        foregroundColor: _kTextPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Section
              if (!isEditing) ...[
                const Text(
                  'Farmer Photo (Mandatory)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kPrimary, letterSpacing: 1.1),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _kTextPrimary.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      image: _photoFile != null
                          ? DecorationImage(
                              image: FileImage(_photoFile!),
                              fit: BoxFit.cover,
                            )
                          : (widget.farmer?.photoUrls != null && widget.farmer!.photoUrls!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(widget.farmer!.photoUrls!.first),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: _photoFile == null && (widget.farmer?.photoUrls == null || widget.farmer!.photoUrls!.isEmpty)
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.face, size: 48, color: _kPrimary),
                              SizedBox(height: 12),
                              Text(
                                'Tap to capture face',
                                style: TextStyle(color: _kTextSecondary, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Used for delivery verification',
                                style: TextStyle(color: _kTextSecondary, fontSize: 12),
                              ),
                            ],
                          )
                        : Container(
                            alignment: Alignment.bottomRight,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                              ),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Basic Information
              const Text(
                'PERSONAL DETAILS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kPrimary, letterSpacing: 1.1),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: _kTextPrimary.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      maxLength: 50,
                      decoration: _inputDecoration('Farmer Name').copyWith(counterText: ''),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim()) || v.trim().length < 2) {
                          return 'Please enter the valid name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration('Phone Number').copyWith(
                        prefixText: '+91 ',
                        counterText: '',
                      ),
                      validator: (v) => (v == null || v.trim().length != 10) ? '10-digit phone required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Address Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LOCATION',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kPrimary, letterSpacing: 1.1),
                  ),
                  if (_isLocating)
                    const Row(
                      children: [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
                        SizedBox(width: 8),
                        Text('Fetching GPS...', style: TextStyle(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w600)),
                      ],
                    )
                  else if (!isEditing)
                    GestureDetector(
                      onTap: _fetchCurrentLocation,
                      child: const Row(
                        children: [
                          Icon(Icons.my_location, size: 16, color: _kPrimary),
                          SizedBox(width: 4),
                          Text('Auto-fill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
                        ],
                      ),
                    )
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: _kTextPrimary.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _villageController,
                      decoration: _inputDecoration('Village'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Village is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration('Address / House No.'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _districtController,
                            decoration: _inputDecoration('District'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _pinCodeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _inputDecoration('Pincode').copyWith(counterText: ''),
                            validator: (v) => (v == null || v.trim().length != 6) ? '6 digits required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: _inputDecoration('Latitude'),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Invalid Lat' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: _inputDecoration('Longitude'),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Invalid Lng' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Security Details
              const Text(
                'SECURITY',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kPrimary, letterSpacing: 1.1),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: _kTextPrimary.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration('Delivery Verification OTP').copyWith(
                    hintText: 'Default: 1234',
                    counterText: '',
                  ),
                  validator: (v) => (v == null || v.trim().length != 4) ? '4-digit OTP required' : null,
                ),
              ),
              const SizedBox(height: 32),

              // Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DELIVERY ITEMS',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kPrimary, letterSpacing: 1.1),
                  ),
                  GestureDetector(
                    onTap: _addItem,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 16, color: _kPrimary),
                          SizedBox(width: 4),
                          Text('Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...List.generate(_itemGroups.length, (index) {
                final group = _itemGroups[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: _kTextPrimary.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: group.nameController,
                          decoration: _inputDecoration('Name'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: group.quantityController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Qty'),
                          validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Invalid' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: group.unitController,
                          decoration: _inputDecoration('Unit'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Req' : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                        onPressed: () => _removeItem(index),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Update Farmer Details' : 'Create Farmer',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemControllerGroup {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;

  _ItemControllerGroup({
    required String name,
    required String quantity,
    required String unit,
  })  : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(text: quantity),
        unitController = TextEditingController(text: unit);

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }
}
