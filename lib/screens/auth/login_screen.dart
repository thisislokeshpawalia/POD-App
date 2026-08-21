import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

enum LoginFlowState {
  initial,
  login,
  registerForm,
  registerOtp,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginFlowState _flowState = LoginFlowState.initial;

  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());
  
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _aadhaarController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text.trim()).join();

  void _handleLoginSubmit() async {
    FocusScope.of(context).unfocus();
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (rawPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid 10-digit mobile number.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final exists = await authProvider.checkPhoneAndRequestOtp(rawPhone);
    if (!mounted) return;
    
    if (exists) {
      setState(() => _flowState = LoginFlowState.registerOtp);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent successfully! Enter 1234 to verify.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Account not found. Please register.'),
        backgroundColor: Colors.orange,
      ));
      setState(() => _flowState = LoginFlowState.registerForm);
    }
  }

  void _handleRegisterSubmit() async {
    FocusScope.of(context).unfocus();
    final nameText = _nameController.text.trim();
    if (nameText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(nameText) || nameText.length < 2 || nameText.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the valid name.')),
      );
      return;
    }

    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (rawPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number.')),
      );
      return;
    }

    if (_aadhaarController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Aadhaar number.')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.startRegistration(rawPhone);
    if (!mounted) return;

    // Go to OTP screen
    setState(() {
      _flowState = LoginFlowState.registerOtp;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP sent successfully! Enter 1234 to verify.'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  void _handleOtpSubmit() async {
    FocusScope.of(context).unfocus();
    if (_enteredOtp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit OTP')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtpAndLogin(_enteredOtp);
    
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Invalid OTP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (authProvider.isRegistrationFlow) {
      await authProvider.completeProfile(
        fullName: _nameController.text.trim(),
        email: '',
        aadhaar: _aadhaarController.text.trim(),
        address: 'Sector 132',
        city: 'Noida',
        state: 'UP',
        pincode: '201304',
        vehicleType: 'Bike',
        vehicleNumber: 'NA',
      );
    }
  }

  Widget _buildInitialView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _flowState = LoginFlowState.login;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _flowState = LoginFlowState.registerForm;
            });
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
          child: const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        ),
      ],
    );
  }

  Widget _buildLoginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          onPressed: _handleLoginSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _flowState = LoginFlowState.initial;
              _phoneController.clear();
            });
          },
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildRegisterFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.person, color: Color(0xFF2E7D32)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _aadhaarController,
            keyboardType: TextInputType.number,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Aadhaar Number',
              hintText: 'Enter 12 digit Aadhaar number',
              prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF2E7D32)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleRegisterSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _flowState = LoginFlowState.initial;
                _phoneController.clear();
                _nameController.clear();
                _aadhaarController.clear();
              });
            },
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterOtpView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'OTP sent to +91 ${_phoneController.text}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Demo Testing OTP: 1234',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (i) {
            return SizedBox(
              width: 56,
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                    if (_otpControllers[i].text.isEmpty && i > 0) {
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.length == 2) {
                      _otpControllers[i].text = val[0];
                      if (i < 3) {
                        _otpControllers[i + 1].text = val[1];
                        _otpControllers[i + 1].selection = const TextSelection.collapsed(offset: 1);
                        _otpFocusNodes[i + 1].requestFocus();
                      }
                    } else if (val.length == 1 && i < 3) {
                      _otpFocusNodes[i + 1].requestFocus();
                    } else if (val.isEmpty && i > 0) {
                      _otpFocusNodes[i - 1].requestFocus();
                    }
                  },
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _handleOtpSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _flowState = LoginFlowState.registerForm;
            });
          },
          child: const Text('Back'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                  _flowState == LoginFlowState.initial 
                    ? 'Welcome! Please select an option'
                    : _flowState == LoginFlowState.login
                      ? 'Sign in with your Mobile Number'
                      : _flowState == LoginFlowState.registerForm
                        ? 'Create a new account'
                        : 'Enter the verification OTP sent to your phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 36),
                if (_flowState == LoginFlowState.initial)
                  _buildInitialView()
                else if (_flowState == LoginFlowState.login)
                  _buildLoginView()
                else if (_flowState == LoginFlowState.registerForm)
                  _buildRegisterFormView()
                else if (_flowState == LoginFlowState.registerOtp)
                  _buildRegisterOtpView(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
