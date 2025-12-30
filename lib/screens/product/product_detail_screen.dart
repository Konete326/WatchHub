import 'package:flutter/material.dart';
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

class ProductDetailScreen extends StatefulWidget {
  final String watchId;

  const ProductDetailScreen({super.key, required this.watchId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
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
                onPressed: () {
                  final wishlistItem = wishlistProvider.wishlistItems
                      .where((item) => item.watchId == watch.id)
                      .firstOrNull;
                  wishlistProvider.toggleWishlist(watch.id, wishlistItem?.id);
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
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 300,
                            viewportFraction: 1.0,
                            enableInfiniteScroll: watch.images.length > 1,
                          ),
                          items: watch.images.map<Widget>((imageUrl) {
                            final fullImageUrl = imageUrl;
                            return GestureDetector(
                              onTap: () => ImageUtils.showFullScreenImage(
                                  context, fullImageUrl),
                              child: CachedNetworkImage(
                                imageUrl: fullImageUrl,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    height: 300,
                                    width: double.infinity,
                                    color: Colors.white,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 300,
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      settings.formatPrice(watch.price),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
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
                                  const SizedBox(height: 30),
                                ],
                              ),

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
                  child: ElevatedButton(
                    onPressed: watch.isInStock
                        ? () async {
                            final cartProvider = Provider.of<CartProvider>(
                                context,
                                listen: false);
                            final success =
                                await cartProvider.addToCart(watch.id);

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
                      watch.isInStock ? 'Add to Cart' : 'Out of Stock',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
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
