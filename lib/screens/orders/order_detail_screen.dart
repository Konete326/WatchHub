import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/order_tracker.dart';
import '../../widgets/neumorphic_widgets.dart';

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
      backgroundColor: AppTheme.softUiBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: NeumorphicTopBar(
          title: 'Order Details',
          onBackTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer2<OrderProvider, SettingsProvider>(
        builder: (context, orderProvider, settings, child) {
          if (orderProvider.isLoading || orderProvider.selectedOrder == null) {
            return const ListShimmer();
          }

          final order = orderProvider.selectedOrder!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Header
                Row(
                  children: [
                    NeumorphicContainer(
                      isConcave: true,
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        _getStatusIcon(order.status),
                        color: _getStatusColor(order.status),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.statusDisplay,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(order.status),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order #${order.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              color: AppTheme.softUiTextColor.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Buy Again Button (Primary Action)
                NeumorphicButton(
                  onTap: () async {
                    final cartProvider =
                        Provider.of<CartProvider>(context, listen: false);
                    if (order.orderItems != null) {
                      final success =
                          await cartProvider.reorder(order.orderItems!);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Items added to cart successfully!'),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(15),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh_rounded,
                          color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Buy Again',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Order Tracking Timeline
                const Text(
                  'Order Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softUiTextColor,
                  ),
                ),
                const SizedBox(height: 20),
                NeumorphicContainer(
                  borderRadius: BorderRadius.circular(25),
                  padding: const EdgeInsets.all(24),
                  child: OrderTracker(
                    currentStatus: order.status,
                    isHorizontal: false,
                  ),
                ),

                const SizedBox(height: 32),

                // Items Section
                const Text(
                  'Items Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softUiTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                if (order.orderItems != null)
                  ...order.orderItems!.map((item) {
                    final watch = item.watch!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: NeumorphicContainer(
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            NeumorphicContainer(
                              isConcave: true,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: watch.images.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.watch!.images.first,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                          baseColor: AppTheme.softUiShadowDark
                                              .withOpacity(0.3),
                                          highlightColor: AppTheme
                                              .softUiShadowLight
                                              .withOpacity(0.5),
                                          child: Container(
                                              width: 70,
                                              height: 70,
                                              color: Colors.white),
                                        ),
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: AppTheme.softUiBackground,
                                        child: const Icon(Icons.watch,
                                            color: Colors.grey),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    watch.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.softUiTextColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.productColor != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Color: ${item.productColor}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.softUiTextColor
                                              .withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: TextStyle(
                                            color: AppTheme.softUiTextColor
                                                .withOpacity(0.5),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        settings
                                            .formatPrice(item.priceAtPurchase),
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

                const SizedBox(height: 12),

                // Delivery Address
                if (order.address != null) ...[
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softUiTextColor),
                  ),
                  const SizedBox(height: 16),
                  NeumorphicContainer(
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NeumorphicContainer(
                          isConcave: true,
                          shape: BoxShape.circle,
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.location_on_rounded,
                              color: AppTheme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.address!.fullAddress,
                                style: const TextStyle(
                                    color: AppTheme.softUiTextColor,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500),
                              ),
                              if (order.address!.phone != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Phone: ${order.address!.phone}',
                                  style: TextStyle(
                                      color: AppTheme.softUiTextColor
                                          .withOpacity(0.6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Order Summary
                const Text(
                  'Order Summary',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.softUiTextColor),
                ),
                const SizedBox(height: 16),
                NeumorphicContainer(
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _summaryRow(
                          'Order Date', dateFormat.format(order.createdAt)),
                      const SizedBox(height: 16),
                      _etchedLine(),
                      const SizedBox(height: 16),
                      _summaryRow('Payment Method',
                          (order.paymentMethod ?? 'N/A').toUpperCase()),
                      const SizedBox(height: 16),
                      _etchedLine(),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.softUiTextColor),
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
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _etchedLine() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: AppTheme.softUiShadowDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1),
        boxShadow: [
          const BoxShadow(
            color: AppTheme.softUiShadowLight,
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: AppTheme.softUiTextColor.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.softUiTextColor)),
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
      case 'OUT_FOR_DELIVERY':
        return Colors.teal;
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
        return Icons.schedule_rounded;
      case 'PROCESSING':
        return Icons.hourglass_empty_rounded;
      case 'SHIPPED':
        return Icons.local_shipping_rounded;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining_rounded;
      case 'DELIVERED':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}
