import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _aadhaarController;
  File? _profileImage;
  String? _existingProfileImageUrl;

  @override
  void initState() {
    super.initState();
    final partner = context.read<AuthProvider>().partner;
    _nameController = TextEditingController(text: partner?.name ?? '');
    _emailController = TextEditingController(text: partner?.email ?? '');
    _addressController = TextEditingController(text: partner?.address ?? '');
    _cityController = TextEditingController(text: partner?.city ?? '');
    _stateController = TextEditingController(text: partner?.state ?? '');
    _pincodeController = TextEditingController(text: partner?.pincode ?? '');
    _vehicleTypeController = TextEditingController(text: partner?.vehicleType ?? 'Two Wheeler');
    _vehicleNumberController = TextEditingController(text: partner?.vehicleNumber ?? '');
    _aadhaarController = TextEditingController(text: partner?.aadhaar ?? '');
    _existingProfileImageUrl = partner?.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    _aadhaarController.dispose();
    super.dispose();
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
      vehicleNumber: _vehicleNumberController.text.trim(),
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

              // Full Name
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full Name is required';
                  }
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim()) || v.trim().length < 2) {
                    return 'Name must be 2-50 characters long and contain only letters and spaces.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  prefixIcon: Icon(Icons.home_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // City
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // State
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pincode
              TextFormField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Pincode *',
                  prefixIcon: Icon(Icons.pin_drop_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) => (v == null || v.trim().length != 6) ? 'Enter valid 6-digit Pincode' : null,
              ),
              const SizedBox(height: 16),

              // Vehicle Type
              DropdownButtonFormField<String>(
                initialValue: ['Two Wheeler', 'Three Wheeler', 'Four Wheeler', 'Other']
                        .contains(_vehicleTypeController.text)
                    ? _vehicleTypeController.text
                    : 'Two Wheeler',
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type *',
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

              // Vehicle Number
              TextFormField(
                controller: _vehicleNumberController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number *',
                  hintText: 'e.g. MP 15 AB 1234',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vehicle Number is required' : null,
              ),
              const SizedBox(height: 16),

              // Aadhaar
              TextFormField(
                controller: _aadhaarController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Aadhaar Number *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) => (v == null || v.trim().length != 12) ? 'Enter valid 12-digit Aadhaar' : null,
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
