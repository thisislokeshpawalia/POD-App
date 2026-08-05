import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text.trim()).join();

  Future<void> _handlePhoneSubmit() async {
    FocusScope.of(context).unfocus();
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (rawPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rawPhone.isEmpty
                ? 'Please enter your 10-digit mobile number'
                : 'Mobile number must be 10 digits (You entered ${rawPhone.length} digits)',
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final exists = await authProvider.checkPhoneAndRequestOtp(rawPhone);
    if (!mounted) return;

    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!exists) {
      _showRegistrationSheet(rawPhone);
    } else {
      _autofillTestOtp();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully! Enter 1234 to log in.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _autofillTestOtp() {
    const testOtp = '1234';
    for (int i = 0; i < 4; i++) {
      _otpControllers[i].text = testOtp[i];
    }
  }

  void _showRegistrationSheet(String phone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_add_outlined, size: 50, color: Color(0xFF2E7D32)),
            const SizedBox(height: 16),
            const Text(
              'This mobile number is not registered.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mobile: +91 $phone\n\nWould you like to register as a new Delivery Partner?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await context.read<AuthProvider>().startRegistration(phone);
                if (mounted) {
                  _autofillTestOtp();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Registration started! Enter OTP 1234 to proceed.'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Register as Delivery Partner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthProvider>().cancelOtpFlow();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleOtpSubmit() async {
    FocusScope.of(context).unfocus();
    if (_enteredOtp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit OTP')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtpAndLogin(_enteredOtp);
    if (!success && authProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isOtpSent = authProvider.status == AuthStatus.otpSent;
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 80,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Subsidy Delivery Partner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOtpSent
                        ? (authProvider.isRegistrationFlow
                            ? 'Registration: Enter OTP to create account'
                            : 'Enter the verification OTP sent to your phone')
                        : 'Sign in or Register with your Mobile Number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: authProvider.isRegistrationFlow ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                      fontWeight: authProvider.isRegistrationFlow ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 36),

                  if (authProvider.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (!isOtpSent) ...[
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: 'Enter 10 digit mobile number',
                        prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF2E7D32)),
                        prefixText: '+91 ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : _handlePhoneSubmit,
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
                          : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'OTP sent to +91 ${authProvider.currentPhone}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: authProvider.cancelOtpFlow,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (authProvider.otpCode != null)
                      Text(
                        'Demo Testing OTP: ${authProvider.otpCode}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    const SizedBox(height: 24),
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
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
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
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleOtpSubmit,
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
                          : Text(
                              authProvider.isRegistrationFlow ? 'Verify & Register' : 'Verify & Login',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: authProvider.cancelOtpFlow,
                      child: const Text('Back to Phone Entry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
