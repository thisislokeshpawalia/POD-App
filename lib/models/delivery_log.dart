import 'customer.dart';
class DeliveryLog {
  final Customer customer;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final List<DeliveryItem> items;
  final List<String>? photoPaths;
  final String? videoPath;
  final String? farmerFacePhotoPath;
  DeliveryLog({
    required this.customer,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.items,
    this.photoPaths,
    this.videoPath,
    this.farmerFacePhotoPath,
  });
}