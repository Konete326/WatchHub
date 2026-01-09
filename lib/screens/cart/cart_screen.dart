import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/empty_state.dart';
import '../checkout/address_selection_screen.dart';

class CartScreen extends StatefulWidget {
  final bool showBackButton;
  const CartScreen({super.key, this.showBackButton = true});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Neumorphic Design Constants
  static const Color kBackgroundColor = Color(0xFFE0E5EC);
  static const Color kShadowDark = Color(0xFFA3B1C6);
  static const Color kShadowLight = Color(0xFFFFFFFF);
  static const Color kTextColor = Color(0xFF4A5568);
  static const Color kPrimaryColor = AppTheme.primaryColor;
  static const Color kRedColor = Color(0xFFEF5350);

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
      backgroundColor: kBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: kBackgroundColor,
            child: Row(
              children: [
                if (widget.showBackButton && Navigator.canPop(context))
                  _NeumorphicButton(
                    onTap: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(10),
                    shape: BoxShape.circle,
                    child: const Icon(Icons.arrow_back, color: kTextColor),
                  )
                else
                  const SizedBox(width: 44),
                Expanded(
                  child: Center(
                    child: Text(
                      'My Cart',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: kTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                    ),
                  ),
                ),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    if (cartProvider.isEmpty) return const SizedBox(width: 44);
                    return _NeumorphicButton(
                      onTap: () async {
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
                                    foregroundColor: kRedColor),
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await Provider.of<CartProvider>(context,
                                  listen: false)
                              .clearCart();
                        }
                      },
                      padding: const EdgeInsets.all(10),
                      shape: BoxShape.circle,
                      child: const Icon(Icons.delete_outline,
                          color: kRedColor, size: 22),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer2<CartProvider, SettingsProvider>(
        builder: (context, cartProvider, settings, child) {
          if (cartProvider.isLoading && cartProvider.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Your cart is empty',
              message:
                  'Looks like you haven\'t added any luxury timepieces to your cart yet.',
              actionLabel: 'Start Shopping',
              onActionPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (route) => false);
              },
            );
          }

          return Column(
            children: [
              // Select All Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: _NeumorphicContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: BorderRadius.circular(15),
                  child: Row(
                    children: [
                      _NeumorphicCheckbox(
                        value: cartProvider.isAllSelected,
                        onChanged: (value) => cartProvider.selectAll(value),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Select All Items',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: kTextColor,
                          ),
                        ),
                      ),
                      Text(
                        '${cartProvider.selectedItemIds.length} Selected',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cart Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  itemCount: cartProvider.cartItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final item = cartProvider.cartItems[index];
                    final watch = item.watch!;
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(left: 40),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE), // Light red
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 28),
                        child: _NeumorphicContainer(
                          shape: BoxShape.circle,
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.delete_outline,
                            color: kRedColor,
                            size: 24,
                          ),
                        ),
                      ),
                      onDismissed: (direction) async {
                        await cartProvider.removeItem(item.id);
                      },
                      child: _NeumorphicContainer(
                        padding: const EdgeInsets.all(12),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Selection Checkbox
                            _NeumorphicCheckbox(
                              value: cartProvider.selectedItemIds
                                  .contains(item.id),
                              size: 22,
                              onChanged: (value) =>
                                  cartProvider.toggleSelection(item.id),
                            ),

                            const SizedBox(width: 12),

                            // 2. Product Image
                            // Using a white container to ensure image pops against the grey background
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: watch.images.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: watch.images.first,
                                        fit: BoxFit
                                            .contain, // Contain ensures standard watch faces show fully
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(color: Colors.white),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.broken_image,
                                                color: Colors.grey),
                                      )
                                    : const Icon(Icons.watch,
                                        color: Colors.grey, size: 40),
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    watch.brand?.name.toUpperCase() ?? 'BRAND',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: kTextColor.withOpacity(0.5),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    watch.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: kTextColor,
                                      height: 1.1,
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
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryColor,
                                        ),
                                      ),

                                      // Quantity Controls
                                      Row(
                                        children: [
                                          _NeumorphicButton(
                                            onTap: () async {
                                              if (item.quantity > 1) {
                                                await cartProvider
                                                    .updateQuantity(item.id,
                                                        item.quantity - 1);
                                              }
                                            },
                                            padding: const EdgeInsets.all(6),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: const Icon(Icons.remove,
                                                size: 14, color: kTextColor),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white70,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: kTextColor,
                                              ),
                                            ),
                                          ),
                                          _NeumorphicButton(
                                            onTap: () async {
                                              if (item.quantity < watch.stock) {
                                                await cartProvider
                                                    .updateQuantity(item.id,
                                                        item.quantity + 1);
                                              }
                                            },
                                            padding: const EdgeInsets.all(6),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: const Icon(Icons.add,
                                                size: 14, color: kTextColor),
                                          ),
                                        ],
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

              // Bottom Checkout Slab
              _NeumorphicContainer(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            settings.formatPrice(cartProvider.totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: kTextColor,
                            ),
                          ),
                        ],
                      ),
                      if (cartProvider.deliveryCharge > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Shipping',
                              style: TextStyle(
                                color: kTextColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              settings.formatPrice(cartProvider.deliveryCharge),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: kTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Colors.grey),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                          Text(
                            settings.formatPrice(cartProvider.totalAmount +
                                cartProvider.deliveryCharge),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: _NeumorphicButton(
                          onTap: cartProvider.hasSelection
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AddressSelectionScreen()),
                                  );
                                }
                              : () {},
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.credit_card,
                                color: cartProvider.hasSelection
                                    ? kPrimaryColor
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Checkout',
                                style: TextStyle(
                                  color: cartProvider.hasSelection
                                      ? kPrimaryColor
                                      : Colors.grey,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
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
}

// --- Neumorphic Components ---

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const _NeumorphicContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _CartScreenState.kBackgroundColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: const [
          BoxShadow(
            color: _CartScreenState.kShadowDark,
            offset: Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: _CartScreenState.kShadowLight,
            offset: Offset(-4, -4),
            blurRadius: 10,
          ),
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
          color: _CartScreenState.kBackgroundColor,
          shape: widget.shape,
          borderRadius:
              widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
          boxShadow: _isPressed
              ? [] // Flat/Pressed
              : [
                  const BoxShadow(
                    color: _CartScreenState.kShadowDark,
                    offset: Offset(4, 4),
                    blurRadius: 10,
                  ),
                  const BoxShadow(
                    color: _CartScreenState.kShadowLight,
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _NeumorphicCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  const _NeumorphicCheckbox({
    required this.value,
    required this.onChanged,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _CartScreenState.kBackgroundColor,
          borderRadius: BorderRadius.circular(size * 0.25),
          boxShadow: value
              ? [] // Pressed/Active state (Flat or slightly concave)
              : [
                  // Elevated
                  const BoxShadow(
                    color: _CartScreenState.kShadowDark,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                  const BoxShadow(
                    color: _CartScreenState.kShadowLight,
                    offset: Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
          gradient: value
              ? LinearGradient(
                  colors: [
                    _CartScreenState.kPrimaryColor.withOpacity(0.8),
                    _CartScreenState.kPrimaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border:
              value ? null : Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: value
            ? Icon(Icons.check, size: size * 0.7, color: Colors.white)
            : null,
      ),
    );
  }
}
