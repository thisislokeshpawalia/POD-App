class DeliveryPartnerModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? aadhaar;
  final String? profileImage;
  final DateTime createdAt;

  DeliveryPartnerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.vehicleType,
    this.vehicleNumber,
    this.aadhaar,
    this.profileImage,
    required this.createdAt,
  });

  factory DeliveryPartnerModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'] ?? json['pin_code'],
      vehicleType: json['vehicle_type'],
      vehicleNumber: json['vehicle_number'],
      aadhaar: json['aadhaar'],
      profileImage: json['profile_image'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'aadhaar': aadhaar,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DeliveryPartnerModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? vehicleType,
    String? vehicleNumber,
    String? aadhaar,
    String? profileImage,
  }) {
    return DeliveryPartnerModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      aadhaar: aadhaar ?? this.aadhaar,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
    );
  }
}

class AuthResponseModel {
  final String accessToken;
  final String tokenType;
  final bool isNewUser;
  final DeliveryPartnerModel partner;

  AuthResponseModel({
    required this.accessToken,
    required this.tokenType,
    required this.isNewUser,
    required this.partner,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      isNewUser: json['is_new_user'] ?? false,
      partner: DeliveryPartnerModel.fromJson(json['partner'] ?? {}),
    );
  }
}
