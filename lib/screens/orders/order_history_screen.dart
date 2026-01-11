import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final Set<String> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OrderProvider>(context, listen: false)
          .fetchOrders(refresh: true);
    });
  }

  void _toggleExpanded(String orderId) {
    setState(() {
      if (_expandedOrders.contains(orderId)) {
        _expandedOrders.remove(orderId);
      } else {
        _expandedOrders.add(orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = AppTheme.softUiBackground;
    const kTextColor = AppTheme.softUiTextColor;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: _NeumorphicContainer(
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _NeumorphicButton(
                    onTap: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.all(10),
                    shape: BoxShape.circle,
                    child: const Icon(Icons.arrow_back,
                        color: kTextColor, size: 20),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Order History',
                        style: TextStyle(
                          color: kTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        backgroundColor: kBackgroundColor,
        onRefresh: () async {
          await Provider.of<OrderProvider>(context, listen: false)
              .fetchOrders(refresh: true);
        },
        child: Consumer2<OrderProvider, SettingsProvider>(
          builder: (context, orderProvider, settings, child) {
            if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
              return _buildShimmerLoading();
            }

            if (orderProvider.orders.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              itemCount: orderProvider.orders.length,
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                final isExpanded = _expandedOrders.contains(order.id);
                final firstItem = order.orderItems?.isNotEmpty == true
                    ? order.orderItems!.first
                    : null;
                final thumbnailUrl = firstItem?.watch?.images.isNotEmpty == true
                    ? firstItem!.watch!.images.first
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _NeumorphicOrderCard(
                    orderId: order.id,
                    orderDate: dateFormat.format(order.createdAt),
                    status: order.status,
                    statusDisplay: order.statusDisplay,
                    thumbnailUrl: thumbnailUrl,
                    itemCount: order.orderItems?.length ?? 0,
                    totalAmount: settings.formatPrice(order.totalAmount),
                    isExpanded: isExpanded,
                    onTap: () => _toggleExpanded(order.id),
                    onViewDetails: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderDetailScreen(orderId: order.id),
                        ),
                      );
                    },
                    onBuyAgain: () async {
                      final cartProvider =
                          Provider.of<CartProvider>(context, listen: false);
                      final orderProv =
                          Provider.of<OrderProvider>(context, listen: false);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Adding items to cart...'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          duration: const Duration(seconds: 1),
                        ),
                      );

                      if (order.orderItems == null) {
                        await orderProv.fetchOrderById(order.id);
                      }

                      final fullOrder = orderProv.selectedOrder;
                      if (fullOrder != null && fullOrder.orderItems != null) {
                        final success =
                            await cartProvider.reorder(fullOrder.orderItems!);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Items added to cart successfully!'),
                              backgroundColor: AppTheme.successColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    const kTextColor = Color(0xFF4A5568);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NeumorphicContainer(
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(50),
              isConcave: true,
              child: Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: kTextColor.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'When you place an order, it will appear here. Start exploring our luxury collection!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: kTextColor.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            _NeumorphicButton(
              onTap: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (route) => false);
              },
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              borderRadius: BorderRadius.circular(20),
              child: const Text(
                'Start Shopping',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }
}

class _NeumorphicOrderCard extends StatelessWidget {
  final String orderId;
  final String orderDate;
  final String status;
  final String statusDisplay;
  final String? thumbnailUrl;
  final int itemCount;
  final String totalAmount;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onViewDetails;
  final VoidCallback onBuyAgain;

  const _NeumorphicOrderCard({
    required this.orderId,
    required this.orderDate,
    required this.status,
    required this.statusDisplay,
    required this.thumbnailUrl,
    required this.itemCount,
    required this.totalAmount,
    required this.isExpanded,
    required this.onTap,
    required this.onViewDetails,
    required this.onBuyAgain,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
        return Colors.purple;
      case 'DELIVERED':
        return AppTheme.successColor;
      case 'CANCELLED':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'PENDING':
        return Icons.access_time_rounded;
      case 'PROCESSING':
        return Icons.inventory_2_outlined;
      case 'SHIPPED':
        return Icons.local_shipping_outlined;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining_outlined;
      case 'DELIVERED':
        return Icons.check_circle_outline_rounded;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    const kTextColor = Color(0xFF4A5568);
    final statusColor = _getStatusColor();

    return _NeumorphicContainer(
      borderRadius: BorderRadius.circular(25),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Main Body
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(25),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Thumbnail in Concave Square
                  _NeumorphicContainer(
                    isConcave: true,
                    borderRadius: BorderRadius.circular(15),
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: thumbnailUrl != null
                          ? CachedNetworkImage(
                              imageUrl: thumbnailUrl!,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.watch, color: Colors.grey),
                            )
                          : const Icon(Icons.watch, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderDate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$itemCount item${itemCount != 1 ? 's' : ''} • $totalAmount',
                          style: TextStyle(
                            fontSize: 13,
                            color: kTextColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Pill
                  _NeumorphicIndicatorContainer(
                    isSelected: true,
                    borderRadius: BorderRadius.circular(12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(), size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusDisplay,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Expand Arrow
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: kTextColor.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Section
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(context),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    const kTextColor = Color(0xFF4A5568);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Divider Line (Concave)
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.softUiBackground,
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(1, 1),
                    blurRadius: 1),
                const BoxShadow(
                    color: Colors.white, offset: Offset(-1, -1), blurRadius: 1),
              ],
            ),
          ),

          // Order Timeline
          _OrderTimeline(currentStatus: status),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: _NeumorphicButton(
                  onTap: onViewDetails,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  borderRadius: BorderRadius.circular(12),
                  child: const Center(
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _NeumorphicButton(
                  onTap: onBuyAgain,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  borderRadius: BorderRadius.circular(12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.reorder_rounded,
                          size: 16, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Buy Again',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  final String currentStatus;

  const _OrderTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        status: 'PENDING',
        label: 'Ordered',
        icon: Icons.shopping_bag_outlined,
      ),
      _TimelineStep(
        status: 'PROCESSING',
        label: 'Processing',
        icon: Icons.inventory_2_outlined,
      ),
      _TimelineStep(
        status: 'SHIPPED',
        label: 'Shipped',
        icon: Icons.local_shipping_outlined,
      ),
      _TimelineStep(
        status: 'DELIVERED',
        label: 'Delivered',
        icon: Icons.check_circle_outline_rounded,
      ),
    ];

    if (currentStatus == 'CANCELLED') {
      return _buildCancelledTimeline();
    }

    final currentIndex = _getStatusIndex(currentStatus);

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index <= currentIndex;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Rail
            SizedBox(
              width: 30,
              child: Column(
                children: [
                  // Dot (Convex if completed, Concave if pending)
                  _NeumorphicContainer(
                    isConcave: !isCompleted,
                    shape: BoxShape.circle,
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? _getStepColor(step.status)
                            : Colors.transparent,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 8, color: Colors.white)
                          : null,
                    ),
                  ),

                  // Line (Concave path)
                  if (!isLast)
                    Container(
                      width: 4,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.softUiBackground,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(1, 0),
                              blurRadius: 1),
                          const BoxShadow(
                              color: Colors.white,
                              offset: Offset(-1, 0),
                              blurRadius: 1),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Step Label
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 20),
                child: Row(
                  children: [
                    Icon(
                      step.icon,
                      size: 18,
                      color: isCompleted
                          ? _getStepColor(step.status)
                          : const Color(0xFF4A5568).withOpacity(0.3),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isCompleted ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted
                            ? const Color(0xFF4A5568)
                            : const Color(0xFF4A5568).withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCancelledTimeline() {
    return _NeumorphicIndicatorContainer(
      isSelected: true,
      borderRadius: BorderRadius.circular(15),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined,
              color: AppTheme.errorColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'This order has been cancelled',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getStatusIndex(String status) {
    switch (status) {
      case 'PENDING':
        return 0;
      case 'PROCESSING':
        return 1;
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
        return 2;
      case 'DELIVERED':
        return 3;
      default:
        return 0;
    }
  }

  Color _getStepColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }
}

class _TimelineStep {
  final String status;
  final String label;
  final IconData icon;

  _TimelineStep({
    required this.status,
    required this.label,
    required this.icon,
  });
}

// --- Neumorphic Helpers ---

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final bool isConcave;

  const _NeumorphicContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.isConcave = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.softUiBackground,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: isConcave
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(4, 4),
                    blurRadius: 4,
                    spreadRadius: 1),
                BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(-4, -4),
                    blurRadius: 4,
                    spreadRadius: 1),
              ]
            : [
                const BoxShadow(
                    color: AppTheme.softUiShadowDark,
                    offset: Offset(6, 6),
                    blurRadius: 16),
                const BoxShadow(
                    color: AppTheme.softUiShadowLight,
                    offset: Offset(-6, -6),
                    blurRadius: 16),
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
          color: AppTheme.softUiBackground,
          shape: widget.shape,
          borderRadius:
              widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(2, 2),
                      blurRadius: 2,
                      spreadRadius: 1),
                  const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-2, -2),
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
        child: widget.child,
      ),
    );
  }
}

class _NeumorphicIndicatorContainer extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const _NeumorphicIndicatorContainer({
    required this.child,
    required this.isSelected,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.softUiBackground,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(2, 2),
                    blurRadius: 2,
                    spreadRadius: 1),
                const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-2, -2),
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
      child: child,
    );
  }
}
