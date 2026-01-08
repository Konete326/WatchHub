import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../models/order.dart';
import '../../utils/theme.dart';
import '../../providers/settings_provider.dart';
import 'admin_order_detail_screen.dart';
import '../../widgets/admin/admin_drawer.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final AdminService _adminService = AdminService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
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
      _errorMessage = null;
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
        String message = e.toString();
        if (message.contains('FAILED_PRECONDITION') ||
            message.contains('index')) {
          message =
              'Database index required. Please contact developer or check Firebase console logs to create the required composite index.';
        }
        setState(() {
          _errorMessage = 'Failed to load orders: $message';
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _statuses.length + 1, // +1 for "All"
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Orders'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppTheme.secondaryColor,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppTheme.secondaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            onTap: (index) {
              if (index == 0) {
                _loadOrders(page: 1, status: null);
              } else {
                _loadOrders(
                    page: 1, status: _statuses[index - 1].toUpperCase());
              }
            },
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'Shipped'),
              Tab(text: 'Delivered'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        drawer: const AdminDrawer(),
        body: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              children: [
                // Results count
                if (!_isLoading && _orders.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Found $_total order${_total != 1 ? 's' : ''}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),

                // Content
                Expanded(
                  child: _isLoading && _orders.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 64, color: AppTheme.errorColor),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => _loadOrders(
                                        page: _currentPage,
                                        status: _selectedStatus),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _orders.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_bag_outlined,
                                          size: 64, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No orders found',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () => _loadOrders(
                                      page: _currentPage,
                                      status: _selectedStatus),
                                  child: ListView.builder(
                                    itemCount: _orders.length,
                                    padding: const EdgeInsets.all(16),
                                    itemBuilder: (context, index) {
                                      final order = _orders[index];
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                              color: Colors.grey.shade200),
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.all(16),
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Order #${order.id.substring(0, 8).toUpperCase()}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                settings.formatPrice(
                                                    order.totalAmount),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.primaryColor),
                                              ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 8),
                                              if (order.user != null)
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.person_outline,
                                                        size: 14,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text('${order.user!.name}',
                                                        style: const TextStyle(
                                                            fontSize: 13)),
                                                  ],
                                                ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .calendar_today_outlined,
                                                      size: 14,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                      DateFormat(
                                                              'MMM dd, yyyy HH:mm')
                                                          .format(
                                                              order.createdAt),
                                                      style: const TextStyle(
                                                          fontSize: 13)),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                          order.status)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  order.statusDisplay,
                                                  style: TextStyle(
                                                    color: _getStatusColor(
                                                        order.status),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing:
                                              const Icon(Icons.chevron_right),
                                          onTap: () async {
                                            final result =
                                                await Navigator.of(context)
                                                    .push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AdminOrderDetailScreen(
                                                        orderId: order.id),
                                              ),
                                            );
                                            if (result == true) {
                                              _loadOrders(
                                                  page: _currentPage,
                                                  status: _selectedStatus);
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                ),

                // Pagination
                if (_totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 1
                              ? () => _loadOrders(
                                  page: _currentPage - 1,
                                  status: _selectedStatus)
                              : null,
                        ),
                        Text('Page $_currentPage of $_totalPages',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < _totalPages
                              ? () => _loadOrders(
                                  page: _currentPage + 1,
                                  status: _selectedStatus)
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
