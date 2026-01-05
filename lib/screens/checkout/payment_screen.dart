import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material show Card;
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
  // Map of cartItemId -> {strapType, strapColor}
  final Map<String, Map<String, String?>> _strapSelections = {};

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Minimum order amount for this coupon is ${settingsProvider.formatPrice(coupon.minAmount!)}'),
            behavior: SnackBarBehavior.floating));
        return;
      }
      setState(() {
        _appliedCoupon = coupon;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Coupon applied successfully!'),
          behavior: SnackBarBehavior.floating));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Invalid coupon code'),
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Check if Stripe is properly configured
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
        // Create payment intent
        final paymentData =
            await orderProvider.createPaymentIntent(finalAmount);

        if (paymentData == null) {
          final errorMsg = orderProvider.errorMessage ??
              'Failed to create payment intent. Please check backend Stripe configuration.';
          throw Exception(errorMsg);
        }

        paymentIntentId = paymentData['paymentIntentId'];

        // Only proceed with Stripe UI if we are NOT in fake mode
        if (!Constants.useFakePayment) {
          // Handle web vs mobile differently
          if (kIsWeb) {
            // Web payment flow using Stripe.js
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
            // Mobile payment flow using Flutter Stripe SDK
            // Initialize payment sheet
            await Stripe.instance.initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                merchantDisplayName: 'WatchHub',
                paymentIntentClientSecret: paymentData['clientSecret'],
                style: ThemeMode.light,
              ),
            );

            // Present payment sheet
            await Stripe.instance.presentPaymentSheet();
          }
        } else {
          // In fake mode, we just simulate a small delay to mimic payment processing
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      // Create order
      final order = await orderProvider.createOrder(
        addressId: widget.addressId,
        paymentIntentId: paymentIntentId,
        shippingCost: cartProvider.deliveryCharge,
        cartItemIds: cartProvider.selectedItemIds.toList(),
        paymentMethod: _paymentMethod,
        couponId: _appliedCoupon?.id,
        strapSelections: _strapSelections,
      );

      if (order == null) {
        throw Exception('Failed to create order');
      }

      // Clear cart
      await cartProvider.clearCart();

      if (!mounted) return;

      // Navigate to confirmation
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(orderId: order.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Payment failed';

      if (e is StripeException) {
        errorMessage = e.error.message ?? 'Payment cancelled or failed';
      } else if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');

        // Provide helpful messages for common issues
        if (errorMessage.contains('Stripe is not configured')) {
          errorMessage =
              'Stripe is not configured. Please set your Stripe publishable key in lib/utils/constants.dart';
        } else if (errorMessage.contains('Failed to create payment intent')) {
          errorMessage =
              'Failed to create payment intent. Please check:\n1. Backend has STRIPE_SECRET_KEY in .env\n2. Backend is running\n3. You are logged in';
        } else if (errorMessage.contains('Network error')) {
          errorMessage =
              'Network error. Please check your connection and ensure the backend is running.';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildStrapSelectionSection(CartProvider cartProvider) {
    // Get watches with strap options
    final watchesWithStrapOptions = cartProvider.cartItems
        .where((item) => 
            item.watch != null && 
            (item.watch!.hasBeltOption || item.watch!.hasChainOption) &&
            cartProvider.selectedItemIds.contains(item.id))
        .toList();

    if (watchesWithStrapOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Strap Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please select strap type and color for each watch:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        ...watchesWithStrapOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final watch = item.watch!;
          final cartItemId = item.id;
          
          // Initialize selection if not exists
          if (!_strapSelections.containsKey(cartItemId)) {
            _strapSelections[cartItemId] = {'strapType': null, 'strapColor': null};
          }
          
          return _buildWatchStrapSelector(
            watch: watch,
            cartItemId: cartItemId,
            item: item,
            index: index + 1,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWatchStrapSelector({
    required Watch watch,
    required String cartItemId,
    required CartItem item,
    required int index,
  }) {
    final currentSelection = _strapSelections[cartItemId]!;
    final selectedType = currentSelection['strapType'];
    final selectedColor = currentSelection['strapColor'];

    return material.Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Watch Header with Image and Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Watch Image
                if (watch.images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      watch.images.first,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.watch, color: Colors.grey),
                      ),
                    ),
                  ),
                if (watch.images.isNotEmpty) const SizedBox(width: 12),
                // Watch Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Watch Number Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Watch #$index',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Brand Name
                      if (watch.brand != null)
                        Text(
                          watch.brand!.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      // Watch Name
                      Text(
                        watch.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Strap Type Selection
            if (watch.hasBeltOption || watch.hasChainOption) ...[
              const Text(
                'Select Strap Type:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  if (watch.hasBeltOption)
                    const ButtonSegment(value: 'belt', label: Text('Belt')),
                  if (watch.hasChainOption)
                    const ButtonSegment(value: 'chain', label: Text('Chain')),
                ],
                selected: selectedType != null ? {selectedType} : <String>{},
                emptySelectionAllowed: true,
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _strapSelections[cartItemId] = {
                      'strapType': newSelection.isNotEmpty ? newSelection.first : null,
                      'strapColor': null, // Reset color when type changes
                    };
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Color Selection
            if (selectedType != null) ...[
              if (selectedType == 'belt')
                _buildBeltColorPicker(watch, cartItemId, selectedColor)
              else if (selectedType == 'chain')
                _buildChainColorSelector(watch, cartItemId, selectedColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBeltColorPicker(Watch watch, String cartItemId, String? selectedColor) {
    final colors = [
      {'name': 'Black', 'color': Colors.black, 'hex': '#000000'},
      {'name': 'White', 'color': Colors.white, 'hex': '#FFFFFF'},
      {'name': 'Brown', 'color': Colors.brown, 'hex': '#795548'},
      {'name': 'Dark Brown', 'color': Colors.brown[800]!, 'hex': '#3E2723'},
      {'name': 'Tan', 'color': const Color(0xFFD2B48C), 'hex': '#D2B48C'},
      {'name': 'Red', 'color': Colors.red, 'hex': '#F44336'},
      {'name': 'Blue', 'color': Colors.blue, 'hex': '#2196F3'},
      {'name': 'Green', 'color': Colors.green, 'hex': '#4CAF50'},
      {'name': 'Gray', 'color': Colors.grey, 'hex': '#9E9E9E'},
      {'name': 'Navy', 'color': Colors.indigo[900]!, 'hex': '#1A237E'},
      {'name': 'Beige', 'color': const Color(0xFFF5F5DC), 'hex': '#F5F5DC'},
      {'name': 'Burgundy', 'color': const Color(0xFF800020), 'hex': '#800020'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Belt Color:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((colorData) {
            final isSelected = selectedColor == colorData['hex'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _strapSelections[cartItemId]!['strapColor'] = colorData['hex'] as String;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorData['color'] as Color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChainColorSelector(Watch watch, String cartItemId, String? selectedColor) {
    final chainColors = [
      {'name': 'Black', 'hex': '#000000'},
      {'name': 'Silver', 'hex': '#C0C0C0'},
      {'name': 'Gold', 'hex': '#FFD700'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Chain Color:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedColor,
          decoration: const InputDecoration(
            labelText: 'Chain Color',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.color_lens),
          ),
          items: chainColors.map((colorData) {
            return DropdownMenuItem(
              value: colorData['hex'] as String,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _hexToColor(colorData['hex'] as String),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(colorData['name'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _strapSelections[cartItemId]!['strapColor'] = value;
            });
          },
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    try {
      if (hex.startsWith('#')) {
        return Color(int.parse('0xFF${hex.substring(1)}'));
      }
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final discount =
        _appliedCoupon?.calculateDiscount(cartProvider.subtotal) ?? 0;
    final finalAmount = cartProvider.totalAmount - discount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Consumer2<CartProvider, SettingsProvider>(
        builder: (context, cartProvider, settings, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment Summary
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      material.Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:',
                                      style: TextStyle(fontSize: 15)),
                                  Text(
                                      settings
                                          .formatPrice(cartProvider.subtotal),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Shipping:',
                                      style: TextStyle(fontSize: 15)),
                                  Text(
                                      cartProvider.deliveryCharge == 0
                                          ? 'FREE'
                                          : settings.formatPrice(
                                              cartProvider.deliveryCharge),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: cartProvider.deliveryCharge == 0
                                            ? AppTheme.successColor
                                            : AppTheme.textPrimaryColor,
                                      )),
                                ],
                              ),
                              if (_appliedCoupon != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Coupon (${_appliedCoupon!.code}):',
                                        style: const TextStyle(
                                            color: AppTheme.successColor,
                                            fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '- ${settings.formatPrice(discount)}',
                                      style: const TextStyle(
                                          color: AppTheme.successColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    settings.formatPrice(finalAmount),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Strap Selection Section
                      _buildStrapSelectionSection(cartProvider),

                      const SizedBox(height: 24),

                      // Coupon Section
                      const Text(
                        'Coupon Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _couponController,
                              decoration: InputDecoration(
                                hintText: 'Enter coupon code',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              enabled: _appliedCoupon == null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _appliedCoupon == null
                                  ? _applyCoupon
                                  : () => setState(() => _appliedCoupon = null),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _appliedCoupon == null
                                    ? AppTheme.primaryColor
                                    : AppTheme.errorColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                  _appliedCoupon == null ? 'Apply' : 'Remove'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Payment Info
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      material.Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: const Text('Credit/Debit Card',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('Secure payment via Stripe'),
                              value: 'card',
                              groupValue: _paymentMethod,
                              onChanged: (v) =>
                                  setState(() => _paymentMethod = v!),
                              secondary: const Icon(Icons.credit_card,
                                  color: AppTheme.primaryColor),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16))),
                            ),
                            const Divider(height: 0),
                            RadioListTile<String>(
                              title: const Text('Cash on Delivery (COD)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('Pay when you receive'),
                              value: 'cod',
                              groupValue: _paymentMethod,
                              onChanged: (v) =>
                                  setState(() => _paymentMethod = v!),
                              secondary:
                                  const Icon(Icons.money, color: Colors.green),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(16))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pay Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _paymentMethod == 'card'
                                ? 'Pay ${settings.formatPrice(finalAmount)}'
                                : 'Place Order ${settings.formatPrice(finalAmount)}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
