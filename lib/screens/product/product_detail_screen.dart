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
import '../../models/watch.dart';
import '../../widgets/watch_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final String watchId;

  const ProductDetailScreen({super.key, required this.watchId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  WatchVariant? _selectedVariant;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final ScrollController _scrollController = ScrollController();
  bool _isSpecificationsExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<WatchProvider>(context, listen: false)
          .fetchWatchById(widget.watchId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''), // Transparent to show image
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              final watch = Provider.of<WatchProvider>(context).selectedWatch;
              if (watch == null) return const SizedBox();

              final isInWishlist = wishlistProvider.isInWishlist(watch.id);
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: isInWishlist ? AppTheme.errorColor : Colors.black,
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final wishlistItem = wishlistProvider.wishlistItems
                        .where((item) => item.watchId == watch.id)
                        .firstOrNull;
                    await wishlistProvider.toggleWishlist(
                        watch.id, wishlistItem?.id);
                  },
                ),
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

          // Initialize selected variant if not already set
          if (_selectedVariant == null &&
              watch.variants != null &&
              watch.variants!.isNotEmpty) {
            _selectedVariant = watch.variants!.first;
          }

          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Carousel (Full bleed top)
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: 450, // Taller image area
                          color: const Color(0xFFF7F8FA),
                          padding: const EdgeInsets.only(top: 80, bottom: 20),
                          child: watch.images.isNotEmpty
                              ? CarouselSlider(
                                  carouselController: _carouselController,
                                  options: CarouselOptions(
                                    height: double.infinity,
                                    viewportFraction: 1.0,
                                    enableInfiniteScroll:
                                        watch.images.length > 1,
                                    onPageChanged: (index, reason) {
                                      setState(() {
                                        _currentImageIndex = index;
                                      });
                                    },
                                  ),
                                  items: watch.images.map<Widget>((imageUrl) {
                                    return GestureDetector(
                                      onTap: () =>
                                          ImageUtils.showFullScreenImage(
                                              context, imageUrl),
                                      child: Hero(
                                        tag: 'watch_${watch.id}_detail',
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.contain,
                                          placeholder: (context, url) =>
                                              const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 80,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              : const Center(
                                  child: Icon(Icons.watch,
                                      size: 100, color: Colors.grey),
                                ),
                        ),
                        // Dots Indicator
                        if (watch.images.length > 1)
                          Positioned(
                            bottom: 24,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  watch.images.asMap().entries.map((entry) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentImageIndex == entry.key
                                      ? 20.0
                                      : 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.0),
                                    color: _currentImageIndex == entry.key
                                        ? AppTheme.primaryColor
                                        : Colors.grey.withOpacity(0.4),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),

                    // Main Content Body in a rounded sheet effect
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      // Shift up slightly to overlap image bg
                      transform: Matrix4.translationValues(0, -20, 0),
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand & Rating Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                watch.brand?.name ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor.withOpacity(0.7),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              if (watch.averageRating != null &&
                                  watch.averageRating! > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        watch.averageRating!.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        ' (${watch.reviewCount})',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Product Name
                          Text(
                            watch.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            watch.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.6,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 24),

                          // Variant Selector (Circular)
                          if (watch.variants != null &&
                              watch.variants!.isNotEmpty) ...[
                            const Text(
                              'Color',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: watch.variants!.map((variant) {
                                final isSelected =
                                    _selectedVariant?.colorName ==
                                        variant.colorName;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedVariant = variant;
                                      if (variant.image != null) {
                                        final imgIndex = watch.images
                                            .indexOf(variant.image!);
                                        if (imgIndex != -1) {
                                          _carouselController
                                              .animateToPage(imgIndex);
                                        }
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding:
                                        const EdgeInsets.all(3), // Border width
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(variant.colorHex
                                            .replaceAll('#', '0xFF'))),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Experience / Specifications Expandable Tile
                          Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: const Text(
                                'Experience & Specifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              tilePadding: EdgeInsets.zero,
                              childrenPadding:
                                  const EdgeInsets.only(bottom: 16),
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _isSpecificationsExpanded = expanded;
                                });
                              },
                              children: [
                                if (watch.specifications != null)
                                  ...watch.specifications!.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              entry.key,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              entry.value.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          const SizedBox(height: 24),

                          // Similar Watches
                          if (watchProvider.relatedWatches.isNotEmpty) ...[
                            const Text(
                              'Similar Watches',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 260,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: watchProvider.relatedWatches.length,
                                itemBuilder: (context, index) {
                                  final relatedWatch =
                                      watchProvider.relatedWatches[index];
                                  return Container(
                                    width:
                                        170, // Slightly narrower for horizontal list
                                    margin: const EdgeInsets.only(right: 16),
                                    child: WatchCard(
                                      watch: relatedWatch,
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductDetailScreen(
                                                    watchId: relatedWatch.id),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Reviews
                          ReviewsSection(watchId: watch.id),
                          const SizedBox(
                              height: 100), // Space for floating bottom bar
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      20, 20, 20, MediaQuery.of(context).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      // Price
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Price',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Consumer<SettingsProvider>(
                              builder: (context, settings, _) {
                                return Text(
                                  settings.formatPrice(watch.currentPrice),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Add to Cart Button
                      Expanded(
                        flex: 6,
                        child: Consumer<CartProvider>(
                          builder: (context, cartProvider, _) {
                            final currentQty =
                                cartProvider.getQuantityInCart(watch.id);
                            final isStockLimitReached =
                                currentQty >= watch.stock;
                            return ElevatedButton(
                              onPressed: (watch.isInStock &&
                                      !isStockLimitReached)
                                  ? () async {
                                      HapticFeedback.lightImpact();
                                      final success =
                                          await cartProvider.addToCart(
                                        watch,
                                        productColor:
                                            _selectedVariant?.colorName,
                                      );
                                      if (mounted) {
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
                                            margin: const EdgeInsets.only(
                                                bottom: 100,
                                                left: 16,
                                                right: 16),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                !watch.isInStock
                                    ? 'Out of Stock'
                                    : (isStockLimitReached
                                        ? 'Limit Reached'
                                        : 'Add to Cart'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
