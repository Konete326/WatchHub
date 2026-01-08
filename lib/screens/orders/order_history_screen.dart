import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final Set<String> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OrderProvider>(context, listen: false)
          .fetchOrders(refresh: true);
    });
  }

  void _toggleExpanded(String orderId) {
    setState(() {
      if (_expandedOrders.contains(orderId)) {
        _expandedOrders.remove(orderId);
      } else {
        _expandedOrders.add(orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<OrderProvider>(context, listen: false)
              .fetchOrders(refresh: true);
        },
        child: Consumer2<OrderProvider, SettingsProvider>(
          builder: (context, orderProvider, settings, child) {
            if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
              return const ListShimmer();
            }

            if (orderProvider.orders.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message:
                    'When you place an order, it will appear here. Start exploring our luxury collection!',
                actionLabel: 'Start Shopping',
                onActionPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false);
                },
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: orderProvider.orders.length,
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                final isExpanded = _expandedOrders.contains(order.id);
                final firstItem = order.orderItems?.isNotEmpty == true
                    ? order.orderItems!.first
                    : null;
                final thumbnailUrl = firstItem?.watch?.images.isNotEmpty == true
                    ? firstItem!.watch!.images.first
                    : null;

                return _MinimalistOrderCard(
                  orderId: order.id,
                  orderDate: dateFormat.format(order.createdAt),
                  status: order.status,
                  statusDisplay: order.statusDisplay,
                  thumbnailUrl: thumbnailUrl,
                  itemCount: order.orderItems?.length ?? 0,
                  totalAmount: settings.formatPrice(order.totalAmount),
                  isExpanded: isExpanded,
                  isDark: isDark,
                  onTap: () => _toggleExpanded(order.id),
                  onViewDetails: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                  onBuyAgain: () async {
                    final cartProvider =
                        Provider.of<CartProvider>(context, listen: false);
                    final orderProv =
                        Provider.of<OrderProvider>(context, listen: false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Adding items to cart...'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    if (order.orderItems == null) {
                      await orderProv.fetchOrderById(order.id);
                    }

                    final fullOrder = orderProv.selectedOrder;
                    if (fullOrder != null && fullOrder.orderItems != null) {
                      final success =
                          await cartProvider.reorder(fullOrder.orderItems!);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Items added to cart successfully!'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MinimalistOrderCard extends StatelessWidget {
  final String orderId;
  final String orderDate;
  final String status;
  final String statusDisplay;
  final String? thumbnailUrl;
  final int itemCount;
  final String totalAmount;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onViewDetails;
  final VoidCallback onBuyAgain;

  const _MinimalistOrderCard({
    required this.orderId,
    required this.orderDate,
    required this.status,
    required this.statusDisplay,
    required this.thumbnailUrl,
    required this.itemCount,
    required this.totalAmount,
    required this.isExpanded,
    required this.isDark,
    required this.onTap,
    required this.onViewDetails,
    required this.onBuyAgain,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
        return Colors.purple;
      case 'DELIVERED':
        return AppTheme.successColor;
      case 'CANCELLED':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'PENDING':
        return Icons.access_time_rounded;
      case 'PROCESSING':
        return Icons.inventory_2_outlined;
      case 'SHIPPED':
        return Icons.local_shipping_outlined;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining_outlined;
      case 'DELIVERED':
        return Icons.check_circle_outline_rounded;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            children: [
              // Main Card Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: thumbnailUrl != null
                          ? CachedNetworkImage(
                              imageUrl: thumbnailUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Icon(
                                  Icons.watch_outlined,
                                  color: Colors.grey.shade400,
                                  size: 24,
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.watch_outlined,
                                  color: Colors.grey.shade400,
                                  size: 24,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.watch_outlined,
                                color: Colors.grey.shade400,
                                size: 24,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),

                    // Order Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderDate,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$itemCount item${itemCount != 1 ? 's' : ''} • $totalAmount',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Expand Arrow
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded Content - Order Timeline
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedContent(context),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          // Order Timeline
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: _OrderTimeline(
              currentStatus: status,
              isDark: isDark,
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white70 : Colors.grey.shade700,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'View Details',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBuyAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Buy Again',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  final String currentStatus;
  final bool isDark;

  const _OrderTimeline({
    required this.currentStatus,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        status: 'PENDING',
        label: 'Ordered',
        icon: Icons.shopping_bag_outlined,
      ),
      _TimelineStep(
        status: 'PROCESSING',
        label: 'Processing',
        icon: Icons.inventory_2_outlined,
      ),
      _TimelineStep(
        status: 'SHIPPED',
        label: 'Shipped',
        icon: Icons.local_shipping_outlined,
      ),
      _TimelineStep(
        status: 'DELIVERED',
        label: 'Delivered',
        icon: Icons.check_circle_outline_rounded,
      ),
    ];

    // Handle cancelled status
    if (currentStatus == 'CANCELLED') {
      return _buildCancelledTimeline();
    }

    final currentIndex = _getStatusIndex(currentStatus);

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index <= currentIndex;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Dot and Line
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  // Dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? _getStepColor(step.status)
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                      border: isCompleted
                          ? null
                          : Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                              width: 2,
                            ),
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 8,
                            color: Colors.white,
                          )
                        : null,
                  ),

                  // Line
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 28,
                      color: index < currentIndex
                          ? _getStepColor(steps[index + 1].status)
                          : (isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Step Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Row(
                  children: [
                    Icon(
                      step.icon,
                      size: 16,
                      color: isCompleted
                          ? _getStepColor(step.status)
                          : (isDark ? Colors.white38 : Colors.grey.shade400),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isCompleted ? FontWeight.w600 : FontWeight.w400,
                        color: isCompleted
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white38 : Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCancelledTimeline() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cancel_outlined,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This order has been cancelled',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getStatusIndex(String status) {
    switch (status) {
      case 'PENDING':
        return 0;
      case 'PROCESSING':
        return 1;
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
        return 2;
      case 'DELIVERED':
        return 3;
      default:
        return 0;
    }
  }

  Color _getStepColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }
}

class _TimelineStep {
  final String status;
  final String label;
  final IconData icon;

  _TimelineStep({
    required this.status,
    required this.label,
    required this.icon,
  });
}
