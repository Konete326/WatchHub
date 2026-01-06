import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/manage_products_screen.dart';
import '../../screens/admin/manage_orders_screen.dart';
import '../../screens/admin/manage_users_screen.dart';
import '../../screens/admin/manage_categories_screen.dart';
import '../../screens/admin/manage_brands_screen.dart';
import '../../screens/admin/manage_reviews_screen.dart';
import '../../screens/admin/manage_banners_screen.dart';
import '../../screens/admin/manage_promotion_screen.dart';
import '../../screens/admin/manage_coupons_screen.dart';
import '../../screens/admin/shipping_settings_screen.dart';
import '../../screens/admin/manage_faqs_screen.dart';
import '../../screens/admin/manage_tickets_screen.dart';
import '../../screens/admin/send_notification_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Admin'),
            accountEmail: const Text('admin@watchhub.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings,
                  size: 32, color: Colors.blue),
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(context, Icons.dashboard, 'Dashboard',
                    const AdminDashboardScreen(),
                    isReplacement: true),
                _buildDrawerItem(context, Icons.watch, 'Products',
                    const ManageProductsScreen()),
                _buildDrawerItem(context, Icons.shopping_bag, 'Orders',
                    const ManageOrdersScreen()),
                _buildDrawerItem(
                    context, Icons.people, 'Users', const ManageUsersScreen()),
                _buildDrawerItem(context, Icons.category, 'Categories',
                    const ManageCategoriesScreen()),
                _buildDrawerItem(context, Icons.business, 'Brands',
                    const ManageBrandsScreen()),
                _buildDrawerItem(context, Icons.star, 'Reviews',
                    const ManageReviewsScreen()),
                _buildDrawerItem(context, Icons.image, 'Banners',
                    const ManageBannersScreen()),
                _buildDrawerItem(context, Icons.campaign, 'Promotions',
                    const ManagePromotionScreen()),
                _buildDrawerItem(context, Icons.confirmation_number, 'Coupons',
                    const ManageCouponsScreen()),
                _buildDrawerItem(context, Icons.local_shipping, 'Shipping',
                    const ShippingSettingsScreen()),
                _buildDrawerItem(context, Icons.help_outline, 'FAQs',
                    const ManageFAQsScreen()),
                _buildDrawerItem(context, Icons.support_agent, 'Tickets',
                    const ManageTicketsScreen()),
                _buildDrawerItem(context, Icons.notifications_active,
                    'Notifications', const SendNotificationScreen()),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
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

              if (confirm == true && context.mounted) {
                await Provider.of<AuthProvider>(context, listen: false)
                    .logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, Widget page,
      {bool isReplacement = false}) {
    // Check if we are currently on this page to highlight it or disable navigation
    // Determining exactly which page we are on from context is tricky without named routes
    // For now, we just allow navigation.

    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: TextStyle(color: Colors.grey[800])),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (isReplacement) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => page),
          );
        } else {
          // If we are already on this page (e.g. from Dashboard -> Products),
          // pushing again stacks it. Ideally we should replace if we are "switching" tabs.
          // But since we are not using a ShellRoute matching structure, simple push is safer
          // to avoid losing the dashboard history if they want to go back.
          // However, for a sidebar, usuallly users expect "Switching sections".
          // Let's use pushReplacement to act like a tab switch, but keep Dashboard as "Home".

          // Actually, if we use pushReplacement everywhere, we lose the "Back" to Dashboard.
          // Safe bet: Push. But if the user clicks Products, then Orders, they have a stack [Dash, Prod, Ord].
          // Back goes Ord -> Prod -> Dash.
          // If they want "Root" navigation, they should click Dashboard.
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
    );
  }
}
