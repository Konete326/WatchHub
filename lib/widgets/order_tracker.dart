import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'neumorphic_widgets.dart';

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
      return NeumorphicContainer(
        isConcave: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_rounded,
                color: AppTheme.errorColor, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Order Cancelled',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
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

    String effectiveStatus = currentStatus;
    if (effectiveStatus == 'PROCESSING') effectiveStatus = 'PENDING';

    int currentIndex = steps.indexWhere((s) => s['status'] == effectiveStatus);
    if (currentIndex == -1) currentIndex = 0;

    if (isHorizontal) {
      return Column(
        children: [
          Row(
            children: List.generate(steps.length, (index) {
              final isCompleted = index <= currentIndex;
              final isLast = index == steps.length - 1;

              return Expanded(
                flex: isLast ? 0 : 1,
                child: Row(
                  children: [
                    // Dot
                    NeumorphicContainer(
                      isConcave: !isCompleted,
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : (steps[index]['icon'] as IconData),
                        size: 14,
                        color: isCompleted
                            ? AppTheme.primaryColor
                            : AppTheme.softUiTextColor.withOpacity(0.3),
                      ),
                    ),
                    // Line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.primaryColor.withOpacity(0.5)
                                : AppTheme.softUiShadowDark.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isCompleted
                                ? []
                                : [
                                    const BoxShadow(
                                      color: AppTheme.softUiShadowLight,
                                      offset: Offset(0, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
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
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isCompleted
                        ? AppTheme.softUiTextColor
                        : AppTheme.softUiTextColor.withOpacity(0.4),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    } else {
      // Vertical
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
                    NeumorphicContainer(
                      isConcave: !isCompleted,
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : (steps[index]['icon'] as IconData),
                        size: 16,
                        color: isCompleted
                            ? AppTheme.primaryColor
                            : AppTheme.softUiTextColor.withOpacity(0.3),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 4,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.primaryColor.withOpacity(0.5)
                                : AppTheme.softUiShadowDark.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isCompleted
                                ? []
                                : [
                                    const BoxShadow(
                                      color: AppTheme.softUiShadowLight,
                                      offset: Offset(1, 0),
                                      blurRadius: 1,
                                    ),
                                  ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0, top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w600,
                          color: isCompleted
                              ? AppTheme.softUiTextColor
                              : AppTheme.softUiTextColor.withOpacity(0.4),
                        ),
                      ),
                      if (isActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Current Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                            ),
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
