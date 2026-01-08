import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/watch.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/theme.dart';

class WatchCard extends StatelessWidget {
  final Watch watch;
  final VoidCallback onTap;

  const WatchCard({
    super.key,
    required this.watch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF283593), // Light highlight
            offset: Offset(-4, -4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color(0xFF000051), // Dark shadow
            offset: Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section with Badges & Actions
            Stack(
              children: [
                // Product Image
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: watch.images.isNotEmpty
                        ? Hero(
                            tag: 'watch_${watch.id}',
                            child: CachedNetworkImage(
                              imageUrl: watch.images.first,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[200]!,
                                highlightColor: Colors.grey[50]!,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.watch,
                            size: 48,
                            color: Colors.grey,
                          ),
                  ),
                ),

                // Wishlist Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<WishlistProvider>(
                    builder: (context, wishlistProvider, child) {
                      final isInWishlist =
                          wishlistProvider.isInWishlist(watch.id);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            final wishlistItem = wishlistProvider.wishlistItems
                                .where((item) => item.watchId == watch.id)
                                .firstOrNull;
                            await wishlistProvider.toggleWishlist(
                                watch.id, wishlistItem?.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF000051), // Dark shadow
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                                BoxShadow(
                                  color: Color(0xFF283593), // Light highlight
                                  offset: Offset(-2, -2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: isInWishlist
                                  ? AppTheme.errorColor
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Badges
                if (watch.isOnSale)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${watch.discountPercentage}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Out of Stock Overlay
                if (!watch.isInStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SOLD OUT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand Name
                        if (watch.brand != null)
                          Text(
                            watch.brand!.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white60,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        // Product Name
                        Text(
                          watch.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Price and Add to Cart Row
                    Consumer2<SettingsProvider, CartProvider>(
                      builder: (context, settings, cartProvider, child) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Price Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (watch.isOnSale)
                                  Text(
                                    settings.formatPrice(watch.price),
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                Text(
                                  settings.formatPrice(watch.currentPrice),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: watch.isOnSale
                                        ? AppTheme.errorColor
                                        : AppTheme.secondaryColor,
                                  ),
                                ),
                              ],
                            ),

                            // Add to Cart Button
                            if (watch.isInStock)
                              Material(
                                color: Colors
                                    .transparent, // Use container decoration
                                child: InkWell(
                                  onTap: () async {
                                    HapticFeedback.lightImpact();
                                    final success =
                                        await cartProvider.addToCart(watch);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(success
                                              ? 'Added to cart'
                                              : 'Failed to add'),
                                          backgroundColor: success
                                              ? AppTheme.successColor
                                              : AppTheme.errorColor,
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(
                                              0xFF283593), // Light highlight
                                          offset: Offset(-2, -2),
                                          blurRadius: 4,
                                        ),
                                        BoxShadow(
                                          color:
                                              Color(0xFF000051), // Dark shadow
                                          offset: Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
