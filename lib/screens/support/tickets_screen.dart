import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/support_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/neumorphic_widgets.dart';
import 'contact_screen.dart';
import 'user_ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().fetchUserTickets();
    });
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
      body: Consumer<SupportProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.tickets.isEmpty) {
            return const _NeumorphicLoadingIndicator();
          }

          if (provider.tickets.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchUserTickets(),
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: provider.tickets.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final ticket = provider.tickets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: NeumorphicButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserTicketDetailScreen(ticketId: ticket.id),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(25),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPriorityPill(ticket.priority),
                        const SizedBox(width: 16),
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
                                  Text(
                                    dateFormat.format(ticket.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
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
                                  color:
                                      AppTheme.softUiTextColor.withOpacity(0.7),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  NeumorphicPill(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    child: Text(
                                      ticket.statusDisplay,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(ticket.status),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (ticket.status == 'OPEN' ||
                                      ticket.status == 'IN_PROGRESS')
                                    Text(
                                      'Exp. Reply: ${_getTimeRemaining(ticket.slaDeadline)}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.softUiTextColor
                                              .withOpacity(0.4)),
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
        },
      ),
      floatingActionButton: NeumorphicButton(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ContactScreen())),
        shape: BoxShape.circle,
        padding: const EdgeInsets.all(16),
        child: const Icon(Icons.add_rounded, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildPriorityPill(String priority) {
    Color color = Colors.blue;
    if (priority == 'URGENT')
      color = Colors.red;
    else if (priority == 'HIGH') color = Colors.orange;

    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _getTimeRemaining(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Soon';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
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
