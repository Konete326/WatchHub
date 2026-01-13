import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/support_ticket.dart';
import '../../providers/support_provider.dart';
import 'ticket_detail_screen.dart';

class ManageTicketsScreen extends StatefulWidget {
  const ManageTicketsScreen({super.key});

  @override
  State<ManageTicketsScreen> createState() => _ManageTicketsScreenState();
}

class _ManageTicketsScreenState extends State<ManageTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Open', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().fetchUserTickets();
      context.read<SupportProvider>().fetchStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Support Desk'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Consumer<SupportProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.tickets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildStatsBar(provider.stats),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map((tab) => _buildTicketList(provider.tickets, tab))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBar(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
              'Open', stats['open']?.toString() ?? '0', Colors.orange),
          const SizedBox(width: 8),
          _buildStatCard(
              'SLA Breach', stats['expired']?.toString() ?? '0', Colors.red),
          const SizedBox(width: 8),
          _buildStatCard(
              'Resolved', stats['resolved']?.toString() ?? '0', Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(List<SupportTicket> tickets, String tab) {
    List<SupportTicket> filtered = tickets;
    if (tab == 'Open')
      filtered = tickets.where((t) => t.status == 'OPEN').toList();
    else if (tab == 'In Progress')
      filtered = tickets
          .where((t) => t.status == 'IN_PROGRESS' || t.status == 'PENDING_USER')
          .toList();
    else if (tab == 'Resolved')
      filtered = tickets
          .where((t) => t.status == 'RESOLVED' || t.status == 'CLOSED')
          .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('No $tab tickets', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final ticket = filtered[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final bool isSLAExceeded = ticket.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TicketDetailScreen(ticketId: ticket.id)))
            .then((_) => context.read<SupportProvider>().fetchUserTickets()),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getPriorityIndicator(ticket.priority),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _getStatusBadge(ticket.status, ticket.statusDisplay),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.message,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(ticket.user?.name ?? 'Customer',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  Icon(
                    isSLAExceeded ? Icons.timer_off : Icons.timer_outlined,
                    size: 14,
                    color: isSLAExceeded ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSLAExceeded
                        ? 'SLA Breached'
                        : _getTimeRemaining(ticket.slaDeadline),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSLAExceeded ? Colors.red : Colors.grey,
                      fontWeight:
                          isSLAExceeded ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPriorityIndicator(String priority) {
    Color color = Colors.grey;
    if (priority == 'URGENT')
      color = Colors.red;
    else if (priority == 'HIGH')
      color = Colors.orange;
    else if (priority == 'MEDIUM')
      color = Colors.blue;
    else if (priority == 'LOW') color = Colors.green;

    return Container(
      width: 4,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _getStatusBadge(String status, String display) {
    Color color = Colors.grey;
    if (status == 'OPEN')
      color = Colors.orange;
    else if (status == 'IN_PROGRESS')
      color = Colors.blue;
    else if (status == 'RESOLVED')
      color = Colors.green;
    else if (status == 'PENDING_USER') color = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        display,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getTimeRemaining(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Breached';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }
}
