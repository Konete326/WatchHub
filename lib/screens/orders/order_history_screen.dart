import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_tracker.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OrderProvider>(context, listen: false)
          .fetchOrders(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

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
              padding: const EdgeInsets.all(16),
              itemCount: orderProvider.orders.length,
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderDetailScreen(orderId: order.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateFormat.format(order.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order.status)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  order.statusDisplay,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(order.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OrderTracker(currentStatus: order.status),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${order.orderItems?.length ?? 0} item(s)',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13),
                              ),
                              Text(
                                settings.formatPrice(order.totalAmount),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final cartProvider = Provider.of<CartProvider>(
                                    context,
                                    listen: false);
                                final orderProvider =
                                    Provider.of<OrderProvider>(context,
                                        listen: false);

                                // Show loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Adding items to cart...'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );

                                // Fetch full order if items are missing
                                if (order.orderItems == null) {
                                  await orderProvider.fetchOrderById(order.id);
                                }

                                final fullOrder = orderProvider.selectedOrder;
                                if (fullOrder != null &&
                                    fullOrder.orderItems != null) {
                                  final success = await cartProvider
                                      .reorder(fullOrder.orderItems!);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Items added to cart successfully!'),
                                        backgroundColor: AppTheme.successColor,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.reorder, size: 18),
                              label: const Text('Buy Again'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppTheme.primaryColor),
                                foregroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
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
}
