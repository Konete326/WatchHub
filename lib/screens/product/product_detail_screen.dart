import 'dart:ui';
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
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
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
    // Calculate AppBar opacity based on scroll
    final appBarOpacity = (_scrollOffset / 200).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10 * appBarOpacity,
              sigmaY: 10 * appBarOpacity,
            ),
            child: AppBar(
              title: const Text(''),
              backgroundColor: Colors.white.withOpacity(0.7 * appBarOpacity),
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.black, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    final watch =
                        Provider.of<WatchProvider>(context).selectedWatch;
                    if (watch == null) return const SizedBox();

                    final isInWishlist =
                        wishlistProvider.isInWishlist(watch.id);
                    return Container(
                      margin:
                          const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color:
                              isInWishlist ? AppTheme.errorColor : Colors.black,
                          size: 22,
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
          ),
        ),
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
                          height: 480,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFF7F8FA),
                                Colors.white.withOpacity(0.5),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.only(top: 100, bottom: 40),
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
                        // Modern Dots Indicator
                        if (watch.images.length > 1)
                          Positioned(
                            bottom: 28,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:
                                    watch.images.asMap().entries.map((entry) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: _currentImageIndex == entry.key
                                        ? 24.0
                                        : 8.0,
                                    height: 8.0,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4.0),
                                      color: _currentImageIndex == entry.key
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.4),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Main Content Body in a rounded sheet effect
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      transform: Matrix4.translationValues(0, -30, 0),
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand & Rating Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  watch.brand?.name.toUpperCase() ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              if (watch.averageRating != null &&
                                  watch.averageRating! > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
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
                          const SizedBox(height: 16),

                          // Product Name
                          Text(
                            watch.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            watch.description,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Variant Selector (Enhanced Circular)
                          if (watch.variants != null &&
                              watch.variants!.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Color',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (_selectedVariant != null)
                                  Text(
                                    _selectedVariant!.colorName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: watch.variants!.map((variant) {
                                final isSelected =
                                    _selectedVariant?.colorName ==
                                        variant.colorName;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
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
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade300,
                                        width: isSelected ? 3 : 2,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(variant.colorHex
                                            .replaceAll('#', '0xFF'))),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // Experience Section with Icon
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Colors.grey.shade200, width: 1),
                                bottom: BorderSide(
                                    color: Colors.grey.shade200, width: 1),
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_outlined,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Experience & Specifications',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                tilePadding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                childrenPadding:
                                    const EdgeInsets.only(bottom: 16, top: 8),
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    _isSpecificationsExpanded = expanded;
                                  });
                                },
                                children: [
                                  if (watch.specifications != null)
                                    ...watch.specifications!.entries
                                        .map((entry) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                entry.key,
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
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
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Similar Watches with Enhanced Header
                          if (watchProvider.relatedWatches.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Similar Watches',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: watchProvider.relatedWatches.length,
                                padding: const EdgeInsets.only(bottom: 8),
                                itemBuilder: (context, index) {
                                  final relatedWatch =
                                      watchProvider.relatedWatches[index];
                                  return Container(
                                    width: 170,
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
                            const SizedBox(height: 32),
                          ],

                          // Reviews
                          ReviewsSection(watchId: watch.id),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Enhanced Floating Bottom Action Bar with Gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Price
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Price',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Consumer<SettingsProvider>(
                                builder: (context, settings, _) {
                                  return Flexible(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            settings.formatPrice(
                                                watch.currentPrice),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                              letterSpacing: -0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (watch.isOnSale) ...[
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              settings.formatPrice(watch.price),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[400],
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Add to Cart Button - Solid Blue
                        Expanded(
                          flex: 6,
                          child: Consumer<CartProvider>(
                            builder: (context, cartProvider, _) {
                              final currentQty =
                                  cartProvider.getQuantityInCart(watch.id);
                              final isStockLimitReached =
                                  currentQty >= watch.stock;
                              return Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color:
                                      (watch.isInStock && !isStockLimitReached)
                                          ? AppTheme.primaryColor
                                          : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: (watch.isInStock &&
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
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  margin: const EdgeInsets.only(
                                                      bottom: 100,
                                                      left: 16,
                                                      right: 16),
                                                ),
                                              );
                                            }
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            !watch.isInStock
                                                ? Icons.error_outline
                                                : (isStockLimitReached
                                                    ? Icons.info_outline
                                                    : Icons
                                                        .shopping_cart_outlined),
                                            color: (watch.isInStock &&
                                                    !isStockLimitReached)
                                                ? Colors.white
                                                : Colors.grey[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            !watch.isInStock
                                                ? 'Out of Stock'
                                                : (isStockLimitReached
                                                    ? 'Limit Reached'
                                                    : 'Add to Cart'),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: (watch.isInStock &&
                                                      !isStockLimitReached)
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
