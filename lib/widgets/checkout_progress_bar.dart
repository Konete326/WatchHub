import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'neumorphic_widgets.dart';

class CheckoutProgressBar extends StatelessWidget {
  final int currentStep;

  const CheckoutProgressBar({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: AppTheme.softUiBackground,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Deep Recessed Track
          Positioned(
            left: 40,
            right: 40,
            child: NeumorphicContainer(
              isConcave: true,
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(height: 8, width: double.infinity),
            ),
          ),

          // Steps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStep(0, 'Address', Icons.location_on_rounded),
              _buildStep(1, 'Payment', Icons.account_balance_wallet_rounded),
              _buildStep(2, 'Success', Icons.verified_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, IconData icon) {
    final bool isCompleted = step < currentStep;
    final bool isActive = step == currentStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeumorphicContainer(
          isConcave: !isActive && !isCompleted,
          shape: BoxShape.circle,
          padding: const EdgeInsets.all(12),
          backgroundColor: isActive || isCompleted
              ? AppTheme.softUiBackground
              : AppTheme.softUiBackground,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isCompleted ? Icons.check_rounded : icon,
              key: ValueKey('${step}_${isCompleted}'),
              size: 20,
              color: isActive || isCompleted
                  ? AppTheme.primaryColor
                  : AppTheme.softUiTextColor.withOpacity(0.2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isActive || isCompleted ? FontWeight.bold : FontWeight.w500,
            color: isActive || isCompleted
                ? AppTheme.softUiTextColor
                : AppTheme.softUiTextColor.withOpacity(0.3),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
