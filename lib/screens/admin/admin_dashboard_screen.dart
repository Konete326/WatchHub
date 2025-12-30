import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
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
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await Provider.of<AuthProvider>(context, listen: false)
                    .logout();
                if (mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
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
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Management Cards
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
}
