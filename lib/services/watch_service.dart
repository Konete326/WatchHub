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
    try {
      // Get all banners, filter by isActive if it exists, otherwise include all
      final snapshot = await _firestore
          .collection('banners')
          .orderBy('createdAt', descending: true)
          .get();

      // Filter banners: include if isActive is true or if isActive field doesn't exist
      final banners = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final isActive = data['isActive'];
            // Include if isActive is true, or if isActive field doesn't exist (backward compatibility)
            return isActive == null || isActive == true;
          })
          .map((doc) => HomeBanner.fromFirestore(doc))
          .toList();

      return banners;
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
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

    final snapshot =
        await query.limit(100).get(); // Fetch up to 100 for client-side search

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

    // Manual slicing for "pagination" as a quick migration step
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
        'total': allWatches.length,
        'totalPages': (allWatches.length / limit).ceil()
      },
    };
  }

  Future<List<Watch>> getFeaturedWatches({int limit = 10}) async {
    try {
      // First try to get watches marked as featured
      var snapshot = await _firestore
          .collection('watches')
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      var featuredWatches = snapshot.docs
          .map((doc) => Watch.fromFirestore(doc))
          .toList();

      // If no featured watches found, get the most recent watches instead
      if (featuredWatches.isEmpty) {
        snapshot = await _firestore
            .collection('watches')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        featuredWatches = snapshot.docs
            .map((doc) => Watch.fromFirestore(doc))
            .toList();
      }

      return featuredWatches;
    } catch (e) {
      print('Error fetching featured watches: $e');
      // If there's an error (e.g., missing index), try getting all watches
      try {
        final snapshot = await _firestore
            .collection('watches')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs
            .map((doc) => Watch.fromFirestore(doc))
            .toList();
      } catch (e2) {
        print('Error fetching watches fallback: $e2');
        return [];
      }
    }
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
