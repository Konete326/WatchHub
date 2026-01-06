import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import 'manage_products_screen.dart';
import 'manage_orders_screen.dart';
import 'manage_users_screen.dart';
import 'manage_reviews_screen.dart';
import 'manage_faqs_screen.dart';
import 'manage_tickets_screen.dart';
import 'manage_banners_screen.dart';
import 'shipping_settings_screen.dart';
import 'manage_coupons_screen.dart';
import 'manage_promotion_screen.dart';
import 'manage_brands_screen.dart';
import 'manage_categories_screen.dart';
import 'send_notification_screen.dart';
import '../../widgets/admin/admin_drawer.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AdminProvider>(context, listen: false)
            .fetchDashboardStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      drawer: const AdminDrawer(),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.dashboardStats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.fetchDashboardStats(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          context,
                          icon: Icons.people,
                          title: 'Total Users',
                          value: adminProvider.totalUsers.toString(),
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.shopping_bag,
                          title: 'Total Orders',
                          value: adminProvider.totalOrders.toString(),
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.watch,
                          title: 'Total Watches',
                          value: adminProvider.totalWatches.toString(),
                          color: Colors.orange,
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.attach_money,
                          title: 'Total Revenue',
                          value: NumberFormat.currency(
                                  symbol: '\$', decimalDigits: 0)
                              .format(adminProvider.totalRevenue),
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),

                  // Low Stock Alert
                  if (adminProvider.lowStockWatches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        color: Colors.orange[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning,
                                      color: Colors.orange[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Low Stock Alert',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${adminProvider.lowStockWatches.length} watch(es) have low stock (≤5 units)',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _showLowStockDialog(
                                      context, adminProvider.lowStockWatches),
                                  icon: const Icon(Icons.inventory),
                                  label: const Text('Resolve'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.orange[700],
                                    backgroundColor:
                                        Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Sales Trend Graph
                  _buildSectionHeader('Weekly Sales Trend'),
                  _buildSalesChart(adminProvider.salesTrend),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Selling Products
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Top Selling'),
                            _buildTopSellingList(adminProvider.topSelling),
                          ],
                        ),
                      ),
                      // Category Revenue Pie Chart
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Categories'),
                            _buildCategoryPieChart(
                                adminProvider.categoryRevenue),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Recent Activity
                  _buildSectionHeader('Recent Activity'),
                  _buildActivityFeed(adminProvider.recentActivity),

                  const SizedBox(height: 16),

                  // Management Cards
                  _buildSectionHeader('Quick Actions'),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        final user = auth.user!;
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            if (user.canManageProducts)
                              _buildDashboardCard(
                                context,
                                icon: Icons.watch,
                                title: 'Manage Products',
                                subtitle: 'Add, edit, or remove watches',
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageProductsScreen(),
                                    ),
                                  );
                                },
                              ),
                            if (user.canManageBrands)
                              _buildDashboardCard(
                                context,
                                icon: Icons.business,
                                title: 'Manage Brands',
                                subtitle: 'Add and edit watch brands',
                                color: Colors.indigo,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageBrandsScreen(),
                                    ),
                                  );
                                },
                              ),
                            if (user.canManageCategories)
                              _buildDashboardCard(
                                context,
                                icon: Icons.category,
                                title: 'Manage Categories',
                                subtitle: 'Organize watches by types',
                                color: Colors.teal,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageCategoriesScreen(),
                                    ),
                                  );
                                },
                              ),
                            if (user.canManageOrders)
                              _buildDashboardCard(
                                context,
                                icon: Icons.shopping_bag,
                                title: 'Manage Orders',
                                subtitle: 'View and update order status',
                                color: Colors.green,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageOrdersScreen(),
                                    ),
                                  );
                                },
                              ),
                            if (user.canManageUsers)
                              _buildDashboardCard(
                                context,
                                icon: Icons.people,
                                title: 'Manage Users',
                                subtitle: 'View and manage users',
                                color: Colors.orange,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageUsersScreen(),
                                    ),
                                  );
                                },
                              ),
                            _buildDashboardCard(
                              context,
                              icon: Icons.star,
                              title: 'Manage Reviews',
                              subtitle: 'Moderate user reviews',
                              color: Colors.amber,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ManageReviewsScreen(),
                                  ),
                                );
                              },
                            ),
                            if (user.canManageFAQs)
                              _buildDashboardCard(
                                context,
                                icon: Icons.help_outline,
                                title: 'Manage FAQs',
                                subtitle: 'Add and edit FAQs',
                                color: Colors.purple,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageFAQsScreen(),
                                    ),
                                  );
                                },
                              ),
                            if (user.canManageTickets)
                              _buildDashboardCard(
                                context,
                                icon: Icons.support_agent,
                                title: 'Support Tickets',
                                subtitle: 'Handle customer support',
                                color: Colors.red,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageTicketsScreen(),
                                    ),
                                  );
                                },
                              ),
                            if (user.canManageBanners)
                              _buildDashboardCard(
                                context,
                                icon: Icons.image,
                                title: 'Manage Banners',
                                subtitle: 'Home screen sliders',
                                color: Colors.cyan,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageBannersScreen(),
                                    ),
                                  );
                                },
                              ),
                            if (user.canManageSettings)
                              _buildDashboardCard(
                                context,
                                icon: Icons.local_shipping,
                                title: 'Shipping Settings',
                                subtitle: 'Delivery charges & rules',
                                color: Colors.amber,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ShippingSettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            if (user.canManageCoupons)
                              _buildDashboardCard(
                                context,
                                icon: Icons.confirmation_number,
                                title: 'Coupons',
                                subtitle: 'Manage discount codes',
                                color: Colors.purple,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageCouponsScreen(),
                                    ),
                                  );
                                },
                              ),
                            if (user.canManagePromotions)
                              _buildDashboardCard(
                                context,
                                icon: Icons.campaign,
                                title: 'Sale Highlights',
                                subtitle: 'Promotional ads on home',
                                color: Colors.deepOrange,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManagePromotionScreen(),
                                    ),
                                  );
                                },
                              ),
                            _buildDashboardCard(
                              context,
                              icon: Icons.notifications_active,
                              title: 'Broadcast',
                              subtitle: 'Send push notification',
                              color: Colors.redAccent,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SendNotificationScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
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

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSalesChart(Map<String, double> salesTrend) {
    if (salesTrend.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No sales data available')),
      );
    }

    final dates = salesTrend.keys.toList();
    dates.sort();
    final values = dates.map((d) => salesTrend[d]!).toList();

    double maxValue =
        values.isEmpty ? 100 : values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) maxValue = 100;

    // Add margin to max value for better visualization
    maxValue = maxValue * 1.2;

    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 8), // Added right padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxValue,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < dates.length) {
                    final date = DateTime.parse(dates[index]);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('E').format(date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  values.length, (i) => FlSpot(i.toDouble(), values[i])),
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(2)}',
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSellingList(List<dynamic> topSelling) {
    if (topSelling.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No products sold yet'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topSelling.length,
      itemBuilder: (context, index) {
        final watch = topSelling[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: watch.images.isNotEmpty
                ? Image.network(watch.images[0], fit: BoxFit.cover)
                : const Icon(Icons.watch),
          ),
          title: Text(
            watch.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${watch.popularity} orders',
            style: const TextStyle(fontSize: 10),
          ),
          trailing: Text(
            '\$${watch.price.toInt()}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildCategoryPieChart(Map<String, double> categoryRevenue) {
    if (categoryRevenue.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('No data')),
      );
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];

    int colorIndex = 0;
    final sections = categoryRevenue.entries.map((e) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: e.value,
        title: '',
        radius: 40,
        color: color,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...categoryRevenue.keys.take(3).map((cat) {
          final index = categoryRevenue.keys.toList().indexOf(cat);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  color: colors[index % colors.length],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    cat,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActivityFeed(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No recent activity'),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          final type = activity['type'];
          final time = activity['time'] as DateTime;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  type == 'order' ? Colors.green[50] : Colors.blue[50],
              child: Icon(
                type == 'order' ? Icons.shopping_cart : Icons.person_add,
                color: type == 'order' ? Colors.green : Colors.blue,
                size: 20,
              ),
            ),
            title: Text(
              activity['title'],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              activity['subtitle'],
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              DateFormat('HH:mm').format(time),
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          );
        },
      ),
    );
  }

  void _showLowStockDialog(
      BuildContext context, List<dynamic> lowStockWatches) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Low Stock Items'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: lowStockWatches.length,
            itemBuilder: (context, index) {
              final watch = lowStockWatches[index];
              final TextEditingController controller =
                  TextEditingController(text: watch.stock.toString());

              return ListTile(
                title: Text(watch.name),
                subtitle: Text('Current Stock: ${watch.stock}'),
                trailing: SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.all(8),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          final newStock = int.tryParse(controller.text);
                          if (newStock != null) {
                            final success = await Provider.of<AdminProvider>(
                                    context,
                                    listen: false)
                                .updateWatchStock(watch.id, newStock);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Stock updated for ${watch.name}'
                                      : 'Failed to update stock'),
                                  backgroundColor:
                                      success ? Colors.green : Colors.red,
                                ),
                              );
                              if (success) {
                                Navigator.pop(
                                    context); // Close dialog to refresh or keep open?
                                // Better to keep open but state needs update.
                                // Since provider updates, if we use consumer here or just rely on parent rebuild..
                                // Actually Dialog needs to rebuild to show new stock.
                                // For simplicity, let's close it or maybe just clear focus.
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
