import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/watch.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/theme.dart';
import '../utils/premium_dialogs.dart';
import 'premium_card.dart';

class WatchCard extends StatelessWidget {
  final Watch watch;
  final VoidCallback onTap;
  final bool isListMode;
  final String? heroTag;

  const WatchCard({
    super.key,
    required this.watch,
    required this.onTap,
    this.isListMode = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    if (isListMode) {
      return _buildListMode(context);
    }
    return _buildGridMode(context);
  }

  Widget _buildGridMode(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: watch.images.isNotEmpty
                          ? Hero(
                              tag: heroTag ?? 'watch_${watch.id}_grid',
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
                // Wishlist Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildWishlistButton(),
                ),

                // Sale Badge
                if (watch.isOnSale)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildSaleBadge(),
                  ),
              ],
            ),
          ),

          // Product Details
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
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
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.goldColor,
                            letterSpacing: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        watch.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Price & Add to Cart
                  _buildPriceAndCart(context),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).moveY(begin: 10, end: 0);
  }

  Widget _buildListMode(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      borderRadius: 16,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image Section
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: watch.images.isNotEmpty
                    ? Hero(
                        tag: heroTag ?? 'watch_${watch.id}_list',
                        child: CachedNetworkImage(
                          imageUrl: watch.images.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor:
                                AppTheme.softUiShadowDark.withOpacity(0.3),
                            highlightColor:
                                AppTheme.softUiShadowLight.withOpacity(0.5),
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.image_not_supported)),
                        ),
                      )
                    : const Center(child: Icon(Icons.watch)),
              ),
            ),
            const SizedBox(width: 16),
            // Details Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (watch.brand != null)
                        Expanded(
                          child: Text(
                            watch.brand!.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.goldColor,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      _buildWishlistButton(small: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    watch.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  _buildPriceAndCart(context, small: true),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).moveX(begin: 10, end: 0);
  }

  Widget _buildWishlistButton({bool small = false}) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isInWishlist = wishlistProvider.isInWishlist(watch.id);
        return Semantics(
          label: isInWishlist ? 'Remove from wishlist' : 'Add to wishlist',
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              HapticFeedback.selectionClick();
              final wishlistItem = wishlistProvider.wishlistItems
                  .where((item) => item.watchId == watch.id)
                  .firstOrNull;
              await wishlistProvider.toggleWishlist(watch.id, wishlistItem?.id);
            },
            child: Container(
              padding: const EdgeInsets.all(12), // Increased tap target padding
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  size: small ? 16 : 18,
                  color: isInWishlist
                      ? AppTheme.errorColor
                      : AppTheme.charcoalBlack,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${watch.discountPercentage}% OFF',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriceAndCart(BuildContext context, {bool small = false}) {
    return Consumer2<SettingsProvider, CartProvider>(
      builder: (context, settings, cartProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (watch.isOnSale)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        settings.formatPrice(watch.price),
                        style: GoogleFonts.inter(
                          decoration: TextDecoration.lineThrough,
                          fontSize: small ? 9 : 10,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textTertiaryColor,
                        ),
                      ),
                    ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      settings.formatPrice(watch.currentPrice),
                      style: GoogleFonts.inter(
                        fontSize: small ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: watch.isOnSale
                            ? AppTheme.roseGoldColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (watch.isInStock)
              Semantics(
                label: 'Add to cart',
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final success = await cartProvider.addToCart(watch);
                    if (context.mounted) {
                      if (success) {
                        PremiumDialogs.showSuccessDialog(
                          context,
                          '${watch.name} has been added to your collection.',
                        );
                      }
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.all(4), // Reduced to prevent overflow
                    child: Container(
                      padding: EdgeInsets.all(small ? 8 : 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Icon(
                        Icons.add_shopping_cart_rounded,
                        color: AppTheme.primaryColor,
                        size: small ? 18 : 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
