import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool animateOnTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.padding = EdgeInsets.zero,
    this.color,
    this.animateOnTap = true,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 4, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.animateOnTap) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null && widget.animateOnTap) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && widget.animateOnTap) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.color ?? AppTheme.cardColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: AppTheme.borderColor.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: _elevationAnimation.value * 2,
                    offset: Offset(0, _elevationAnimation.value),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
