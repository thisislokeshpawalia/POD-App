import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'api/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/farmer_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/farmer_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/profile_completion_screen.dart';
import 'screens/customer_list_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/farmer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final authService = AuthService(apiService);
  final farmerService = FarmerService(apiService);
  final authRepository = AuthRepository(authService: authService, apiService: apiService);
  final farmerRepository = FarmerRepository(farmerService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository)..initAutoLogin(),
        ),
        ChangeNotifierProvider(
          create: (_) => FarmerProvider(farmerRepository),
        ),
      ],
      child: const SubsidyDeliveryApp(),
    ),
  );
}


class SubsidyDeliveryApp extends StatelessWidget {
  const SubsidyDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subsidy Delivery Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF818CF8),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        chipTheme: ChipThemeData(
          selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
          checkmarkColor: const Color(0xFF6366F1),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class PermissionGate extends StatefulWidget {
  final Widget child;
  const PermissionGate({super.key, required this.child});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    final cameraStatus = await Permission.camera.status;
    final allGranted = locationStatus.isGranted && cameraStatus.isGranted;
    
    if (allGranted) {
      setState(() { _permissionsGranted = true; });
    } else {
      // Directly request permissions instead of showing a custom dialog first.
      // This is the standard pattern and avoids popping up an unnecessary alert dialog.
      final statuses = await [Permission.location, Permission.camera].request();
      final nowAllGranted = statuses[Permission.location]!.isGranted && 
                            statuses[Permission.camera]!.isGranted;
      
      setState(() { _permissionsGranted = nowAllGranted; });
      
      // If still not granted, we might want to guide the user to settings, 
      // but for now, we just remain on the loading indicator or show a message.
      if (!nowAllGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions are required to use this app. Please grant them in settings.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsGranted) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return widget.child;
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF6366F1)),
                SizedBox(height: 16),
                Text(
                  'Connecting to Subsidy Delivery Backend...',
                  style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );

      case AuthStatus.unauthenticated:
      case AuthStatus.otpSent:
        return const LoginScreen();

      case AuthStatus.needsProfile:
        return const ProfileCompletionScreen();

      case AuthStatus.authenticated:
        return const PermissionGate(child: CustomerListScreen());
    }
  }
}
