import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/admin_provider.dart';
import 'manage_products_screen.dart';
import 'manage_orders_screen.dart';
import 'manage_users_screen.dart';
import 'manage_brands_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_reviews_screen.dart';
import 'manage_banners_screen.dart';
import 'send_notification_screen.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin/admin_layout.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AdminProvider>(context, listen: false)
            .fetchDashboardStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Admin Dashboard',
      currentRoute: '/admin',
      child: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.dashboardStats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.fetchDashboardStats(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header & Period Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overview',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        _buildPeriodToggle(adminProvider),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // KPI Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth > 1400
                            ? 4
                            : (constraints.maxWidth > 900
                                ? 3
                                : (constraints.maxWidth > 600 ? 2 : 1));
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.6,
                          children: [
                            _buildStatCard(
                              context,
                              icon: Icons.payments_outlined,
                              title: 'Total Revenue',
                              value: NumberFormat.compactCurrency(
                                      symbol: '\$', decimalDigits: 2)
                                  .format(adminProvider.totalRevenue),
                              color: Colors.green,
                              onTap: () {},
                              subtitle: 'in selected period',
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.shopping_bag_outlined,
                              title: 'Orders',
                              value: adminProvider.totalOrders.toString(),
                              color: Colors.blue,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ManageOrdersScreen())),
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.attach_money_rounded,
                              title: 'AOV',
                              value: NumberFormat.currency(symbol: '\$')
                                  .format(adminProvider.aov),
                              color: Colors.orange,
                              onTap: () {},
                              subtitle: 'Avg. Order Value',
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.person_add_alt_1_outlined,
                              title: 'Conversion',
                              value:
                                  '${adminProvider.conversionRate.toStringAsFixed(1)}%',
                              color: Colors.purple,
                              onTap: () {},
                              subtitle: 'User -> Buyer',
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.repeat_rounded,
                              title: 'Returning Rate',
                              value:
                                  '${adminProvider.returningRate.toStringAsFixed(1)}%',
                              color: Colors.teal,
                              onTap: () {},
                              subtitle: 'Repeat Buyers',
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.people_outline_rounded,
                              title: 'Total Users',
                              value: adminProvider.totalUsers.toString(),
                              color: Colors.indigo,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ManageUsersScreen())),
                              subtitle: 'Lifetime Value',
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Low Stock Alert
                    if (adminProvider.lowStockWatches.isNotEmpty) ...[
                      _buildAlertSection(adminProvider),
                      const SizedBox(height: 32),
                    ],

                    // Charts Section 1: Trend & Category
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 900;
                        return Column(
                          children: [
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildSalesColumn(adminProvider),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: _buildCategoryColumn(adminProvider),
                                  ),
                                ],
                              )
                            else ...[
                              _buildSalesColumn(adminProvider),
                              const SizedBox(height: 32),
                              _buildCategoryColumn(adminProvider),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Charts Section 2: Brands & Payment Methods
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 900;
                        return Column(
                          children: [
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildBrandColumn(adminProvider),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: _buildPaymentMethodColumn(
                                        adminProvider),
                                  ),
                                ],
                              )
                            else ...[
                              _buildBrandColumn(adminProvider),
                              const SizedBox(height: 32),
                              _buildPaymentMethodColumn(adminProvider),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Top Selling & Activity
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 900;
                        return Column(
                          children: [
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child:
                                        _buildTopSellingColumn(adminProvider),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 3,
                                    child: _buildActivityColumn(adminProvider),
                                  ),
                                ],
                              )
                            else ...[
                              _buildTopSellingColumn(adminProvider),
                              const SizedBox(height: 32),
                              _buildActivityColumn(adminProvider),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                    _buildSectionHeader('Quick Management'),
                    const SizedBox(height: 16),
                    _buildManagementGrid(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlertSection(AdminProvider adminProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.amber.shade100, shape: BoxShape.circle),
            child:
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Low Stock Warning',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        fontSize: 16)),
                Text(
                    '${adminProvider.lowStockWatches.length} items are running low on stock.',
                    style: TextStyle(color: Colors.amber.shade800)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                _showLowStockDialog(context, adminProvider.lowStockWatches),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade900,
                foregroundColor: Colors.white),
            child: const Text('Review Stock'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String value,
      required Color color,
      required VoidCallback onTap,
      String? subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    if (subtitle != null)
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500)),
                  ],
                ),
                const Spacer(),
                Text(value,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(title,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }

  Widget _buildSalesChart(Map<String, double> salesTrend) {
    if (salesTrend.isEmpty)
      return const Card(
          child: SizedBox(height: 350, child: Center(child: Text('No data'))));

    final dates = salesTrend.keys.toList()..sort();
    final values = dates.map((d) => salesTrend[d]!).toList();
    double maxVal =
        (values.isEmpty ? 100 : values.reduce((a, b) => a > b ? a : b)) * 1.2;
    if (maxVal == 0) maxVal = 100;

    return Container(
      height: 350,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxVal / 5,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (v, m) => Text(
                        '\$${NumberFormat.compact().format(v)}',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 10)))),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      int i = v.toInt();
                      if (i >= 0 && i < dates.length)
                        return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                                DateFormat('E')
                                    .format(DateTime.parse(dates[i])),
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 10)));
                      return const SizedBox.shrink();
                    })),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  values.length, (i) => FlSpot(i.toDouble(), values[i])),
              isCurved: true,
              color: Colors.blue.shade600,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                  show: true,
                  getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: Colors.blue.shade600)),
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(colors: [
                    Colors.blue.shade600.withOpacity(0.15),
                    Colors.blue.shade600.withOpacity(0.0)
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesColumn(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Revenue Performance'),
        const SizedBox(height: 16),
        _buildSalesChart(adminProvider.salesTrend),
      ],
    );
  }

  Widget _buildCategoryColumn(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Category Distribution'),
        const SizedBox(height: 16),
        _buildCategoryPieChart(adminProvider.categoryRevenue),
      ],
    );
  }

  Widget _buildTopSellingColumn(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Top Selling Products'),
        const SizedBox(height: 16),
        _buildTopSellingList(adminProvider.topSelling),
      ],
    );
  }

  Widget _buildActivityColumn(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recent Activity'),
        const SizedBox(height: 16),
        _buildActivityFeed(adminProvider.recentActivity),
      ],
    );
  }

  Widget _buildCategoryPieChart(Map<String, double> categoryRevenue) {
    if (categoryRevenue.isEmpty)
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No data available',
                  style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    final colors = [
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.pink
    ];
    int i = 0;
    final sections = categoryRevenue.entries
        .map((e) => PieChartSectionData(
            value: e.value,
            color: colors[i++ % colors.length],
            radius: 40,
            showTitle: false))
        .toList();

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          Expanded(
              child: PieChart(PieChartData(
                  sections: sections,
                  sectionsSpace: 4,
                  centerSpaceRadius: 60))),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: categoryRevenue.keys.take(5).map((cat) {
              final color = colors[
                  categoryRevenue.keys.toList().indexOf(cat) % colors.length];
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(cat,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                )
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingList(List<dynamic> topSelling) {
    if (topSelling.isEmpty)
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Center(
          child: Text('No sales data yet',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topSelling.length,
        itemBuilder: (context, index) {
          final watch = topSelling[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[100],
                        child: watch.images.isNotEmpty
                            ? Image.network(watch.images[0], fit: BoxFit.cover)
                            : const Icon(Icons.watch))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(watch.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('${watch.popularity} orders',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Text('\$${watch.price.toInt()}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityFeed(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty)
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Center(
          child: Text('No recent activity',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.shade50),
        itemBuilder: (context, index) {
          final a = activities[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 18,
                    backgroundColor: a['type'] == 'order'
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    child: Icon(
                        a['type'] == 'order'
                            ? Icons.shopping_basket_outlined
                            : Icons.person_outline,
                        size: 18,
                        color:
                            a['type'] == 'order' ? Colors.green : Colors.blue)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['title'],
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(a['subtitle'],
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(DateFormat('HH:mm').format(a['time'] as DateTime),
                    style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildManagementGrid() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user!;
        final actions = [
          if (user.canManageProducts)
            _ActionItem(Icons.inventory_2_outlined, 'Products',
                'Inventory & Price', Colors.blue, const ManageProductsScreen()),
          if (user.canManageOrders)
            _ActionItem(Icons.local_shipping_outlined, 'Orders',
                'Tracking & Status', Colors.green, const ManageOrdersScreen()),
          if (user.canManageUsers)
            _ActionItem(Icons.group_outlined, 'Users', 'Roles & Access',
                Colors.orange, const ManageUsersScreen()),
          if (user.canManageCategories)
            _ActionItem(Icons.category_outlined, 'Categories', 'Taxonomy',
                Colors.teal, const ManageCategoriesScreen()),
          if (user.canManageBrands)
            _ActionItem(Icons.diamond_outlined, 'Brands', 'Manufacturer list',
                Colors.indigo, const ManageBrandsScreen()),
          _ActionItem(Icons.star_outline_rounded, 'Reviews', 'User Feedback',
              Colors.amber, const ManageReviewsScreen()),
          if (user.canManageBanners)
            _ActionItem(Icons.view_carousel_outlined, 'Banners', 'Marketing',
                Colors.cyan, const ManageBannersScreen()),
          _ActionItem(Icons.notifications_none_rounded, 'Broadcast',
              'Push Alerts', Colors.redAccent, const SendNotificationScreen()),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final item = actions[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade100)),
              child: InkWell(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => item.screen)),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 32, color: item.color),
                      const SizedBox(height: 12),
                      Text(item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(item.subtitle,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLowStockDialog(
      BuildContext context, List<dynamic> lowStockWatches) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Low Stock'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: 500,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: lowStockWatches.length,
            itemBuilder: (context, index) {
              final watch = lowStockWatches[index];
              final controller =
                  TextEditingController(text: watch.stock.toString());
              return ListTile(
                title: Text(watch.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Current: ${watch.stock} units'),
                trailing: SizedBox(
                    width: 80,
                    child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8))),
                        onSubmitted: (v) async {
                          final n = int.tryParse(v);
                          if (n != null)
                            await Provider.of<AdminProvider>(context,
                                    listen: false)
                                .updateWatchStock(watch.id, n);
                        })),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodToggle(AdminProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['day', 'week', 'month'].map((p) {
          bool isSelected = provider.period == p;
          return GestureDetector(
            onTap: () => provider.setPeriod(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                p[0].toUpperCase() + p.substring(1),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBrandColumn(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Sales by Brand'),
        const SizedBox(height: 16),
        _buildBarChart(adminProvider.brandSales),
      ],
    );
  }

  Widget _buildPaymentMethodColumn(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Payment Channels'),
        const SizedBox(height: 16),
        _buildCategoryPieChart(adminProvider.paymentMethodStats),
      ],
    );
  }

  Widget _buildBarChart(Map<String, double> data) {
    if (data.isEmpty)
      return Container(
          height: 200, child: const Center(child: Text('No Data')));

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(7).toList();

    return Container(
      height: 350,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, m) {
                      if (v.toInt() >= 0 && v.toInt() < topEntries.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            topEntries[v.toInt()].key.length > 6
                                ? topEntries[v.toInt()].key.substring(0, 6) +
                                    '..'
                                : topEntries[v.toInt()].key,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    })),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(topEntries.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: topEntries[index].value,
                  color: Colors.indigoAccent,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget screen;
  const _ActionItem(
      this.icon, this.title, this.subtitle, this.color, this.screen);
}
