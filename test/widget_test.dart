// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import 'package:pod_delivery/api/api_service.dart';
import 'package:pod_delivery/main.dart';
import 'package:pod_delivery/providers/auth_provider.dart';
import 'package:pod_delivery/providers/farmer_provider.dart';
import 'package:pod_delivery/repositories/auth_repository.dart';
import 'package:pod_delivery/repositories/farmer_repository.dart';
import 'package:pod_delivery/services/auth_service.dart';
import 'package:pod_delivery/services/farmer_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final apiService = ApiService();
    final authService = AuthService(apiService);
    final farmerService = FarmerService(apiService);
    final authRepo = AuthRepository(authService: authService, apiService: apiService);
    final farmerRepo = FarmerRepository(farmerService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
          ChangeNotifierProvider(create: (_) => FarmerProvider(farmerRepo)),
        ],
        child: const SubsidyDeliveryApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
