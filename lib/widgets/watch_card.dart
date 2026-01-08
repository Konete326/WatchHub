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
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-8, -8),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFFA6ABBD).withOpacity(0.3),
            offset: const Offset(8, 8),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppTheme.primaryColor.withOpacity(0.05),
          highlightColor: AppTheme.primaryColor.withOpacity(0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section with Badges & Actions
              Expanded(
                flex: 5, // Increased flex to give image more space
                child: Stack(
                  children: [
                    // Product Image Background
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                          12), // Reduced padding for larger images
                      decoration: const BoxDecoration(
                        color: Colors
                            .white, // Pure white background for better blending
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: watch.images.isNotEmpty
                          ? Hero(
                              tag: 'watch_${watch.id}',
                              child: CachedNetworkImage(
                                imageUrl: watch.images.first,
                                fit: BoxFit.contain,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey[200]!,
                                  highlightColor: Colors.grey[50]!,
                                  child: Container(color: Colors.white),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
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

                    // Wishlist Button - Highlighted Blue
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Consumer<WishlistProvider>(
                        builder: (context, wishlistProvider, child) {
                          final isInWishlist =
                              wishlistProvider.isInWishlist(watch.id);
                          return InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              final wishlistItem = wishlistProvider
                                  .wishlistItems
                                  .where((item) => item.watchId == watch.id)
                                  .firstOrNull;
                              await wishlistProvider.toggleWishlist(
                                  watch.id, wishlistItem?.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor, // Blue background
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.4),
                                    offset: const Offset(2, 2),
                                    blurRadius: 6,
                                  ),
                                  const BoxShadow(
                                    color: Colors.white,
                                    offset: Offset(-2, -2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color: isInWishlist
                                    ? AppTheme.errorColor // Red heart if active
                                    : Colors.white.withOpacity(
                                        0.9), // White border if inactive
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Sale Badge
                    if (watch.isOnSale)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.errorColor.withOpacity(0.3),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            '${watch.discountPercentage}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    // Out of Stock Overlay
                    if (!watch.isInStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Details
              Expanded(
                flex: 2, // Reduced flex to make text section smaller
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      12, 8, 12, 12), // Tighter padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand Name
                          if (watch.brand != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                watch.brand!.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor.withOpacity(0.6),
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          // Product Name
                          Text(
                            watch.name,
                            style: const TextStyle(
                              fontSize: 13, // Slightly smaller font
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3142),
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Price and Add to Cart Row
                      Consumer2<SettingsProvider, CartProvider>(
                        builder: (context, settings, cartProvider, child) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Price Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
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
                                      fontSize: 15, // Compact price size
                                      fontWeight: FontWeight.w800,
                                      color: watch.isOnSale
                                          ? AppTheme.errorColor
                                          : const Color(0xFF2D3142),
                                    ),
                                  ),
                                ],
                              ),

                              // Add to Cart Button
                              if (watch.isInStock)
                                Material(
                                  color: Colors.transparent,
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
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            duration:
                                                const Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                          8), // Smaller button padding
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppTheme.primaryColor,
                                            Color(0xFF283593),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.4),
                                            offset: const Offset(3, 3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                          const BoxShadow(
                                            color: Colors.white,
                                            offset: Offset(-2, -2),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add_shopping_cart_rounded,
                                        color: AppTheme.secondaryColor,
                                        size: 18, // Smaller icon
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
      ),
    );
  }
}
