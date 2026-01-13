import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/theme.dart';
import '../utils/haptics.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final String? lottieUrl;
  final IconData? icon;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
    this.lottieUrl,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottieUrl != null)
              Lottie.network(
                lottieUrl!,
                height: 200,
                repeat: true,
                errorBuilder: (context, error, stackTrace) =>
                    _buildIconFallback(),
              )
            else if (icon != null)
              _buildIconFallback()
            else
              const SizedBox(height: 200),
            const SizedBox(height: 32),
            Text(
              title,
              style: AppTheme.headingFont.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTheme.bodyFont.copyWith(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticHelper.medium();
                    onActionPressed!();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconFallback() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? Icons.shopping_basket_outlined,
        size: 80,
        color: AppTheme.primaryColor.withOpacity(0.3),
      ),
    );
  }
}
