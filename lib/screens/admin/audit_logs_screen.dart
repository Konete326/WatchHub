import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/audit_log.dart';
import '../../services/audit_service.dart';
import '../../widgets/admin/admin_drawer.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final AuditService _auditService = AuditService();
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String? _filterAdmin;
  AuditAction? _filterAction;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      List<AuditLog> logs;

      if (_dateRange != null) {
        logs = await _auditService.getAuditLogsByDateRange(
          _dateRange!.start,
          _dateRange!.end,
        );
      } else if (_filterAdmin != null) {
        logs = await _auditService.getAuditLogsByAdmin(_filterAdmin!);
      } else if (_filterAction != null) {
        logs = await _auditService.getAuditLogsByAction(_filterAction!);
      } else {
        logs = await _auditService.getAuditLogs(limit: 100);
      }

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _filterAdmin = null;
        _filterAction = null;
      });
      _loadLogs();
    }
  }

  void _clearFilters() {
    setState(() {
      _filterAdmin = null;
      _filterAction = null;
      _dateRange = null;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Filter by Date',
          ),
          if (_filterAdmin != null ||
              _filterAction != null ||
              _dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Filter chips
          if (_filterAdmin != null ||
              _filterAction != null ||
              _dateRange != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Wrap(
                spacing: 8,
                children: [
                  if (_filterAdmin != null)
                    Chip(
                      label: Text('Admin: $_filterAdmin'),
                      onDeleted: () {
                        setState(() => _filterAdmin = null);
                        _loadLogs();
                      },
                    ),
                  if (_filterAction != null)
                    Chip(
                      label: Text(
                          'Action: ${_filterAction!.toString().split('.').last}'),
                      onDeleted: () {
                        setState(() => _filterAction = null);
                        _loadLogs();
                      },
                    ),
                  if (_dateRange != null)
                    Chip(
                      label: Text(
                        'Date: ${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                      ),
                      onDeleted: () {
                        setState(() => _dateRange = null);
                        _loadLogs();
                      },
                    ),
                ],
              ),
            ),

          // Logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No audit logs found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return _buildLogCard(log);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(AuditLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: _getActionIcon(log.action),
        title: Text(
          log.actionName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              log.actionDescription,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  log.adminName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, y HH:mm').format(log.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Admin ID', log.adminId),
                _buildDetailRow('Admin Email', log.adminEmail),
                if (log.targetId != null)
                  _buildDetailRow('Target ID', log.targetId!),
                if (log.targetType != null)
                  _buildDetailRow('Target Type', log.targetType!),

                // Old values
                if (log.oldValues != null && log.oldValues!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Previous Values:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: log.oldValues!.entries
                          .map((e) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],

                // New values
                if (log.newValues != null && log.newValues!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'New Values:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: log.newValues!.entries
                          .map((e) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],

                // Metadata
                if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Additional Info:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  ...log.metadata!.entries
                      .map((e) => Text(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(fontSize: 13),
                          ))
                      .toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Icon _getActionIcon(AuditAction action) {
    IconData iconData;
    Color color;

    switch (action) {
      case AuditAction.productCreated:
      case AuditAction.productUpdated:
      case AuditAction.productPriceChanged:
      case AuditAction.productStockChanged:
        iconData = Icons.inventory;
        color = Colors.blue;
        break;
      case AuditAction.productDeleted:
        iconData = Icons.delete;
        color = Colors.red;
        break;
      case AuditAction.orderStatusChanged:
      case AuditAction.orderCreated:
        iconData = Icons.shopping_bag;
        color = Colors.orange;
        break;
      case AuditAction.orderCancelled:
        iconData = Icons.cancel;
        color = Colors.red;
        break;
      case AuditAction.userCreated:
      case AuditAction.userUpdated:
      case AuditAction.userRoleChanged:
        iconData = Icons.person;
        color = Colors.purple;
        break;
      case AuditAction.userDeleted:
        iconData = Icons.person_remove;
        color = Colors.red;
        break;
      case AuditAction.notificationSent:
        iconData = Icons.notifications;
        color = Colors.teal;
        break;
      case AuditAction.settingsUpdated:
      case AuditAction.shippingSettingsUpdated:
        iconData = Icons.settings;
        color = Colors.grey;
        break;
      default:
        iconData = Icons.info;
        color = Colors.grey;
    }

    return Icon(iconData, color: color);
  }
}
