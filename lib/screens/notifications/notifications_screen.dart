import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification.dart';
import '../../utils/theme.dart';
import '../../utils/haptics.dart';

import '../product/product_detail_screen.dart';
import '../orders/order_detail_screen.dart';
import '../../widgets/neumorphic_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      provider.fetchNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<NotificationModel> _filterNotifications(
      List<NotificationModel> all, int index) {
    switch (index) {
      case 0: // Orders
        return all
            .where((n) => n.type == NotificationType.orderUpdate)
            .toList();
      case 1: // Offers
        return all
            .where((n) =>
                n.type == NotificationType.promotion ||
                n.type == NotificationType.discount)
            .toList();
      case 2: // Alerts
        return all.where((n) => n.type == NotificationType.general).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = AppTheme.softUiBackground;
    const kTextColor = AppTheme.softUiTextColor;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Consumer2<NotificationProvider, UserProvider>(
        builder: (context, provider, userProvider, child) {
          return Column(
            children: [
              // Custom Neumorphic Header
              _buildHeader(context, provider, userProvider),

              // Neumorphic TabBar
              _buildTabBar(provider),

              // Notifications List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList(provider, 0),
                    _buildNotificationList(provider, 1),
                    _buildNotificationList(provider, 2),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NotificationProvider provider,
      UserProvider userProvider) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Column(
          children: [
            Row(
              children: [
                NeumorphicButtonSmall(
                  onTap: () => Navigator.pop(context),
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Notifications',
                    style: GoogleFonts.playfairDisplay(
                      color: AppTheme.softUiTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                if (provider.notifications.isNotEmpty)
                  NeumorphicButtonSmall(
                    onTap: () async {
                      final confirm = await _showConfirmDialog('Clear All',
                          'Are you sure you want to clear all notifications?');
                      if (confirm == true) {
                        provider.clearAllNotifications();
                        HapticHelper.success();
                      }
                    },
                    icon: Icons.delete_sweep_rounded,
                    tooltip: 'Clear All',
                  ),
                const SizedBox(width: 12),
                NeumorphicButtonSmall(
                  onTap: () => provider.markAllAsRead(),
                  icon: Icons.done_all_rounded,
                  tooltip: 'Mark all as read',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(NotificationProvider provider) {
    int orderUnread = _filterNotifications(provider.notifications, 0)
        .where((n) => !n.isRead)
        .length;
    int offerUnread = _filterNotifications(provider.notifications, 1)
        .where((n) => !n.isRead)
        .length;
    int alertUnread = _filterNotifications(provider.notifications, 2)
        .where((n) => !n.isRead)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.softUiBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppTheme.softUiShadowDark,
                offset: const Offset(4, 4),
                blurRadius: 10),
            BoxShadow(
                color: AppTheme.softUiShadowLight,
                offset: const Offset(-4, -4),
                blurRadius: 10),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.softUiTextColor.withOpacity(0.4),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            _buildTab('Orders', orderUnread),
            _buildTab('Offers', offerUnread),
            _buildTab('Alerts', alertUnread),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppTheme.primaryColor, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationList(NotificationProvider provider, int tabIndex) {
    final filtered = _filterNotifications(provider.notifications, tabIndex);

    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: tabIndex == 0
            ? Icons.local_shipping_outlined
            : (tabIndex == 1
                ? Icons.sell_outlined
                : Icons.notifications_none_outlined),
        title:
            'No ${tabIndex == 0 ? 'Orders' : (tabIndex == 1 ? 'Offers' : 'Alerts')}',
        message: 'You have no notifications in this category yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchNotifications(),
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.softUiBackground,
      child: ListView.builder(
        itemCount: filtered.length,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemBuilder: (context, index) {
          final notification = filtered[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _NotificationItem(notification: notification),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String title,
      required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: AppTheme.softUiBackground,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.softUiShadowDark,
                    offset: Offset(6, 6),
                    blurRadius: 12),
                BoxShadow(
                    color: AppTheme.softUiShadowLight,
                    offset: Offset(-6, -6),
                    blurRadius: 12),
              ],
            ),
            child: Icon(icon,
                size: 48, color: AppTheme.softUiTextColor.withOpacity(0.1)),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softUiTextColor)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.softUiTextColor.withOpacity(0.5))),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.softUiBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(title,
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(title,
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final bool isRead = notification.isRead;

    return GestureDetector(
      onTap: () {
        if (!isRead) provider.markAsRead(notification.id);
        _handleNotificationTap(context, notification);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.softUiBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isRead
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 2,
                      spreadRadius: 1),
                ]
              : [
                  const BoxShadow(
                      color: AppTheme.softUiShadowDark,
                      offset: Offset(4, 4),
                      blurRadius: 10),
                  const BoxShadow(
                      color: AppTheme.softUiShadowLight,
                      offset: Offset(-4, -4),
                      blurRadius: 10),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.softUiBackground,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: AppTheme.softUiShadowDark,
                      offset: Offset(2, 2),
                      blurRadius: 4),
                  BoxShadow(
                      color: AppTheme.softUiShadowLight,
                      offset: Offset(-2, -2),
                      blurRadius: 4),
                ],
              ),
              child: Icon(_getIcon(notification.type),
                  color: _getIconColor(notification.type), size: 20),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.softUiTextColor,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.softUiTextColor.withOpacity(0.6),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM dd • hh:mm a')
                        .format(notification.timestamp),
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.softUiTextColor.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.local_shipping_outlined;
      case NotificationType.promotion:
        return Icons.campaign_outlined;
      case NotificationType.discount:
        return Icons.sell_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Colors.blue;
      case NotificationType.promotion:
        return Colors.purple;
      case NotificationType.discount:
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          _NotificationActionSheet(notification: notification),
    );
  }
}

class _NotificationActionSheet extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationActionSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppTheme.softUiBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: AppTheme.softUiBackground,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.softUiShadowDark,
                          offset: Offset(2, 2),
                          blurRadius: 4),
                      BoxShadow(
                          color: AppTheme.softUiShadowLight,
                          offset: Offset(-2, -2),
                          blurRadius: 4),
                    ]),
                child: Icon(_getIcon(notification.type),
                    color: _getIconColor(notification.type), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.softUiTextColor)),
                    Text(
                        DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(notification.timestamp),
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.softUiTextColor.withOpacity(0.5))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.softUiBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: AppTheme.softUiShadowDark,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    spreadRadius: 1),
                BoxShadow(
                    color: AppTheme.softUiShadowLight,
                    offset: Offset(-2, -2),
                    blurRadius: 4,
                    spreadRadius: 1),
              ],
            ),
            child: Text(notification.body,
                style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppTheme.softUiTextColor)),
          ),
          const SizedBox(height: 32),
          // Actions logic
          if (notification.type == NotificationType.orderUpdate &&
              notification.data?['orderId'] != null)
            _buildActionButton(context, 'Track Order', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(
                          orderId: notification.data!['orderId'])));
            }),
          if (notification.data?['watchId'] != null)
            _buildActionButton(context, 'View Product', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                          watchId: notification.data!['watchId'])));
            }),
          _buildActionButton(context, 'Dismiss', () => Navigator.pop(context),
              isSecondary: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, VoidCallback onTap,
      {bool isSecondary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.softUiBackground,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                  color: AppTheme.softUiShadowDark,
                  offset: Offset(4, 4),
                  blurRadius: 8),
              BoxShadow(
                  color: AppTheme.softUiShadowLight,
                  offset: Offset(-4, -4),
                  blurRadius: 8),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSecondary
                    ? AppTheme.softUiTextColor.withOpacity(0.5)
                    : AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.local_shipping_outlined;
      case NotificationType.promotion:
        return Icons.campaign_outlined;
      case NotificationType.discount:
        return Icons.sell_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Colors.blue;
      case NotificationType.promotion:
        return Colors.purple;
      case NotificationType.discount:
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }
}
