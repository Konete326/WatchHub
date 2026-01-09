import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'neumorphic_widgets.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    const Color kBgColor = Color(0xFFE0E5EC);
    const Color kLightShadow = Color(0xFFFFFFFF);
    const Color kDarkShadow = Color(0xFFA3B1C6);
    const Color kTextColor = Color(0xFF4A5568);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration Section
            _buildIllustration(kBgColor, kLightShadow, kDarkShadow),

            const SizedBox(height: 56),

            // Typography
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: kTextColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: kTextColor.withOpacity(0.7),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 56),
              // Action Button
              _NeumorphicActionButton(
                label: actionLabel!,
                onPressed: onActionPressed!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(
      Color bgColor, Color lightShadow, Color darkShadow) {
    return Container(
      width: 220,
      height: 220,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outermost Ring (180px) - Concave
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              boxShadow: [
                BoxShadow(
                  color: darkShadow.withOpacity(0.8),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: lightShadow.withOpacity(0.9),
                  offset: const Offset(-4, -4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),

          // Middle Ring (140px) - Convex
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              boxShadow: [
                BoxShadow(
                  color: darkShadow,
                  offset: const Offset(8, 8),
                  blurRadius: 16,
                ),
                BoxShadow(
                  color: lightShadow,
                  offset: const Offset(-8, -8),
                  blurRadius: 16,
                ),
              ],
            ),
          ),

          // Innermost Circle (100px) - Deep Concave
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              boxShadow: [
                BoxShadow(
                  color: darkShadow.withOpacity(0.6),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: lightShadow.withOpacity(0.8),
                  offset: const Offset(-3, -3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppTheme.primaryColor.withOpacity(0.4),
            ),
          ),

          // Decorative Elements - Convex Dots
          Positioned(
            top: 30,
            right: 40,
            child: _buildDecorativeDot(12, darkShadow, lightShadow),
          ),
          Positioned(
            bottom: 50,
            left: 30,
            child: _buildDecorativeDot(8, darkShadow, lightShadow),
          ),
          Positioned(
            top: 60,
            left: 50,
            child: _buildDecorativeDot(6, darkShadow, lightShadow),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeDot(double size, Color darkShadow, Color lightShadow) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: lightShadow,
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _NeumorphicActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _NeumorphicActionButton({
    required this.label,
    required this.onPressed,
  });

  @override
  State<_NeumorphicActionButton> createState() =>
      _NeumorphicActionButtonState();
}

class _NeumorphicActionButtonState extends State<_NeumorphicActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const Color kBgColor = Color(0xFFE0E5EC);
    const Color kLightShadow = Color(0xFFFFFFFF);
    const Color kDarkShadow = Color(0xFFA3B1C6);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        decoration: BoxDecoration(
          color: kBgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: kDarkShadow.withOpacity(0.8),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: kLightShadow.withOpacity(0.9),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  const BoxShadow(
                    color: kDarkShadow,
                    offset: Offset(6, 6),
                    blurRadius: 12,
                  ),
                  const BoxShadow(
                    color: kLightShadow,
                    offset: Offset(-6, -6),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
