enum DeliveryStatus { pending, inTransit, delivered }

class DeliveryItem {
  final String name;
  final double quantity;
  final String unit;

  const DeliveryItem({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  String get displayText =>
      '$name – ${quantity.toStringAsFixed(quantity == quantity.roundToDouble() ? 0 : 1)} $unit';

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      name: json['name'] ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : double.tryParse(json['quantity'].toString()) ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String village;
  final String address;
  final String district;
  final String pinCode;
  DeliveryStatus status;
  final double latitude;
  final double longitude;
  final List<DeliveryItem> items;
  final String otp;
  final String? videoUrl;
  final String? invoiceUrl;
  final String? farmerPhotoUrl;
  final String? farmerFacePhotoUrl;
  final List<String>? photoUrls;
  final List<String>? proofPhotoUrls;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.village,
    required this.address,
    required this.district,
    required this.pinCode,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.items,
    this.otp = '1234',
    this.videoUrl,
    this.invoiceUrl,
    this.farmerPhotoUrl,
    this.farmerFacePhotoUrl,
    this.photoUrls,
    this.proofPhotoUrls,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get fullAddress => '$address, $village, $district – $pinCode';
  bool get isDelivered => status == DeliveryStatus.delivered;
  bool get isPending => status == DeliveryStatus.pending;
  bool get isInTransit => status == DeliveryStatus.inTransit;

  factory Customer.fromJson(Map<String, dynamic> json) {
    DeliveryStatus parsedStatus = DeliveryStatus.pending;
    if (json['status'] == 'delivered') {
      parsedStatus = DeliveryStatus.delivered;
    } else if (json['status'] == 'inTransit') {
      parsedStatus = DeliveryStatus.inTransit;
    }

    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((item) => DeliveryItem.fromJson(item as Map<String, dynamic>))
        .toList();


    return Customer(
      id: json['id']?.toString() ?? json['farmer_id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      village: json['village'] ?? '',
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      pinCode: json['pin_code'] ?? json['pinCode'] ?? '',
      status: parsedStatus,
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude'].toString()) ?? 0.0,
      otp: json['otp'] ?? '1234',
      items: itemsList,
      videoUrl: json['video_url'],
      invoiceUrl: json['invoice_url'],
      farmerPhotoUrl: json['farmer_photo_url'],
      farmerFacePhotoUrl: json['farmer_face_photo_url'],
      photoUrls: json['photo_urls'] != null ? List<String>.from(json['photo_urls']) : null,
      proofPhotoUrls: json['proof_photo_urls'] != null ? List<String>.from(json['proof_photo_urls']) : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'phone': phone,
      'village': village,
      'address': address,
      'district': district,
      'pin_code': pinCode,
      'latitude': latitude,
      'longitude': longitude,
      'otp': otp.isEmpty ? '1234' : otp,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'phone': phone,
      'village': village,
      'address': address,
      'district': district,
      'pin_code': pinCode,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
      'otp': otp,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}