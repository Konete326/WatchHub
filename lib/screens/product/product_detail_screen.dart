import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/watch_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../utils/image_utils.dart';
import '../../widgets/reviews_section.dart';
import '../../models/watch.dart';

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
      if (!mounted) return;
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
    const kBackgroundColor = AppTheme.softUiBackground;
    const kTextColor = AppTheme.softUiTextColor;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NeumorphicButton(
                  onTap: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(12),
                  shape: BoxShape.circle,
                  child:
                      const Icon(Icons.arrow_back, color: kTextColor, size: 20),
                ),
                const Text(
                  'Details',
                  style: TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    final watch =
                        Provider.of<WatchProvider>(context).selectedWatch;
                    if (watch == null) return const SizedBox(width: 44);

                    final isInWishlist =
                        wishlistProvider.isInWishlist(watch.id);
                    return _NeumorphicIndicatorContainer(
                      isSelected: isInWishlist,
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(4),
                      child: _NeumorphicButton(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final wishlistItem = wishlistProvider.wishlistItems
                              .where((item) => item.watchId == watch.id)
                              .firstOrNull;
                          await wishlistProvider.toggleWishlist(
                              watch.id, wishlistItem?.id);
                        },
                        padding: const EdgeInsets.all(10),
                        shape: BoxShape.circle,
                        child: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist ? Colors.redAccent : kTextColor,
                          size: 20,
                        ),
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
          if (watchProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (watchProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 60, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(
                    watchProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kTextColor, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _NeumorphicButton(
                    onTap: () => watchProvider.fetchWatchById(widget.watchId),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    borderRadius: BorderRadius.circular(15),
                    child: const Text('RETRY',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor)),
                  ),
                ],
              ),
            );
          }

          if (watchProvider.selectedWatch == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 60, color: kTextColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Product not found',
                    style: TextStyle(
                        color: kTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _NeumorphicButton(
                    onTap: () => Navigator.pop(context),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    borderRadius: BorderRadius.circular(15),
                    child: const Text('GO BACK',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor)),
                  ),
                ],
              ),
            );
          }

          final watch = watchProvider.selectedWatch!;

          if (_selectedVariant == null &&
              watch.variants != null &&
              watch.variants!.isNotEmpty) {
            _selectedVariant = watch.variants!.first;
          }

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image Area - Concave Container
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _NeumorphicContainer(
                      isConcave: true,
                      borderRadius: BorderRadius.circular(40),
                      padding: const EdgeInsets.all(32),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          CarouselSlider(
                            carouselController: _carouselController,
                            options: CarouselOptions(
                              height: double.infinity,
                              viewportFraction: 1.0,
                              enableInfiniteScroll: watch.images.length > 1,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                            ),
                            items: watch.images.map<Widget>((imageUrl) {
                              return GestureDetector(
                                onTap: () => ImageUtils.showFullScreenImage(
                                    context, imageUrl),
                                child: Hero(
                                  tag: 'watch_${watch.id}_detail',
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.contain,
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
                          ),
                          if (watch.images.length > 1)
                            Positioned(
                              bottom: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:
                                    watch.images.asMap().entries.map((entry) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: _currentImageIndex == entry.key
                                        ? 16.0
                                        : 6.0,
                                    height: 6.0,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3.0),
                                      color: _currentImageIndex == entry.key
                                          ? AppTheme.primaryColor
                                          : kTextColor.withOpacity(0.2),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand Label & Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (watch.brand?.name != null &&
                              watch.brand!.name.isNotEmpty)
                            _NeumorphicContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              borderRadius: BorderRadius.circular(12),
                              child: Text(
                                watch.brand!.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          if (watch.brand?.name == null ||
                              watch.brand!.name.isEmpty)
                            const SizedBox.shrink(),
                          if (watch.averageRating != null &&
                              watch.averageRating! > 0)
                            _NeumorphicContainer(
                              isConcave: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              borderRadius: BorderRadius.circular(12),
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
                                      color: kTextColor,
                                    ),
                                  ),
                                  Text(
                                    ' (${watch.reviewCount})',
                                    style: TextStyle(
                                      color: kTextColor.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Product Name
                      Text(
                        watch.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        watch.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: kTextColor.withOpacity(0.7),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Variant Selector
                      if (watch.variants != null &&
                          watch.variants!.isNotEmpty) ...[
                        const Text(
                          'Available Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: watch.variants!.map((variant) {
                            final isSelected = _selectedVariant?.colorName ==
                                variant.colorName;
                            return _NeumorphicIndicatorContainer(
                              isSelected: isSelected,
                              shape: BoxShape.circle,
                              padding: const EdgeInsets.all(6),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedVariant = variant;
                                    if (variant.image != null) {
                                      final imgIndex =
                                          watch.images.indexOf(variant.image!);
                                      if (imgIndex != -1) {
                                        _carouselController
                                            .animateToPage(imgIndex);
                                      }
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(variant.colorHex
                                        .replaceAll('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                    boxShadow: isSelected
                                        ? []
                                        : [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              offset: const Offset(3, 3),
                                              blurRadius: 6,
                                            ),
                                            BoxShadow(
                                              color: Colors.white,
                                              offset: const Offset(-3, -3),
                                              blurRadius: 6,
                                            ),
                                          ],
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 24)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Specifications Expansion Header
                      _NeumorphicButton(
                        onTap: () {
                          setState(() {
                            _isSpecificationsExpanded =
                                !_isSpecificationsExpanded;
                          });
                        },
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Specifications',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: kTextColor,
                              ),
                            ),
                            Icon(
                              _isSpecificationsExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: kTextColor,
                            ),
                          ],
                        ),
                      ),

                      AnimatedCrossFade(
                        firstChild:
                            const SizedBox(height: 0, width: double.infinity),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _NeumorphicIndicatorContainer(
                            isSelected: true,
                            borderRadius: BorderRadius.circular(20),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                if (watch.specifications != null)
                                  ...watch.specifications!.entries.map((entry) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: TextStyle(
                                              color:
                                                  kTextColor.withOpacity(0.6),
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            entry.value.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: kTextColor,
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
                        crossFadeState: _isSpecificationsExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),

                      const SizedBox(height: 32),

                      // Similar Watches
                      if (watchProvider.relatedWatches.isNotEmpty) ...[
                        const Text(
                          'Similar Watches',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: watchProvider.relatedWatches.length,
                            clipBehavior: Clip.none,
                            itemBuilder: (context, index) {
                              final relatedWatch =
                                  watchProvider.relatedWatches[index];
                              return Container(
                                width: 180,
                                margin: const EdgeInsets.only(right: 20),
                                child: _NeumorphicRelatedCard(
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: Consumer<WatchProvider>(
        builder: (context, watchProvider, child) {
          final watch = watchProvider.selectedWatch;
          if (watch == null) return const SizedBox();

          return Container(
            color: kBackgroundColor,
            padding: EdgeInsets.fromLTRB(
                24, 0, 24, MediaQuery.of(context).padding.bottom + 20),
            child: _NeumorphicContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kTextColor,
                        ),
                      ),
                      Consumer<SettingsProvider>(
                        builder: (context, settings, _) => Text(
                          settings.formatPrice(watch.currentPrice),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<CartProvider>(
                          builder: (context, cartProvider, _) {
                            final currentQty =
                                cartProvider.getQuantityInCart(watch.id);
                            final isStockLimitReached =
                                currentQty >= watch.stock;
                            final canAdd =
                                watch.isInStock && !isStockLimitReached;

                            return _NeumorphicButton(
                              onTap: canAdd
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
                                                bottom: 150,
                                                left: 24,
                                                right: 24),
                                          ),
                                        );
                                      }
                                    }
                                  : () {},
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              borderRadius: BorderRadius.circular(15),
                              child: Center(
                                child: Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: canAdd
                                        ? AppTheme.primaryColor
                                        : kTextColor.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _NeumorphicButton(
                          onTap: watch.isInStock
                              ? () async {
                                  HapticFeedback.mediumImpact();
                                  final success =
                                      await Provider.of<CartProvider>(context,
                                              listen: false)
                                          .addToCart(watch,
                                              productColor:
                                                  _selectedVariant?.colorName);

                                  if (!mounted) return;

                                  if (success) {
                                    Navigator.pushNamed(context, '/cart');
                                  } else {
                                    final errorMessage =
                                        Provider.of<CartProvider>(context,
                                                listen: false)
                                            .errorMessage;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            errorMessage ?? 'Failed to buy'),
                                        backgroundColor: AppTheme.errorColor,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(
                                            bottom: 150, left: 24, right: 24),
                                      ),
                                    );
                                  }
                                }
                              : () {},
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          borderRadius: BorderRadius.circular(15),
                          child: Center(
                            child: Text(
                              'Buy Now',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: watch.isInStock
                                    ? kTextColor
                                    : kTextColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Neumorphic Components ---

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final bool isConcave;

  const _NeumorphicContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.isConcave = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.softUiBackground,
        borderRadius: borderRadius,
        boxShadow: isConcave
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(4, 4),
                    blurRadius: 4,
                    spreadRadius: 1),
                BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(-4, -4),
                    blurRadius: 4,
                    spreadRadius: 1),
              ]
            : [
                const BoxShadow(
                    color: AppTheme.softUiShadowDark,
                    offset: Offset(6, 6),
                    blurRadius: 16),
                const BoxShadow(
                    color: AppTheme.softUiShadowLight,
                    offset: Offset(-6, -6),
                    blurRadius: 16),
              ],
      ),
      child: child,
    );
  }
}

class _NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const _NeumorphicButton({
    required this.child,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<_NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<_NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: AppTheme.softUiBackground,
          shape: widget.shape,
          borderRadius:
              widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(2, 2),
                      blurRadius: 2),
                  const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-2, -2),
                      blurRadius: 2),
                ]
              : [
                  const BoxShadow(
                      color: AppTheme.softUiShadowDark,
                      offset: Offset(4, 4),
                      blurRadius: 10),
                  const BoxShadow(
                      color: AppTheme.softUiShadowLight,
                      offset: Offset(-4, -4),
                      blurRadius: 10),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _NeumorphicIndicatorContainer extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const _NeumorphicIndicatorContainer({
    required this.child,
    required this.isSelected,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.softUiBackground,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(2, 2),
                    blurRadius: 2,
                    spreadRadius: 1),
                const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-2, -2),
                    blurRadius: 2,
                    spreadRadius: 1),
              ]
            : [
                const BoxShadow(
                    color: AppTheme.softUiShadowDark,
                    offset: Offset(4, 4),
                    blurRadius: 10),
                const BoxShadow(
                    color: AppTheme.softUiShadowLight,
                    offset: Offset(-4, -4),
                    blurRadius: 10),
              ],
        border: isSelected
            ? Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: child,
    );
  }
}

class _NeumorphicRelatedCard extends StatelessWidget {
  final Watch watch;
  final VoidCallback onTap;

  const _NeumorphicRelatedCard({required this.watch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const kTextColor = Color(0xFF4A5568);
    return GestureDetector(
      onTap: onTap,
      child: _NeumorphicContainer(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NeumorphicContainer(
                isConcave: true,
                borderRadius: BorderRadius.circular(15),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Hero(
                    tag: 'watch_${watch.id}_related',
                    child: CachedNetworkImage(
                      imageUrl:
                          watch.images.isNotEmpty ? watch.images.first : '',
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.watch, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              watch.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Consumer<SettingsProvider>(
              builder: (context, settings, _) => Text(
                settings.formatPrice(watch.currentPrice),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
