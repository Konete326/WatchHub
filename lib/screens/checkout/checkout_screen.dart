import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/watch_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/checkout_progress_bar.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../../models/address.dart';
import '../../models/coupon.dart';
import '../profile/add_address_screen.dart';
import 'order_confirmation_screen.dart';
import '../../services/analytics_service.dart';

class CheckoutScreen extends StatefulWidget {
  final int initialStep;
  const CheckoutScreen({super.key, this.initialStep = 1});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late PageController _pageController;
  int _currentStep = 1;

  String? _selectedAddressId;
  String _shippingMethod = 'standard';
  String _paymentMethod = 'card';
  Coupon? _appliedCoupon;
  final TextEditingController _couponController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _pageController = PageController(initialPage: _currentStep);
    AnalyticsService().logEvent(AnalyticsEvent.beginCheckout);

    Future.microtask(() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.fetchAddresses();
      if (userProvider.defaultAddress != null) {
        setState(() => _selectedAddressId = userProvider.defaultAddress!.id);
      }

      Provider.of<OrderProvider>(context, listen: false)
          .fetchAvailableCoupons();
      Provider.of<WatchProvider>(context, listen: false).fetchFeaturedWatches();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  double get _shippingCost {
    if (_shippingMethod == 'standard') return 0;
    return 25.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softUiBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                NeumorphicButtonSmall(
                  onTap: _previousStep,
                  icon: Icons.arrow_back,
                  tooltip: 'Previous Step',
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _getStepTitle(),
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softUiTextColor,
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
      body: Column(
        children: [
          CheckoutProgressBar(currentStep: _currentStep),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCartStep(),
                _buildAddressStep(),
                _buildShippingStep(),
                _buildPaymentStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'My Cart';
      case 1:
        return 'Shipping Address';
      case 2:
        return 'Shipping Method';
      case 3:
        return 'Payment Method';
      case 4:
        return 'Review Order';
      default:
        return 'Checkout';
    }
  }

  Widget _buildCartStep() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final items = cartProvider.cartItems;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...items.map((item) => _buildCartItem(item)).toList(),
              if (items.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('Your cart is empty'))),
              const SizedBox(height: 32),
              _buildUpsellSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressStep() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final addresses = userProvider.addresses;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ...addresses.map((addr) => _buildAddressCard(addr)).toList(),
              const SizedBox(height: 24),
              NeumorphicButton(
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddAddressScreen()));
                  userProvider.fetchAddresses();
                },
                padding: const EdgeInsets.symmetric(vertical: 20),
                borderRadius: BorderRadius.circular(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text('Add New Address',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShippingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShippingMethodCard(
            id: 'standard',
            title: 'Standard Delivery',
            subtitle: '3-5 Business Days',
            price: 'Free',
            icon: Icons.delivery_dining_outlined,
          ),
          const SizedBox(height: 20),
          _buildShippingMethodCard(
            id: 'express',
            title: 'Express Shipping',
            subtitle: '1-2 Business Days',
            price: '25.00',
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 32),
          _buildInfoNote(
              'Estimated delivery: ${DateTime.now().add(Duration(days: _shippingMethod == 'standard' ? 5 : 2)).toString().split(' ')[0]}'),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPaymentCard('card', Icons.credit_card_rounded,
              'Credit/Debit Card', 'Secure payment via Stripe'),
          const SizedBox(height: 20),
          _buildPaymentCard('cod', Icons.payments_rounded, 'Cash on Delivery',
              'Pay when you receive'),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final settings = Provider.of<SettingsProvider>(context);
        final subtotal = cartProvider.subtotal;
        final discount = _appliedCoupon?.calculateDiscount(subtotal) ?? 0;
        final shipping = _shippingCost;
        final total = subtotal + shipping - discount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewSection('Shipping To', _getSelectedAddressSummary()),
              const SizedBox(height: 24),
              _buildReviewSection(
                  'Items', '${cartProvider.selectedItemCount} items selected'),
              const SizedBox(height: 24),
              _buildReviewSection(
                  'Payment',
                  _paymentMethod == 'card'
                      ? 'Credit Card'
                      : 'Cash on Delivery'),
              const SizedBox(height: 32),
              _buildCouponSection(subtotal),
              const SizedBox(height: 32),
              NeumorphicContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    _buildSummaryRow(
                        'Subtotal', settings.formatPrice(subtotal)),
                    _buildSummaryRow(
                        'Shipping', settings.formatPrice(shipping)),
                    if (discount > 0)
                      _buildSummaryRow(
                          'Discount', '-${settings.formatPrice(discount)}',
                          color: AppTheme.successColor),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(settings.formatPrice(total),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItem(item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                  imageUrl: item.watch.images.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.watch.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('Qty: ${item.quantity}',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Text(
                Provider.of<SettingsProvider>(context)
                    .formatPrice(item.watch.currentPrice * item.quantity),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpsellSection() {
    final watchProvider = Provider.of<WatchProvider>(context);
    final upsells = watchProvider.newArrivals;
    if (upsells.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequently Bought Together',
            style: GoogleFonts.montserrat(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: upsells.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final watch = upsells[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 16),
                child: NeumorphicContainer(
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(15),
                  child: Column(
                    children: [
                      Expanded(
                          child: CachedNetworkImage(
                              imageUrl: watch.images.first,
                              fit: BoxFit.contain)),
                      const SizedBox(height: 8),
                      Text(watch.name,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1),
                      Text(
                          Provider.of<SettingsProvider>(context)
                              .formatPrice(watch.currentPrice),
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.primaryColor)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () =>
                            Provider.of<CartProvider>(context, listen: false)
                                .addToCart(watch),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Text('Add',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(Address addr) {
    final bool isSelected = _selectedAddressId == addr.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = addr.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: NeumorphicContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(20),
          backgroundColor: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.05)
              : AppTheme.softUiBackground,
          child: Row(
            children: [
              Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addr.addressLine,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${addr.city}, ${addr.state} ${addr.zip}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShippingMethodCard(
      {required String id,
      required String title,
      required String subtitle,
      required String price,
      required IconData icon}) {
    final bool isSelected = _shippingMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _shippingMethod = id),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(20),
        backgroundColor: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : AppTheme.softUiBackground,
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Text(price,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.softUiTextColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
      String id, IconData icon, String title, String subtitle) {
    final bool isSelected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(20),
        backgroundColor: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : AppTheme.softUiBackground,
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(content,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCouponSection(double subtotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HAVE A COUPON?',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: NeumorphicContainer(
                isConcave: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _couponController,
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: 'Enter code'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _applyCoupon,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12)),
                child: const Text('Apply',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        if (_appliedCoupon != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppTheme.successColor, size: 16),
                const SizedBox(width: 8),
                Text('Coupon ${_appliedCoupon!.code} applied!',
                    style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const Spacer(),
                GestureDetector(
                    onTap: () => setState(() => _appliedCoupon = null),
                    child: const Text('Remove',
                        style: TextStyle(
                            color: AppTheme.errorColor, fontSize: 13))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _getSelectedAddressSummary() {
    if (_selectedAddressId == null) return 'No address selected';
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final addr =
          userProvider.addresses.firstWhere((a) => a.id == _selectedAddressId);
      return '${addr.addressLine}, ${addr.city}';
    } catch (_) {
      return 'Selected address not found';
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final coupon = await orderProvider.validateCoupon(code);

    if (coupon != null) {
      setState(() => _appliedCoupon = coupon);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Coupon applied!'),
            backgroundColor: AppTheme.successColor));
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Invalid coupon'),
            backgroundColor: AppTheme.errorColor));
    }
  }

  Widget _buildBottomAction() {
    bool canGoNext = true;
    if (_currentStep == 1 && _selectedAddressId == null) canGoNext = false;

    return NeumorphicContainer(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: NeumorphicButton(
        onTap:
            canGoNext ? (_currentStep == 4 ? _placeOrder : _nextStep) : () {},
        backgroundColor:
            canGoNext ? AppTheme.primaryColor : Colors.grey.shade400,
        padding: const EdgeInsets.symmetric(vertical: 18),
        borderRadius: BorderRadius.circular(15),
        child: Center(
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _currentStep == 4 ? 'Confirm & Place Order' : 'Continue',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    try {
      String? paymentIntentId;
      if (_paymentMethod == 'card') {
        paymentIntentId = 'pi_mock_${DateTime.now().millisecondsSinceEpoch}';
        await Future.delayed(const Duration(seconds: 2));
      }

      final order = await orderProvider.createOrder(
        addressId: _selectedAddressId!,
        paymentIntentId: paymentIntentId,
        shippingCost: _shippingCost,
        cartItemIds: cartProvider.selectedItemIds.toList(),
        paymentMethod: _paymentMethod,
        couponId: _appliedCoupon?.id,
      );

      if (order != null) {
        AnalyticsService().logPurchase(
          order.id,
          order.totalAmount,
          order.orderItems?.map((e) => e.watchId).toList() ?? [],
        );
        await cartProvider.clearCart();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(orderId: order.id)));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppTheme.errorColor));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildInfoNote(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
