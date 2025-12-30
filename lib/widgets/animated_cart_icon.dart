import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class AnimatedCartIcon extends StatefulWidget {
  const AnimatedCartIcon({super.key});

  @override
  State<AnimatedCartIcon> createState() => _AnimatedCartIconState();
}

class _AnimatedCartIconState extends State<AnimatedCartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.4)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.4, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (cartProvider.addedToCart) {
          // Use addPostFrameCallback to avoid build-time state changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _triggerAnimation();
              cartProvider.consumeAddedToCart();
            }
          });
        }

        return ScaleTransition(
          scale: _scaleAnimation,
          child: Badge(
            label: Text(cartProvider.itemCount.toString()),
            isLabelVisible: cartProvider.itemCount > 0,
            child: const Icon(Icons.shopping_cart),
          ),
        );
      },
    );
  }
}
