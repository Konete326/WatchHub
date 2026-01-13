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
import '../../utils/haptics.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';

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
    HapticHelper.light();
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
              return const ListShimmer(itemCount: 6);
            }

            if (orderProvider.orders.isEmpty) {
              return EmptyState(
                lottieUrl:
                    'https://assets10.lottiefiles.com/packages/lf20_p366v7bb.json', // Order history animation
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message:
                    'When you place an order, it will appear here. Start exploring our luxury collection!',
                actionLabel: 'Start Shopping',
                onActionPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false);
                },
              );
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
                      HapticHelper.medium();

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

  // Removed unused _buildEmptyState and _buildShimmerLoading in favor of consistent widgets
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

          // Actions Row 1: Details & Buy Again
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
          const SizedBox(height: 16),
          // Actions Row 2: Invoice & Return
          Row(
            children: [
              Expanded(
                child: _NeumorphicButton(
                  onTap: () {
                    // Placeholder for invoice download
                    HapticHelper.success();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading Invoice...')),
                    );
                  },
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded,
                          size: 16, color: kTextColor.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      const Text(
                        'Invoice',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (status == 'DELIVERED')
                Expanded(
                  child: _NeumorphicButton(
                    onTap: () {
                      // Placeholder for return/exchange
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Initiating Return/Exchange request...')),
                      );
                    },
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: BorderRadius.circular(12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard_return_rounded,
                            size: 16, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text(
                          'Return',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),
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
    if (currentStatus == 'CANCELLED') {
      return _buildCancelledTimeline();
    }

    final steps = [
      _TimelineStep(
        status: 'PENDING',
        label: 'Order Placed',
        description: 'Your order has been confirmed',
        icon: Icons.shopping_bag_outlined,
      ),
      _TimelineStep(
        status: 'PROCESSING',
        label: 'Processing',
        description: 'We are preparing your order',
        icon: Icons.inventory_2_outlined,
      ),
      _TimelineStep(
        status: 'SHIPPED',
        label: 'Shipped',
        description: 'Your order is on the way',
        icon: Icons.local_shipping_outlined,
      ),
      _TimelineStep(
        status: 'OUT_FOR_DELIVERY',
        label: 'Out for Delivery',
        description: 'Arriving today',
        icon: Icons.delivery_dining_outlined,
      ),
      _TimelineStep(
        status: 'DELIVERED',
        label: 'Delivered',
        description: 'Order completed successfully',
        icon: Icons.check_circle_outline_rounded,
      ),
    ];

    final currentIndex = _getStatusIndex(currentStatus);
    final progressPercent = (currentIndex / (steps.length - 1)).clamp(0.0, 1.0);

    return Column(
      children: [
        // Progress Bar
        _NeumorphicContainer(
          isConcave: true,
          borderRadius: BorderRadius.circular(10),
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E5EC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Progress
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    widthFactor: progressPercent,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStepColor(currentStatus),
                            _getStepColor(currentStatus).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Step Icons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Expanded(
              child: Column(
                children: [
                  // Icon Circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isCurrent ? 44 : 36,
                    height: isCurrent ? 44 : 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? _getStepColor(step.status)
                          : const Color(0xFFE0E5EC),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color:
                                    _getStepColor(step.status).withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : isCompleted
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                  const BoxShadow(
                                    color: Colors.white,
                                    offset: Offset(-2, -2),
                                    blurRadius: 4,
                                  ),
                                ],
                    ),
                    child: Icon(
                      step.icon,
                      size: isCurrent ? 22 : 18,
                      color: isCompleted
                          ? Colors.white
                          : const Color(0xFF4A5568).withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Label
                  Text(
                    step.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted
                          ? const Color(0xFF4A5568)
                          : const Color(0xFF4A5568).withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Current Step Description Card
        _NeumorphicIndicatorContainer(
          isSelected: true,
          borderRadius: BorderRadius.circular(15),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStepColor(currentStatus).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  steps[currentIndex].icon,
                  color: _getStepColor(currentStatus),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[currentIndex].label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStepColor(currentStatus),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[currentIndex].description,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF4A5568).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancelledTimeline() {
    return _NeumorphicIndicatorContainer(
      isSelected: true,
      borderRadius: BorderRadius.circular(15),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined,
                color: AppTheme.errorColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Cancelled',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This order has been cancelled',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF4A5568).withOpacity(0.7),
                  ),
                ),
              ],
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
        return 2;
      case 'OUT_FOR_DELIVERY':
        return 3;
      case 'DELIVERED':
        return 4;
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
      case 'OUT_FOR_DELIVERY':
        return Colors.deepPurple;
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
  final String description;
  final IconData icon;

  _TimelineStep({
    required this.status,
    required this.label,
    required this.description,
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
