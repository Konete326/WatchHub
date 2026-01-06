import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../models/order.dart';
import '../../utils/theme.dart';
import '../../providers/settings_provider.dart';

import '../../services/invoice_service.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final AdminService _adminService = AdminService();

  Order? _order;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedStatus;

  final List<String> _statuses = [
    'PENDING',
    'CONFIRMED',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _adminService.getAllOrders(page: 1, limit: 1000);
      final ordersData = result['orders'];
      if (ordersData != null && ordersData is List) {
        final orders = (ordersData as List)
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList();
        final order = orders.firstWhere(
          (o) => o.id == widget.orderId,
          orElse: () => orders.first,
        );

        if (mounted) {
          setState(() {
            _order = order;
            _selectedStatus = order.status;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load order: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null || _selectedStatus == _order?.status) return;

    try {
      final updatedOrder = await _adminService.updateOrderStatus(
        widget.orderId,
        _selectedStatus!,
      );

      if (mounted) {
        setState(() {
          _order = updatedOrder;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order status updated successfully'),
              behavior: SnackBarBehavior.floating),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Invoice',
            onPressed: () async {
              if (_order != null) {
                await InvoiceService.generateAndPrintInvoice(_order!);
              }
            },
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _loadOrder, child: const Text('Retry')),
                ],
              ),
            );
          }

          if (_order == null) {
            return const Center(child: Text('Order not found'));
          }

          final order = _order!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Timeline
                _buildStatusTimeline(order.status),
                const SizedBox(height: 24),

                // Summary Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(dateFormat.format(order.createdAt),
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.statusDisplay,
                                style: TextStyle(
                                    color: _getStatusColor(order.status),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Revenue',
                                style: TextStyle(fontSize: 16)),
                            Text(
                              settings.formatPrice(order.totalAmount),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Customer Info
                const Text('Customer Info',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _infoRow(Icons.person_outline, 'Name',
                            order.user?.name ?? 'Unknown'),
                        const Divider(height: 24),
                        _infoRow(Icons.email_outlined, 'Email',
                            order.user?.email ?? 'Unknown'),
                        const Divider(height: 24),
                        _infoRow(Icons.location_on_outlined, 'Address',
                            order.address?.fullAddress ?? 'No Address'),
                        if (order.address?.phone != null) ...[
                          const Divider(height: 24),
                          _infoRow(Icons.phone_outlined, 'Phone',
                              order.address!.phone!),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Items list
                const Text('Order Items',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...(order.orderItems ?? []).map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade100)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.watch?.images.isNotEmpty == true
                            ? CachedNetworkImage(
                                imageUrl: item.watch!.images.first,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover)
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.watch)),
                      ),
                      title: Text(item.watch?.name ?? 'Unknown Watch',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Qty: ${item.quantity}'),
                      trailing: Text(settings.formatPrice(item.priceAtPurchase),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor)),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Status Update Card
                const Text('Management',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Update Order Status',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: _statuses
                              .map((status) => DropdownMenuItem(
                                  value: status, child: Text(status)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedStatus = value),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _updateStatus,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Update Order Status',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    if (currentStatus == 'CANCELLED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              'This order has been cancelled.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final steps = [
      {'label': 'Pending', 'status': 'PENDING', 'icon': Icons.access_time},
      {
        'label': 'Confirmed',
        'status': 'CONFIRMED',
        'icon': Icons.check_circle_outline
      },
      {
        'label': 'Shipped',
        'status': 'SHIPPED',
        'icon': Icons.local_shipping_outlined
      },
      {
        'label': 'Delivered',
        'status': 'DELIVERED',
        'icon': Icons.home_outlined
      },
    ];

    int currentIndex = steps.indexWhere((s) => s['status'] == currentStatus);
    if (currentIndex == -1) currentIndex = 0; // Default or fallback

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              // Step Icon
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: i <= currentIndex
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        steps[i]['icon'] as IconData,
                        size: 18,
                        color: i <= currentIndex
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: i == currentIndex
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: i <= currentIndex
                            ? AppTheme.primaryColor
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Line Connector
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < currentIndex
                        ? AppTheme.primaryColor
                        : Colors.grey.shade200,
                    margin: const EdgeInsets.only(
                        bottom: 20), // Align with circle center roughly
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}
