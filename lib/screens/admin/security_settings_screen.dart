import 'package:flutter/material.dart';
import '../../widgets/admin/admin_drawer.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & RBAC'),
      ),
      drawer: const AdminDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSecurityCard(
            Icons.verified_user,
            'Two-Factor Authentication (2FA)',
            'Enforce 2FA for all administrative accounts for enhanced security.',
            trailing: Switch(value: true, onChanged: (v) {}),
          ),
          const SizedBox(height: 16),
          _buildSecurityCard(
            Icons.webhook,
            'IP Allowlisting',
            'Restrict administrative access to specific IP ranges or static office IPs.',
            onTap: () => _showIpAllowlistDialog(),
          ),
          const SizedBox(height: 16),
          _buildSecurityCard(
            Icons.admin_panel_settings,
            'Role-Based Access Control',
            'Define what each role (Admin, Employee) can do in the dashboard.',
            onTap: () => _showRbacInfo(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Audit Log Policy',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Audit logs are kept for 90 days. Every action taken by an actor is recorded with before/after snapshots.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(IconData icon, String title, String subtitle,
      {Widget? trailing, VoidCallback? onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: Colors.blue, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(fontSize: 12)),
        ),
        trailing: trailing ??
            (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }

  void _showIpAllowlistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Global IP Allowlist'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Add IP Address',
                hintText: 'e.g. 192.168.1.1',
              ),
            ),
            SizedBox(height: 8),
            Text('Currently allowed: All (Open Access)',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Update')),
        ],
      ),
    );
  }

  void _showRbacInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RBAC Definition',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildRoleInfo('ADMIN',
                'Full system access. Can manage settings, security, and users.'),
            _buildRoleInfo('EMPLOYEE',
                'Can manage products, orders, and brands. Cannot change security or delete users.'),
            _buildRoleInfo('PRIVILEGED',
                'Expanded employee with ticket management and refund rights.'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleInfo(String role, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
          Text(desc, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
