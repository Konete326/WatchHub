import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../utils/image_utils.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../checkout/address_selection_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isEmpty) return const SizedBox();
              return Row(
                children: [
                  if (cartProvider.hasSelection)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.white),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Selected'),
                            content: Text(
                                'Remove ${cartProvider.selectedItemIds.length} item(s) from cart?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final success =
                              await cartProvider.deleteSelectedItems();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Selected items removed'),
                                backgroundColor: AppTheme.successColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      tooltip: 'Delete Selected',
                    )
                  else
                    TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Cart'),
                            content: const Text(
                                'Are you sure you want to clear your cart?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && mounted) {
                          final success = await Provider.of<CartProvider>(
                                  context,
                                  listen: false)
                              .clearCart();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cart cleared'),
                                backgroundColor: AppTheme.successColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer2<CartProvider, SettingsProvider>(
        builder: (context, cartProvider, settings, child) {
          if (cartProvider.isLoading && cartProvider.isEmpty) {
            return const ListShimmer();
          }

          if (cartProvider.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message:
                  'Looks like you haven\'t added any luxury timepieces to your cart yet. Discover our collection today.',
              actionLabel: 'Start Shopping',
              onActionPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (route) => false);
              },
            );
          }

          return Column(
            children: [
              // Select All Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[50],
                child: Row(
                  children: [
                    Checkbox(
                      value: cartProvider.isAllSelected,
                      onChanged: (value) =>
                          cartProvider.selectAll(value ?? false),
                    ),
                    const Expanded(
                        child: Text('Select All',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${cartProvider.selectedItemIds.length} items',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.cartItems[index];
                    final watch = item.watch!;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selection Checkbox
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Checkbox(
                                value: cartProvider.selectedItemIds
                                    .contains(item.id),
                                onChanged: (value) =>
                                    cartProvider.toggleSelection(item.id),
                              ),
                            ),
                            // Watch Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: watch.images.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        final imageUrl = watch.images.first;
                                        ImageUtils.showFullScreenImage(
                                            context, imageUrl);
                                      },
                                      child: CachedNetworkImage(
                                        imageUrl: watch.images.first,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.white),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[100],
                                          child: const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[100],
                                      child: const Icon(Icons.watch,
                                          color: Colors.grey),
                                    ),
                            ),
                            const SizedBox(width: 12),

                            // Watch Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (watch.brand != null)
                                    Text(
                                      watch.brand!.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    watch.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    settings.formatPrice(watch.currentPrice),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  if (item.productColor != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Color: ${item.productColor}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),

                                  // Quantity Controls
                                  Row(
                                    children: [
                                      Container(
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove,
                                                  size: 14),
                                              onPressed: item.quantity > 1
                                                  ? () async {
                                                      final success =
                                                          await cartProvider
                                                              .updateQuantity(
                                                        item.id,
                                                        item.quantity - 1,
                                                      );
                                                      if (!success &&
                                                          context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(cartProvider
                                                                    .errorMessage ??
                                                                'Update failed'),
                                                            backgroundColor:
                                                                AppTheme
                                                                    .errorColor,
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  : null,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                  minWidth: 32),
                                            ),
                                            Text(
                                              item.quantity.toString(),
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add,
                                                  size: 14),
                                              onPressed: item.quantity <
                                                      watch.stock
                                                  ? () async {
                                                      final success =
                                                          await cartProvider
                                                              .updateQuantity(
                                                        item.id,
                                                        item.quantity + 1,
                                                      );
                                                      if (!success &&
                                                          context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(cartProvider
                                                                    .errorMessage ??
                                                                'Update failed'),
                                                            backgroundColor:
                                                                AppTheme
                                                                    .errorColor,
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  : null,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                  minWidth: 32),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppTheme.errorColor,
                                            size: 20),
                                        onPressed: () async {
                                          final success = await cartProvider
                                              .removeItem(item.id);
                                          if (success && context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    '${watch.name} removed from cart'),
                                                backgroundColor:
                                                    AppTheme.successColor,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                duration:
                                                    const Duration(seconds: 1),
                                              ),
                                            );
                                          }
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 36, minHeight: 36),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Cart Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      if (cartProvider.settings != null &&
                          (cartProvider.deliveryCharge > 0))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery Fee',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              Text(
                                  settings
                                      .formatPrice(cartProvider.deliveryCharge),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      if (cartProvider.deliveryCharge == 0 &&
                          cartProvider.settings != null &&
                          cartProvider.settings!.deliveryCharge > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: AppTheme.successColor, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'You\'ve unlocked FREE delivery!',
                                  style: TextStyle(
                                      color: AppTheme.successColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (cartProvider.settings != null &&
                          cartProvider.settings!.freeDeliveryThreshold > 0 &&
                          cartProvider.itemCount <
                              cartProvider.settings!.freeDeliveryThreshold)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Add ${cartProvider.settings!.freeDeliveryThreshold - cartProvider.itemCount} more item(s) for FREE delivery',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            settings.formatPrice(cartProvider.totalAmount),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: cartProvider.hasSelection
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const AddressSelectionScreen()),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(55),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          cartProvider.hasSelection
                              ? 'Checkout (${cartProvider.selectedItemIds.length} items)'
                              : 'Select items to checkout',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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
