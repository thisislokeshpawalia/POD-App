import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/delivery_log.dart';
import '../providers/farmer_provider.dart';
import 'delivery_log_screen.dart';

class OrderCompletionScreen extends StatefulWidget {
  final Customer customer;
  final void Function(String customerId) onCustomerDelivered;

  const OrderCompletionScreen({
    super.key,
    required this.customer,
    required this.onCustomerDelivered,
  });

  @override
  State<OrderCompletionScreen> createState() => _OrderCompletionScreenState();
}

class _OrderCompletionScreenState extends State<OrderCompletionScreen> {
  final _picker = ImagePicker();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());

  File? _photoFile;
  String? _videoPath;
  bool _showOtpHint = false;
  bool _simulateArrival = false;
  bool _isSubmitting = false;

  static const _locationRadiusMeters = 500.0;

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp =>
      _otpControllers.map((c) => c.text.trim()).join();

  // ─── Photo / Video Pickers ─────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _videoPath = picked.path);
    }
  }

  // ─── Location Helpers ──────────────────────────────────────────────────────

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  double _distanceInMeters(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * pi / 180;

  Future<bool> _checkLocation() async {
    if (_simulateArrival) return true;

    final position = await _getCurrentPosition();
    if (position == null) {
      if (mounted) {
        _showErrorDialog(
          'Location permission denied or GPS unavailable. Enable location or use "Simulate Arrival" for testing.',
        );
      }
      return false;
    }

    final distance = _distanceInMeters(
      position.latitude,
      position.longitude,
      widget.customer.latitude,
      widget.customer.longitude,
    );

    if (distance > _locationRadiusMeters) {
      if (mounted) {
        _showErrorDialog(
          'You are not at the delivery location. Please reach the customer\'s location to complete this order.',
        );
      }
      return false;
    }
    return true;
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot Complete Order'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitDelivery() async {
    // Validate OTP
    if (_enteredOtp.length != 4) {
      _showErrorDialog('Please enter the 4-digit OTP to complete the order.');
      return;
    }
    if (_enteredOtp != widget.customer.otp) {
      _showErrorDialog('Incorrect OTP. Please ask the customer for the correct OTP.');
      return;
    }

    // Validate photo
    if (_photoFile == null) {
      _showErrorDialog('Please upload a proof of delivery photo.');
      return;
    }

    setState(() => _isSubmitting = true);

    // Check location
    final atLocation = await _checkLocation();
    if (!atLocation) {
      setState(() => _isSubmitting = false);
      return;
    }

    // Get current position for log (use customer coords as fallback)
    Position? position;
    try {
      position = await _getCurrentPosition();
    } catch (_) {}

    final log = DeliveryLog(
      customer: widget.customer,
      timestamp: DateTime.now(),
      latitude: _simulateArrival
          ? widget.customer.latitude
          : (position?.latitude ?? widget.customer.latitude),
      longitude: _simulateArrival
          ? widget.customer.longitude
          : (position?.longitude ?? widget.customer.longitude),
      items: widget.customer.items,
      photoPath: _photoFile?.path,
      videoPath: _videoPath,
    );

    widget.onCustomerDelivered(widget.customer.id);
    if (!mounted) return;
    await context.read<FarmerProvider>().markDelivered(widget.customer.id);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryLogScreen(
            deliveryLog: log,
            onBackToHome: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Delivery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.customer.fullAddress,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    ...widget.customer.items.map(
                          (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 16, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 8),
                            Text(item.displayText),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // OTP Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enter OTP',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showOtpHint = !_showOtpHint),
                          child: Text(_showOtpHint ? 'Hide Hint' : 'Show Hint'),
                        ),
                      ],
                    ),
                    if (_showOtpHint)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'OTP for testing: ${widget.customer.otp}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (i) {
                        return SizedBox(
                          width: 56,
                          child: TextField(
                            controller: _otpControllers[i],
                            focusNode: _otpFocusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && i < 3) {
                                _otpFocusNodes[i + 1].requestFocus();
                              } else if (val.isEmpty && i > 0) {
                                _otpFocusNodes[i - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Photo Upload
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proof of Delivery Photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_photoFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _photoFile!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                          _photoFile == null ? 'Upload Photo' : 'Change Photo'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Video Upload
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proof of Delivery Video (Optional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_videoPath != null)
                      Row(
                        children: [
                          const Icon(Icons.video_file,
                              color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _videoPath!.split('/').last,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library_outlined),
                      label: Text(_videoPath == null
                          ? 'Upload Video'
                          : 'Change Video'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Simulate arrival toggle (for testing)
            Card(
              child: SwitchListTile(
                title: const Text('Simulate Arrival (Testing Only)'),
                subtitle: const Text(
                    'Bypasses GPS check for demo purposes'),
                value: _simulateArrival,
                activeColor: colorScheme.primary,
                onChanged: (val) => setState(() => _simulateArrival = val),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitDelivery,
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Complete Delivery'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}