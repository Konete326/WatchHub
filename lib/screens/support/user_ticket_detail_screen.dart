import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/support_ticket.dart';
import '../../providers/support_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/neumorphic_widgets.dart';

class UserTicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const UserTicketDetailScreen({super.key, required this.ticketId});

  @override
  State<UserTicketDetailScreen> createState() => _UserTicketDetailScreenState();
}

class _UserTicketDetailScreenState extends State<UserTicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SupportTicket? _ticket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicket();
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
        );

    if (success) {
      _messageController.clear();
      _loadTicket();
    }
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
      backgroundColor: AppTheme.softUiBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: NeumorphicTopBar(
          title: 'Ticket Details',
          onBackTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: (_ticket!.messages?.length ?? 0) + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildInitialTicketInfo();
                final msg = _ticket!.messages![index - 1];
                return _buildMessageItem(msg);
              },
            ),
          ),
          if (_ticket!.status != 'CLOSED' && _ticket!.status != 'RESOLVED')
            _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildInitialTicketInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeumorphicContainer(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NeumorphicPill(
                    child: Text(
                      _ticket!.statusDisplay,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(_ticket!.status),
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_ticket!.createdAt),
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.softUiTextColor.withOpacity(0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _ticket!.subject,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softUiTextColor),
              ),
              const SizedBox(height: 12),
              Text(
                _ticket!.message,
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.softUiTextColor.withOpacity(0.7),
                    height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Messages',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.softUiTextColor),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMessageItem(TicketMessage msg) {
    final isAdmin = msg.isAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment:
            isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment:
                isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isAdmin)
                const Icon(Icons.support_agent,
                    size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text(
                isAdmin ? 'Support Team' : 'You',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softUiTextColor.withOpacity(0.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          NeumorphicContainer(
            isConcave: !isAdmin,
            borderRadius: BorderRadius.circular(15),
            padding: const EdgeInsets.all(16),
            child: Text(
              msg.message,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.softUiTextColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(msg.createdAt),
            style: TextStyle(
                fontSize: 10, color: AppTheme.softUiTextColor.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Row(
        children: [
          Expanded(
            child: NeumorphicTextField(
              controller: _messageController,
              hintText: 'Type your reply...',
            ),
          ),
          const SizedBox(width: 16),
          NeumorphicButton(
            onTap: _sendReply,
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(16),
            child: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'RESOLVED':
        return AppTheme.successColor;
      case 'CLOSED':
        return Colors.grey;
      case 'PENDING_USER':
        return Colors.purple;
      default:
        return AppTheme.softUiTextColor.withOpacity(0.5);
    }
  }
}
