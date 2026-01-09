import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../orders/order_detail_screen.dart';
import '../../widgets/neumorphic_widgets.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      },
      child: Scaffold(
        backgroundColor: AppTheme.softUiBackground,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const NeumorphicTopBar(
                title: 'Order Confirmed',
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Success Icon in Convex Well
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: NeumorphicContainer(
                          shape: BoxShape.circle,
                          padding: const EdgeInsets.all(48),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.1),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 72,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const Text(
                              'Success!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.softUiTextColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your order has been placed successfully.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    AppTheme.softUiTextColor.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Order Details Slab
                            NeumorphicContainer(
                              borderRadius: BorderRadius.circular(25),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _buildInfoRow('Order ID',
                                      '#${widget.orderId.substring(0, 8).toUpperCase()}'),
                                  const SizedBox(height: 16),
                                  const Divider(
                                      height: 1, color: Colors.black12),
                                  const SizedBox(height: 16),
                                  _buildInfoRow('Status', 'Processing'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'A confirmation email has been sent to your registered address.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.softUiTextColor
                                          .withOpacity(0.5),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 60),

                            // Action Buttons
                            NeumorphicButton(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailScreen(
                                        orderId: widget.orderId),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(15),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: const Center(
                                child: Text(
                                  'View Order History',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.softUiTextColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            NeumorphicButton(
                              onTap: () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/home', (route) => false);
                              },
                              borderRadius: BorderRadius.circular(15),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: AppTheme.primaryColor,
                              child: const Center(
                                child: Text(
                                  'Continue Shopping',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.softUiTextColor.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.softUiTextColor,
          ),
        ),
      ],
    );
  }
}
