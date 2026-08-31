import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _pincodeController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _addressController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _aadhaarController;
  File? _profileImage;
  String? _existingProfileImageUrl;

  bool _isFetchingPincode = false;
  String? _pincodeStatusMessage;
  bool _isManualCityStateOverride = false;

  @override
  void initState() {
    super.initState();
    final partner = context.read<AuthProvider>().partner;
    _nameController = TextEditingController(text: partner?.name ?? '');
    _emailController = TextEditingController(text: partner?.email ?? '');
    _pincodeController = TextEditingController(text: partner?.pincode ?? '');
    _cityController = TextEditingController(text: partner?.city ?? '');
    _stateController = TextEditingController(text: partner?.state ?? '');
    _addressController = TextEditingController(text: partner?.address ?? '');
    _vehicleTypeController = TextEditingController(text: partner?.vehicleType ?? 'Two Wheeler');
    _vehicleNumberController = TextEditingController(text: partner?.vehicleNumber ?? '');
    _aadhaarController = TextEditingController(text: partner?.aadhaar ?? '');
    _existingProfileImageUrl = partner?.profileImage;

    if (_pincodeController.text.trim().length == 6 &&
        (_cityController.text.trim().isEmpty || _stateController.text.trim().isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchCityAndState(_pincodeController.text.trim());
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _fetchCityAndState(String pincode) async {
    if (pincode.length != 6) return;
    setState(() {
      _isFetchingPincode = true;
      _pincodeStatusMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List?;
          if (postOffices != null && postOffices.isNotEmpty) {
            final first = postOffices[0] as Map<String, dynamic>;
            final district = (first['District'] ?? first['Circle'] ?? first['Block'] ?? '').toString().trim();
            final state = (first['State'] ?? '').toString().trim();

            if (mounted) {
              setState(() {
                _cityController.text = district;
                _stateController.text = state;
                _isFetchingPincode = false;
                _pincodeStatusMessage = 'Auto-detected: $district, $state';
              });
              return;
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _isFetchingPincode = false;
          _pincodeStatusMessage = 'Could not find details for PIN: $pincode';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFetchingPincode = false;
          _pincodeStatusMessage = 'Unable to fetch location automatically';
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if image is present for new users or existing users without an image
    if (_profileImage == null && (_existingProfileImageUrl == null || _existingProfileImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile photo')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.completeProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      vehicleType: _vehicleTypeController.text.trim(),
      vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
      aadhaar: _aadhaarController.text.trim(),
      profileImagePath: _profileImage?.path,
    );

    if (!success && authProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
            tooltip: 'Logout',
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
              const Text(
                'Delivery Partner Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 6),
              Text(
                'Please complete your partner profile according to the system backend schema before accessing orders.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Profile Photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!) as ImageProvider
                          : (_existingProfileImageUrl != null && _existingProfileImageUrl!.isNotEmpty)
                              ? NetworkImage(_existingProfileImageUrl!)
                              : null,
                      child: (_profileImage == null && (_existingProfileImageUrl == null || _existingProfileImageUrl!.isEmpty))
                          ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showImagePickerBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1) Full Name (No numbers or special characters allowed)
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                decoration: const InputDecoration(
                  labelText: '1. Full Name *',
                  hintText: 'e.g. Rahul Sharma',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full Name is required';
                  }
                  if (v.trim().length < 2) {
                    return 'Name must be at least 2 characters long';
                  }
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) {
                    return 'Name must contain only letters and spaces';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2) Email (Proper format validation)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: const InputDecoration(
                  labelText: '2. Email Address *',
                  hintText: 'e.g. rahul@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email Address is required';
                  }
                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(v.trim())) {
                    return 'Enter a valid email address (e.g. name@example.com)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3) PIN Code (6 digits, triggers auto-fetch for city & state)
              TextFormField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  if (val.trim().length == 6) {
                    _fetchCityAndState(val.trim());
                  } else {
                    if (_pincodeStatusMessage != null) {
                      setState(() {
                        _pincodeStatusMessage = null;
                      });
                    }
                  }
                },
                decoration: InputDecoration(
                  labelText: '3. PIN Code *',
                  hintText: '6-digit PIN code',
                  prefixIcon: const Icon(Icons.pin_drop_outlined),
                  suffixIcon: _isFetchingPincode
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
                          ),
                        )
                      : null,
                  helperText: _pincodeStatusMessage,
                  helperStyle: TextStyle(
                    color: (_pincodeStatusMessage?.startsWith('Auto') ?? false)
                        ? const Color(0xFF2E7D32)
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'PIN code is required';
                  }
                  if (v.trim().length != 6) {
                    return 'PIN code must be exactly 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4) City and State (Automatically fetched by PIN code)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      readOnly: !_isManualCityStateOverride,
                      decoration: InputDecoration(
                        labelText: '4. City *',
                        hintText: 'Auto-fetched',
                        filled: !_isManualCityStateOverride,
                        fillColor: _isManualCityStateOverride ? null : Colors.grey.shade100,
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'City required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // State
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      readOnly: !_isManualCityStateOverride,
                      decoration: InputDecoration(
                        labelText: 'State *',
                        hintText: 'Auto-fetched',
                        filled: !_isManualCityStateOverride,
                        fillColor: _isManualCityStateOverride ? null : Colors.grey.shade100,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isManualCityStateOverride ? Icons.lock_open : Icons.edit_note,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          tooltip: _isManualCityStateOverride ? 'Lock fields' : 'Edit manually if needed',
                          onPressed: () {
                            setState(() {
                              _isManualCityStateOverride = !_isManualCityStateOverride;
                            });
                          },
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'State required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5) Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '5. Address *',
                  hintText: 'House/Flat No., Street, Locality',
                  prefixIcon: Icon(Icons.home_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Address is required';
                  }
                  if (v.trim().length < 5) {
                    return 'Address must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 6) Vehicle Type
              DropdownButtonFormField<String>(
                initialValue: ['Two Wheeler', 'Three Wheeler', 'Four Wheeler', 'Other']
                        .contains(_vehicleTypeController.text)
                    ? _vehicleTypeController.text
                    : 'Two Wheeler',
                decoration: const InputDecoration(
                  labelText: '6. Vehicle Type *',
                  prefixIcon: Icon(Icons.directions_bike_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Two Wheeler', child: Text('Two Wheeler')),
                  DropdownMenuItem(value: 'Three Wheeler', child: Text('Three Wheeler')),
                  DropdownMenuItem(value: 'Four Wheeler', child: Text('Four Wheeler')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) _vehicleTypeController.text = val;
                },
              ),
              const SizedBox(height: 16),

              // 7) Vehicle Number (Strict Indian vehicle registration format)
              TextFormField(
                controller: _vehicleNumberController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s-]')),
                  UpperCaseTextFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: '7. Vehicle Number *',
                  hintText: 'e.g. DL 01 AB 1234 or UP 16 CP 6755',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vehicle Number is required';
                  }
                  final cleaned = v.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
                  final vehicleRegex = RegExp(r'^([A-Z]{2}[0-9]{1,2}[A-Z]{0,3}[0-9]{4}|[0-9]{2}BH[0-9]{4}[A-Z]{1,2})$');
                  if (!vehicleRegex.hasMatch(cleaned)) {
                    return 'Enter valid vehicle number (e.g. DL 01 AB 1234)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 8) Aadhaar Number (12 digits, cannot start with 0 or 1)
              TextFormField(
                controller: _aadhaarController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '8. Aadhaar Number *',
                  hintText: '12-digit Aadhaar number',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Aadhaar Number is required';
                  }
                  if (v.trim().length != 12) {
                    return 'Aadhaar number must be exactly 12 digits';
                  }
                  if (!RegExp(r'^[2-9][0-9]{11}$').hasMatch(v.trim())) {
                    return 'Enter valid 12-digit Aadhaar (cannot start with 0 or 1)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: isLoading ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Profile & Proceed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
