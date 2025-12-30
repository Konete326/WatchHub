import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final String? profileImage;
  final String? fcmToken;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.profileImage,
    this.fcmToken,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'USER',
      profileImage: json['profileImage'] as String?,
      fcmToken: json['fcmToken'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      role: data['role'] ?? 'USER',
      profileImage: data['profileImage'],
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'fcmToken': fcmToken,
      'createdAt': createdAt,
    };
  }

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isEmployee => role.toUpperCase() == 'EMPLOYEE';
  bool get isPrivileged => isAdmin || isEmployee;

  bool get canManageUsers => isAdmin; // Only admin can manage users
  bool get canManageFAQs => isAdmin; // Only admin can manage FAQs
  bool get canManageTickets =>
      isAdmin; // Only admin can handle tickets? (User didn't specify, but I'll assume)
  bool get canManageSettings =>
      isAdmin; // Only admin can change shipping/general settings
  bool get canManageCoupons => isAdmin; // Only admin can manage coupons
  bool get canManagePromotions =>
      isAdmin; // Only admin can manage sale highlights

  bool get canManageProducts => isAdmin || isEmployee;
  bool get canManageBrands => isAdmin || isEmployee;
  bool get canManageCategories => isAdmin || isEmployee;
  bool get canManageOrders => isAdmin || isEmployee;
  bool get canManageBanners => isAdmin || isEmployee;
}
