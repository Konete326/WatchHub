import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../../utils/animation_utils.dart';
import '../../utils/theme.dart';
import '../orders/order_detail_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 100,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Order ID: ${orderId.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thank you for your purchase!\nYou will receive a confirmation email shortly.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  AnimationUtils.pushSharedAxis(
                    context,
                    OrderDetailScreen(orderId: orderId),
                    transitionType: SharedAxisTransitionType.horizontal,
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('View Order Details'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // Navigate to home screen, clearing all previous routes
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false, // Remove all previous routes
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

