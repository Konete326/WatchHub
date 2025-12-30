import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String userId;
  final String addressLine;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String? phone;
  final bool isDefault;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.userId,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    this.phone,
    required this.isDefault,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      addressLine: json['addressLine'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zip: json['zip'] as String? ?? '',
      country: json['country'] as String? ?? '',
      phone: json['phone'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
    );
  }

  factory Address.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Address(
      id: doc.id,
      userId: data['userId'] ?? '',
      addressLine: data['addressLine'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zip: data['zip'] ?? '',
      country: data['country'] ?? '',
      phone: data['phone'],
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
      'phone': phone,
      'isDefault': isDefault,
      'createdAt': createdAt,
    };
  }

  String get fullAddress => '$addressLine, $city, $state $zip, $country';
}
