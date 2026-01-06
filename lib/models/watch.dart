import 'package:cloud_firestore/cloud_firestore.dart';
import 'brand.dart';

class Watch {
  final String id;
  final String brandId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final List<String> images;
  final Map<String, dynamic>? specifications;
  final String category;
  final int popularity;
  final double? salePrice;
  final int? discountPercentage;
  final double? averageRating;
  final int reviewCount;
  final String sku;
  final DateTime createdAt;
  final Brand? brand;
  final bool hasBeltOption; // Whether belt option is available
  final bool hasChainOption; // Whether chain option is available
  final String? strapType; // 'belt' or 'chain' (selected by user)
  final String? strapColor; // Color in hex format (selected by user)

  Watch({
    required this.id,
    required this.brandId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.images,
    this.specifications,
    required this.category,
    required this.popularity,
    this.averageRating,
    required this.reviewCount,
    this.salePrice,
    this.discountPercentage,
    required this.sku,
    required this.createdAt,
    this.brand,
    this.hasBeltOption = false,
    this.hasChainOption = false,
    this.strapType,
    this.strapColor,
  });

  factory Watch.fromJson(Map<String, dynamic> json) {
    return Watch(
      id: json['id'] as String? ?? '',
      brandId: json['brandId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price:
          json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      stock: json['stock'] as int? ?? 0,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      specifications: json['specifications'] as Map<String, dynamic>?,
      category: json['category'] as String? ?? '',
      popularity: json['popularity'] as int? ?? 0,
      averageRating: json['averageRating'] != null
          ? double.parse(json['averageRating'].toString())
          : null,
      reviewCount: json['reviewCount'] as int? ?? 0,
      salePrice: json['salePrice'] != null
          ? double.parse(json['salePrice'].toString())
          : null,
      discountPercentage: json['discountPercentage'] as int?,
      hasBeltOption: json['hasBeltOption'] as bool? ?? false,
      hasChainOption: json['hasChainOption'] as bool? ?? false,
      strapType: json['strapType'] as String?,
      strapColor: json['strapColor'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
      brand: json['brand'] != null
          ? Brand.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
    );
  }

  factory Watch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Watch(
      id: doc.id,
      brandId: data['brandId'] ?? '',
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      stock: data['stock'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      specifications: data['specifications'],
      category: data['category'] ?? '',
      popularity: data['popularity'] ?? 0,
      averageRating: data['averageRating'] != null
          ? (data['averageRating'] as num).toDouble()
          : null,
      reviewCount: data['reviewCount'] ?? 0,
      salePrice: data['salePrice'] != null
          ? (data['salePrice'] as num).toDouble()
          : null,
      discountPercentage: data['discountPercentage'],
      hasBeltOption: data['hasBeltOption'] as bool? ?? false,
      hasChainOption: data['hasChainOption'] as bool? ?? false,
      strapType: data['strapType'] as String?,
      strapColor: data['strapColor'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brandId': brandId,
      'name': name,
      'sku': sku,
      'description': description,
      'price': price,
      'stock': stock,
      'images': images,
      'specifications': specifications,
      'category': category,
      'popularity': popularity,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'salePrice': salePrice,
      'discountPercentage': discountPercentage,
      'hasBeltOption': hasBeltOption,
      'hasChainOption': hasChainOption,
      'strapType': strapType,
      'strapColor': strapColor,
      'createdAt': createdAt,
    };
  }

  bool get isOnSale => discountPercentage != null && discountPercentage! > 0;
  double get currentPrice => isOnSale ? (salePrice ?? price) : price;

  bool get isInStock => stock > 0;
  bool get isLowStock => stock > 0 && stock <= 5;

  // Helper to check if any strap options are available
  bool get hasAnyStrapOption => hasBeltOption || hasChainOption;

  Watch copyWith({required int stock}) {
    return Watch(
      id: id,
      brandId: brandId,
      name: name,
      description: description,
      price: price,
      stock: stock,
      images: images,
      specifications: specifications,
      category: category,
      popularity: popularity,
      salePrice: salePrice,
      discountPercentage: discountPercentage,
      averageRating: averageRating,
      reviewCount: reviewCount,
      sku: sku,
      createdAt: createdAt,
      brand: brand,
      hasBeltOption: hasBeltOption,
      hasChainOption: hasChainOption,
      strapType: strapType,
      strapColor: strapColor,
    );
  }
}
