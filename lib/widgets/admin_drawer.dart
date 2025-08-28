import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/posts/manage_posts_screen.dart';
import '../screens/orders/manage_orders_screen.dart';
import '../screens/accounts/manage_accounts_screen.dart';
import '../screens/banners/manage_banners_screen.dart';
import 'package:vietmall_admin/screens/Contact/manage_support_screen.dart';
import 'package:vietmall_admin/services/auth_service.dart';
import 'package:vietmall_admin/screens/login_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings,
                      size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'VietMall Management',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Control Panel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _tile(context, Icons.dashboard, 'Dashboard',
                          () => _go(context, const DashboardScreen())),
                  _tile(context, Icons.fact_check, 'Manage Posts',
                          () => _go(context, const ManagePostsScreen())),
                  _tile(context, Icons.inventory_2, 'Manage Orders',
                          () => _go(context, const ManageOrdersScreen())),
                  _tile(context, Icons.people_alt, 'Manage Accounts',
                          () => _go(context, const ManageAccountsScreen())),
                  _tile(context, Icons.image, 'Manage Banners',
                          () => _go(context, const ManageBannersScreen())),
                  _tile(context, Icons.support_agent_outlined, 'Manage Contact',
                          () => _go(context, const ManageSupportScreen())),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w500)),
              onTap: () async {
                await AuthService().signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext ctx, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[800]),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: Colors.blue.shade50,
      selectedTileColor: Colors.blue.shade100,
    );
  }

  void _go(BuildContext ctx, Widget page) {
    Navigator.of(ctx).pop();
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => page));
  }
}
