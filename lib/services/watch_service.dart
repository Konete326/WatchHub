import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/watch.dart';
import '../models/brand.dart';
import '../models/home_banner.dart';
import '../models/app_settings.dart';
import '../models/promotion_banner.dart';
import '../models/category.dart';

class WatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<PromotionBanner?> getPromotionHighlight() async {
    try {
      final doc = await _firestore
          .collection('settings')
          .doc('promotion_highlight')
          .get();
      if (doc.exists && (doc.data()?['isActive'] ?? true)) {
        return PromotionBanner.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<AppSettings> getAppSettings() async {
    try {
      final doc =
          await _firestore.collection('settings').doc('app_settings').get();
      if (doc.exists) {
        return AppSettings.fromFirestore(doc);
      }
      return AppSettings(deliveryCharge: 0.0, freeDeliveryThreshold: 0);
    } catch (e) {
      return AppSettings(deliveryCharge: 0.0, freeDeliveryThreshold: 0);
    }
  }

  Future<List<HomeBanner>> getBanners() async {
    final snapshot = await _firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => HomeBanner.fromFirestore(doc)).toList();
  }

  Future<Map<String, dynamic>> getWatches({
    int page = 1,
    int limit = 10,
    String? search,
    String? brandId,
    String? category,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    Query query = _firestore.collection('watches');

    // For robust search without Algolia, we'll fetch wider results and filter client-side
    // This supports "contains" and case-insensitivity which Firestore lacks natively
    if (search != null && search.isNotEmpty) {
      // Don't apply 'where' filter here to get more results for client-side filtering
    }

    if (brandId != null) query = query.where('brandId', isEqualTo: brandId);
    if (category != null) query = query.where('category', isEqualTo: category);

    // Note: Firestore requires composite indexes for range filters on multiple fields
    // We might need to apply price filtering client-side if indexes are missing
    if (minPrice != null)
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    if (maxPrice != null)
      query = query.where('price', isLessThanOrEqualTo: maxPrice);

    query = query.orderBy(sortBy, descending: sortOrder == 'desc');

    final aggregateQuery = await query.count().get();
    final totalCount = aggregateQuery.count ?? 0;

    // Fetch only what's needed for the current page request
    // We allow up to 200 for client-side search within current filters
    final snapshot = await query.limit(page * limit).get();

    var allWatches =
        snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();

    // Client-side Search Filtering
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      allWatches = allWatches
          .where((w) =>
              w.name.toLowerCase().contains(searchLower) ||
              w.category.toLowerCase().contains(searchLower))
          .toList();
    }

    // Manual slicing
    final startIndex = (page - 1) * limit;
    final paginatedWatches = allWatches.length > startIndex
        ? allWatches.sublist(
            startIndex, (startIndex + limit).clamp(0, allWatches.length))
        : <Watch>[];

    return {
      'watches': paginatedWatches,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': totalCount,
        'totalPages': (totalCount / limit).ceil()
      },
    };
  }

  Future<List<Watch>> getFeaturedWatches({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('watches')
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();
  }

  Future<Map<String, dynamic>> getWatchById(String id) async {
    final doc = await _firestore.collection('watches').doc(id).get();
    if (!doc.exists) throw Exception('Watch not found');

    final watch = Watch.fromFirestore(doc);

    // Fetch related watches (same brand or category)
    final relatedSnapshot = await _firestore
        .collection('watches')
        .where('category', isEqualTo: watch.category)
        .where(FieldPath.documentId, isNotEqualTo: id)
        .limit(5)
        .get();

    final relatedWatches =
        relatedSnapshot.docs.map((d) => Watch.fromFirestore(d)).toList();

    return {
      'watch': watch,
      'relatedWatches': relatedWatches,
    };
  }

  Future<List<Brand>> getBrands() async {
    final snapshot =
        await _firestore.collection('brands').orderBy('name').get();
    return snapshot.docs.map((doc) => Brand.fromFirestore(doc)).toList();
  }

  Future<List<Category>> getCategories() async {
    final snapshot =
        await _firestore.collection('categories').orderBy('name').get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  Future<List<String>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _firestore
        .collection('watches')
        .limit(100) // Fetch some to filter client-side
        .get();

    final queryLower = query.toLowerCase();
    final suggestions = snapshot.docs
        .map((doc) => doc.data()['name'] as String)
        .where((name) => name.toLowerCase().contains(queryLower))
        .take(5)
        .toList();

    return suggestions;
  }
}
