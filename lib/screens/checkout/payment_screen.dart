import 'package:flutter/material.dart' hide Card;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:watchhub/models/coupon.dart';
import '../../models/watch.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'order_confirmation_screen.dart';
import 'stripe_web_payment_dialog.dart';
import '../../widgets/checkout_progress_bar.dart';
import '../../widgets/neumorphic_widgets.dart';

class PaymentScreen extends StatefulWidget {
  final String addressId;

  const PaymentScreen({super.key, required this.addressId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  final _couponController = TextEditingController();
  Coupon? _appliedCoupon;
  String _paymentMethod = 'card'; // 'card' or 'cod'
  final Map<String, Map<String, String?>> _strapSelections = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OrderProvider>(context, listen: false)
          .fetchAvailableCoupons();
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    if (_couponController.text.isEmpty) return;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final coupon =
        await orderProvider.validateCoupon(_couponController.text.trim());

    if (coupon != null && mounted) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      if (coupon.minAmount != null &&
          cartProvider.subtotal < coupon.minAmount!) {
        _showSnackBar(
            'Minimum order amount for this coupon is ${settingsProvider.formatPrice(coupon.minAmount!)}',
            isError: true);
        return;
      }
      setState(() => _appliedCoupon = coupon);
      _showSnackBar('Coupon applied successfully!');
    } else if (mounted) {
      _showSnackBar(orderProvider.errorMessage ?? 'Invalid coupon code',
          isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    try {
      if (Constants.stripePublishableKey ==
              'pk_test_your_stripe_publishable_key' ||
          Constants.stripePublishableKey.isEmpty) {
        throw Exception(
            'Stripe is not configured. Please set your Stripe publishable key in lib/utils/constants.dart');
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final discount =
          _appliedCoupon?.calculateDiscount(cartProvider.subtotal) ?? 0;
      final finalAmount = cartProvider.totalAmount - discount;

      String? paymentIntentId;

      if (_paymentMethod == 'card') {
        final paymentData =
            await orderProvider.createPaymentIntent(finalAmount);
        if (paymentData == null)
          throw Exception(
              orderProvider.errorMessage ?? 'Failed to create payment intent');
        paymentIntentId = paymentData['paymentIntentId'];

        if (!Constants.useFakePayment) {
          if (kIsWeb) {
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              barrierDismissible: false,
              builder: (context) => StripeWebPaymentDialog(
                clientSecret: paymentData['clientSecret'],
                publishableKey: Constants.stripePublishableKey,
                amount: finalAmount,
              ),
            );
            if (result == null || result['status'] != 'succeeded') {
              throw Exception(
                  result?['error'] ?? 'Payment was cancelled or failed');
            }
          } else {
            await Stripe.instance.initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                merchantDisplayName: 'WatchHub',
                paymentIntentClientSecret: paymentData['clientSecret'],
                style: ThemeMode.light,
              ),
            );
            await Stripe.instance.presentPaymentSheet();
          }
        } else {
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      final order = await orderProvider.createOrder(
        addressId: widget.addressId,
        paymentIntentId: paymentIntentId,
        shippingCost: cartProvider.deliveryCharge,
        cartItemIds: cartProvider.selectedItemIds.toList(),
        paymentMethod: _paymentMethod,
        couponId: _appliedCoupon?.id,
        strapSelections: _strapSelections,
      );

      if (order == null) throw Exception('Failed to create order');
      await cartProvider.clearCart();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(orderId: order.id)),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final discount =
        _appliedCoupon?.calculateDiscount(cartProvider.subtotal) ?? 0;
    final finalAmount = cartProvider.totalAmount - discount;

    return Scaffold(
      backgroundColor: AppTheme.softUiBackground,
      body: SafeArea(
        child: Column(
          children: [
            const NeumorphicTopBar(title: 'Payment'),
            const CheckoutProgressBar(currentStep: 1),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Order Summary'),
                    _buildOrderSummary(
                        cartProvider, settings, discount, finalAmount),
                    const SizedBox(height: 32),
                    _buildStrapSelectionSection(cartProvider),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Coupon Code'),
                    _buildCouponInput(),
                    const SizedBox(height: 12),
                    _buildAvailableCoupons(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Payment Method'),
                    _buildPaymentMethodSelection(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            _buildStickyPayButton(settings, finalAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.softUiTextColor,
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider,
      SettingsProvider settings, double discount, double total) {
    return NeumorphicContainer(
      borderRadius: BorderRadius.circular(25),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSummaryRow(
              'Subtotal', settings.formatPrice(cartProvider.subtotal)),
          const SizedBox(height: 12),
          _buildSummaryRow(
              'Shipping',
              cartProvider.deliveryCharge == 0
                  ? 'FREE'
                  : settings.formatPrice(cartProvider.deliveryCharge),
              valueColor: cartProvider.deliveryCharge == 0
                  ? AppTheme.successColor
                  : null),
          if (_appliedCoupon != null) ...[
            const SizedBox(height: 12),
            _buildSummaryRow('Discount (${_appliedCoupon!.code})',
                '- ${settings.formatPrice(discount)}',
                valueColor: AppTheme.successColor),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Colors.black12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.softUiTextColor)),
              Text(settings.formatPrice(total),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 15,
                color: AppTheme.softUiTextColor.withOpacity(0.6))),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.softUiTextColor)),
      ],
    );
  }

  Widget _buildCouponInput() {
    return Row(
      children: [
        Expanded(
          child: NeumorphicContainer(
            isConcave: true,
            borderRadius: BorderRadius.circular(15),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: _couponController,
              enabled: _appliedCoupon == null,
              decoration: InputDecoration(
                hintText: 'Enter coupon code',
                hintStyle:
                    TextStyle(color: AppTheme.softUiTextColor.withOpacity(0.3)),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                  color: AppTheme.softUiTextColor, fontWeight: FontWeight.bold),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
        ),
        const SizedBox(width: 16),
        NeumorphicButton(
          onTap: _appliedCoupon == null
              ? _applyCoupon
              : () => setState(() => _appliedCoupon = null),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          borderRadius: BorderRadius.circular(15),
          child: Text(
            _appliedCoupon == null ? 'Apply' : 'Remove',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _appliedCoupon == null
                  ? AppTheme.primaryColor
                  : AppTheme.errorColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableCoupons() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.availableCoupons.isEmpty)
          return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
              child: Text('Available Offers',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.softUiTextColor.withOpacity(0.4))),
            ),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: orderProvider.availableCoupons.length,
                itemBuilder: (context, index) {
                  final coupon = orderProvider.availableCoupons[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 4),
                    child: NeumorphicButton(
                      onTap: () {
                        _couponController.text = coupon.code;
                        _applyCoupon();
                      },
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      borderRadius: BorderRadius.circular(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(coupon.code,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                  fontSize: 14)),
                          Text(
                            coupon.type == 'percentage'
                                ? '${coupon.value.toInt()}% Off'
                                : '${Provider.of<SettingsProvider>(context, listen: false).formatPrice(coupon.value)} Off',
                            style: TextStyle(
                                fontSize: 10,
                                color:
                                    AppTheme.softUiTextColor.withOpacity(0.6)),
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
      },
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      children: [
        _buildPaymentCard('card', Icons.credit_card_rounded,
            'Credit/Debit Card', 'Secure payment via Stripe'),
        const SizedBox(height: 20),
        _buildPaymentCard('cod', Icons.payments_rounded, 'Cash on Delivery',
            'Pay when you receive'),
      ],
    );
  }

  Widget _buildPaymentCard(
      String value, IconData icon, String title, String subtitle) {
    final bool isSelected = _paymentMethod == value;
    return NeumorphicButton(
      onTap: () => setState(() => _paymentMethod = value),
      isPressed: isSelected,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      backgroundColor: isSelected
          ? AppTheme.primaryColor.withOpacity(0.05)
          : AppTheme.softUiBackground,
      child: Row(
        children: [
          NeumorphicContainer(
            shape: BoxShape.circle,
            isConcave: !isSelected,
            padding: const EdgeInsets.all(12),
            child: Icon(
              isSelected ? Icons.check_circle_rounded : icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.softUiTextColor.withOpacity(0.4),
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.softUiTextColor)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.softUiTextColor.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyPayButton(SettingsProvider settings, double amount) {
    return NeumorphicContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: NeumorphicButton(
        onTap: _isProcessing ? () {} : _processPayment,
        isPressed: _isProcessing,
        backgroundColor: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: _isProcessing
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(
                  _paymentMethod == 'card'
                      ? 'Proceed to Pay ${settings.formatPrice(amount)}'
                      : 'Place Order ${settings.formatPrice(amount)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1),
                ),
        ),
      ),
    );
  }

  Widget _buildStrapSelectionSection(CartProvider cartProvider) {
    final watchesWithStrapOptions = cartProvider.cartItems
        .where((item) =>
            item.watch != null &&
            (item.watch!.hasBeltOption || item.watch!.hasChainOption) &&
            cartProvider.selectedItemIds.contains(item.id))
        .toList();

    if (watchesWithStrapOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Customize Straps'),
        ...watchesWithStrapOptions.asMap().entries.map((entry) {
          return _buildWatchStrapSelector(
              watch: entry.value.watch!,
              cartItemId: entry.value.id,
              item: entry.value,
              index: entry.key + 1);
        }).toList(),
      ],
    );
  }

  Widget _buildWatchStrapSelector(
      {required Watch watch,
      required String cartItemId,
      required CartItem item,
      required int index}) {
    if (!_strapSelections.containsKey(cartItemId)) {
      _strapSelections[cartItemId] = {'strapType': null, 'strapColor': null};
    }
    final currentSelection = _strapSelections[cartItemId]!;
    final selectedType = currentSelection['strapType'];
    final selectedColor = currentSelection['strapColor'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: NeumorphicContainer(
        borderRadius: BorderRadius.circular(25),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NeumorphicContainer(
                  isConcave: true,
                  borderRadius: BorderRadius.circular(15),
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(watch.images.first,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.watch, size: 40)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WATCH #$index',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                              letterSpacing: 1)),
                      Text(watch.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.softUiTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (item.productColor != null)
                        Text('COLOR: ${item.productColor!.toUpperCase()}',
                            style: TextStyle(
                                fontSize: 10,
                                color:
                                    AppTheme.softUiTextColor.withOpacity(0.5))),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Colors.black12)),
            const Text('Strap Type',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softUiTextColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (watch.hasBeltOption)
                  _buildStrapTypeToggle('belt', 'Leather Belt', cartItemId,
                      selectedType == 'belt'),
                if (watch.hasChainOption) ...[
                  if (watch.hasBeltOption) const SizedBox(width: 12),
                  _buildStrapTypeToggle('chain', 'Metal Chain', cartItemId,
                      selectedType == 'chain'),
                ],
              ],
            ),
            if (selectedType != null) ...[
              const SizedBox(height: 24),
              Text('Select ${selectedType == 'belt' ? 'Belt' : 'Chain'} Color',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.softUiTextColor)),
              const SizedBox(height: 12),
              selectedType == 'belt'
                  ? _buildBeltColorPicker(cartItemId, selectedColor)
                  : _buildChainColorSelector(cartItemId, selectedColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStrapTypeToggle(
      String type, String label, String cartItemId, bool isSelected) {
    return Expanded(
      child: NeumorphicButton(
        onTap: () => setState(() {
          _strapSelections[cartItemId]!['strapType'] = isSelected ? null : type;
          _strapSelections[cartItemId]!['strapColor'] = null;
        }),
        isPressed: isSelected,
        borderRadius: BorderRadius.circular(15),
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: isSelected
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.softUiBackground,
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.softUiTextColor)),
        ),
      ),
    );
  }

  Widget _buildBeltColorPicker(String cartItemId, String? selectedColor) {
    final colors = [
      {'hex': '#000000', 'color': Colors.black},
      {'hex': '#FFFFFF', 'color': Colors.white},
      {'hex': '#795548', 'color': Colors.brown},
      {'hex': '#3E2723', 'color': Colors.brown[900]!},
      {'hex': '#D2B48C', 'color': const Color(0xFFD2B48C)},
      {'hex': '#2196F3', 'color': Colors.blue},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((c) {
        final bool isSelected = selectedColor == c['hex'];
        return NeumorphicButton(
          onTap: () => setState(() =>
              _strapSelections[cartItemId]!['strapColor'] = c['hex'] as String),
          isPressed: isSelected,
          shape: BoxShape.circle,
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: c['color'] as Color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12)),
            child: isSelected
                ? Icon(Icons.check,
                    size: 18,
                    color: (c['color'] as Color).computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChainColorSelector(String cartItemId, String? selectedColor) {
    final colors = [
      {'name': 'Silver', 'hex': '#C0C0C0'},
      {'name': 'Gold', 'hex': '#FFD700'},
      {'name': 'Black', 'hex': '#000000'},
    ];

    return Row(
      children: colors.map((c) {
        final bool isSelected = selectedColor == c['hex'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: NeumorphicButton(
              onTap: () => setState(
                  () => _strapSelections[cartItemId]!['strapColor'] = c['hex']),
              isPressed: isSelected,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: _hexToColor(c['hex']!),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(c['name']!,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.softUiTextColor)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _hexToColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));
}
