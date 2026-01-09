import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification.dart';
import '../../utils/theme.dart';

import '../product/product_detail_screen.dart';
import '../orders/order_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      provider.fetchNotifications();
      provider.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = Color(0xFFE0E5EC);
    const kTextColor = Color(0xFF4A5568);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: kBackgroundColor,
            child: Row(
              children: [
                _NeumorphicButton(
                  onTap: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(10),
                  shape: BoxShape.circle,
                  child: const Icon(Icons.arrow_back, color: kTextColor),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.notifications.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _NeumorphicButton(
                      onTap: () => provider.markAllAsRead(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      borderRadius: BorderRadius.circular(10),
                      child: const Text(
                        'Mark all',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final user = userProvider.user;
                    if (user == null) return const SizedBox.shrink();
                    return _NeumorphicToggle(
                      value: user.notificationsEnabled,
                      onChanged: userProvider.isLoading
                          ? (v) {}
                          : (value) async {
                              final success =
                                  await userProvider.toggleNotifications(value);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(value
                                        ? 'Notifications Enabled'
                                        : 'Notifications Disabled'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: kTextColor,
                                  ),
                                );
                              }
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer2<NotificationProvider, UserProvider>(
        builder: (context, provider, userProvider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.user?.notificationsEnabled == false &&
              provider.notifications.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.notifications_off_outlined,
              title: 'Notifications Disabled',
              message:
                  'Turn on notifications to stay updated with your orders and exciting offers.',
              actionLabel: 'Enable Notifications',
              onActionPressed: () => userProvider.toggleNotifications(true),
            );
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.notifications_none_outlined,
              title: 'No Notifications',
              message:
                  'Stay tuned! We\'ll notify you when something exciting happens.',
              actionLabel: 'Go Shopping',
              onActionPressed: () => Navigator.pop(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            color: AppTheme.primaryColor,
            backgroundColor: kBackgroundColor,
            child: ListView.builder(
              itemCount: provider.notifications.length,
              padding: const EdgeInsets.all(24),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _NotificationItem(notification: notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onActionPressed,
  }) {
    const kTextColor = Color(0xFF4A5568);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NeumorphicContainer(
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(40),
              isConcave: true,
              child: Icon(
                icon,
                size: 64,
                color: kTextColor.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kTextColor.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _NeumorphicButton(
              onTap: onActionPressed,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              borderRadius: BorderRadius.circular(15),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
    final isRead = notification.isRead;
    const kTextColor = Color(0xFF4A5568);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5E5), // Soft red background
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: _NeumorphicContainer(
          shape: BoxShape.circle,
          padding: const EdgeInsets.all(12),
          isConcave: true,
          color: const Color(0xFFFFE5E5),
          child: const Icon(Icons.delete, color: Colors.redAccent, size: 24),
        ),
      ),
      onDismissed: (direction) => provider.deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () {
          if (!isRead) provider.markAsRead(notification.id);
          _handleNotificationTap(context, notification);
        },
        child: _NeumorphicIndicatorContainer(
          isSelected: !isRead,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NeumorphicContainer(
                shape: BoxShape.circle,
                padding: const EdgeInsets.all(12),
                isConcave: true,
                child: Icon(
                  _getIcon(notification.type),
                  color: _getIconColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 16,
                              color: kTextColor,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: kTextColor.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      DateFormat('MMM dd • hh:mm a')
                          .format(notification.timestamp),
                      style: TextStyle(
                        color: kTextColor.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _NeumorphicButton(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => _NeumorphicAlertDialog(
                      title: 'Delete Notification',
                      content:
                          'Are you sure you want to delete this notification?',
                    ),
                  );
                  if (confirm == true) {
                    provider.deleteNotification(notification.id);
                  }
                },
                padding: const EdgeInsets.all(8),
                shape: BoxShape.circle,
                child: Icon(Icons.close,
                    color: kTextColor.withOpacity(0.5), size: 16),
              ),
            ],
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
        return Icons.notifications_outlined;
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
        return const Color(0xFF6366F1);
    }
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _NotificationDetailSheet(notification: notification),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = Color(0xFFE0E5EC);
    const kTextColor = Color(0xFF4A5568);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: ListView(
          controller: controller,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(1, 1),
                      blurRadius: 1,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-1, -1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                _NeumorphicContainer(
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(16),
                  isConcave: true,
                  child: Icon(
                    _getIcon(notification.type),
                    color: _getIconColor(notification.type),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(notification.timestamp),
                        style: TextStyle(
                          color: kTextColor.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _NeumorphicContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              isConcave: true,
              child: Text(
                notification.body,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: kTextColor,
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (notification.data?['watchId'] != null)
              _NeumorphicButton(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        watchId: notification.data!['watchId'],
                      ),
                    ),
                  );
                },
                padding: const EdgeInsets.symmetric(vertical: 18),
                borderRadius: BorderRadius.circular(15),
                child: const Center(
                  child: Text(
                    'View Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            if (notification.type == NotificationType.orderUpdate &&
                notification.data?['orderId'] != null)
              _NeumorphicButton(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(
                        orderId: notification.data!['orderId'],
                      ),
                    ),
                  );
                },
                padding: const EdgeInsets.symmetric(vertical: 18),
                borderRadius: BorderRadius.circular(15),
                child: const Center(
                  child: Text(
                    'View Order Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            if (notification.type == NotificationType.promotion ||
                notification.type == NotificationType.discount)
              _NeumorphicButton(
                onTap: () {
                  Navigator.pop(context);
                },
                padding: const EdgeInsets.symmetric(vertical: 18),
                borderRadius: BorderRadius.circular(15),
                child: const Center(
                  child: Text(
                    'Shop Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _NeumorphicButton(
              onTap: () => Navigator.pop(context),
              padding: const EdgeInsets.symmetric(vertical: 18),
              borderRadius: BorderRadius.circular(15),
              child: const Center(
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                ),
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
        return Icons.notifications_outlined;
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
        return const Color(0xFF6366F1);
    }
  }
}

// --- Neumorphic Components ---

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final bool isConcave;
  final Color? color;

  const _NeumorphicContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.isConcave = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? const Color(0xFFE0E5EC);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: isConcave
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(4, 4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  offset: const Offset(-4, -4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : [
                const BoxShadow(
                  color: Color(0xFFA3B1C6),
                  offset: Offset(6, 6),
                  blurRadius: 16,
                ),
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  offset: Offset(-6, -6),
                  blurRadius: 16,
                ),
              ],
      ),
      child: child,
    );
  }
}

class _NeumorphicIndicatorContainer extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const _NeumorphicIndicatorContainer({
    required this.child,
    required this.isSelected,
    required this.padding,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: borderRadius,
        boxShadow: isSelected
            ? [
                const BoxShadow(
                  color: Color(0xFFA3B1C6),
                  offset: Offset(8, 8),
                  blurRadius: 20,
                ),
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  offset: Offset(-8, -8),
                  blurRadius: 20,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 1,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: child,
    );
  }
}

class _NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const _NeumorphicButton({
    required this.child,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<_NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<_NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E5EC),
          shape: widget.shape,
          borderRadius:
              widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(2, 2),
                    blurRadius: 2,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-2, -2),
                    blurRadius: 2,
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0xFFA3B1C6),
                    offset: Offset(4, 4),
                    blurRadius: 10,
                  ),
                  const BoxShadow(
                    color: Color(0xFFFFFFFF),
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _NeumorphicToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NeumorphicToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E5EC),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(2, 2),
              blurRadius: 2,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-2, -2),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn,
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      value ? AppTheme.primaryColor : const Color(0xFFE0E5EC),
                  shape: BoxShape.circle,
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xFFA3B1C6),
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                    const BoxShadow(
                      color: Color(0xFFFFFFFF),
                      offset: Offset(-2, -2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: value
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : const Icon(Icons.close, size: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeumorphicAlertDialog extends StatelessWidget {
  final String title;
  final String content;

  const _NeumorphicAlertDialog({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    const kTextColor = Color(0xFF4A5568);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: _NeumorphicContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kTextColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _NeumorphicButton(
                    onTap: () => Navigator.pop(context, false),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: BorderRadius.circular(15),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: kTextColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _NeumorphicButton(
                    onTap: () => Navigator.pop(context, true),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: BorderRadius.circular(15),
                    child: const Center(
                      child: Text(
                        'Delete',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
