import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/shimmer_loading.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<WishlistProvider>(context, listen: false)
              .fetchWishlist();
        },
        child: Consumer2<WishlistProvider, SettingsProvider>(
          builder: (context, wishlistProvider, settings, child) {
            if (wishlistProvider.isLoading && wishlistProvider.isEmpty) {
              return const ListShimmer();
            }

            if (wishlistProvider.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 100,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your wishlist is empty',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('Save items you love here',
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/home', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Browse Collections'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlistProvider.wishlistItems.length,
              itemBuilder: (context, index) {
                final item = wishlistProvider.wishlistItems[index];
                final watch = item.watch!;

                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppTheme.errorColor, size: 28),
                  ),
                  onDismissed: (_) {
                    wishlistProvider.toggleWishlist(watch.id, item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Removed ${watch.name} from wishlist'),
                          behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade100)),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(watchId: watch.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Watch Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: watch.images.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: watch.images.first,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                            width: 110,
                                            height: 110,
                                            color: Colors.white),
                                      ),
                                    )
                                  : Container(
                                      width: 110,
                                      height: 110,
                                      color: Colors.grey.shade50,
                                      child: const Icon(Icons.watch,
                                          size: 40, color: Colors.grey),
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
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    watch.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        settings
                                            .formatPrice(watch.currentPrice),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      if (watch.isOnSale) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          settings.formatPrice(watch.price),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Actions
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: watch.isInStock &&
                                                  !wishlistProvider.isLoading
                                              ? () async {
                                                  final cartProvider =
                                                      Provider.of<CartProvider>(
                                                          context,
                                                          listen: false);
                                                  final success =
                                                      await wishlistProvider
                                                          .moveToCart(item.id);
                                                  if (success && mounted) {
                                                    await cartProvider
                                                        .fetchCart();
                                                    cartProvider
                                                        .triggerAddedToCartAnimation();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Moved to cart successfully'),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating),
                                                    );
                                                  }
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 40),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                          icon: watch.isInStock
                                              ? const Icon(
                                                  Icons.shopping_cart_outlined,
                                                  size: 16)
                                              : const Icon(Icons.info_outline,
                                                  size: 16),
                                          label: Text(
                                              watch.isInStock
                                                  ? 'Move to Cart'
                                                  : 'Out of Stock',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          wishlistProvider.toggleWishlist(
                                              watch.id, item.id);
                                        },
                                        icon: const Icon(Icons.favorite,
                                            color: AppTheme.errorColor),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
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
}
