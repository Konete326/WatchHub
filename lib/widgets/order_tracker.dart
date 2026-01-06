import 'package:flutter/material.dart';
import '../utils/theme.dart';

class OrderTracker extends StatelessWidget {
  final String currentStatus;
  final bool isHorizontal;

  const OrderTracker({
    super.key,
    required this.currentStatus,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'CANCELLED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Text(
              'Order Cancelled',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final steps = [
      {
        'status': 'PENDING',
        'label': 'Ordered',
        'icon': Icons.inventory_2_outlined
      },
      {
        'status': 'SHIPPED',
        'label': 'Shipped',
        'icon': Icons.local_shipping_outlined
      },
      {
        'status': 'OUT_FOR_DELIVERY',
        'label': 'Out for Delivery',
        'icon': Icons.delivery_dining_outlined
      },
      {
        'status': 'DELIVERED',
        'label': 'Delivered',
        'icon': Icons.verified_outlined
      },
    ];

    // Map PROCESSING to PENDING context for visual tracker
    String effectiveStatus = currentStatus;
    if (effectiveStatus == 'PROCESSING') effectiveStatus = 'PENDING';

    int currentIndex = steps.indexWhere((s) => s['status'] == effectiveStatus);
    if (currentIndex == -1) currentIndex = 0;

    if (isHorizontal) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Row(
              children: List.generate(steps.length, (index) {
                final isCompleted = index <= currentIndex;
                final isLast = index == steps.length - 1;

                return Expanded(
                  flex: isLast ? 0 : 1,
                  child: Row(
                    children: [
                      // Point
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.primaryColor
                              : Colors.white,
                          border: Border.all(
                            color: isCompleted
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : (steps[index]['icon'] as IconData),
                          size: 12,
                          color:
                              isCompleted ? Colors.white : Colors.grey.shade400,
                        ),
                      ),
                      // Line
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index < currentIndex
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: steps.map((step) {
                final index = steps.indexOf(step);
                final isCompleted = index <= currentIndex;
                final isActive = index == currentIndex;

                return Expanded(
                  child: Text(
                    step['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isCompleted
                          ? AppTheme.textPrimaryColor
                          : Colors.grey.shade400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    } else {
      // Vertical implementation
      return Column(
        children: List.generate(steps.length, (index) {
          final isCompleted = index <= currentIndex;
          final isLast = index == steps.length - 1;
          final isActive = index == currentIndex;

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:
                            isCompleted ? AppTheme.primaryColor : Colors.white,
                        border: Border.all(
                          color: isCompleted
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check
                            : (steps[index]['icon'] as IconData),
                        size: 14,
                        color:
                            isCompleted ? Colors.white : Colors.grey.shade400,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: index < currentIndex
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w600,
                          color: isCompleted
                              ? AppTheme.textPrimaryColor
                              : Colors.grey,
                        ),
                      ),
                      if (isActive)
                        Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      );
    }
  }
}
