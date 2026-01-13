import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final String? profileImage;
  final String? fcmToken;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final int loyaltyPoints;
  final String loyaltyTier;
  final double storeCredit;
  final String referralCode;
  final String? savedStrapSize;

  // Segmentation & RFM
  final double ltv;
  final int totalOrders;
  final DateTime? lastPurchaseAt;
  final int recencyScore;
  final int frequencyScore;
  final int monetaryScore;
  final bool isVIP;
  final List<String> tags;

  // Security & RBAC
  final List<String> permissions;
  final bool twoFactorEnabled;
  final List<String> ipAllowlist;
  final String? lastLoginIp;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.profileImage,
    this.fcmToken,
    this.notificationsEnabled = true,
    required this.createdAt,
    this.loyaltyPoints = 0,
    this.loyaltyTier = 'Bronze',
    this.storeCredit = 0.0,
    this.referralCode = '',
    this.savedStrapSize,
    this.ltv = 0.0,
    this.totalOrders = 0,
    this.lastPurchaseAt,
    this.recencyScore = 0,
    this.frequencyScore = 0,
    this.monetaryScore = 0,
    this.isVIP = false,
    this.tags = const [],
    this.permissions = const [],
    this.twoFactorEnabled = false,
    this.ipAllowlist = const [],
    this.lastLoginIp,
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
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
      loyaltyTier: json['loyaltyTier'] as String? ?? 'Bronze',
      storeCredit: (json['storeCredit'] ?? 0.0).toDouble(),
      referralCode: json['referralCode'] as String? ?? '',
      savedStrapSize: json['savedStrapSize'] as String?,
      ltv: (json['ltv'] ?? 0.0).toDouble(),
      totalOrders: json['totalOrders'] as int? ?? 0,
      lastPurchaseAt: json['lastPurchaseAt'] != null
          ? (json['lastPurchaseAt'] is Timestamp
              ? (json['lastPurchaseAt'] as Timestamp).toDate()
              : DateTime.parse(json['lastPurchaseAt'] as String))
          : null,
      recencyScore: json['recencyScore'] as int? ?? 0,
      frequencyScore: json['frequencyScore'] as int? ?? 0,
      monetaryScore: json['monetaryScore'] as int? ?? 0,
      isVIP: json['isVIP'] as bool? ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      ipAllowlist: json['ipAllowlist'] != null
          ? List<String>.from(json['ipAllowlist'])
          : [],
      lastLoginIp: json['lastLoginIp'] as String?,
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
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      loyaltyPoints: data['loyaltyPoints'] ?? 0,
      loyaltyTier: data['loyaltyTier'] ?? 'Bronze',
      storeCredit: (data['storeCredit'] ?? 0.0).toDouble(),
      referralCode: data['referralCode'] ?? '',
      savedStrapSize: data['savedStrapSize'],
      ltv: (data['ltv'] ?? 0.0).toDouble(),
      totalOrders: data['totalOrders'] ?? 0,
      lastPurchaseAt: (data['lastPurchaseAt'] as Timestamp?)?.toDate(),
      recencyScore: data['recencyScore'] ?? 0,
      frequencyScore: data['frequencyScore'] ?? 0,
      monetaryScore: data['monetaryScore'] ?? 0,
      isVIP: data['isVIP'] ?? false,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      permissions: data['permissions'] != null
          ? List<String>.from(data['permissions'])
          : [],
      twoFactorEnabled: data['twoFactorEnabled'] ?? false,
      ipAllowlist: data['ipAllowlist'] != null
          ? List<String>.from(data['ipAllowlist'])
          : [],
      lastLoginIp: data['lastLoginIp'],
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
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt,
      'loyaltyPoints': loyaltyPoints,
      'loyaltyTier': loyaltyTier,
      'storeCredit': storeCredit,
      'referralCode': referralCode,
      'savedStrapSize': savedStrapSize,
      'ltv': ltv,
      'totalOrders': totalOrders,
      'lastPurchaseAt': lastPurchaseAt,
      'recencyScore': recencyScore,
      'frequencyScore': frequencyScore,
      'monetaryScore': monetaryScore,
      'isVIP': isVIP,
      'tags': tags,
      'permissions': permissions,
      'twoFactorEnabled': twoFactorEnabled,
      'ipAllowlist': ipAllowlist,
      'lastLoginIp': lastLoginIp,
    };
  }

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isEmployee => role.toUpperCase() == 'EMPLOYEE';
  bool get isPrivileged => isAdmin || isEmployee;

  // Fine-grained Permission Checks
  bool hasPermission(String permission) {
    if (isAdmin) return true; // Admins have all permissions
    return permissions.contains(permission);
  }

  bool get canManageUsers => hasPermission('MANAGE_USERS');
  bool get canManageFAQs => hasPermission('MANAGE_FAQS');
  bool get canManageTickets => hasPermission('MANAGE_TICKETS');
  bool get canManageSettings => hasPermission('MANAGE_SETTINGS');
  bool get canManageCoupons => hasPermission('MANAGE_COUPONS');
  bool get canManagePromotions => hasPermission('MANAGE_PROMOTIONS');
  bool get canManageProducts => hasPermission('MANAGE_PRODUCTS');
  bool get canManageBrands => hasPermission('MANAGE_BRANDS');
  bool get canManageCategories => hasPermission('MANAGE_CATEGORIES');
  bool get canManageOrders => hasPermission('MANAGE_ORDERS');
  bool get canManageBanners => hasPermission('MANAGE_BANNERS');
  bool get canViewAuditLogs => hasPermission('VIEW_AUDIT_LOGS');

  String get rfmSummary {
    if (recencyScore == 0) return 'New';
    final avg = (recencyScore + frequencyScore + monetaryScore) / 3;
    if (avg >= 4.5) return 'Champion';
    if (avg >= 3.5) return 'Loyal';
    if (avg >= 2.5) return 'At Risk';
    return 'Hibernating';
  }

  User copyWith({
    String? name,
    String? phone,
    String? profileImage,
    bool? notificationsEnabled,
    int? loyaltyPoints,
    String? loyaltyTier,
    double? storeCredit,
    String? savedStrapSize,
    double? ltv,
    int? totalOrders,
    DateTime? lastPurchaseAt,
    int? recencyScore,
    int? frequencyScore,
    int? monetaryScore,
    bool? isVIP,
    List<String>? tags,
    List<String>? permissions,
    bool? twoFactorEnabled,
    List<String>? ipAllowlist,
    String? lastLoginIp,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role,
      profileImage: profileImage ?? this.profileImage,
      fcmToken: fcmToken,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      storeCredit: storeCredit ?? this.storeCredit,
      referralCode: referralCode,
      savedStrapSize: savedStrapSize ?? this.savedStrapSize,
      ltv: ltv ?? this.ltv,
      totalOrders: totalOrders ?? this.totalOrders,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      recencyScore: recencyScore ?? this.recencyScore,
      frequencyScore: frequencyScore ?? this.frequencyScore,
      monetaryScore: monetaryScore ?? this.monetaryScore,
      isVIP: isVIP ?? this.isVIP,
      tags: tags ?? this.tags,
      permissions: permissions ?? this.permissions,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      ipAllowlist: ipAllowlist ?? this.ipAllowlist,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
    );
  }
}

// Permission Constants
class UserPermissions {
  static const String manageUsers = 'MANAGE_USERS';
  static const String manageFAQs = 'MANAGE_FAQS';
  static const String manageTickets = 'MANAGE_TICKETS';
  static const String manageSettings = 'MANAGE_SETTINGS';
  static const String manageCoupons = 'MANAGE_COUPONS';
  static const String managePromotions = 'MANAGE_PROMOTIONS';
  static const String manageProducts = 'MANAGE_PRODUCTS';
  static const String manageBrands = 'MANAGE_BRANDS';
  static const String manageCategories = 'MANAGE_CATEGORIES';
  static const String manageOrders = 'MANAGE_ORDERS';
  static const String manageBanners = 'MANAGE_BANNERS';
  static const String viewAuditLogs = 'VIEW_AUDIT_LOGS';

  static List<String> get all => [
        manageUsers,
        manageFAQs,
        manageTickets,
        manageSettings,
        manageCoupons,
        managePromotions,
        manageProducts,
        manageBrands,
        manageCategories,
        manageOrders,
        manageBanners,
        viewAuditLogs,
      ];
}
