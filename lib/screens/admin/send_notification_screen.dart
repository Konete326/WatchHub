import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../models/user.dart';
import '../../widgets/admin/admin_drawer.dart';

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
      if (_targetType == 'broadcast') {
        await _adminService.sendNotification(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          type: 'general',
          expiryDays: 3, // Auto expire after 3 days
        );
      } else {
        // Send to each selected user
        for (final user in _selectedUsers) {
          await _adminService.sendNotification(
            userId: user.id,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            type: 'general',
            expiryDays: 3,
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
        _loadHistory(); // Refresh history
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

  void _showUserSelectionDialog() async {
    await _loadAllUsers();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Select Users'),
            content: SizedBox(
              width: double.maxFinite,
              child: _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final user = _allUsers[index];
                        final isSelected =
                            _selectedUsers.any((u) => u.id == user.id);
                        return CheckboxListTile(
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setStateDialog(() {
                              if (value == true) {
                                _selectedUsers.add(user);
                              } else {
                                _selectedUsers
                                    .removeWhere((u) => u.id == user.id);
                              }
                            });
                            // Update main state as well
                            this.setState(() {});
                          },
                        );
                      },
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
                        backgroundColor: _targetType == 'broadcast'
                            ? Colors.orange
                            : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // History Tab
          _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
                  ? const Center(child: Text('No notification history'))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];

                        DateTime date = DateTime.now();
                        if (item['createdAt'] != null) {
                          try {
                            if (item['createdAt'] is Timestamp) {
                              date = (item['createdAt'] as Timestamp).toDate();
                            } else {
                              date =
                                  DateTime.parse(item['createdAt'].toString());
                            }
                          } catch (e) {
                            // fallback
                          }
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item['type'] == 'general'
                                ? Colors.blue
                                : Colors.orange,
                            child: const Icon(Icons.notifications,
                                color: Colors.white),
                          ),
                          title: Text(item['title'] ?? 'No Title'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['body'] ?? ''),
                              Text(
                                '${DateFormat('MMM dd, HH:mm').format(date)} • ${item['target'] ?? 'Broadcast'}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
