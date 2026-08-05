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
import 'services/auth_service.dart';
import 'services/farmer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();

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

Future<void> _requestPermissions() async {
  await [
    Permission.location,
    Permission.camera,
    Permission.photos,
  ].request();
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
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF66BB6A),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        chipTheme: ChipThemeData(
          selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
          checkmarkColor: const Color(0xFF2E7D32),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
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
      home: const AuthGate(),
    );
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
                CircularProgressIndicator(color: Color(0xFF2E7D32)),
                SizedBox(height: 16),
                Text(
                  'Connecting to Subsidy Delivery Backend...',
                  style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w500),
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
        return const CustomerListScreen();
    }
  }
}
