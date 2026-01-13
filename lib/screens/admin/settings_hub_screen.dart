import 'package:flutter/material.dart';
import '../../widgets/admin/admin_drawer.dart';
import 'manage_shipping_zones_screen.dart';
import 'manage_tax_rules_screen.dart';
import 'manage_return_policies_screen.dart';
import 'manage_channels_screen.dart';
import 'security_settings_screen.dart';
import 'shipping_settings_screen.dart';

class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Store Settings'),
      ),
      drawer: const AdminDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('General Configuration'),
          _buildSettingsCard(
            context,
            Icons.settings,
            'Global Settings',
            'Currency, delivery thresholds, and base charges.',
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ShippingSettingsScreen())),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Logistics & Finance'),
          _buildSettingsCard(
            context,
            Icons.local_shipping,
            'Shipping Zones',
            'Define countries, regions, and weight-based rates.',
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ManageShippingZonesScreen())),
          ),
          _buildSettingsCard(
            context,
            Icons.receipt_long,
            'Tax Rules',
            'Configure VAT, Sales tax per country/state.',
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ManageTaxRulesScreen())),
          ),
          _buildSettingsCard(
            context,
            Icons.assignment_return,
            'Return Policies',
            'Templates for product returns and restocking fees.',
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ManageReturnPoliciesScreen())),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Sales Channels'),
          _buildSettingsCard(
            context,
            Icons.devices,
            'Storefront Channels',
            'Manage Web and App configurations.',
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ManageChannelsScreen())),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Security & Access'),
          _buildSettingsCard(
            context,
            Icons.security,
            'Security & RBAC',
            '2FA, IP allowlists, and fine-grained permissions.',
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SecuritySettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(fontSize: 12)),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
