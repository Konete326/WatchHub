import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user.dart';
import 'admin_user_detail_screen.dart';
import 'send_notification_screen.dart';
import '../../widgets/admin/admin_layout.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  bool _isBulkMode = false;

  List<User> _users = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  String? _searchQuery;
  String _selectedRoleFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers(
      {int page = 1, String? search, String? segment}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = page;
    });

    try {
      final result = await _adminService.getAllUsers(
        page: page,
        limit: 20,
        search: search,
        role: _selectedRoleFilter == 'ALL' ? null : _selectedRoleFilter,
        segment: segment,
      );

      if (mounted) {
        setState(() {
          final usersData = result['users'];
          if (usersData != null && usersData is List) {
            _users = usersData.cast<User>();
          } else {
            _users = [];
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

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
    _loadUsers(page: 1, search: _searchQuery);
  }

  void _bulkNotify() {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select users to notify')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Bulk notification for ${_selectedUserIds.length} users coming soon!')));
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Manage Users',
      currentRoute: '/admin/users',
      actions: [
        if (_selectedUserIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded),
            onPressed: _bulkNotify,
            tooltip: 'Notify Selected',
          ),
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          onPressed: _showFilterMenu,
        ),
      ],
      child: DefaultTabController(
        length: 6, // All + 5 Segments
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                onTap: (index) {
                  final segments = [
                    null,
                    'CHAMPION',
                    'LOYAL',
                    'AT_RISK',
                    'HIBERNATING',
                    'VIP'
                  ];
                  _loadUsers(
                      page: 1, search: _searchQuery, segment: segments[index]);
                },
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Champions'),
                  Tab(text: 'Loyal'),
                  Tab(text: 'At Risk'),
                  Tab(text: 'Churned'),
                  Tab(text: 'VIP Only'),
                ],
                labelColor: Colors.blue.shade700,
                indicatorColor: Colors.blue.shade700,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by name or email...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
                onSubmitted: _onSearch,
                onChanged: (v) => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Found $_total users',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _isBulkMode = !_isBulkMode;
                      if (!_isBulkMode) _selectedUserIds.clear();
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
              child: _isLoading && _users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(child: Text('No users found'))
                      : RefreshIndicator(
                          onRefresh: () => _loadUsers(
                              page: _currentPage, search: _searchQuery),
                          child: ListView.builder(
                            itemCount: _users.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              bool isSelected =
                                  _selectedUserIds.contains(user.id);

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
                                                _selectedUserIds.add(user.id);
                                              else
                                                _selectedUserIds
                                                    .remove(user.id);
                                            });
                                          },
                                        )
                                      : Stack(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor:
                                                  _getRoleColor(user.role)
                                                      .withValues(alpha: 0.1),
                                              child: Text(
                                                  user.name[0].toUpperCase(),
                                                  style: TextStyle(
                                                      color: _getRoleColor(
                                                          user.role),
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                            if (user.isVIP)
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.amber,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.star,
                                                      size: 10,
                                                      color: Colors.white),
                                                ),
                                              ),
                                          ],
                                        ),
                                  title: Row(
                                    children: [
                                      Text(user.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      if (user.ltv > 1000) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: const Text('HIGH VALUE',
                                              style: TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('${user.role} | ${user.email}'),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _buildRFMBadge(user.rfmSummary),
                                          const SizedBox(width: 8),
                                          Text(
                                              'LTV: \$${user.ltv.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                  fontSize: 10)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.message_outlined,
                                            size: 20),
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    SendNotificationScreen(
                                                        targetUser: user))),
                                      ),
                                      const Icon(Icons.chevron_right_rounded),
                                    ],
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                AdminUserDetailScreen(
                                                    user: user)));
                                    if (result == true)
                                      _loadUsers(
                                          page: _currentPage,
                                          search: _searchQuery);
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(status,
          style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Filter by Role',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...['ALL', 'ADMIN', 'EMPLOYEE', 'USER'].map((role) => ListTile(
                title: Text(role),
                trailing: _selectedRoleFilter == role
                    ? const Icon(Icons.check_rounded, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _selectedRoleFilter = role);
                  Navigator.pop(context);
                  _loadUsers(page: 1, search: _searchQuery);
                },
              )),
          const SizedBox(height: 20),
        ],
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
                ? () => _loadUsers(page: _currentPage - 1, search: _searchQuery)
                : null,
          ),
          Text('Page $_currentPage of $_totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _currentPage < _totalPages
                ? () => _loadUsers(page: _currentPage + 1, search: _searchQuery)
                : null,
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.purple;
      case 'EMPLOYEE':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
