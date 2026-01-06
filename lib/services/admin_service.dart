import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/watch.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../models/review.dart';
import '../models/faq.dart';
import '../models/support_ticket.dart';
import '../models/home_banner.dart';
import '../models/app_settings.dart';
import '../models/coupon.dart';
import '../models/promotion_banner.dart';
import '../models/brand.dart';
import '../models/category.dart';
import 'cloudinary_service.dart';
import 'package:intl/intl.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Brand Management
  Future<List<Brand>> getAllBrands() async {
    final snapshot = await _firestore.collection('brands').get();
    return snapshot.docs.map((doc) => Brand.fromFirestore(doc)).toList();
  }

  Future<Brand> createBrand({
    required String name,
    String? description,
    dynamic logoFile, // XFile for web, File for mobile
  }) async {
    String? logoUrl;
    if (logoFile != null) {
      logoUrl = await CloudinaryService.uploadImage(logoFile, folder: 'brands');
    }

    final docRef = await _firestore.collection('brands').add({
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return Brand.fromFirestore(doc);
  }

  Future<Brand> updateBrand({
    required String id,
    String? name,
    String? description,
    dynamic logoFile, // XFile for web, File for mobile
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    if (logoFile != null) {
      updates['logoUrl'] = await CloudinaryService.uploadImage(
        logoFile,
        folder: 'brands',
        publicId: 'brands/$id',
      );
    }

    await _firestore.collection('brands').doc(id).update(updates);
    final doc = await _firestore.collection('brands').doc(id).get();
    return Brand.fromFirestore(doc);
  }

  Future<void> deleteBrand(String id) async {
    final doc = await _firestore.collection('brands').doc(id).get();
    if (doc.exists) {
      final logoUrl = doc.data()?['logoUrl'];
      if (logoUrl != null) {
        final publicId = CloudinaryService.extractPublicId(logoUrl);
        if (publicId != null) {
          await CloudinaryService.deleteImage(publicId);
        }
      }
      await doc.reference.delete();
    }
  }

  // Category Management
  Future<List<Category>> getAllCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  Future<Category> createCategory({
    required String name,
    String? description,
    dynamic imageFile, // XFile for web, File for mobile
  }) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl =
          await CloudinaryService.uploadImage(imageFile, folder: 'categories');
    }

    final docRef = await _firestore.collection('categories').add({
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return Category.fromFirestore(doc);
  }

  Future<Category> updateCategory({
    required String id,
    String? name,
    String? description,
    dynamic imageFile, // XFile for web, File for mobile
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    if (imageFile != null) {
      updates['imageUrl'] = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'categories',
        publicId: 'categories/$id',
      );
    }

    await _firestore.collection('categories').doc(id).update(updates);
    final doc = await _firestore.collection('categories').doc(id).get();
    return Category.fromFirestore(doc);
  }

  Future<void> deleteCategory(String id) async {
    final doc = await _firestore.collection('categories').doc(id).get();
    if (doc.exists) {
      final imageUrl = doc.data()?['imageUrl'];
      if (imageUrl != null) {
        final publicId = CloudinaryService.extractPublicId(imageUrl);
        if (publicId != null) {
          await CloudinaryService.deleteImage(publicId);
        }
      }
      await doc.reference.delete();
    }
  }

  // Coupon Management
  Future<List<Coupon>> getAllCoupons() async {
    final snapshot = await _firestore.collection('coupons').get();
    return snapshot.docs.map((doc) => Coupon.fromFirestore(doc)).toList();
  }

  Future<Coupon> createCoupon(Coupon coupon) async {
    final docRef = await _firestore.collection('coupons').add(coupon.toJson());
    final doc = await docRef.get();
    return Coupon.fromFirestore(doc);
  }

  Future<void> deleteCoupon(String id) async {
    await _firestore.collection('coupons').doc(id).delete();
  }

  // App Settings Management
  Future<AppSettings> getSettings() async {
    final doc =
        await _firestore.collection('settings').doc('app_settings').get();
    if (doc.exists) {
      return AppSettings.fromFirestore(doc);
    }
    return AppSettings(deliveryCharge: 0.0, freeDeliveryThreshold: 0);
  }

  Future<AppSettings> updateSettings(AppSettings settings) async {
    await _firestore
        .collection('settings')
        .doc('app_settings')
        .set(settings.toJson());
    return settings;
  }

  // Promotion Highlight Management
  Future<PromotionBanner?> getPromotionHighlight() async {
    final doc = await _firestore
        .collection('settings')
        .doc('promotion_highlight')
        .get();
    if (doc.exists) {
      return PromotionBanner.fromFirestore(doc);
    }
    return null;
  }

  Future<PromotionBanner> updatePromotionHighlight({
    required String type,
    dynamic imageFile, // XFile for web, File for mobile
    String? title,
    String? subtitle,
    String? backgroundColor,
    String? textColor,
    String? link,
    bool isActive = true,
  }) async {
    String? imageUrl;
    if (type == 'image' && imageFile != null) {
      imageUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'promotions',
        publicId: 'promotions/highlight',
      );
    } else {
      final oldDoc = await _firestore
          .collection('settings')
          .doc('promotion_highlight')
          .get();
      if (oldDoc.exists && type == 'image') {
        imageUrl = oldDoc.data()?['imageUrl'];
      }
    }

    final data = {
      'type': type,
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'link': link,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('settings')
        .doc('promotion_highlight')
        .set(data);
    final doc = await _firestore
        .collection('settings')
        .doc('promotion_highlight')
        .get();
    return PromotionBanner.fromFirestore(doc);
  }

  // Banners Management
  Future<List<HomeBanner>> getAllBanners() async {
    final snapshot = await _firestore.collection('banners').get();
    return snapshot.docs.map((doc) => HomeBanner.fromFirestore(doc)).toList();
  }

  Future<HomeBanner> createBanner({
    required dynamic imageFile, // XFile for web, File for mobile
    String? title,
    String? subtitle,
    String? link,
  }) async {
    final imageUrl = await CloudinaryService.uploadImage(
      imageFile,
      folder: 'banners',
    );

    final docRef = await _firestore.collection('banners').add({
      'image':
          imageUrl, // Changed from 'imageUrl' to 'image' to match HomeBanner model
      'title': title,
      'subtitle': subtitle,
      'link': link,
      'isActive': true, // Set isActive to true by default
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return HomeBanner.fromFirestore(doc);
  }

  Future<void> deleteBanner(String id) async {
    final doc = await _firestore.collection('banners').doc(id).get();
    if (doc.exists) {
      // Check both 'image' and 'imageUrl' for backward compatibility
      final imageUrl = doc.data()?['image'] ?? doc.data()?['imageUrl'];
      if (imageUrl != null) {
        final publicId = CloudinaryService.extractPublicId(imageUrl);
        if (publicId != null) {
          await CloudinaryService.deleteImage(publicId);
        }
      }
      await doc.reference.delete();
    }
  }

  // Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    // Basic Counts
    final usersCount =
        (await _firestore.collection('users').count().get()).count;
    final ordersCount =
        (await _firestore.collection('orders').count().get()).count;
    final watchesCount =
        (await _firestore.collection('watches').count().get()).count;

    // Get all watches to have category info and names cached
    final watchesSnapshot = await _firestore.collection('watches').get();
    final watches =
        watchesSnapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();
    // ignore: unused_local_variable
    final watchMap = {for (var w in watches) w.id: w};

    // Get last 100 orders for trend and recent activity calculation
    // We order by createdAt descending to get the most recent ones
    final ordersSnapshot = await _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final orders =
        ordersSnapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();

    // Calculate Sales Trend (Last 7 days)
    final salesTrend = <String, double>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      salesTrend[dateStr] = 0.0;
    }

    // For category-wise revenue, we would ideally need order items.
    // For now, let's use watches' popularity and category to estimate distribution
    // if we want to avoid extra calls. Or better, just group watches by category.
    final categoryRevenue = <String, double>{};

    for (var order in orders) {
      // We calculate total revenue from these fetched orders (which are the last 100)
      // This might not be the complete total if there are more than 100 orders,
      // but it provides a good sample for the dashboard.
      final dateStr = DateFormat('yyyy-MM-dd').format(order.createdAt);
      if (salesTrend.containsKey(dateStr)) {
        salesTrend[dateStr] = (salesTrend[dateStr] ?? 0) + order.totalAmount;
      }
    }

    // Since we can't easily get category-wise revenue without fetching all items for all orders,
    // we'll estimate it using the watches' popularity * price for the top watches.
    // This is a "workable" approximation for a client-side dashboard.
    for (var w in watches) {
      if (w.popularity > 0) {
        categoryRevenue[w.category] =
            (categoryRevenue[w.category] ?? 0) + (w.popularity * w.price);
      }
    }

    // Top Selling (Using popularity based on watches)
    final topSelling = [...watches];
    topSelling.sort((a, b) => b.popularity.compareTo(a.popularity));
    final top5Selling = topSelling.take(5).toList();

    // Recent Activity
    // Fetch latest 5 users
    final usersSnapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    final recentUsers =
        usersSnapshot.docs.map((doc) => User.fromFirestore(doc)).toList();

    final activities = <Map<String, dynamic>>[];
    for (var o in orders.take(5)) {
      activities.add({
        'type': 'order',
        'title': 'New Order #${o.id.substring(o.id.length - 5).toUpperCase()}',
        'subtitle': 'Order of \$${o.totalAmount.toStringAsFixed(2)}',
        'time': o.createdAt,
      });
    }
    for (var u in recentUsers) {
      activities.add({
        'type': 'user',
        'title': 'User Registered',
        'subtitle': u.name,
        'time': u.createdAt,
      });
    }
    activities.sort(
        (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

    // For total revenue across ALL orders, we still need a full scan if not using triggers.
    // Let's use the most efficient way to get it for now.
    final allOrdersSnapshot = await _firestore.collection('orders').get();
    double absoluteTotalRevenue = 0;
    for (var doc in allOrdersSnapshot.docs) {
      absoluteTotalRevenue += (doc.data()['totalAmount'] ?? 0.0).toDouble();
    }

    return {
      'totalUsers': usersCount,
      'totalOrders': ordersCount,
      'totalWatches': watchesCount,
      'totalRevenue': absoluteTotalRevenue,
      'salesTrend': salesTrend,
      'topSelling': top5Selling,
      'categoryRevenue': categoryRevenue,
      'recentActivity': activities,
      'allWatches': watches,
    };
  }

  // Watches Management
  Future<Map<String, dynamic>> getAllWatches({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    Query query = _firestore.collection('watches');

    // Get total count (server-side, very efficient)
    final aggregateQuery = await query.count().get();
    final totalCount = aggregateQuery.count ?? 0;

    // Fetch only up to what we need
    final snapshot = await query.limit(page * limit).get();
    var watches = snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();

    if (search != null && search.isNotEmpty) {
      watches = watches
          .where((w) => w.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    final startIndex = (page - 1) * limit;
    final paginatedWatches = watches.length > startIndex
        ? watches.sublist(
            startIndex, (startIndex + limit).clamp(0, watches.length))
        : <Watch>[];

    return {
      'watches': paginatedWatches,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': totalCount,
        'totalPages': (totalCount / limit).ceil()
      }
    };
  }

  /// Check if a watch name already exists (case-insensitive)
  /// Returns true if a watch with the same name exists (excluding the current watch if editing)
  Future<bool> watchNameExists(String name, {String? excludeWatchId}) async {
    final snapshot = await _firestore.collection('watches').get();
    final watches =
        snapshot.docs.map((doc) => Watch.fromFirestore(doc)).toList();

    return watches.any((w) =>
        w.name.toLowerCase().trim() == name.toLowerCase().trim() &&
        (excludeWatchId == null || w.id != excludeWatchId));
  }

  // User Stats & History
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    // Fetch all orders for this user
    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    final orders =
        ordersSnapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();

    int totalOrders = orders.length;
    int cancelledOrders = 0;
    double totalSpent = 0.0;

    for (var order in orders) {
      if (order.status == 'CANCELLED') {
        cancelledOrders++;
      } else {
        totalSpent += order.totalAmount;
      }
    }

    return {
      'totalOrders': totalOrders,
      'cancelledOrders': cancelledOrders,
      'totalSpent': totalSpent,
      'orders': orders,
    };
  }

  // Notifications
  // Notifications
  Future<void> sendNotification({
    String? userId,
    required String title,
    required String body,
    required String type,
    int expiryDays = 7, // Default 7 days
  }) async {
    final notificationData = {
      'title': title,
      'body': body,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(Duration(days: expiryDays)),
      'isRead': false,
      'sentBy': 'admin',
    };

    if (userId != null) {
      // Send to specific user
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notificationData);

      // Also add to a queue for Cloud Functions to pick up and send FCM
      await _firestore.collection('notification_queue').add({
        ...notificationData,
        'targetUser': userId,
        'status': 'pending',
      });

      // Save to Admin History
      await _firestore.collection('admin_notification_history').add({
        ...notificationData,
        'target': 'User: $userId',
      });
    } else {
      // Send to all users (Broadcast)
      // 1. Add to announcements for in-app feed
      // Using a valid collection for Broadcasts that users can query
      await _firestore.collection('announcements').add(notificationData);

      // 2. Add to queue for Cloud Functions to send to 'all_users' topic
      await _firestore.collection('notification_queue').add({
        ...notificationData,
        'targetTopic': 'all_users',
        'status': 'pending',
      });

      // Save to Admin History
      await _firestore.collection('admin_notification_history').add({
        ...notificationData,
        'target': 'Broadcast (All Users)',
      });
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    final snapshot = await _firestore
        .collection('admin_notification_history')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<Watch> createWatch({
    required String brandId,
    required String name,
    required String sku,
    required String description,
    required double price,
    required int stock,
    required String category,
    Map<String, dynamic>? specifications,
    int? discountPercentage,
    List<dynamic>? imageFiles, // XFile for web, File for mobile
    bool hasBeltOption = false,
    bool hasChainOption = false,
  }) async {
    final imageUrls = <String>[];
    if (imageFiles != null && imageFiles.isNotEmpty) {
      try {
        imageUrls.addAll(await CloudinaryService.uploadImages(imageFiles,
            folder: 'watches'));
      } catch (e) {
        print('Error uploading images: $e');
      }
    }

    // Calculate salePrice if discountPercentage is provided
    double? salePrice;
    if (discountPercentage != null && discountPercentage > 0) {
      salePrice = price * (1 - discountPercentage / 100);
    }

    final docRef = await _firestore.collection('watches').add({
      'brandId': brandId,
      'name': name,
      'sku': sku,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'stock': stock,
      'category': category,
      'specifications': specifications,
      'discountPercentage': discountPercentage,
      'hasBeltOption': hasBeltOption,
      'hasChainOption': hasChainOption,
      'images': imageUrls,
      'popularity': 0,
      'reviewCount': 0,
      'averageRating': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception(
          'Failed to create watch - document not found after creation');
    }
    return Watch.fromFirestore(doc);
  }

  /// Updates an existing watch product.
  Future<Watch> updateWatch({
    required String id,
    String? brandId,
    String? name,
    String? sku,
    String? description,
    double? price,
    int? stock,
    String? category,
    Map<String, dynamic>? specifications,
    int? discountPercentage,
    List<dynamic>? imageFiles, // XFile for web, File for mobile
    bool? hasBeltOption,
    bool? hasChainOption,
  }) async {
    final updates = <String, dynamic>{};
    if (brandId != null) updates['brandId'] = brandId;
    if (name != null) updates['name'] = name;
    if (sku != null) updates['sku'] = sku;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (stock != null) updates['stock'] = stock;
    if (category != null) updates['category'] = category;
    if (specifications != null) updates['specifications'] = specifications;
    if (discountPercentage != null)
      updates['discountPercentage'] = discountPercentage;
    if (hasBeltOption != null) updates['hasBeltOption'] = hasBeltOption;
    if (hasChainOption != null) updates['hasChainOption'] = hasChainOption;

    // Recalculate salePrice if price or discountPercentage is updated
    if (price != null || discountPercentage != null) {
      final currentDoc = await _firestore.collection('watches').doc(id).get();
      final currentData = currentDoc.data();
      final effectivePrice =
          price ?? (currentData?['price'] as num?)?.toDouble() ?? 0.0;
      final effectiveDiscount =
          discountPercentage ?? currentData?['discountPercentage'] as int?;

      if (effectiveDiscount != null && effectiveDiscount > 0) {
        updates['salePrice'] = effectivePrice * (1 - effectiveDiscount / 100);
      } else {
        updates['salePrice'] = null;
      }
    }

    if (imageFiles != null && imageFiles.isNotEmpty) {
      final imageUrls =
          await CloudinaryService.uploadImages(imageFiles, folder: 'watches');
      updates['images'] = FieldValue.arrayUnion(imageUrls);
    }

    await _firestore.collection('watches').doc(id).update(updates);
    final doc = await _firestore.collection('watches').doc(id).get();
    return Watch.fromFirestore(doc);
  }

  Future<void> deleteWatch(String id) async {
    final doc = await _firestore.collection('watches').doc(id).get();
    if (doc.exists) {
      final images = List<String>.from(doc.data()?['images'] ?? []);
      for (var url in images) {
        final publicId = CloudinaryService.extractPublicId(url);
        if (publicId != null) {
          await CloudinaryService.deleteImage(publicId);
        }
      }
      await doc.reference.delete();
    }
  }

  // Orders Management
  Future<Map<String, dynamic>> getAllOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    Query query =
        _firestore.collection('orders').orderBy('createdAt', descending: true);
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    final aggregateQuery = await query.count().get();
    final totalCount = aggregateQuery.count ?? 0;

    final snapshot = await query.limit(page * limit).get();
    final orders =
        snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();

    final startIndex = (page - 1) * limit;
    final paginatedOrders = orders.length > startIndex
        ? orders.sublist(
            startIndex, (startIndex + limit).clamp(0, orders.length))
        : <Order>[];

    return {
      'orders': paginatedOrders,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': totalCount,
        'totalPages': (totalCount / limit).ceil()
      }
    };
  }

  Future<Order> updateOrderStatus(String id, String status) async {
    await _firestore.collection('orders').doc(id).update({'status': status});
    final doc = await _firestore.collection('orders').doc(id).get();
    return Order.fromFirestore(doc);
  }

  // Users Management
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
  }) async {
    Query query = _firestore.collection('users');

    if (role != null && role.toUpperCase() != 'ALL') {
      query = query.where('role', isEqualTo: role.toUpperCase());
    }

    final aggregateQuery = await query.count().get();
    final totalCount = aggregateQuery.count ?? 0;

    final snapshot = await query.limit(page * limit).get();
    var users = snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();

    if (search != null && search.isNotEmpty) {
      users = users
          .where((u) =>
              u.name.toLowerCase().contains(search.toLowerCase()) ||
              u.email.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    final startIndex = (page - 1) * limit;
    final paginatedUsers = users.length > startIndex
        ? users.sublist(startIndex, (startIndex + limit).clamp(0, users.length))
        : <User>[];

    return {
      'users': paginatedUsers,
      'pagination': {
        'page': page,
        'limit': limit,
        'search': search,
        'role': role,
        'total': totalCount,
        'totalPages': (totalCount / limit).ceil()
      }
    };
  }

  Future<User> updateUserRole(
      String id, String role, String currentAdminId) async {
    if (id == currentAdminId) {
      throw Exception('You cannot change your own role.');
    }

    final targetDoc = await _firestore.collection('users').doc(id).get();
    final currentRole = targetDoc.data()?['role']?.toString().toUpperCase();

    if (currentRole == 'ADMIN' && role.toUpperCase() != 'ADMIN') {
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'ADMIN')
          .get();

      if (adminQuery.docs.length <= 1) {
        throw Exception('At least one admin must remain in the system.');
      }
    }

    await _firestore
        .collection('users')
        .doc(id)
        .update({'role': role.toUpperCase()});
    final doc = await _firestore.collection('users').doc(id).get();
    return User.fromFirestore(doc);
  }

  // Reviews Management
  Future<Map<String, dynamic>> getAllReviews({
    int page = 1,
    int limit = 20,
    String? watchId,
    String? userId,
    int? rating,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    Query query = _firestore
        .collection('reviews')
        .orderBy(sortBy, descending: sortOrder == 'desc');
    if (watchId != null) query = query.where('watchId', isEqualTo: watchId);
    if (userId != null) query = query.where('userId', isEqualTo: userId);
    if (rating != null) query = query.where('rating', isEqualTo: rating);

    final snapshot = await query.get();
    final reviews =
        snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();

    final startIndex = (page - 1) * limit;
    final paginatedReviews = reviews.length > startIndex
        ? reviews.sublist(
            startIndex, (startIndex + limit).clamp(0, reviews.length))
        : <Review>[];

    return {
      'reviews': paginatedReviews,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': reviews.length,
        'totalPages': (reviews.length / limit).ceil()
      }
    };
  }

  Future<void> deleteReview(String id) async {
    await _firestore.collection('reviews').doc(id).delete();
  }

  // FAQs Management
  Future<FAQ> createFAQ({
    required String question,
    required String answer,
    required String category,
    int order = 0,
  }) async {
    final docRef = await _firestore.collection('faqs').add({
      'question': question,
      'answer': answer,
      'category': category,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return FAQ.fromFirestore(doc);
  }

  Future<FAQ> updateFAQ({
    required String id,
    String? question,
    String? answer,
    String? category,
    int? order,
  }) async {
    final updates = <String, dynamic>{};
    if (question != null) updates['question'] = question;
    if (answer != null) updates['answer'] = answer;
    if (category != null) updates['category'] = category;
    if (order != null) updates['order'] = order;

    await _firestore.collection('faqs').doc(id).update(updates);
    final doc = await _firestore.collection('faqs').doc(id).get();
    return FAQ.fromFirestore(doc);
  }

  Future<void> deleteFAQ(String id) async {
    await _firestore.collection('faqs').doc(id).delete();
  }

  // Support Tickets Management
  Future<Map<String, dynamic>> getAllTickets({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    Query query = _firestore
        .collection('support_tickets')
        .orderBy('createdAt', descending: true);
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    final aggregateQuery = await query.count().get();
    final totalCount = aggregateQuery.count ?? 0;

    final snapshot = await query.limit(page * limit).get();
    final tickets =
        snapshot.docs.map((doc) => SupportTicket.fromFirestore(doc)).toList();

    final startIndex = (page - 1) * limit;
    final paginatedTickets = tickets.length > startIndex
        ? tickets.sublist(
            startIndex, (startIndex + limit).clamp(0, tickets.length))
        : <SupportTicket>[];

    return {
      'tickets': paginatedTickets,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': totalCount,
        'totalPages': (totalCount / limit).ceil()
      }
    };
  }

  Future<SupportTicket> updateTicketStatus(String id, String status) async {
    await _firestore
        .collection('support_tickets')
        .doc(id)
        .update({'status': status});
    final doc = await _firestore.collection('support_tickets').doc(id).get();
    return SupportTicket.fromFirestore(doc);
  }
}
