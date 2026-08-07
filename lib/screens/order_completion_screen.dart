import 'dart:io';

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
  bool _isSubmitting = false;
  bool _isAtLocation = false;
  String _locationMessage = 'Checking location...';



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

  @override
  void initState() {
    super.initState();
    _checkInitialLocation();
  }

  Future<void> _checkInitialLocation() async {
    if (mounted) {
      setState(() {
        _locationMessage = 'Fetching exact location...';
      });
    }

    final position = await _getCurrentPosition();
    if (position == null) {
      if (mounted) {
        setState(() {
          _isAtLocation = false;
          _locationMessage = 'Location permission denied or service disabled.';
        });
      }
      return;
    }

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.customer.latitude,
      widget.customer.longitude,
    );

    final isMatching = distance <= 200.0;

    if (mounted) {
      setState(() {
        if (isMatching) {
          _isAtLocation = true;
          _locationMessage = "You reached customer's location";
        } else {
          _isAtLocation = false;
          _locationMessage = "Location mismatch: You are ${distance.toStringAsFixed(0)}m away (limit: 200m)";
        }
      });
    }
  }


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



  Future<bool> _checkLocation() async {
    final position = await _getCurrentPosition();
    if (position == null) {
      if (mounted) {
        _showErrorDialog('Unable to fetch location. Please enable GPS and allow location permissions.');
      }
      return false;
    }

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.customer.latitude,
      widget.customer.longitude,
    );

    if (distance > 200.0) {
      if (mounted) {
        _showErrorDialog(
          'You cannot complete this order because you are ${distance.toStringAsFixed(0)}m away.\n\nYou must be within 200m of the delivery address.',
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
      latitude: position?.latitude ?? widget.customer.latitude,
      longitude: position?.longitude ?? widget.customer.longitude,
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
          builder: (builderCtx) => DeliveryLogScreen(
            deliveryLog: log,
            onBackToHome: () =>
                Navigator.popUntil(builderCtx, (route) => route.isFirst),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to the customer list screen
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Proximity UI Message
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _isAtLocation ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAtLocation ? Colors.green.shade300 : Colors.orange.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAtLocation ? Icons.check_circle : Icons.location_off,
                    color: _isAtLocation ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationMessage,
                      style: TextStyle(
                        color: _isAtLocation ? Colors.green.shade700 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _checkInitialLocation,
                    tooltip: 'Refresh Location',
                  ),
                ],
              ),
            ),

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