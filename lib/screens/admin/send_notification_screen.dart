import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../models/user.dart';
import '../../widgets/admin/admin_drawer.dart';
import '../../utils/theme.dart';

class SendNotificationScreen extends StatefulWidget {
  final User? targetUser; // If null, sending to all users (initially)

  const SendNotificationScreen({super.key, this.targetUser});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  String _targetType = 'broadcast'; // 'broadcast', 'single', 'multi'
  List<User> _selectedUsers = [];
  List<User> _allUsers = []; // Cache for user selection
  bool _isLoadingUsers = false;

  // History
  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.targetUser != null) {
      _targetType = 'single';
      _selectedUsers = [widget.targetUser!];
    }
    _loadHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _adminService.getNotificationHistory();
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadAllUsers() async {
    if (_allUsers.isNotEmpty) return;
    setState(() => _isLoadingUsers = true);
    try {
      final result = await _adminService.getAllUsers(
          page: 1, limit: 1000); // Fetch mostly all for selection
      if (mounted) {
        setState(() {
          _allUsers = (result['users'] as List).cast<User>();
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetType != 'broadcast' && _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();

      if (_targetType == 'broadcast') {
        await _adminService.sendNotification(
          title: title,
          body: body,
          type: 'general',
          expiryDays: 3,
        );
      } else {
        // Send to each selected user, but only add ONE history record for the batch
        for (int i = 0; i < _selectedUsers.length; i++) {
          final user = _selectedUsers[i];
          await _adminService.sendNotification(
            userId: user.id,
            title: title,
            body: body,
            type: 'general',
            expiryDays: 3,
            addToHistory:
                i == 0, // Only add historical record for the first user sent
            customTarget: _selectedUsers.length > 1
                ? 'Batch (${_selectedUsers.length} Users)'
                : 'User: ${user.name}',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _bodyController.clear();
        // Switch to history tab and refresh
        _tabController.animateTo(1);
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHistory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History'),
        content: const Text(
            'Are you sure you want to delete this notification record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteNotificationHistory(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('History record deleted')),
          );
          _loadHistory();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showUserSelectionDialog() async {
    await _loadAllUsers();
    if (!mounted) return;

    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final filteredUsers = _allUsers.where((u) {
            final query = searchQuery.toLowerCase();
            return u.name.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query);
          }).toList();

          return AlertDialog(
            title: const Text('Select Users'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                    ),
                    onChanged: (val) {
                      setStateDialog(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _isLoadingUsers
                        ? const Center(child: CircularProgressIndicator())
                        : filteredUsers.isEmpty
                            ? const Center(child: Text('No users found'))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  final isSelected = _selectedUsers
                                      .any((u) => u.id == user.id);
                                  return CheckboxListTile(
                                    title: Text(user.name),
                                    subtitle: Text(user.email),
                                    value: isSelected,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (bool? value) {
                                      setStateDialog(() {
                                        if (value == true) {
                                          _selectedUsers.add(user);
                                        } else {
                                          _selectedUsers.removeWhere(
                                              (u) => u.id == user.id);
                                        }
                                      });
                                      // Update main state as well
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondaryColor,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Compose'),
            Tab(text: 'History'),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Compose Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Selection
                  const Text('Send To:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      if (widget.targetUser != null)
                        ChoiceChip(
                          label: Text('User: ${widget.targetUser!.name}'),
                          selected: _targetType == 'single',
                          onSelected: (selected) {
                            if (selected)
                              setState(() => _targetType = 'single');
                          },
                        ),
                      ChoiceChip(
                        label: const Text('All Users (Broadcast)'),
                        selected: _targetType == 'broadcast',
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _targetType = 'broadcast');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Select Users'),
                        selected: _targetType == 'multi',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _targetType = 'multi');
                            _showUserSelectionDialog();
                          }
                        },
                      ),
                    ],
                  ),
                  if (_targetType == 'multi') ...[
                    const SizedBox(height: 8),
                    Text('${_selectedUsers.length} users selected'),
                    TextButton(
                      onPressed: _showUserSelectionDialog,
                      child: const Text('Edit Selection'),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Form Fields
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., Flash Sale!',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Enter your announcement...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendNotification,
                      icon: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.send),
                      label:
                          Text(_isLoading ? 'Sending...' : 'Send Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppTheme.primaryColor.withOpacity(0.5),
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

          // History Tab
          RefreshIndicator(
            onRefresh: _loadHistory,
            color: AppTheme.primaryColor,
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No notification history',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16)),
                            Text('(History older than 3 days is auto-deleted)',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];

                          DateTime date = DateTime.now();
                          if (item['createdAt'] != null) {
                            try {
                              if (item['createdAt'] is Timestamp) {
                                date =
                                    (item['createdAt'] as Timestamp).toDate();
                              } else {
                                date = DateTime.parse(
                                    item['createdAt'].toString());
                              }
                            } catch (e) {}
                          }

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: item['target']
                                                .toString()
                                                .contains('Broadcast')
                                            ? Colors.orange.withOpacity(0.1)
                                            : Colors.blue.withOpacity(0.1),
                                        child: Icon(
                                          item['target']
                                                  .toString()
                                                  .contains('Broadcast')
                                              ? Icons.campaign
                                              : Icons.person,
                                          color: item['target']
                                                  .toString()
                                                  .contains('Broadcast')
                                              ? Colors.orange
                                              : Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title'] ?? 'No Title',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              '${DateFormat('MMM dd, hh:mm a').format(date)} • ${item['target']}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _deleteHistory(item['id']),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Text(
                                    item['body'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Icon(Icons.remove_red_eye_outlined,
                                          size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item['seenCount'] ?? 0} Seen',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
