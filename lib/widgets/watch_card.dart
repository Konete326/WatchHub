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
import 'neumorphic_widgets.dart';

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
    return NeumorphicContainer(
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section (Concave)
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: NeumorphicContainer(
                        isConcave: true,
                        borderRadius: BorderRadius.circular(15),
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: watch.images.isNotEmpty
                              ? Hero(
                                  tag: 'watch_${watch.id}_home',
                                  child: CachedNetworkImage(
                                    imageUrl: watch.images.first,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                      baseColor: AppTheme.softUiShadowDark
                                          .withOpacity(0.3),
                                      highlightColor: AppTheme.softUiShadowLight
                                          .withOpacity(0.5),
                                      child: Container(color: Colors.white),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.watch,
                                      size: 48, color: Colors.grey),
                                ),
                        ),
                      ),
                    ),

                    // Wishlist Button (Small Convex Circle)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Consumer<WishlistProvider>(
                        builder: (context, wishlistProvider, child) {
                          final isInWishlist =
                              wishlistProvider.isInWishlist(watch.id);
                          return NeumorphicButton(
                            shape: BoxShape.circle,
                            padding: const EdgeInsets.all(6),
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              final wishlistItem = wishlistProvider
                                  .wishlistItems
                                  .where((item) => item.watchId == watch.id)
                                  .firstOrNull;
                              await wishlistProvider.toggleWishlist(
                                  watch.id, wishlistItem?.id);
                            },
                            child: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 14,
                              color: isInWishlist
                                  ? AppTheme.errorColor
                                  : AppTheme.softUiTextColor,
                            ),
                          );
                        },
                      ),
                    ),

                    // Quick View Button
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: NeumorphicButton(
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(8),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (watch.images.isNotEmpty) {
                            showQuickView(
                              context,
                              watch.images.first,
                              'watch_${watch.id}_home',
                            );
                          }
                        },
                        child: const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: AppTheme.softUiTextColor,
                        ),
                      ),
                    ),

                    // Sale Badge (Custom Neumorphic Style)
                    if (watch.isOnSale)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: NeumorphicContainer(
                          borderRadius: BorderRadius.circular(8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            '${watch.discountPercentage}% OFF',
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 9,
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
                            color: AppTheme.softUiBackground.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: NeumorphicContainer(
                              borderRadius: BorderRadius.circular(8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: const Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: AppTheme.softUiTextColor,
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
              ),

              // Product Details
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (watch.brand != null)
                            Text(
                              watch.brand!.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color:
                                    AppTheme.softUiTextColor.withOpacity(0.5),
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 2),
                          Text(
                            watch.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.softUiTextColor,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Price & Add to Cart
                      Consumer2<SettingsProvider, CartProvider>(
                        builder: (context, settings, cartProvider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (watch.isOnSale)
                                    Text(
                                      settings.formatPrice(watch.price),
                                      style: TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 10,
                                        color: AppTheme.softUiTextColor
                                            .withOpacity(0.4),
                                      ),
                                    ),
                                  Text(
                                    settings.formatPrice(watch.currentPrice),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: watch.isOnSale
                                          ? AppTheme.errorColor
                                          : AppTheme.softUiTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (watch.isInStock)
                                NeumorphicButton(
                                  borderRadius: BorderRadius.circular(10),
                                  padding: const EdgeInsets.all(6),
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
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Icon(
                                    Icons.add_shopping_cart_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 16,
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
