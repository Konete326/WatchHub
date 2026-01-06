import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/watch_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../utils/image_utils.dart';
import '../../widgets/reviews_section.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/watch_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final String watchId;

  const ProductDetailScreen({super.key, required this.watchId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<WatchProvider>(context, listen: false)
          .fetchWatchById(widget.watchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Details'),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              final watch = Provider.of<WatchProvider>(context).selectedWatch;
              if (watch == null) return const SizedBox();

              final isInWishlist = wishlistProvider.isInWishlist(watch.id);
              return IconButton(
                icon: Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist ? AppTheme.errorColor : Colors.white,
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final wishlistItem = wishlistProvider.wishlistItems
                      .where((item) => item.watchId == watch.id)
                      .firstOrNull;
                  final success = await wishlistProvider.toggleWishlist(
                      watch.id, wishlistItem?.id);

                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isInWishlist
                              ? 'Removed from wishlist'
                              : 'Added to wishlist'),
                          backgroundColor: AppTheme.successColor,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(wishlistProvider.errorMessage ??
                              'Error occurred'),
                          backgroundColor: AppTheme.errorColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<WatchProvider>(
        builder: (context, watchProvider, child) {
          if (watchProvider.isLoading || watchProvider.selectedWatch == null) {
            return const ProductDetailShimmer();
          }

          final watch = watchProvider.selectedWatch!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Carousel
                      if (watch.images.isNotEmpty)
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            CarouselSlider(
                              options: CarouselOptions(
                                height: 350,
                                viewportFraction: 1.0,
                                enableInfiniteScroll: watch.images.length > 1,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                              ),
                              items: watch.images.map<Widget>((imageUrl) {
                                final fullImageUrl = imageUrl;
                                return GestureDetector(
                                  onTap: () => ImageUtils.showFullScreenImage(
                                      context, fullImageUrl),
                                  child: Container(
                                    color: Colors.white,
                                    child: CachedNetworkImage(
                                      imageUrl: fullImageUrl,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey[200]!,
                                        highlightColor: Colors.grey[50]!,
                                        child: Container(
                                          height: 350,
                                          width: double.infinity,
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        height: 350,
                                        color: Colors.grey[100],
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 100,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (watch.images.length > 1)
                              Positioned(
                                bottom: 16,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:
                                      watch.images.asMap().entries.map((entry) {
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: _currentImageIndex == entry.key
                                          ? 24.0
                                          : 8.0,
                                      height: 8.0,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                        color: _currentImageIndex == entry.key
                                            ? AppTheme.primaryColor
                                            : AppTheme.primaryColor
                                                .withOpacity(0.2),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        )
                      else
                        Container(
                          height: 300,
                          width: double.infinity,
                          color: Colors.grey[100],
                          child: const Center(
                            child: Icon(Icons.watch,
                                size: 100, color: Colors.grey),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Brand and Name
                            if (watch.brand != null)
                              Text(
                                watch.brand!.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              watch.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              // Removing maxLines to allow full title in details but ensuring it's not overflowing container
                            ),
                            const SizedBox(height: 12),

                            // Rating
                            if (watch.averageRating != null &&
                                watch.averageRating! > 0)
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  RatingBarIndicator(
                                    rating: watch.averageRating!,
                                    itemBuilder: (context, index) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    itemCount: 5,
                                    itemSize: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${watch.averageRating!.toStringAsFixed(1)} (${watch.reviewCount} reviews)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),

                            // Price
                            Consumer<SettingsProvider>(
                                builder: (context, settings, child) {
                              if (watch.isOnSale) {
                                return Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    Text(
                                      settings.formatPrice(watch.currentPrice),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.errorColor,
                                      ),
                                    ),
                                    Text(
                                      settings.formatPrice(watch.price),
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade500,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: Colors.grey.shade500,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${watch.discountPercentage}% OFF',
                                        style: const TextStyle(
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Text(
                                  settings.formatPrice(watch.price),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                );
                              }
                            }),
                            const SizedBox(height: 20),

                            // Stock Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: (watch.isInStock
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    watch.isInStock
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: watch.isInStock
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    watch.isInStock
                                        ? (watch.isLowStock
                                            ? 'Only ${watch.stock} left!'
                                            : 'In Stock')
                                        : 'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: watch.isInStock
                                          ? (watch.isLowStock
                                              ? AppTheme.errorColor
                                              : AppTheme.successColor)
                                          : AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Description
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              watch.description,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textPrimaryColor,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Specifications
                            if (watch.specifications != null &&
                                watch.specifications!.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Specifications',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      children: watch.specifications!.entries
                                          .map((entry) {
                                        final bool isLast = watch
                                                .specifications!
                                                .entries
                                                .last
                                                .key ==
                                            entry.key;
                                        return Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    flex: 4,
                                                    child: Text(
                                                      entry.key,
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade600,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    flex: 6,
                                                    child: Text(
                                                      entry.value.toString(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!isLast)
                                              Divider(
                                                  height: 1,
                                                  color: Colors.grey.shade100),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 24),

                            // Related Products Section
                            if (watchProvider.relatedWatches.isNotEmpty) ...[
                              const Divider(),
                              const SizedBox(height: 24),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'Similar Watches',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 280,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      watchProvider.relatedWatches.length,
                                  itemBuilder: (context, index) {
                                    final relatedWatch =
                                        watchProvider.relatedWatches[index];
                                    return Container(
                                      width: 180,
                                      margin: const EdgeInsets.only(right: 16),
                                      child: WatchCard(
                                        watch: relatedWatch,
                                        onTap: () {
                                          // Close current detail and open new one
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailScreen(
                                                watchId: relatedWatch.id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Reviews Section
                            const Divider(),
                            const SizedBox(height: 16),
                            ReviewsSection(watchId: watch.id),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Add to Cart Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      final currentQty =
                          cartProvider.getQuantityInCart(watch.id);
                      final isStockLimitReached = currentQty >= watch.stock;
                      final canAddToCart =
                          watch.isInStock && !isStockLimitReached;

                      return ElevatedButton(
                        onPressed: canAddToCart
                            ? () async {
                                HapticFeedback.lightImpact();
                                final success =
                                    await cartProvider.addToCart(watch);

                                if (!mounted) return;

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to cart'),
                                      backgroundColor: AppTheme.successColor,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(cartProvider.errorMessage ??
                                          'Failed to add to cart'),
                                      backgroundColor: AppTheme.errorColor,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          !watch.isInStock
                              ? 'Out of Stock'
                              : (isStockLimitReached
                                  ? 'Stock Limit Reached'
                                  : 'Add to Cart'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
