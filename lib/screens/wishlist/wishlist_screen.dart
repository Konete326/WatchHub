import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = Color(0xFFE0E5EC);
    const kTextColor = Color(0xFF4A5568);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: _NeumorphicContainer(
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _NeumorphicButton(
                    onTap: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.all(10),
                    shape: BoxShape.circle,
                    child: const Icon(Icons.arrow_back,
                        color: kTextColor, size: 20),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'My Wishlist',
                        style: TextStyle(
                          color: kTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<WishlistProvider>(context, listen: false)
              .fetchWishlist();
        },
        child: Consumer3<WishlistProvider, CartProvider, SettingsProvider>(
          builder: (context, wishlistProvider, cartProvider, settings, child) {
            if (wishlistProvider.isLoading && wishlistProvider.isEmpty) {
              return _buildShimmerLoading();
            }

            if (wishlistProvider.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
              itemCount: wishlistProvider.wishlistItems.length,
              itemBuilder: (context, index) {
                final item = wishlistProvider.wishlistItems[index];
                final watch = item.watch!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE), // Solid soft red
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: _NeumorphicContainer(
                        isConcave: true,
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 28),
                      ),
                    ),
                    onDismissed: (_) {
                      wishlistProvider.toggleWishlist(watch.id, item.id);
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed ${watch.name} from wishlist'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: kTextColor.withOpacity(0.9),
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(watchId: watch.id),
                          ),
                        );
                      },
                      child: _NeumorphicContainer(
                        borderRadius: BorderRadius.circular(25),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Watch Image in Concave Container
                            _NeumorphicContainer(
                              isConcave: true,
                              borderRadius: BorderRadius.circular(20),
                              padding: const EdgeInsets.all(8),
                              child: Hero(
                                tag: 'watch_${watch.id}',
                                child: CachedNetworkImage(
                                  imageUrl: watch.images.isNotEmpty
                                      ? watch.images.first
                                      : '',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: const Color(0xFFE0E5EC),
                                    highlightColor: const Color(0xFFF1F4F8),
                                    child: Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Watch Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (watch.brand != null)
                                    Text(
                                      watch.brand!.name.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    watch.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: kTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    settings.formatPrice(watch.currentPrice),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Actions
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMoveToCartButton(
                                            watch,
                                            wishlistProvider,
                                            cartProvider,
                                            item),
                                      ),
                                      const SizedBox(width: 12),
                                      _NeumorphicIndicatorContainer(
                                        isSelected: true,
                                        shape: BoxShape.circle,
                                        padding: const EdgeInsets.all(4),
                                        child: _NeumorphicButton(
                                          onTap: () async {
                                            HapticFeedback.selectionClick();
                                            await wishlistProvider
                                                .toggleWishlist(
                                                    watch.id, item.id);
                                          },
                                          padding: const EdgeInsets.all(10),
                                          shape: BoxShape.circle,
                                          child: const Icon(Icons.favorite,
                                              color: Colors.redAccent,
                                              size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMoveToCartButton(
      dynamic watch,
      WishlistProvider wishlistProvider,
      CartProvider cartProvider,
      dynamic item) {
    final currentQty = cartProvider.getQuantityInCart(watch.id);
    final isStockLimitReached = currentQty >= watch.stock;
    final canAdd = watch.isInStock && !isStockLimitReached;

    return _NeumorphicButton(
      onTap: canAdd
          ? () async {
              HapticFeedback.lightImpact();
              final success = await wishlistProvider.moveToCart(item.id);
              if (success && mounted) {
                await cartProvider.fetchCart();
                cartProvider.triggerAddedToCartAnimation();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Moved to cart successfully'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.successColor,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                );
              }
            }
          : () {},
      padding: const EdgeInsets.symmetric(vertical: 12),
      borderRadius: BorderRadius.circular(12),
      isPressed: !canAdd, // Show as 'pressed/concave' if disabled
      child: Center(
        child: Text(
          !watch.isInStock
              ? 'Out of Stock'
              : (isStockLimitReached ? 'Limit Reached' : 'Move to Cart'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: canAdd
                ? AppTheme.primaryColor
                : const Color(0xFF4A5568).withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    const kTextColor = Color(0xFF4A5568);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NeumorphicContainer(
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(40),
              isConcave: true,
              child: Icon(
                Icons.favorite_border_rounded,
                size: 80,
                color: kTextColor.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Your wishlist is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Save items you love here to find them easily later and get notified of price drops.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: kTextColor.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            _NeumorphicButton(
              onTap: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (route) => false);
              },
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              borderRadius: BorderRadius.circular(20),
              child: const Text(
                'Start Shopping',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFE0E5EC),
          highlightColor: const Color(0xFFF1F4F8),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Neumorphic Components ---

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final bool isConcave;

  const _NeumorphicContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.isConcave = false,
  });

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFE0E5EC);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
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
                    color: Color(0xFFA3B1C6),
                    offset: Offset(6, 6),
                    blurRadius: 16),
                const BoxShadow(
                    color: Color(0xFFFFFFFF),
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
  final bool isPressed;

  const _NeumorphicButton({
    required this.child,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.isPressed = false,
  });

  @override
  State<_NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<_NeumorphicButton> {
  bool _isGesturePressed = false;

  @override
  Widget build(BuildContext context) {
    final bool effectivePressed = widget.isPressed || _isGesturePressed;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isGesturePressed = true),
      onTapUp: (_) => setState(() => _isGesturePressed = false),
      onTapCancel: () => setState(() => _isGesturePressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E5EC),
          shape: widget.shape,
          borderRadius:
              widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
          boxShadow: effectivePressed
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
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
                      color: Color(0xFFA3B1C6),
                      offset: Offset(4, 4),
                      blurRadius: 10),
                  const BoxShadow(
                      color: Color(0xFFFFFFFF),
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
  final BorderRadiusGeometry borderRadius;
  final BoxShape shape;

  const _NeumorphicIndicatorContainer({
    required this.child,
    required this.isSelected,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
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
                    color: Color(0xFFA3B1C6),
                    offset: Offset(4, 4),
                    blurRadius: 10),
                const BoxShadow(
                    color: Color(0xFFFFFFFF),
                    offset: Offset(-4, -4),
                    blurRadius: 10),
              ],
      ),
      child: child,
    );
  }
}
