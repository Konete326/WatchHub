import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../models/support_ticket.dart';
import '../../utils/theme.dart';

class ManageTicketsScreen extends StatefulWidget {
  const ManageTicketsScreen({super.key});

  @override
  State<ManageTicketsScreen> createState() => _ManageTicketsScreenState();
}

class _ManageTicketsScreenState extends State<ManageTicketsScreen> {
  final AdminService _adminService = AdminService();
  
  List<SupportTicket> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  String? _selectedStatus;

  final List<String> _statuses = [
    'OPEN',
    'IN_PROGRESS',
    'RESOLVED',
    'CLOSED',
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets({int page = 1, String? status}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = page;
      _selectedStatus = status;
    });

    try {
      final result = await _adminService.getAllTickets(
        page: page,
        limit: 20,
        status: status,
      );

      if (mounted) {
        setState(() {
          final ticketsData = result['tickets'];
          _tickets = ticketsData != null && ticketsData is List
              ? (ticketsData as List)
                  .map((json) => SupportTicket.fromJson(json as Map<String, dynamic>))
                  .toList()
              : [];
          
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
          _errorMessage = 'Failed to load tickets: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateTicketStatus(String id, String status) async {
    try {
      await _adminService.updateTicketStatus(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket status updated to $status')),
        );
        _loadTickets(page: _currentPage, status: _selectedStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusDialog(SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Ticket Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statuses.map((status) {
            return ListTile(
              title: Text(status),
              leading: Radio<String>(
                value: status,
                groupValue: ticket.status,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  _updateTicketStatus(ticket.id, value!);
                },
              ),
            );
          }).toList(),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('Filter by Status: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    hint: const Text('All Statuses'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      ..._statuses.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      _loadTickets(page: 1, status: value);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Results count
          if (!_isLoading && _tickets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Found $_total ticket${_total != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),

          // Content
          Expanded(
            child: _isLoading && _tickets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadTickets(page: _currentPage, status: _selectedStatus),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _tickets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.support_agent_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No tickets found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadTickets(page: _currentPage, status: _selectedStatus),
                            child: ListView.builder(
                              itemCount: _tickets.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                final ticket = _tickets[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(
                                      ticket.subject,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ticket.message.length > 100
                                              ? '${ticket.message.substring(0, 100)}...'
                                              : ticket.message,
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Date: ${dateFormat.format(ticket.createdAt)}'),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(ticket.status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            ticket.statusDisplay,
                                            style: TextStyle(
                                              color: _getStatusColor(ticket.status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showStatusDialog(ticket),
                                    ),
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
                        ? () => _loadTickets(page: _currentPage - 1, status: _selectedStatus)
                        : null,
                  ),
                  Text('Page $_currentPage of $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages
                        ? () => _loadTickets(page: _currentPage + 1, status: _selectedStatus)
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

