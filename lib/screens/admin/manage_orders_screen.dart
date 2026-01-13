import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/order.dart';
import 'admin_order_detail_screen.dart';
import '../../widgets/admin/admin_layout.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final AdminService _adminService = AdminService();
  final Set<String> _selectedOrderIds = {};
  bool _isBulkMode = false;

  List<Order> _orders = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  String? _selectedStatus;

  final List<String> _statuses = [
    'PENDING',
    'CONFIRMED',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED',
    'ON_HOLD',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({int page = 1, String? status}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _currentPage = page;
      _selectedStatus = status;
    });

    try {
      final result = await _adminService.getAllOrders(
        page: page,
        limit: 20,
        status: status,
      );

      if (mounted) {
        setState(() {
          final ordersData = result['orders'];
          if (ordersData != null && ordersData is List) {
            _orders = ordersData.cast<Order>();
          } else {
            _orders = [];
          }

          final pagination = result['pagination'];
          if (pagination != null) {
            _totalPages = pagination['totalPages'] ?? 1;
            _total = pagination['total'] ?? 0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportOrders() async {
    setState(() => _isLoading = true);
    try {
      final csvData = await _adminService.exportOrdersToCSV(
        status: _selectedStatus,
      );

      // In a real app, we would use path_provider and open_file or share_plus to save this.
      // For this demo, we'll simulate the download.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('CSV exported successfully (${csvData.length} bytes)'),
            action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  // Show a snippet of CSV in a dialog for demo purposes
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('CSV Snippet (First 500 chars)'),
                      content: SingleChildScrollView(
                        child: Text(csvData.substring(
                            0, csvData.length > 500 ? 500 : csvData.length)),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'))
                      ],
                    ),
                  );
                }),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _bulkExportSelected() {
    if (_selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select orders to export')));
      return;
    }
    // Simulation for selected orders only...
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Exporting ${_selectedOrderIds.length} selected orders to CSV...')));
  }

  void _bulkStatusUpdate() async {
    if (_selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select orders to update')));
      return;
    }

    String? newStatus;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Status Update'),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'New Status'),
          items: _statuses
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => newStatus = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update All'),
          ),
        ],
      ),
    );

    if (confirmed == true && newStatus != null) {
      setState(() => _isLoading = true);
      try {
        for (final id in _selectedOrderIds) {
          await _adminService.updateOrderStatus(id, newStatus!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Updated ${_selectedOrderIds.length} orders to $newStatus')),
          );
          _selectedOrderIds.clear();
          _isBulkMode = false;
          _loadOrders(page: _currentPage, status: _selectedStatus);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Update failed: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Manage Orders',
      currentRoute: '/admin/orders',
      actions: [
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          onPressed: _exportOrders,
          tooltip: 'Export Current View',
        ),
        if (_selectedOrderIds.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: _bulkStatusUpdate,
            tooltip: 'Bulk Update Status',
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _bulkExportSelected,
            tooltip: 'Export Selected',
          ),
        ],
      ],
      child: DefaultTabController(
        length: _statuses.length + 1,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                onTap: (index) {
                  _loadOrders(
                      page: 1,
                      status: index == 0 ? null : _statuses[index - 1]);
                },
                tabs: [
                  const Tab(text: 'All'),
                  ..._statuses.map((s) => Tab(
                      text: s
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map((w) => w[0] + w.substring(1).toLowerCase())
                          .join(' '))),
                ],
                labelColor: Colors.blue.shade700,
                indicatorColor: Colors.blue.shade700,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Found $_total orders',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _isBulkMode = !_isBulkMode;
                      if (!_isBulkMode) _selectedOrderIds.clear();
                    }),
                    icon: Icon(
                        _isBulkMode
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 18),
                    label:
                        Text(_isBulkMode ? 'Disable Select' : 'Enable Select'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading && _orders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                      ? const Center(child: Text('No orders found'))
                      : RefreshIndicator(
                          onRefresh: () => _loadOrders(
                              page: _currentPage, status: _selectedStatus),
                          child: ListView.builder(
                            itemCount: _orders.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              bool isSelected =
                                  _selectedOrderIds.contains(order.id);

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade200,
                                      width: isSelected ? 2 : 1),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: _isBulkMode
                                      ? Checkbox(
                                          value: isSelected,
                                          onChanged: (v) {
                                            setState(() {
                                              if (v == true)
                                                _selectedOrderIds.add(order.id);
                                              else
                                                _selectedOrderIds
                                                    .remove(order.id);
                                            });
                                          },
                                        )
                                      : CircleAvatar(
                                          backgroundColor:
                                              _getStatusColor(order.status)
                                                  .withValues(alpha: 0.1),
                                          child: Icon(
                                              order.isOnHold
                                                  ? Icons.pause_circle_outline
                                                  : Icons.shopping_bag_outlined,
                                              color:
                                                  _getStatusColor(order.status),
                                              size: 20),
                                        ),
                                  title: Row(
                                    children: [
                                      Text(
                                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      if (order.isOnHold) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: const Text('HOLD',
                                              style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber)),
                                        ),
                                      ],
                                      if (order.isHighRisk) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.warning,
                                            color: Colors.red, size: 14),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                      '${order.statusDisplay} | \$${order.totalAmount.toStringAsFixed(2)}'),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      if (order.tags.isNotEmpty)
                                        ...order.tags.take(1).map((t) =>
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(4)),
                                              child: Text(t,
                                                  style: const TextStyle(
                                                      fontSize: 8)),
                                            )),
                                      const Icon(Icons.chevron_right_rounded),
                                    ],
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                AdminOrderDetailScreen(
                                                    orderId: order.id)));
                                    if (result == true)
                                      _loadOrders(
                                          page: _currentPage,
                                          status: _selectedStatus);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _currentPage > 1
                ? () =>
                    _loadOrders(page: _currentPage - 1, status: _selectedStatus)
                : null,
          ),
          Text('Page $_currentPage of $_totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _currentPage < _totalPages
                ? () =>
                    _loadOrders(page: _currentPage + 1, status: _selectedStatus)
                : null,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
