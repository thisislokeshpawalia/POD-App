import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/delivery_log.dart';
import '../providers/farmer_provider.dart';
import '../services/face_recognition_service.dart';
import '../services/invoice_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'delivery_log_screen.dart';

// --- Premium Color Palette ---
const Color _kPrimary = Color(0xFF6366F1); // Indigo 500
const Color _kPrimaryDark = Color(0xFF4338CA); // Indigo 700
const Color _kBackground = Color(0xFFF8FAFC); // Slate 50
const Color _kSurface = Colors.white;
const Color _kTextPrimary = Color(0xFF0F172A); // Slate 900
const Color _kTextSecondary = Color(0xFF64748B); // Slate 500
const Color _kSuccess = Color(0xFF10B981); // Emerald 500
const Color _kSuccessLight = Color(0xFFECFDF5); // Emerald 50
const Color _kWarning = Color(0xFFF59E0B); // Amber 500
const Color _kWarningLight = Color(0xFFFFFBEB); // Amber 50

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

class _OrderCompletionScreenState extends State<OrderCompletionScreen> with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());

  final List<File> _photoFiles = [];
  File? _farmerFacePhoto;
  String? _videoPath;
  bool _showOtpHint = false;
  bool _isSubmitting = false;
  bool _isAtLocation = false;
  String _locationMessage = 'Checking location...';

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimations = List.generate(7, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 0.6 + index * 0.05, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(7, (index) {
      return Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 0.6 + index * 0.05, curve: Curves.easeOutCubic),
        ),
      );
    });

    _animationController.forward();
    _checkInitialLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

    final isMatching = distance <= 600.0;

    if (mounted) {
      setState(() {
        if (isMatching) {
          _isAtLocation = true;
          _locationMessage = "You reached customer's location";
        } else {
          _isAtLocation = false;
          _locationMessage = "Location mismatch: You are ${distance.toStringAsFixed(0)}m away (limit: 600m)";
        }
      });
    }
  }


  // ─── Photo / Video Pickers ─────────────────────────────────────────────────

  Future<void> _pickFarmerFacePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _farmerFacePhoto = File(picked.path);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a Photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source != null) {
      if (source == ImageSource.camera) {
        final picked = await _picker.pickImage(source: source, imageQuality: 80);
        if (picked != null) {
          setState(() {
            if (_photoFiles.length < 5) {
              _photoFiles.add(File(picked.path));
            }
          });
        }
      } else {
        final picked = await _picker.pickMultiImage(imageQuality: 80);
        if (picked.isNotEmpty) {
          setState(() {
            for (var file in picked) {
              if (_photoFiles.length < 5) {
                _photoFiles.add(File(file.path));
              }
            }
          });
        }
      }
    }
  }

  Future<void> _pickVideo() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Record a Video'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source != null) {
      final picked = await _picker.pickVideo(source: source);
      if (picked != null) {
        setState(() => _videoPath = picked.path);
      }
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

    if (distance > 600.0) {
      if (mounted) {
        _showErrorDialog(
          'You cannot complete this order because you are ${distance.toStringAsFixed(0)}m away.\n\nYou must be within 600m of the delivery address.',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _kSurface,
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 12),
            Text('Action Denied', style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: _kTextSecondary, height: 1.5)),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _kPrimary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitDelivery() async {
    if (_enteredOtp.length != 4) {
      _showErrorDialog('Please enter the 4-digit OTP to complete the order.');
      return;
    }
    if (_enteredOtp != widget.customer.otp) {
      _showErrorDialog('Incorrect OTP. Please ask the customer for the correct OTP.');
      return;
    }

    if (_farmerFacePhoto == null) {
      _showErrorDialog('Please capture the farmer\'s face photo for verification.');
      return;
    }

    if (_photoFiles.isEmpty) {
      _showErrorDialog('Please upload at least one proof of delivery photo for verification.');
      return;
    }

    setState(() => _isSubmitting = true);

    final atLocation = await _checkLocation();
    if (!atLocation) {
      setState(() => _isSubmitting = false);
      return;
    }

    Position? position;
    try {
      position = await _getCurrentPosition();
    } catch (_) {}

    // --- TFLite Face Verification ---
    if (widget.customer.photoUrls != null && widget.customer.photoUrls!.isNotEmpty) {
      try {
        final registeredPhotoUrl = widget.customer.photoUrls!.first;
        final deliveryPhotoPath = _farmerFacePhoto!.path;

        // Download the registered photo to a temp file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_registered_face.jpg');
        
        final response = await http.get(Uri.parse(registeredPhotoUrl));
        if (response.statusCode == 200) {
          await tempFile.writeAsBytes(response.bodyBytes);
          
          // Verify
          final isMatch = await FaceRecognitionService().verifyFaces(tempFile.path, deliveryPhotoPath);
          if (!isMatch) {
            setState(() => _isSubmitting = false);
            _showErrorDialog('Face mismatch! The person in the delivery photo does not match the registered farmer.');
            return;
          }
        }
      } catch (e) {
        setState(() => _isSubmitting = false);
        _showErrorDialog('Face verification error: $e');
        return;
      }
    } else {
      setState(() => _isSubmitting = false);
      _showErrorDialog('Farmer has no registered photo to verify against.');
      return;
    }
    // --------------------------------

    widget.onCustomerDelivered(widget.customer.id);
    if (!mounted) return;
    
    String? invoicePath;
    try {
      invoicePath = await InvoiceService.generateInvoicePdf(
        customer: widget.customer,
        deliveryDate: DateTime.now(),
        photoPaths: _photoFiles.map((e) => e.path).toList(),
        farmerFacePhotoPath: _farmerFacePhoto!.path,
      );
    } catch (e) {
      debugPrint("Error generating invoice during submission: $e");
    }

    bool success = false;
    if (!mounted) return;
    final provider = context.read<FarmerProvider>();
    success = await provider.uploadProofAndMarkDelivered(
      widget.customer.id, 
      _videoPath, 
      _photoFiles.map((e) => e.path).toList(),
      _farmerFacePhoto!.path,
      invoicePdfPath: invoicePath,
    );
    
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    
    if (!success) {
      _showErrorDialog(provider.errorMessage ?? 'An error occurred during submission.');
      return;
    }
    
    final updatedCustomer = provider.farmers.firstWhere(
      (c) => c.id == widget.customer.id, 
      orElse: () => widget.customer
    );

    final log = DeliveryLog(
      customer: updatedCustomer,
      timestamp: DateTime.now(),
      latitude: position?.latitude ?? updatedCustomer.latitude,
      longitude: position?.longitude ?? updatedCustomer.longitude,
      items: updatedCustomer.items,
      photoPaths: _photoFiles.map((e) => e.path).toList(),
      videoPath: _videoPath,
      farmerFacePhotoPath: _farmerFacePhoto!.path,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => DeliveryLogScreen(
            deliveryLog: log,
            onBackToHome: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  Widget _buildAnimatedItem(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Applying local Theme override to ensure colors pop
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _kBackground,
        primaryColor: _kPrimary,
        colorScheme: ColorScheme.light(
          primary: _kPrimary,
          secondary: _kPrimaryDark,
          surface: _kSurface,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Complete Delivery', 
            style: TextStyle(
              fontWeight: FontWeight.w700, 
              color: _kTextPrimary,
              letterSpacing: -0.5,
            )
          ),
          centerTitle: true,
          backgroundColor: _kBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: _kTextPrimary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Proximity Banner
              _buildAnimatedItem(0, 
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCirc,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: _isAtLocation ? _kSuccessLight : _kWarningLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (_isAtLocation ? _kSuccess : _kWarning).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isAtLocation ? _kSuccess : _kWarning).withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut), 
                          child: child
                        ),
                        child: Container(
                          key: ValueKey(_isAtLocation),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_isAtLocation ? _kSuccess : _kWarning).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isAtLocation ? Icons.check_circle_rounded : Icons.location_on_rounded,
                            color: _isAtLocation ? _kSuccess : _kWarning,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _locationMessage,
                          style: TextStyle(
                            color: _isAtLocation ? Colors.green.shade900 : Colors.orange.shade900,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white.withValues(alpha: 0.6),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 22),
                          onPressed: _checkInitialLocation,
                          color: _isAtLocation ? _kSuccess : _kWarning,
                          tooltip: 'Refresh Location',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Customer Summary Card
              _buildAnimatedItem(1,
                Container(
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _kTextPrimary.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_kPrimary, _kPrimaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _kPrimary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                              image: (widget.customer.photoUrls != null && widget.customer.photoUrls!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(widget.customer.photoUrls!.first),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (widget.customer.photoUrls != null && widget.customer.photoUrls!.isNotEmpty)
                                ? null
                                : Center(
                                    child: Text(
                                      widget.customer.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.customer.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _kTextPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.customer.fullAddress,
                                  style: const TextStyle(
                                    color: _kTextSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Color(0xFFF1F5F9)),
                      ),
                      const Text(
                        'ORDER ITEMS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _kTextSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.customer.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.shopping_bag_rounded,
                                    size: 16, color: _kPrimary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.displayText,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _kTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // OTP Section
              _buildAnimatedItem(2,
                Container(
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _kTextPrimary.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Verification OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _kTextPrimary,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _showOtpHint = !_showOtpHint),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                _showOtpHint ? 'Hide Hint' : 'Show Hint',
                                style: const TextStyle(
                                  color: _kPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: _showOtpHint
                            ? Container(
                                margin: const EdgeInsets.only(top: 12, bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 18, color: _kPrimary),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Test OTP: ${widget.customer.otp}',
                                      style: const TextStyle(
                                        color: _kPrimaryDark, 
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (i) {
                          return SizedBox(
                            width: 64,
                            height: 72,
                            child: Focus(
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                                  if (_otpControllers[i].text.isEmpty && i > 0) {
                                    _otpControllers[i - 1].clear();
                                    _otpFocusNodes[i - 1].requestFocus();
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: TextField(
                                controller: _otpControllers[i],
                                focusNode: _otpFocusNodes[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28, 
                                  fontWeight: FontWeight.w800,
                                  color: _kPrimaryDark,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: _kBackground,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: _kPrimary,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val.length == 2) {
                                    _otpControllers[i].text = val.substring(1);
                                    _otpControllers[i].selection = const TextSelection.collapsed(offset: 1);
                                    if (i < 3) {
                                      _otpFocusNodes[i + 1].requestFocus();
                                    }
                                  } else if (val.length == 1 && i < 3) {
                                    _otpFocusNodes[i + 1].requestFocus();
                                  }
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // Face Verification
              _buildAnimatedItem(3,
                Container(
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _kTextPrimary.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Face Verification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _kTextPrimary,
                            ),
                          ),
                          if (_farmerFacePhoto != null)
                            const Icon(Icons.check_circle, color: _kSuccess)
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_farmerFacePhoto != null)
                        Stack(
                          children: [
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: FileImage(_farmerFacePhoto!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _farmerFacePhoto = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        InkWell(
                          onTap: _pickFarmerFacePhoto,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _kBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 48, color: _kPrimary),
                                SizedBox(height: 12),
                                Text(
                                  'Tap to capture farmer face',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Photo Upload
              _buildAnimatedItem(4,
                Container(
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _kTextPrimary.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Delivery Proof Photos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _kTextPrimary,
                            ),
                          ),
                          Text(
                            '${_photoFiles.length}/5',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_photoFiles.isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photoFiles.length < 5 ? _photoFiles.length + 1 : 5,
                            itemBuilder: (context, index) {
                              if (index == _photoFiles.length) {
                                return GestureDetector(
                                  onTap: _pickPhoto,
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: _kBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.add_a_photo_rounded, color: _kPrimary, size: 32),
                                    ),
                                  ),
                                );
                              }
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image: FileImage(_photoFiles[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _photoFiles.removeAt(index)),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      else
                        InkWell(
                          onTap: _pickPhoto,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _kBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 32, color: _kPrimary),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Tap to select photos',
                                  style: TextStyle(
                                    color: _kTextSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Video Upload
              _buildAnimatedItem(5,
                Container(
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _kTextPrimary.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Delivery Video',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _kTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('OPTIONAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _kTextSecondary, letterSpacing: 0.5)),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickVideo,
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          decoration: BoxDecoration(
                            color: _videoPath != null ? _kPrimary.withValues(alpha: 0.05) : _kBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _videoPath != null ? _kPrimary.withValues(alpha: 0.3) : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _videoPath != null ? _kPrimary : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: _videoPath == null ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ] : [
                                    BoxShadow(
                                      color: _kPrimary.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Icon(
                                  _videoPath != null ? Icons.play_arrow_rounded : Icons.videocam_rounded,
                                  color: _videoPath != null ? Colors.white : _kTextSecondary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _videoPath != null ? 'Video Attached' : 'Record Video',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: _videoPath != null ? _kPrimaryDark : _kTextPrimary,
                                      ),
                                    ),
                                    if (_videoPath != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _videoPath!.split('/').last,
                                        style: const TextStyle(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ]
                                  ],
                                ),
                              ),
                              if (_videoPath != null)
                                const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 28),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Submit Button
              _buildAnimatedItem(6,
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitDelivery,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Complete Delivery'),
                    ),
                  ),
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
