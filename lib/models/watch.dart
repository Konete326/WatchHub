import 'package:cloud_firestore/cloud_firestore.dart';
import 'brand.dart';

class WatchVariant {
  final String colorName;
  final String colorHex;
  final String? image; // Optional specific image for this color

  WatchVariant({
    required this.colorName,
    required this.colorHex,
    this.image,
  });

  factory WatchVariant.fromJson(Map<String, dynamic> json) {
    return WatchVariant(
      colorName: json['colorName'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#000000',
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colorName': colorName,
      'colorHex': colorHex,
      'image': image,
    };
  }
}

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
  final List<WatchVariant>? variants; // Main color variants
  final String? selectedProductColor; // Selected main color (name)
  final String status; // 'DRAFT', 'PUBLISHED', 'SCHEDULED'
  final DateTime? publishAt;
  final DateTime? unpublishAt;
  final String? seoTitle;
  final String? seoDescription;
  final String? slug;
  final String? videoUrl;
  final bool isFeatured;
  final bool isLimitedEdition;

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
    this.variants,
    this.selectedProductColor,
    this.isFeatured = false,
    this.isLimitedEdition = false,
    this.status = 'PUBLISHED', // Default to published for existing items
    this.publishAt,
    this.unpublishAt,
    this.seoTitle,
    this.seoDescription,
    this.slug,
    this.videoUrl,
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
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((v) => WatchVariant.fromJson(v))
              .toList()
          : null,
      selectedProductColor: json['selectedProductColor'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isLimitedEdition: json['isLimitedEdition'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
      brand: json['brand'] != null
          ? Brand.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? 'PUBLISHED',
      publishAt: json['publishAt'] != null
          ? (json['publishAt'] is Timestamp
              ? (json['publishAt'] as Timestamp).toDate()
              : DateTime.parse(json['publishAt'] as String))
          : null,
      unpublishAt: json['unpublishAt'] != null
          ? (json['unpublishAt'] is Timestamp
              ? (json['unpublishAt'] as Timestamp).toDate()
              : DateTime.parse(json['unpublishAt'] as String))
          : null,
      seoTitle: json['seoTitle'] as String?,
      seoDescription: json['seoDescription'] as String?,
      slug: json['slug'] as String?,
      videoUrl: json['videoUrl'] as String?,
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
      variants: data['variants'] != null
          ? (data['variants'] as List)
              .map((v) => WatchVariant.fromJson(v))
              .toList()
          : null,
      selectedProductColor: data['selectedProductColor'] as String?,
      isFeatured: data['isFeatured'] as bool? ?? false,
      isLimitedEdition: data['isLimitedEdition'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'PUBLISHED',
      publishAt: (data['publishAt'] as Timestamp?)?.toDate(),
      unpublishAt: (data['unpublishAt'] as Timestamp?)?.toDate(),
      seoTitle: data['seoTitle'],
      seoDescription: data['seoDescription'],
      slug: data['slug'],
      videoUrl: data['videoUrl'],
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
      'variants': variants?.map((v) => v.toJson()).toList(),
      'selectedProductColor': selectedProductColor,
      'isFeatured': isFeatured,
      'isLimitedEdition': isLimitedEdition,
      'createdAt': createdAt,
      'status': status,
      'publishAt': publishAt,
      'unpublishAt': unpublishAt,
      'seoTitle': seoTitle,
      'seoDescription': seoDescription,
      'slug': slug,
      'videoUrl': videoUrl,
    };
  }

  bool get isOnSale => discountPercentage != null && discountPercentage! > 0;
  double get currentPrice => isOnSale ? (salePrice ?? price) : price;

  bool get isInStock => stock > 0;
  bool get isLowStock => stock > 0 && stock <= 5;

  // Helper to check if any strap options are available
  bool get hasAnyStrapOption => hasBeltOption || hasChainOption;

  Watch copyWith({
    String? id,
    String? brandId,
    String? name,
    String? description,
    double? price,
    int? stock,
    List<String>? images,
    Map<String, dynamic>? specifications,
    String? category,
    int? popularity,
    double? salePrice,
    int? discountPercentage,
    double? averageRating,
    int? reviewCount,
    String? sku,
    DateTime? createdAt,
    Brand? brand,
    bool? hasBeltOption,
    bool? hasChainOption,
    String? strapType,
    String? strapColor,
    List<WatchVariant>? variants,
    String? selectedProductColor,
    bool? isFeatured,
    bool? isLimitedEdition,
    String? status,
    DateTime? publishAt,
    DateTime? unpublishAt,
    String? seoTitle,
    String? seoDescription,
    String? slug,
    String? videoUrl,
  }) {
    return Watch(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      specifications: specifications ?? this.specifications,
      category: category ?? this.category,
      popularity: popularity ?? this.popularity,
      salePrice: salePrice ?? this.salePrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      sku: sku ?? this.sku,
      createdAt: createdAt ?? this.createdAt,
      brand: brand ?? this.brand,
      hasBeltOption: hasBeltOption ?? this.hasBeltOption,
      hasChainOption: hasChainOption ?? this.hasChainOption,
      strapType: strapType ?? this.strapType,
      strapColor: strapColor ?? this.strapColor,
      variants: variants ?? this.variants,
      selectedProductColor: selectedProductColor ?? this.selectedProductColor,
      isFeatured: isFeatured ?? this.isFeatured,
      isLimitedEdition: isLimitedEdition ?? this.isLimitedEdition,
      status: status ?? this.status,
      publishAt: publishAt ?? this.publishAt,
      unpublishAt: unpublishAt ?? this.unpublishAt,
      seoTitle: seoTitle ?? this.seoTitle,
      seoDescription: seoDescription ?? this.seoDescription,
      slug: slug ?? this.slug,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}
