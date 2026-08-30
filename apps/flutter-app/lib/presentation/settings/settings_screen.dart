import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile section
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      (user['full_name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(user['email'] ?? '', style: TextStyle(color: Colors.grey[700])),
                  if (user['phone_number'] != null)
                    Text(user['phone_number'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _buildSettingsTile(
            icon: Icons.person_outlined,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.lock_outlined,
            title: 'Change Password',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            onTap: () {},
          ),

          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Mobile Money', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _buildSettingsTile(
            icon: Icons.phone_android,
            title: 'Connected Accounts',
            subtitle: 'Manage Airtel Money & MTN MoMo',
            onTap: () {},
          ),

          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('App', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _buildSettingsTile(
            icon: Icons.info_outlined,
            title: 'About Smart Budget ZM',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Financial Disclaimer',
            onTap: () => _showDisclaimer(context),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Financial Disclaimer'),
        content: const Text(
          'Smart Budget ZM provides financial insights and recommendations based on your transaction data. '
          'These insights are for informational purposes only and should not be considered professional financial advice. '
          'Please consult a qualified financial advisor for important financial decisions.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('I Understand')),
        ],
      ),
    );
  }
}
