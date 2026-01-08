import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:watchhub/widgets/admin/admin_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../models/user.dart';
import 'admin_user_detail_screen.dart';
import 'send_notification_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  String? _searchQuery;

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

  Future<void> _loadUsers({int page = 1, String? search}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = page;
    });

    try {
      final result = await _adminService.getAllUsers(
        page: page,
        limit: 20,
        search: search,
        role: _selectedRoleFilter,
      );

      if (mounted) {
        setState(() {
          final usersData = result['users'];
          if (usersData != null && usersData is List) {
            // Service already returns User objects, so cast directly
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
          _errorMessage = 'Failed to load users: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserRole(User user, String newRole) async {
    final currentAdminId =
        Provider.of<AuthProvider>(context, listen: false).user?.id;
    if (currentAdminId == null) return;

    try {
      await _adminService.updateUserRole(user.id, newRole, currentAdminId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role updated to $newRole')),
        );
        _loadUsers(page: _currentPage, search: _searchQuery);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRoleDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Role for ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('USER'),
              leading: Radio<String>(
                value: 'USER',
                groupValue: user.role.toUpperCase(),
                onChanged: (value) {
                  Navigator.of(context).pop();
                  _updateUserRole(user, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('EMPLOYEE'),
              leading: Radio<String>(
                value: 'EMPLOYEE',
                groupValue: user.role.toUpperCase(),
                onChanged: (value) {
                  Navigator.of(context).pop();
                  _updateUserRole(user, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('ADMIN'),
              leading: Radio<String>(
                value: 'ADMIN',
                groupValue: user.role.toUpperCase(),
                onChanged: (value) {
                  Navigator.of(context).pop();
                  _updateUserRole(user, value!);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _selectedRoleFilter = 'ALL';

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
    _loadUsers(page: 1, search: _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Role Management'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedRoleFilter = value);
              _loadUsers(page: 1, search: _searchQuery);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ALL', child: Text('All Roles')),
              const PopupMenuItem(value: 'ADMIN', child: Text('Admins Only')),
              const PopupMenuItem(
                  value: 'EMPLOYEE', child: Text('Employees Only')),
              const PopupMenuItem(value: 'USER', child: Text('Users Only')),
            ],
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _onSearch(_searchController.text);
                  },
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _onSearch,
              onChanged: (value) {
                setState(() {}); // Rebuild to update suffixIcon visibility
                if (value.isEmpty) {
                  _onSearch('');
                }
              },
            ),
          ),

          // Results count
          if (!_isLoading && _users.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Found $_total user${_total != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),

          // Content
          Expanded(
            child: _isLoading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadUsers(
                                  page: _currentPage, search: _searchQuery),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadUsers(
                                page: _currentPage, search: _searchQuery),
                            child: ListView.builder(
                              itemCount: _users.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: user.isAdmin
                                          ? Colors.purple
                                          : (user.isEmployee
                                              ? Colors.green
                                              : Colors.blue),
                                      child: Text(
                                        user.name[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      user.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(user.email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        if (user.phone != null)
                                          Text(user.phone!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                        Text(
                                            'Joined: ${dateFormat.format(user.createdAt)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: user.isAdmin
                                                ? Colors.purple.withOpacity(0.1)
                                                : (user.isEmployee
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : Colors.blue
                                                        .withOpacity(0.1)),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            user.role.toUpperCase(),
                                            style: TextStyle(
                                              color: user.isAdmin
                                                  ? Colors.purple
                                                  : (user.isEmployee
                                                      ? Colors.green
                                                      : Colors.blue),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AdminUserDetailScreen(
                                                        user: user),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.message,
                                              color: Colors.blue, size: 20),
                                          tooltip: 'Send Notification',
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SendNotificationScreen(
                                                        targetUser: user),
                                              ),
                                            );
                                          },
                                        ),
                                        if (user.id !=
                                            Provider.of<AuthProvider>(context,
                                                    listen: false)
                                                .user
                                                ?.id)
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 20),
                                            onPressed: () =>
                                                _showRoleDialog(user),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminUserDetailScreen(user: user),
                                        ),
                                      );
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
                        ? () => _loadUsers(
                            page: _currentPage - 1, search: _searchQuery)
                        : null,
                  ),
                  Text('Page $_currentPage of $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages
                        ? () => _loadUsers(
                            page: _currentPage + 1, search: _searchQuery)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
