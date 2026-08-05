import 'customer.dart';
class DeliveryLog {
  final Customer customer;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final List<DeliveryItem> items;
  final String? photoPath;
  final String? videoPath;
  DeliveryLog({
    required this.customer,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.items,
    this.photoPath,
    this.videoPath,
  });
}