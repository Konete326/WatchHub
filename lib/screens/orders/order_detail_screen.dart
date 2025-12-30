import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/shimmer_loading.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OrderProvider>(context, listen: false)
          .fetchOrderById(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Consumer2<OrderProvider, SettingsProvider>(
        builder: (context, orderProvider, settings, child) {
          if (orderProvider.isLoading || orderProvider.selectedOrder == null) {
            return const ListShimmer();
          }

          final order = orderProvider.selectedOrder!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(order.status),
                          color: _getStatusColor(order.status),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.statusDisplay,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order #${order.id.substring(0, 8).toUpperCase()}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Tracking Timeline
                      const Text(
                        'Order Tracking',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeline(order.status),

                      const SizedBox(height: 24),

                      // Items Section
                      const Text(
                        'Items Summary',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (order.orderItems != null)
                        ...order.orderItems!.map((item) {
                          final watch = item.watch!;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade100),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: watch.images.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: item.watch!.images.first,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                  width: 70,
                                                  height: 70,
                                                  color: Colors.white),
                                            ),
                                          )
                                        : Container(
                                            width: 70,
                                            height: 70,
                                            color: Colors.grey[100],
                                            child: const Icon(Icons.watch,
                                                color: Colors.grey),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          watch.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Quantity: ${item.quantity}',
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13),
                                            ),
                                            Text(
                                              settings.formatPrice(
                                                  item.priceAtPurchase),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 24),

                      // Delivery Address
                      if (order.address != null) ...[
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.location_on,
                                      color: AppTheme.primaryColor, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.address!.fullAddress,
                                        style: TextStyle(
                                            color: Colors.grey.shade700,
                                            height: 1.4),
                                      ),
                                      if (order.address!.phone != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Phone: ${order.address!.phone}',
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Order Summary
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _summaryRow('Order Date',
                                  dateFormat.format(order.createdAt)),
                              const Divider(height: 24),
                              _summaryRow('Payment Method',
                                  (order.paymentMethod ?? 'N/A').toUpperCase()),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    settings.formatPrice(order.totalAmount),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    if (currentStatus == 'CANCELLED') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'This order has been cancelled.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final List<Map<String, dynamic>> steps = [
      {
        'status': 'PENDING',
        'title': 'Order Placed',
        'icon': Icons.assignment_turned_in
      },
      {
        'status': 'PROCESSING',
        'title': 'Processing',
        'icon': Icons.hourglass_full
      },
      {'status': 'SHIPPED', 'title': 'Shipped', 'icon': Icons.local_shipping},
      {'status': 'DELIVERED', 'title': 'Delivered', 'icon': Icons.check_circle},
    ];

    int currentIndex = steps.indexWhere((s) => s['status'] == currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: List.generate(steps.length, (index) {
          final isCompleted = index <= currentIndex;
          final isActive = index == currentIndex;
          final isLast = index == steps.length - 1;

          return _buildTimelineStep(
            title: steps[index]['title'],
            isActive: isActive,
            isCompleted: isCompleted,
            isLast: isLast,
            icon: steps[index]['icon'],
          );
        }),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required bool isActive,
    required bool isCompleted,
    required bool isLast,
    required IconData icon,
  }) {
    final color = isCompleted ? AppTheme.primaryColor : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? color : Colors.white,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted ? Colors.white : color,
                size: 14,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: color,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive
                  ? FontWeight.bold
                  : (isCompleted ? FontWeight.w600 : FontWeight.normal),
              color: isCompleted ? AppTheme.textPrimaryColor : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return AppTheme.successColor;
      case 'CANCELLED':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.schedule;
      case 'PROCESSING':
        return Icons.hourglass_empty;
      case 'SHIPPED':
        return Icons.local_shipping;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
