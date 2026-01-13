import 'package:flutter/material.dart';

class AdminSidebar extends StatefulWidget {
  final bool isCollapsed;
  final Function(bool) onToggle;
  final String currentRoute;

  const AdminSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
    required this.currentRoute,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 80 : 260,
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildSidebarItem(
                    Icons.dashboard_rounded, 'Dashboard', '/admin'),
                _buildSidebarItem(
                    Icons.watch_rounded, 'Products', '/admin/products'),
                _buildSidebarItem(
                    Icons.shopping_bag_rounded, 'Orders', '/admin/orders'),
                _buildSidebarItem(
                    Icons.people_rounded, 'Users', '/admin/users'),
                _buildSidebarItem(
                    Icons.category_rounded, 'Categories', '/admin/categories'),
                _buildSidebarItem(
                    Icons.business_rounded, 'Brands', '/admin/brands'),
                _buildSidebarItem(
                    Icons.star_rounded, 'Reviews', '/admin/reviews'),
                const Divider(indent: 20, endIndent: 20),
                _buildSidebarItem(
                    Icons.image_rounded, 'Banners', '/admin/banners'),
                _buildSidebarItem(
                    Icons.campaign_rounded, 'Promotions', '/admin/promotions'),
                _buildSidebarItem(Icons.confirmation_number_rounded, 'Coupons',
                    '/admin/coupons'),
                _buildSidebarItem(Icons.local_shipping_rounded, 'Shipping',
                    '/admin/shipping'),
                const Divider(indent: 20, endIndent: 20),
                _buildSidebarItem(
                    Icons.help_outline_rounded, 'FAQs', '/admin/faqs'),
                _buildSidebarItem(
                    Icons.support_agent_rounded, 'Tickets', '/admin/tickets'),
                _buildSidebarItem(Icons.notifications_active_rounded,
                    'Broadcast', '/admin/notifications'),
              ],
            ),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: widget.isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          const SizedBox(width: 20),
          Icon(Icons.admin_panel_settings,
              color: Colors.blue.shade700, size: 32),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 12),
            const Text(
              'WatchHub',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, String route) {
    bool isSelected = widget.currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          if (widget.currentRoute != route) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.blue.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: IconButton(
        icon: Icon(
          widget.isCollapsed
              ? Icons.chevron_right_rounded
              : Icons.chevron_left_rounded,
          color: Colors.grey.shade600,
        ),
        onPressed: () => widget.onToggle(!widget.isCollapsed),
      ),
    );
  }
}
