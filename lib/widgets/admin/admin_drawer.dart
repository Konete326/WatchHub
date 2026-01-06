import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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
                    routeName: '/admin', isReplacement: true),
                _buildDrawerItem(context, Icons.watch, 'Products',
                    routeName: '/admin/products'),
                _buildDrawerItem(context, Icons.shopping_bag, 'Orders',
                    routeName: '/admin/orders'),
                _buildDrawerItem(context, Icons.people, 'Users',
                    routeName: '/admin/users'),
                _buildDrawerItem(context, Icons.category, 'Categories',
                    routeName: '/admin/categories'),
                _buildDrawerItem(context, Icons.business, 'Brands',
                    routeName: '/admin/brands'),
                _buildDrawerItem(context, Icons.star, 'Reviews',
                    routeName: '/admin/reviews'),
                _buildDrawerItem(context, Icons.image, 'Banners',
                    routeName: '/admin/banners'),
                _buildDrawerItem(context, Icons.campaign, 'Promotions',
                    routeName: '/admin/promotions'),
                _buildDrawerItem(context, Icons.confirmation_number, 'Coupons',
                    routeName: '/admin/coupons'),
                _buildDrawerItem(context, Icons.local_shipping, 'Shipping',
                    routeName: '/admin/shipping'),
                _buildDrawerItem(context, Icons.help_outline, 'FAQs',
                    routeName: '/admin/faqs'),
                _buildDrawerItem(context, Icons.support_agent, 'Tickets',
                    routeName: '/admin/tickets'),
                _buildDrawerItem(context, Icons.history, 'Audit Logs',
                    routeName: '/admin/audit-logs'),
                _buildDrawerItem(
                    context, Icons.notifications_active, 'Notifications',
                    routeName: '/admin/notifications'),
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

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title,
      {bool isReplacement = false, required String routeName}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: TextStyle(color: Colors.grey[800])),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (isReplacement) {
          Navigator.of(context).pushReplacementNamed(routeName);
        } else {
          Navigator.of(context).pushNamed(routeName);
        }
      },
    );
  }
}
