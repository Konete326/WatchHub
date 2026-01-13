import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  Order? _order;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedStatus;

  final List<String> _statuses = [
    'PENDING',
    'CONFIRMED',
    'PROCESSING',
    'SHIPPED',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'CANCELLED',
    'ON_HOLD',
  ];

  final List<String> _availableTags = [
    'VIP',
    'PRIORITY',
    'FRAGILE',
    'GIFT',
    'RUSH',
    'INTERNATIONAL',
  ];

  final List<String> _courierOptions = [
    'FedEx',
    'UPS',
    'DHL',
    'USPS',
    'BlueDart',
    'TCS',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrder();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final order = await _adminService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _selectedStatus = order.status;
          _isLoading = false;
        });
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

  Future<void> _printInvoice() async {
    if (_order == null) return;
    try {
      await InvoiceService.generateAndPrintInvoice(_order!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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
        setState(() => _order = updatedOrder);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order status updated successfully'),
              behavior: SnackBarBehavior.floating),
        );
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
      case 'PROCESSING':
        return Colors.indigo;
      case 'SHIPPED':
        return Colors.purple;
      case 'OUT_FOR_DELIVERY':
        return Colors.teal;
      case 'DELIVERED':
        return AppTheme.successColor;
      case 'CANCELLED':
        return AppTheme.errorColor;
      case 'ON_HOLD':
        return Colors.amber;
      case 'REFUNDED':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null
            ? 'Order #${_order!.id.substring(0, 8).toUpperCase()}'
            : 'Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Invoice',
            onPressed: _printInvoice,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadOrder,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.goldColor,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: AppTheme.goldColor,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Timeline'),
            Tab(text: 'Items'),
            Tab(text: 'Actions'),
          ],
        ),
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

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(order, settings, dateFormat),
              _buildTimelineTab(order, dateFormat),
              _buildItemsTab(order, settings),
              _buildActionsTab(order),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(
      Order order, SettingsProvider settings, DateFormat dateFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fraud Warning
          if (order.isHighRisk || order.isOnHold)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.isOnHold ? 'Order On Hold' : 'High Risk Order',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (order.holdReason != null)
                          Text(order.holdReason!,
                              style: TextStyle(
                                  color: Colors.red.shade600, fontSize: 12)),
                        if (order.fraudSignals.isNotEmpty)
                          Text('Signals: ${order.fraudSignals.join(', ')}',
                              style: TextStyle(
                                  color: Colors.red.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Status Timeline
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
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(dateFormat.format(order.createdAt),
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status)
                              .withValues(alpha: 0.1),
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
                  if (order.hasRefund) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Refunded (${order.refund!.type})',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.red)),
                        Text(
                          '-${settings.formatPrice(order.refund!.amount)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tags
          if (order.tags.isNotEmpty) ...[
            const Text('Tags',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: order.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.blue.shade100,
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeTag(tag),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Tracking Info
          if (order.trackingNumber != null) ...[
            const Text('Tracking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                leading: const Icon(Icons.local_shipping),
                title: Text(order.trackingNumber!),
                subtitle: Text(order.courierName ?? 'Unknown Courier'),
                trailing: order.courierTrackingUrl != null
                    ? IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () =>
                            _openTrackingUrl(order.courierTrackingUrl!),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Customer Info
          const Text('Customer Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    _infoRow(
                        Icons.phone_outlined, 'Phone', order.address!.phone!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(Order order, DateFormat dateFormat) {
    final events = order.timeline.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return events.isEmpty
        ? const Center(child: Text('No timeline events yet'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isFirst = index == 0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isFirst ? AppTheme.primaryColor : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (index < events.length - 1)
                        Container(
                          width: 2,
                          height: 60,
                          color: Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: isFirst ? Colors.blue.shade50 : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatEventName(event.event),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isFirst ? AppTheme.primaryColor : null,
                                  ),
                                ),
                                Text(
                                  dateFormat.format(event.timestamp),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            if (event.note != null) ...[
                              const SizedBox(height: 4),
                              Text(event.note!,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700)),
                            ],
                            if (event.actor != null) ...[
                              const SizedBox(height: 4),
                              Text('by ${event.actor}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
  }

  Widget _buildItemsTab(Order order, SettingsProvider settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: (order.orderItems ?? []).map((item) {
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qty: ${item.quantity}'),
                if (item.strapType != null || item.strapColor != null)
                  Text(
                      'Strap: ${item.strapType ?? ''} ${item.strapColor ?? ''}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            trailing: Text(settings.formatPrice(item.priceAtPurchase),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionsTab(Order order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Update
          const Text('Update Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Order Status',
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _updateStatus,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Update Status'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Add Tag
          const Text('Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags
                .where((tag) => !order.tags.contains(tag))
                .map((tag) => ActionChip(
                      label: Text('+ $tag'),
                      onPressed: () => _addTag(tag),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Tracking Update
          const Text('Tracking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showTrackingDialog(order),
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Update Tracking Info'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Internal Notes
          const Text('Internal Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  ...order.internalNotes.map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• $note',
                            style: TextStyle(color: Colors.grey.shade700)),
                      )),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddNoteDialog,
                    icon: const Icon(Icons.note_add),
                    label: const Text('Add Note'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Refund Section
          const Text('Refund',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (order.hasRefund)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                              'Refund of \$${order.refund!.amount.toStringAsFixed(2)} processed',
                              style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showRefundDialog(order, 'PARTIAL'),
                            icon: const Icon(Icons.money_off),
                            label: const Text('Partial Refund'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showRefundDialog(order, 'FULL'),
                            icon: const Icon(Icons.undo),
                            label: const Text('Full Refund'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Hold/Release
          if (!order.isOnHold)
            ElevatedButton.icon(
              onPressed: () => _showHoldDialog(order),
              icon: const Icon(Icons.pause_circle),
              label: const Text('Put Order On Hold'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                minimumSize: const Size.fromHeight(50),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _releaseHold,
              icon: const Icon(Icons.play_circle),
              label: const Text('Release Hold'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          const SizedBox(height: 16),

          // Exchange Flow
          const Text('Exchange',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showExchangeDialog(order),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Initiate Exchange'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 50),
        ],
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
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
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
                        fontSize: 12,
                        fontWeight: i == currentIndex
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: i <= currentIndex
                            ? AppTheme.primaryColor
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < currentIndex
                        ? AppTheme.primaryColor
                        : Colors.grey.shade200,
                    margin: const EdgeInsets.only(bottom: 20),
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatEventName(String event) {
    return event.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _addTag(String tag) async {
    try {
      await _adminService.addOrderTag(widget.orderId, tag);
      _loadOrder();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add tag: $e')),
      );
    }
  }

  Future<void> _removeTag(String tag) async {
    try {
      await _adminService.removeOrderTag(widget.orderId, tag);
      _loadOrder();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove tag: $e')),
      );
    }
  }

  Future<void> _openTrackingUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showTrackingDialog(Order order) async {
    final trackingCtrl = TextEditingController(text: order.trackingNumber);
    String? selectedCourier = order.courierName;
    final urlCtrl = TextEditingController(text: order.courierTrackingUrl);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Tracking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCourier,
              decoration: const InputDecoration(labelText: 'Courier'),
              items: _courierOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => selectedCourier = v,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: trackingCtrl,
              decoration: const InputDecoration(labelText: 'Tracking Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              decoration:
                  const InputDecoration(labelText: 'Tracking URL (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _adminService.updateOrderTracking(
                widget.orderId,
                trackingNumber: trackingCtrl.text,
                courierName: selectedCourier,
                courierTrackingUrl:
                    urlCtrl.text.isNotEmpty ? urlCtrl.text : null,
              );
              _loadOrder();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddNoteDialog() async {
    final noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Internal Note'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await _adminService.addOrderNote(widget.orderId, noteCtrl.text);
                _loadOrder();
              }
            },
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRefundDialog(Order order, String type) async {
    final amountCtrl = TextEditingController(
        text: type == 'FULL' ? order.totalAmount.toStringAsFixed(2) : '');
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
              ),
              enabled: type == 'PARTIAL',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountCtrl.text.isNotEmpty && reasonCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await _adminService.processRefund(
                  widget.orderId,
                  amount: double.parse(amountCtrl.text),
                  reason: reasonCtrl.text,
                  type: type,
                );
                _loadOrder();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refund processed')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Process Refund'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHoldDialog(Order order) async {
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Put Order On Hold'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Reason for hold...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await _adminService.holdOrder(widget.orderId, reasonCtrl.text);
                _loadOrder();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Hold Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _releaseHold() async {
    await _adminService.releaseOrderHold(widget.orderId);
    _loadOrder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hold released')),
      );
    }
  }

  Future<void> _showExchangeDialog(Order order) async {
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initiate Exchange'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'This will mark the current order as exchanged and allow you to link a replacement order.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration:
                  const InputDecoration(labelText: 'Reason for exchange'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Simply add a timeline event and note for now
              await _adminService.addOrderTimelineEvent(
                  order.id, 'EXCHANGE_INITIATED',
                  note: reasonCtrl.text);
              await _adminService.addOrderTag(order.id, 'EXCHANGED');
              _loadOrder();
            },
            child: const Text('Initiate'),
          ),
        ],
      ),
    );
  }
}
