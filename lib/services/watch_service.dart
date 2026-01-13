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

  Future<List<HomeBanner>> getBanners(
      {String? userSegment, String? deviceType}) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('banners')
          .where('isActive', isEqualTo: true)
          .get();

      final banners = snapshot.docs
          .map((doc) => HomeBanner.fromFirestore(doc))
          .where((banner) {
        // Check Scheduling
        if (banner.startDate != null && now.isBefore(banner.startDate!))
          return false;
        if (banner.endDate != null && now.isAfter(banner.endDate!))
          return false;

        // Check Segments
        if (banner.allowedSegments != null &&
            banner.allowedSegments!.isNotEmpty) {
          if (userSegment == null ||
              !banner.allowedSegments!.contains(userSegment.toUpperCase())) {
            return false;
          }
        }

        // Check Device
        if (deviceType != null && banner.targetDevices != null) {
          if (!banner.targetDevices!.contains(deviceType)) return false;
        }

        return true;
      }).toList();

      // Sort by createdAt descending (client-side since we filtered)
      banners.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return banners;
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
  }

  Future<void> trackBannerImpression(String bannerId) async {
    try {
      await _firestore.collection('banners').doc(bannerId).update({
        'impressions': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error tracking impression: $e');
    }
  }

  Future<void> trackBannerClick(String bannerId) async {
    try {
      await _firestore.collection('banners').doc(bannerId).update({
        'clicks': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error tracking click: $e');
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
    bool onlySale = false,
    String? strapType, // 'belt' or 'chain'
    bool inStockOnly = false,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final searchTrimmed = search?.trim();
    final brandIdTrimmed = brandId?.trim();
    final categoryTrimmed = category?.trim();

    try {
      Query query = _firestore.collection('watches');

      // Attempt server-side filtering
      if (brandIdTrimmed != null)
        query = query.where('brandId', isEqualTo: brandIdTrimmed);
      if (categoryTrimmed != null)
        query = query.where('category', isEqualTo: categoryTrimmed);

      if (strapType == 'belt') {
        query = query.where('hasBeltOption', isEqualTo: true);
      } else if (strapType == 'chain') {
        query = query.where('hasChainOption', isEqualTo: true);
      }

      query = query.orderBy(sortBy, descending: sortOrder == 'desc');

      final snapshot = await query
          .limit(200)
          .get(); // Fetch a larger set to filter client-side

      var allWatches =
          snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();

      // Client-side Price Filtering
      if (minPrice != null) {
        allWatches = allWatches.where((w) => w.price >= minPrice).toList();
      }
      if (maxPrice != null) {
        allWatches = allWatches.where((w) => w.price <= maxPrice).toList();
      }

      // Client-side Sale Filtering
      if (onlySale) {
        allWatches = allWatches.where((w) => w.isOnSale).toList();
      }

      // Client-side Availability Filtering
      if (inStockOnly) {
        allWatches = allWatches.where((w) => w.isInStock).toList();
      }

      // Client-side Search Filtering
      if (searchTrimmed != null && searchTrimmed.isNotEmpty) {
        final searchLower = searchTrimmed.toLowerCase();
        allWatches = allWatches
            .where((w) =>
                w.name.toLowerCase().contains(searchLower) ||
                w.category.toLowerCase().contains(searchLower))
            .toList();
      }

      final totalCount = allWatches.length;

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
    } catch (e) {
      print('Error in getWatches server-side query: $e');
      // FALLBACK: Load all watches and filter client-side if server-side query fails (e.g. missing index)
      Query query = _firestore
          .collection('watches')
          .orderBy('createdAt', descending: true);
      final snapshot =
          await query.limit(200).get(); // Limit to 200 for fallback
      var allWatches =
          snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();

      if (brandIdTrimmed != null) {
        allWatches =
            allWatches.where((w) => w.brandId == brandIdTrimmed).toList();
      }
      if (categoryTrimmed != null) {
        final categoryLower = categoryTrimmed.toLowerCase();
        allWatches = allWatches
            .where((w) => w.category.toLowerCase() == categoryLower)
            .toList();
      }
      if (searchTrimmed != null && searchTrimmed.isNotEmpty) {
        final searchLower = searchTrimmed.toLowerCase();
        allWatches = allWatches
            .where((w) =>
                w.name.toLowerCase().contains(searchLower) ||
                w.category.toLowerCase().contains(searchLower))
            .toList();
      }
      if (minPrice != null) {
        allWatches = allWatches.where((w) => w.price >= minPrice).toList();
      }
      if (maxPrice != null) {
        allWatches = allWatches.where((w) => w.price <= maxPrice).toList();
      }
      if (onlySale) {
        allWatches = allWatches.where((w) => w.isOnSale).toList();
      }
      if (strapType == 'belt') {
        allWatches = allWatches.where((w) => w.hasBeltOption).toList();
      } else if (strapType == 'chain') {
        allWatches = allWatches.where((w) => w.hasChainOption).toList();
      }
      if (inStockOnly) {
        allWatches = allWatches.where((w) => w.isInStock).toList();
      }

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
  }

  Future<List<Watch>> getFeaturedWatches({int limit = 10}) async {
    try {
      // First try to get watches marked as featured
      // Note: We remove orderBy here to avoid requiring a composite index
      // We'll sort them client-side instead
      var snapshot = await _firestore
          .collection('watches')
          .where('isFeatured', isEqualTo: true)
          .limit(limit)
          .get();

      var featuredWatches =
          snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();

      // Sort client-side: most recent first
      featuredWatches.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // If no featured watches found, get the most recent watches instead
      if (featuredWatches.isEmpty) {
        snapshot = await _firestore
            .collection('watches')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        featuredWatches =
            snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();
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

        return snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();
      } catch (e2) {
        print('Error fetching watches fallback: $e2');
        return [];
      }
    }
  }

  Future<List<Watch>> getNewArrivals({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('watches')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching new arrivals: $e');
      return [];
    }
  }

  Future<List<Watch>> getLimitedEditions({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('watches')
          .where('isLimitedEdition', isEqualTo: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching limited editions: $e');
      // Fallback: popularity > 80
      final snapshot = await _firestore
          .collection('watches')
          .orderBy('popularity', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();
    }
  }

  Future<List<Watch>> getBudgetWatches(
      {required double maxPrice, int limit = 10}) async {
    try {
      // Use client-side filtering for price if index is missing or just fetch all
      // Actually standard where for price should work if index exists
      final snapshot = await _firestore
          .collection('watches')
          .where('price', isLessThanOrEqualTo: maxPrice)
          .limit(limit)
          .get();

      var watches =
          snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();
      watches.sort((a, b) => a.price.compareTo(b.price));
      return watches;
    } catch (e) {
      print('Error fetching budget watches: $e');
      return [];
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
