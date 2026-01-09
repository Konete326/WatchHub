import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../models/support_ticket.dart';
import '../../utils/theme.dart';
import 'contact_screen.dart';
import 'package:intl/intl.dart';
import '../../widgets/neumorphic_widgets.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final SupportService _supportService = SupportService();
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final tickets = await _supportService.getUserTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: AppTheme.softUiBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: NeumorphicTopBar(
          title: 'My Tickets',
          onBackTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const _NeumorphicLoadingIndicator()
          : _tickets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _tickets.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: NeumorphicContainer(
                        borderRadius: BorderRadius.circular(25),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Icon in well
                            NeumorphicPill(
                              padding: const EdgeInsets.all(12),
                              borderRadius: BorderRadius.circular(15),
                              child: Icon(
                                _getStatusIcon(ticket.status),
                                color: _getStatusColor(ticket.status),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ticket.subject,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.softUiTextColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        dateFormat.format(ticket.createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.softUiTextColor
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ticket.message,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.softUiTextColor
                                          .withOpacity(0.7),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      NeumorphicPill(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        child: Text(
                                          ticket.statusDisplay,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _getStatusColor(ticket.status),
                                          ),
                                        ),
                                      ),
                                      if (ticket.status == 'OPEN')
                                        Row(
                                          children: [
                                            NeumorphicButton(
                                              onTap: () async {
                                                final updated =
                                                    await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ContactScreen(
                                                            ticket: ticket),
                                                  ),
                                                );
                                                if (updated == true)
                                                  _loadTickets();
                                              },
                                              shape: BoxShape.circle,
                                              padding: const EdgeInsets.all(8),
                                              child: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 16,
                                                  color:
                                                      AppTheme.softUiTextColor),
                                            ),
                                            const SizedBox(width: 12),
                                            NeumorphicButton(
                                              onTap: () =>
                                                  _showDeleteDialog(ticket),
                                              shape: BoxShape.circle,
                                              padding: const EdgeInsets.all(8),
                                              child: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 16,
                                                  color: AppTheme.errorColor),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicContainer(
              isConcave: true,
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(40),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: AppTheme.softUiTextColor.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No support tickets',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.softUiTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'If you have any issues with your orders or account, feel free to contact our support team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.softUiTextColor.withOpacity(0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(SupportTicket ticket) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (context) => NeumorphicDialog(
        title: 'Delete Ticket',
        content:
            'Are you sure you want to delete this support ticket? This action cannot be undone.',
        confirmLabel: 'Delete',
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _supportService.deleteTicket(ticket.id);
        _loadTickets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ticket deleted successfully'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete ticket: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'CLOSED':
        return AppTheme.successColor;
      default:
        return AppTheme.softUiTextColor.withOpacity(0.5);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'OPEN':
        return Icons.mark_as_unread_rounded;
      case 'IN_PROGRESS':
        return Icons.pending_actions_rounded;
      case 'CLOSED':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}

class _NeumorphicLoadingIndicator extends StatefulWidget {
  const _NeumorphicLoadingIndicator();

  @override
  State<_NeumorphicLoadingIndicator> createState() =>
      _NeumorphicLoadingIndicatorState();
}

class _NeumorphicLoadingIndicatorState
    extends State<_NeumorphicLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _animation,
        child: const NeumorphicContainer(
          isConcave: true,
          shape: BoxShape.circle,
          padding: EdgeInsets.all(30),
          child: Icon(
            Icons.receipt_long_rounded,
            color: AppTheme.primaryColor,
            size: 40,
          ),
        ),
      ),
    );
  }
}
