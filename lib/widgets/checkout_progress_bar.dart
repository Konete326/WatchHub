import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CheckoutProgressBar extends StatelessWidget {
  final int currentStep;

  const CheckoutProgressBar({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          _buildStep(0, 'Address', Icons.location_on_outlined),
          _buildDivider(0),
          _buildStep(1, 'Payment', Icons.payment_outlined),
          _buildDivider(1),
          _buildStep(2, 'Confirm', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, IconData icon) {
    bool isCompleted = step < currentStep;
    bool isActive = step == currentStep;
    Color color =
        isCompleted || isActive ? AppTheme.primaryColor : Colors.grey.shade300;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryColor
                  : (isCompleted
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              size: 18,
              color: isActive ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color:
                  isActive ? AppTheme.textPrimaryColor : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(int step) {
    bool isCompleted = step < currentStep;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade200,
    );
  }
}
