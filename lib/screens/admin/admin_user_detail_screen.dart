import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/order.dart';
import '../../services/admin_service.dart';
import '../../services/security_service.dart';
import 'admin_order_detail_screen.dart';

import 'send_notification_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final User user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final AdminService _adminService = AdminService();
  late User _localUser;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userStats;

  @override
  void initState() {
    super.initState();
    _localUser = widget.user;
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _adminService.getUserStats(_localUser.id);
      if (mounted) {
        setState(() {
          _userStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load user stats: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: 'Impersonate User',
            onPressed: _impersonateUser,
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            tooltip: 'Send Message',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      SendNotificationScreen(targetUser: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserStats,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: _localUser.isAdmin
                                            ? Colors.purple.shade50
                                            : Colors.blue.shade50,
                                        child: Text(
                                          _localUser.name[0].toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: _localUser.isAdmin
                                                  ? Colors.purple
                                                  : Colors.blue),
                                        ),
                                      ),
                                      if (_localUser.isVIP)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                                color: Colors.amber,
                                                shape: BoxShape.circle),
                                            child: const Icon(Icons.star,
                                                color: Colors.white, size: 16),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _localUser.name,
                                              style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildRFMBadge(
                                                _localUser.rfmSummary),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(_localUser.email,
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 16)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            ActionChip(
                                              label: Text(_localUser.isVIP
                                                  ? 'VIP'
                                                  : 'Standard'),
                                              avatar: Icon(
                                                  _localUser.isVIP
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  size: 14),
                                              onPressed: _toggleVIP,
                                            ),
                                            Chip(
                                              label: Text(_localUser.role),
                                              backgroundColor:
                                                  Colors.grey.shade100,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildActionStat(
                                      'Points',
                                      '${_localUser.loyaltyPoints}',
                                      Icons.stars,
                                      Colors.amber,
                                      () => _showBalanceDialog('points')),
                                  _buildActionStat(
                                      'Credit',
                                      '\$${_localUser.storeCredit.toStringAsFixed(2)}',
                                      Icons.account_balance_wallet,
                                      Colors.green,
                                      () => _showBalanceDialog('credit')),
                                  _buildActionStat(
                                      'LTV',
                                      '\$${_localUser.ltv.toStringAsFixed(0)}',
                                      Icons.payments,
                                      Colors.blue,
                                      null),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Engagement Scores
                      const Text(
                        'Engagement Scores (RFM)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildScoreIndicator(
                              'Recency', _localUser.recencyScore),
                          _buildScoreIndicator(
                              'Frequency', _localUser.frequencyScore),
                          _buildScoreIndicator(
                              'Monetary', _localUser.monetaryScore),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats Grid
                      if (_userStats != null) ...[
                        const Text(
                          'Statistics',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard(
                              'Total Orders',
                              '${_userStats!['totalOrders']}',
                              Icons.shopping_bag,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Cancelled',
                              '${_userStats!['cancelledOrders']}',
                              Icons.cancel,
                              Colors.red,
                            ),
                            _buildStatCard(
                              'Total Spent',
                              '\$${(_userStats!['totalSpent'] as double).toStringAsFixed(2)}',
                              Icons.attach_money,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Last Order',
                              _localUser.lastPurchaseAt != null
                                  ? dateFormat
                                      .format(_localUser.lastPurchaseAt!)
                                  : 'Never',
                              Icons.event,
                              Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Order History
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Orders',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                                onPressed: () {},
                                child: const Text('View All')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildOrderList(_userStats!['orders'] as List<Order>),
                        const SizedBox(height: 24),

                        // RBAC & Permissions
                        if (_localUser.isAdmin || _localUser.isEmployee) ...[
                          const Text(
                            'Fine-grained Permissions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade100)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: UserPermissions.all.map((p) {
                                  return CheckboxListTile(
                                    title: Text(p.replaceAll('_', ' '),
                                        style: const TextStyle(fontSize: 14)),
                                    value: _localUser.permissions.contains(p),
                                    onChanged: (v) =>
                                        _updatePermission(p, v ?? false),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }

  Future<void> _updatePermission(String permission, bool value) async {
    final permissions = List<String>.from(_localUser.permissions);
    if (value) {
      permissions.add(permission);
    } else {
      permissions.remove(permission);
    }

    final securityService = SecurityService();
    await securityService.updateUserPermissions(_localUser.id, permissions);

    if (mounted) {
      setState(() {
        _localUser = _localUser.copyWith(permissions: permissions);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions updated')),
      );
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRFMBadge(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'CHAMPION':
        color = Colors.green;
        break;
      case 'LOYAL':
        color = Colors.blue;
        break;
      case 'AT RISK':
        color = Colors.orange;
        break;
      case 'HIBERNATING':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionStat(String label, String value, IconData icon,
      Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            if (onTap != null)
              const Icon(Icons.edit, size: 10, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(String label, int score) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                5,
                (index) => Container(
                      width: 20,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color:
                            index < score ? Colors.blue : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
          ),
          const SizedBox(height: 4),
          Text('$score/5',
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _toggleVIP() async {
    final newState = !_localUser.isVIP;
    try {
      await _adminService.toggleVIPStatus(_localUser.id, newState);
      if (mounted) {
        setState(() {
          _localUser = _localUser.copyWith(isVIP: newState);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('VIP Status set to $newState')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update VIP status: $e')),
        );
      }
    }
  }

  Future<void> _impersonateUser() async {
    final token = await _adminService.getImpersonationToken(_localUser.id);
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Impersonate User'),
          content: Text(
              'You are now impersonating ${_localUser.name}.\nToken: ${token['impersonateUserId']}\n\n(In a real app, this would redirect you to the user view with specific permissions.)'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
    }
  }

  Future<void> _showBalanceDialog(String type) async {
    final controller = TextEditingController();
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Adjust ${type == 'points' ? 'Loyalty Points' : 'Store Credit'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(
                  signed: true, decimal: type == 'credit'),
              decoration: InputDecoration(
                labelText: 'Delta (e.g. +50 or -20)',
                hintText: type == 'points' ? 'Integer' : 'Decimal',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final delta = double.tryParse(controller.text) ?? 0.0;
              if (type == 'points') {
                await _adminService.adjustUserBalance(_localUser.id,
                    pointsDelta: delta.toInt(), reason: reasonController.text);
              } else {
                await _adminService.adjustUserBalance(_localUser.id,
                    creditDelta: delta, reason: reasonController.text);
              }
              Navigator.pop(context);
              _loadUserStats(); // Reload to reflect changes
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No orders found for this user.')),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade100)),
          child: ListTile(
            title: Text('Order #${order.id.substring(0, 8).toUpperCase()}'),
            subtitle: Text(
              DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  order.status,
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AdminOrderDetailScreen(orderId: order.id),
                ),
              );
            },
          ),
        );
      },
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
