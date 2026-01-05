import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/watch.dart';
import '../providers/wishlist_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/theme.dart';
import '../utils/image_utils.dart';

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Watch Image with Wishlist Button
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: watch.images.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            final imageUrl = watch.images.first;
                            ImageUtils.showFullScreenImage(context, imageUrl);
                          },
                          child: CachedNetworkImage(
                            imageUrl: watch.images.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.watch,
                            size: 64,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<WishlistProvider>(
                    builder: (context, wishlistProvider, child) {
                      final isInWishlist =
                          wishlistProvider.isInWishlist(watch.id);
                      return CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          icon: Icon(
                            isInWishlist
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isInWishlist
                                ? AppTheme.errorColor
                                : AppTheme.textSecondaryColor,
                          ),
                          onPressed: () {
                            final wishlistItem = wishlistProvider.wishlistItems
                                .where((item) => item.watchId == watch.id)
                                .firstOrNull;
                            wishlistProvider.toggleWishlist(
                                watch.id, wishlistItem?.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (!watch.isInStock)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (watch.isOnSale)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
              ],
            ),

            // Watch Details
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (watch.brand != null)
                      Text(
                        watch.brand!.name,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        watch.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<SettingsProvider>(
                        builder: (context, settings, child) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (watch.isOnSale)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      settings.formatPrice(watch.price),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                Text(
                                  settings.formatPrice(watch.currentPrice),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (watch.averageRating != null &&
                              watch.averageRating! > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      size: 11, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    watch.averageRating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    }),
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
