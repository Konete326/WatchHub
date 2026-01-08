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
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('My Cart',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: AppTheme.errorColor),
                tooltip: 'Clear Cart',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Cart'),
                      content: const Text(
                          'Are you sure you want to remove all items?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                              foregroundColor: AppTheme.errorColor),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    final success =
                        await Provider.of<CartProvider>(context, listen: false)
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
              icon: Icons.shopping_basket_outlined,
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: cartProvider.isAllSelected,
                        activeColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (value) =>
                            cartProvider.selectAll(value ?? false),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Select All Items',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${cartProvider.selectedItemIds.length} Selected',
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

              // Cart Items List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: cartProvider.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.cartItems[index];
                    final watch = item.watch!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 28),
                        ),
                        onDismissed: (direction) async {
                          await cartProvider.removeItem(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${watch.name} removed'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    // Add logic to undo removal if backend supports it efficiently
                                    // or just re-add (complex without quantity logic here)
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Checkbox
                              Checkbox(
                                value: cartProvider.selectedItemIds
                                    .contains(item.id),
                                activeColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                onChanged: (value) =>
                                    cartProvider.toggleSelection(item.id),
                              ),

                              // Product Image
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 90,
                                      height: 90,
                                      color: const Color(0xFFF7F8FA),
                                      child: watch.images.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: watch.images.first,
                                              fit: BoxFit.contain,
                                              placeholder: (context, url) =>
                                                  Shimmer.fromColors(
                                                baseColor: Colors.grey[200]!,
                                                highlightColor:
                                                    Colors.grey[100]!,
                                                child: Container(
                                                    color: Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.watch,
                                              color: Colors.grey),
                                    ),
                                  ),
                                  if (item.productColor != null)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                          ),
                                        ),
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppTheme
                                                .primaryColor, // You might want real color hex here
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (watch.brand != null)
                                      Text(
                                        watch.brand!.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[500],
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      watch.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          settings
                                              .formatPrice(watch.currentPrice),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        // Quantity Controls
                                        Container(
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7F8FA),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              _buildQtyBtn(Icons.remove,
                                                  () async {
                                                if (item.quantity > 1) {
                                                  await cartProvider
                                                      .updateQuantity(item.id,
                                                          item.quantity - 1);
                                                }
                                              }, isEnabled: item.quantity > 1),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                                child: Text(
                                                  '${item.quantity}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              _buildQtyBtn(Icons.add, () async {
                                                if (item.quantity <
                                                    watch.stock) {
                                                  await cartProvider
                                                      .updateQuantity(item.id,
                                                          item.quantity + 1);
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Maximum stock reached')),
                                                  );
                                                }
                                              },
                                                  isEnabled: item.quantity <
                                                      watch.stock),
                                            ],
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
                    );
                  },
                ),
              ),

              // Sticky Bottom Summary
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Subtotal Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                          Text(
                            settings.formatPrice(cartProvider.totalAmount),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Shipping Row (simplified logic for UI demo, keep full logic if preferred)
                      if (cartProvider.deliveryCharge > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Shipping',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                            Text(
                              settings.formatPrice(cartProvider.deliveryCharge),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      if (cartProvider.deliveryCharge == 0 &&
                          cartProvider.totalAmount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Shipping',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                            const Text(
                              'Free',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.successColor),
                            ),
                          ],
                        ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),

                      // Grand Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            settings.formatPrice(cartProvider.totalAmount +
                                cartProvider.deliveryCharge),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Checkout Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFD4AF37),
                              AppTheme.primaryColor
                            ], // Gold to Blue
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: cartProvider.hasSelection
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AddressSelectionScreen()),
                                    );
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Center(
                              child: Text(
                                cartProvider.hasSelection
                                    ? 'Proceed to Checkout (${cartProvider.selectedItemIds.length})'
                                    : 'Select Items to Checkout',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                      cartProvider.hasSelection ? 1.0 : 0.7),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
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

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap,
      {bool isEnabled = true}) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? AppTheme.primaryColor : Colors.grey[400],
        ),
      ),
    );
  }
}
