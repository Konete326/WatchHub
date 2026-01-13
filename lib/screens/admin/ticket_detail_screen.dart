import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/support_ticket.dart';
import '../../models/canned_response.dart';
import '../../providers/support_provider.dart';
import '../../utils/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SupportTicket? _ticket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicket();
    context.read<SupportProvider>().fetchCannedResponses();
  }

  Future<void> _loadTicket() async {
    setState(() => _isLoading = true);
    try {
      final ticket = await context
          .read<SupportProvider>()
          .getTicketDetail(widget.ticketId);
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ticket: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendReply() async {
    if (_messageController.text.trim().isEmpty) return;

    final success = await context.read<SupportProvider>().replyToTicket(
          ticketId: widget.ticketId,
          message: _messageController.text.trim(),
          isAdmin: true,
          senderName: 'Admin Support',
        );

    if (success) {
      _messageController.clear();
      _loadTicket();
    }
  }

  void _useCannedResponse(CannedResponse response) {
    _messageController.text = response.content;
    Navigator.pop(context);
  }

  void _showCannedResponses() {
    final provider = context.read<SupportProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Canned Responses',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.cannedResponses.length,
                itemBuilder: (context, index) {
                  final resp = provider.cannedResponses[index];
                  return ListTile(
                    title: Text(resp.title),
                    subtitle: Text(resp.content,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => _useCannedResponse(resp),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_ticket == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Ticket not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket #${_ticket!.id.substring(0, 8)}',
                style: const TextStyle(fontSize: 16)),
            Text(_ticket!.subject,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => _showResolveDialog(),
            tooltip: 'Resolve Ticket',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'merge', child: Text('Merge Ticket')),
              const PopupMenuItem(value: 'assign', child: Text('Assign Agent')),
            ],
            onSelected: (value) {
              if (value == 'merge') _showMergeDialog();
              if (value == 'assign') _showAssignDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTicketInfoBar(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: (_ticket!.messages?.length ?? 0) + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildOriginalMessage();
                }
                final msg = _ticket!.messages![index - 1];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          _buildReplyBar(),
        ],
      ),
    );
  }

  Widget _buildTicketInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          _buildInfoBadge(
              _ticket!.priority, _getPriorityColor(_ticket!.priority)),
          const SizedBox(width: 8),
          _buildInfoBadge(
              _ticket!.statusDisplay, _getStatusColor(_ticket!.status)),
          const Spacer(),
          if (_ticket!.isExpired)
            const Text(
              'SLA BREACHED',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
            )
          else
            Text(
              'SLA: ${DateFormat('HH:mm').format(_ticket!.slaDeadline)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOriginalMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: const Icon(Icons.person, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_ticket!.user?.name ?? 'Customer',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('MMM dd, HH:mm').format(_ticket!.createdAt),
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(_ticket!.message, style: const TextStyle(height: 1.5)),
          if (_ticket!.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAttachments(_ticket!.attachments),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(TicketMessage msg) {
    final isAdmin = msg.isAdmin;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isAdmin) ...[
            CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 20, color: Colors.white)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAdmin ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isAdmin
                      ? const Radius.circular(12)
                      : const Radius.circular(0),
                  bottomRight: isAdmin
                      ? const Radius.circular(0)
                      : const Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAdmin && msg.senderName != null)
                    Text(msg.senderName!,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  Text(
                    msg.message,
                    style: TextStyle(
                        color: isAdmin ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(msg.createdAt),
                    style: TextStyle(
                        color: isAdmin ? Colors.white60 : Colors.black38,
                        fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.support_agent,
                    size: 20, color: Colors.white)),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachments(List<String> urls) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: urls
          .map((url) => GestureDetector(
                onTap: () => _openImage(url),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                        image: NetworkImage(url), fit: BoxFit.cover),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.orange),
            onPressed: _showCannedResponses,
            tooltip: 'Canned Responses',
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Type your reply...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendReply,
            ),
          ),
        ],
      ),
    );
  }

  void _openImage(String url) {
    // Navigate to image viewer or show dialog
  }

  void _showResolveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Ticket?'),
        content: const Text(
            'This will mark the ticket as resolved and notify the user.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context
                  .read<SupportProvider>()
                  .resolveTicket(widget.ticketId);
              Navigator.pop(context);
              _loadTicket();
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  void _showMergeDialog() {
    // Implementation for merging tickets
  }

  void _showAssignDialog() {
    // Implementation for assigning agents
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.blue;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
      case 'PENDING_USER':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
